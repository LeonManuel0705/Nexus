from flask import Flask, request, jsonify, send_from_directory, send_file
from flask_cors import CORS
from flask_socketio import SocketIO, emit
import os
import threading
from datetime import datetime
from io import BytesIO
import json

import database as db
from recorder import get_recorder, list_audio_devices, get_default_input_device
from transcriber import (
    transcribe_audio, cleanup_audio_file, get_available_models,
    preload_model, transcribe_audio_chunk, get_ollama_status,
    get_correction_status, reset_session
)

app = Flask(__name__, static_folder='static')
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')

# Real-time transcription state
realtime_active = False
realtime_thread = None
current_transcription = []
current_subject = None  # Track current folder/subject for context

def preload_whisper():
    preload_model("small")

threading.Thread(target=preload_whisper, daemon=True).start()

# ============== Static Files ==============

@app.route('/')
def index():
    return send_from_directory('static', 'index.html')

@app.route('/static/<path:path>')
def serve_static(path):
    return send_from_directory('static', path)

# ============== Real-time Transcription ==============

def realtime_transcription_worker():
    """Background worker for real-time transcription with AI correction."""
    global realtime_active, current_transcription, current_subject

    recorder = get_recorder()

    while realtime_active and recorder.is_recording():
        chunk = recorder.get_next_chunk(timeout=0.5)

        if chunk is not None:
            try:
                # Transcribe with speaker filtering and AI correction
                # Text is only returned AFTER correction is applied
                text = transcribe_audio_chunk(
                    chunk,
                    filter_non_teacher=True,
                    apply_correction=True,
                    subject=current_subject
                )

                if text and text.strip():
                    current_transcription.append(text.strip())
                    socketio.emit('transcription_update', {
                        'text': text.strip(),
                        'full_text': ' '.join(current_transcription),
                        'is_final': False,
                        'is_corrected': True  # Always corrected now
                    })
            except Exception as e:
                print(f"Transcription error: {e}")

@socketio.on('start_realtime')
def handle_start_realtime(data):
    """Start real-time recording and transcription."""
    global realtime_active, realtime_thread, current_transcription, current_subject

    folder_id = data.get('folder_id')
    recorder = get_recorder()

    if recorder.is_recording():
        emit('error', {'message': 'Already recording'})
        return

    # Reset for new session
    current_transcription = []
    realtime_active = True
    reset_session()  # Reset speaker tracking

    # Get subject from folder for context-aware correction
    current_subject = None
    if folder_id:
        folder = db.get_folder(folder_id)
        if folder:
            current_subject = folder.get('name')

    recorder.start_recording()

    realtime_thread = threading.Thread(target=realtime_transcription_worker, daemon=True)
    realtime_thread.start()

    emit('recording_started', {
        'message': 'Recording started',
        'subject': current_subject
    })

@socketio.on('stop_realtime')
def handle_stop_realtime(data):
    """Stop real-time recording and save the note."""
    global realtime_active, current_transcription, current_subject

    folder_id = data.get('folder_id')
    recorder = get_recorder()

    if not recorder.is_recording():
        emit('error', {'message': 'Not recording'})
        return

    realtime_active = False
    audio_path, duration = recorder.stop_recording()

    # Do final transcription of full audio for accuracy
    result = None
    if audio_path:
        result = transcribe_audio(audio_path, subject=current_subject)
        cleanup_audio_file(audio_path)

        if result['success']:
            final_text = result['text']
        else:
            final_text = ' '.join(current_transcription)
    else:
        final_text = ' '.join(current_transcription)

    # Save the note
    if final_text.strip():
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
        title = f"Voice Note - {timestamp}"

        note_id = db.create_note(
            title=title,
            content=final_text,
            folder_id=folder_id,
            language=result.get('language', 'de') if result else 'de',
            audio_duration=duration
        )

        note = db.get_note(note_id)

        emit('recording_stopped', {
            'success': True,
            'note': note,
            'final_text': final_text,
            'duration': duration,
            'used_ai': result.get('used_ai_correction', False) if result else False
        })
    else:
        emit('recording_stopped', {
            'success': False,
            'message': 'No speech detected'
        })

# ============== Recording API (non-realtime fallback) ==============

@app.route('/api/recording/start', methods=['POST'])
def start_recording():
    recorder = get_recorder()
    if recorder.is_recording():
        return jsonify({'success': False, 'error': 'Already recording'}), 400

    reset_session()
    success = recorder.start_recording()
    return jsonify({'success': success})

@app.route('/api/recording/stop', methods=['POST'])
def stop_recording():
    recorder = get_recorder()
    if not recorder.is_recording():
        return jsonify({'success': False, 'error': 'Not recording'}), 400

    data = request.get_json() or {}
    folder_id = data.get('folder_id')

    # Get subject for context
    subject = None
    if folder_id:
        folder = db.get_folder(folder_id)
        if folder:
            subject = folder.get('name')

    audio_path, duration = recorder.stop_recording()

    if not audio_path:
        return jsonify({'success': False, 'error': 'No audio recorded'}), 400

    result = transcribe_audio(audio_path, subject=subject)
    cleanup_audio_file(audio_path)

    if not result['success']:
        return jsonify({'success': False, 'error': result['error']}), 500

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    title = f"Voice Note - {timestamp}"

    note_id = db.create_note(
        title=title,
        content=result['text'],
        folder_id=folder_id,
        language=result['language'],
        audio_duration=duration
    )

    note = db.get_note(note_id)

    return jsonify({
        'success': True,
        'note': note,
        'transcription': {
            'text': result['text'],
            'language': result['language'],
            'duration': duration,
            'used_ai': result.get('used_ai_correction', False)
        }
    })

@app.route('/api/recording/status', methods=['GET'])
def recording_status():
    recorder = get_recorder()
    return jsonify({
        'recording': recorder.is_recording(),
        'duration': recorder.get_duration()
    })

@app.route('/api/audio/devices', methods=['GET'])
def audio_devices():
    devices = list_audio_devices()
    default = get_default_input_device()
    return jsonify({'devices': devices, 'default': default})

# ============== Folders API ==============

@app.route('/api/folders', methods=['GET'])
def get_folders():
    parent_id = request.args.get('parent_id', type=int)
    if request.args.get('all') == 'true':
        folders = db.get_all_folders()
    else:
        folders = db.get_folders(parent_id)
    return jsonify({'folders': folders})

@app.route('/api/folders', methods=['POST'])
def create_folder():
    data = request.get_json()
    if not data or not data.get('name'):
        return jsonify({'error': 'Name is required'}), 400

    folder_id = db.create_folder(name=data['name'], parent_id=data.get('parent_id'))
    folder = db.get_folder(folder_id)
    return jsonify({'folder': folder}), 201

@app.route('/api/folders/<int:folder_id>', methods=['GET'])
def get_folder(folder_id):
    folder = db.get_folder(folder_id)
    if not folder:
        return jsonify({'error': 'Folder not found'}), 404
    return jsonify({'folder': folder})

@app.route('/api/folders/<int:folder_id>', methods=['PUT'])
def update_folder(folder_id):
    data = request.get_json()
    if not data or not data.get('name'):
        return jsonify({'error': 'Name is required'}), 400

    success = db.rename_folder(folder_id, data['name'])
    if not success:
        return jsonify({'error': 'Folder not found'}), 404

    folder = db.get_folder(folder_id)
    return jsonify({'folder': folder})

@app.route('/api/folders/<int:folder_id>', methods=['DELETE'])
def delete_folder(folder_id):
    success = db.delete_folder(folder_id)
    if not success:
        return jsonify({'error': 'Folder not found'}), 404
    return jsonify({'success': True})

@app.route('/api/folders/<int:folder_id>/subfolders', methods=['GET'])
def get_subfolders(folder_id):
    subfolders = db.get_folders(folder_id)
    return jsonify({'folders': subfolders})

# ============== Notes API ==============

@app.route('/api/notes', methods=['GET'])
def get_notes():
    folder_id = request.args.get('folder_id', type=int)
    notes = db.get_notes(folder_id)
    return jsonify({'notes': notes})

@app.route('/api/notes/<int:note_id>', methods=['GET'])
def get_note(note_id):
    note = db.get_note(note_id)
    if not note:
        return jsonify({'error': 'Note not found'}), 404
    return jsonify({'note': note})

@app.route('/api/notes/<int:note_id>', methods=['PUT'])
def update_note(note_id):
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No data provided'}), 400

    success = db.update_note(
        note_id,
        title=data.get('title'),
        content=data.get('content'),
        folder_id=data.get('folder_id')
    )

    if not success:
        return jsonify({'error': 'Note not found or no changes'}), 404

    note = db.get_note(note_id)
    return jsonify({'note': note})

@app.route('/api/notes/<int:note_id>', methods=['DELETE'])
def delete_note(note_id):
    success = db.delete_note(note_id)
    if not success:
        return jsonify({'error': 'Note not found'}), 404
    return jsonify({'success': True})

@app.route('/api/notes/search', methods=['GET'])
def search_notes():
    query = request.args.get('q', '')
    if not query:
        return jsonify({'notes': []})
    notes = db.search_notes(query)
    return jsonify({'notes': notes})

# ============== Tags API ==============

@app.route('/api/tags', methods=['GET'])
def get_tags():
    tags = db.get_all_tags()
    return jsonify({'tags': tags})

@app.route('/api/notes/<int:note_id>/tags', methods=['POST'])
def add_tag(note_id):
    data = request.get_json()
    if not data or not data.get('tag'):
        return jsonify({'error': 'Tag is required'}), 400

    success = db.add_tag_to_note(note_id, data['tag'])
    note = db.get_note(note_id)
    return jsonify({'note': note, 'added': success})

@app.route('/api/notes/<int:note_id>/tags/<tag_name>', methods=['DELETE'])
def remove_tag(note_id, tag_name):
    success = db.remove_tag_from_note(note_id, tag_name)
    note = db.get_note(note_id)
    return jsonify({'note': note, 'removed': success})

@app.route('/api/tags/<tag_name>/notes', methods=['GET'])
def get_notes_by_tag(tag_name):
    notes = db.get_notes_by_tag(tag_name)
    return jsonify({'notes': notes})

# ============== Export API ==============

@app.route('/api/notes/<int:note_id>/export', methods=['GET'])
def export_note(note_id):
    format_type = request.args.get('format', 'txt')
    note = db.get_note(note_id)

    if not note:
        return jsonify({'error': 'Note not found'}), 404

    if format_type == 'md':
        content = f"# {note['title']}\n\n"
        content += f"*Created: {note['created_at']}*\n\n"
        if note['tags']:
            content += f"**Tags:** {', '.join(note['tags'])}\n\n"
        content += "---\n\n"
        content += note['content']
        filename = f"{note['title']}.md"
        mimetype = 'text/markdown'
    else:
        content = f"{note['title']}\n"
        content += f"Created: {note['created_at']}\n"
        if note['tags']:
            content += f"Tags: {', '.join(note['tags'])}\n"
        content += "\n" + "=" * 40 + "\n\n"
        content += note['content']
        filename = f"{note['title']}.txt"
        mimetype = 'text/plain'

    buffer = BytesIO()
    buffer.write(content.encode('utf-8'))
    buffer.seek(0)

    return send_file(buffer, as_attachment=True, download_name=filename, mimetype=mimetype)

@app.route('/api/folders/<int:folder_id>/export', methods=['GET'])
def export_folder(folder_id):
    format_type = request.args.get('format', 'md')
    folder = db.get_folder(folder_id)
    notes = db.get_notes(folder_id)

    if not folder:
        return jsonify({'error': 'Folder not found'}), 404

    if format_type == 'md':
        content = f"# {folder['name']}\n\n"
        for note in notes:
            content += f"## {note['title']}\n\n"
            content += f"*Created: {note['created_at']}*\n\n"
            content += note['content'] + "\n\n---\n\n"
        filename = f"{folder['name']}.md"
        mimetype = 'text/markdown'
    else:
        content = f"{folder['name']}\n{'=' * 40}\n\n"
        for note in notes:
            content += f"{note['title']}\n"
            content += f"Created: {note['created_at']}\n"
            content += "-" * 20 + "\n"
            content += note['content'] + "\n\n"
        filename = f"{folder['name']}.txt"
        mimetype = 'text/plain'

    buffer = BytesIO()
    buffer.write(content.encode('utf-8'))
    buffer.seek(0)

    return send_file(buffer, as_attachment=True, download_name=filename, mimetype=mimetype)

# ============== Full Database Export ==============

@app.route('/api/export/database', methods=['GET'])
def export_database():
    """Export the entire database as JSON for backup."""
    folders = db.get_all_folders()
    notes = db.get_notes()  # All notes
    tags = db.get_all_tags()

    export_data = {
        'version': '2.0',
        'exported_at': datetime.now().isoformat(),
        'folders': folders,
        'notes': notes,
        'tags': tags
    }

    buffer = BytesIO()
    buffer.write(json.dumps(export_data, indent=2, ensure_ascii=False).encode('utf-8'))
    buffer.seek(0)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"voicenotes_backup_{timestamp}.json"

    return send_file(buffer, as_attachment=True, download_name=filename, mimetype='application/json')

# ============== Settings API ==============

@app.route('/api/settings/models', methods=['GET'])
def get_models():
    models = get_available_models()
    return jsonify({'models': models})

@app.route('/api/settings/ollama', methods=['GET'])
def get_ollama():
    status = get_ollama_status()
    return jsonify(status)

@app.route('/api/settings/status', methods=['GET'])
def get_system_status():
    """Get full system status for offline indicator."""
    correction = get_correction_status()

    return jsonify({
        'offline_ready': True,
        'ai_correction': correction['ai_correction'],
        'speaker_diarization': correction['speaker_diarization'],
        'whisper': {
            'fast_model': 'base',
            'accurate_model': 'small'
        }
    })

if __name__ == '__main__':
    print("\n" + "=" * 50)
    print("  Voice Notes App - Offline AI Transcription")
    print("  Open http://localhost:5050 in your browser")
    print("=" * 50 + "\n")
    socketio.run(app, host='127.0.0.1', port=5050, debug=False, allow_unsafe_werkzeug=True)
