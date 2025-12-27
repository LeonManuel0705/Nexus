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
    get_correction_status, reset_session, get_text_corrector
)

app = Flask(__name__, static_folder='static')
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')

realtime_active = False
realtime_thread = None
current_transcription = []
current_language = "de"

threading.Thread(target=preload_model, daemon=True).start()


@app.route('/')
def index():
    return send_from_directory('static', 'index.html')

@app.route('/static/<path:path>')
def serve_static(path):
    return send_from_directory('static', path)


def realtime_transcription_worker():
    global realtime_active, current_transcription, current_language

    recorder = get_recorder()

    while realtime_active and recorder.is_recording():
        chunk = recorder.get_next_chunk(timeout=0.5)

        if chunk is not None:
            try:
                raw_text, corrected_text, confidence = transcribe_audio_chunk(
                    chunk,
                    sample_rate=recorder.sample_rate,
                    language=current_language,
                    apply_instant_correction=True
                )

                if corrected_text and corrected_text.strip():
                    current_transcription.append(corrected_text.strip())
                    full_text = ' '.join(current_transcription)

                    corrector = get_text_corrector(current_language)
                    full_corrected = corrector.correct_instant(full_text)

                    socketio.emit('transcription_update', {
                        'text': corrected_text.strip(),
                        'raw_text': raw_text.strip() if raw_text else '',
                        'full_text': full_corrected,
                        'confidence': confidence,
                        'is_final': False,
                        'is_corrected': True
                    })

            except Exception as e:
                print(f"Transcription error: {e}")
                import traceback
                traceback.print_exc()


@socketio.on('start_realtime')
def handle_start_realtime(data):
    global realtime_active, realtime_thread, current_transcription, current_language

    folder_id = data.get('folder_id')
    current_language = data.get('language', 'de')
    recorder = get_recorder()

    if recorder.is_recording():
        emit('error', {'message': 'Already recording'})
        return

    current_transcription = []
    realtime_active = True
    reset_session()

    subject = None
    if folder_id:
        folder = db.get_folder(folder_id)
        if folder:
            subject = folder.get('name')

    recorder.start_recording()

    realtime_thread = threading.Thread(target=realtime_transcription_worker, daemon=True)
    realtime_thread.start()

    emit('recording_started', {
        'message': 'Recording started',
        'language': current_language,
        'subject': subject
    })


@socketio.on('stop_realtime')
def handle_stop_realtime(data):
    global realtime_active, current_transcription, current_language

    folder_id = data.get('folder_id')
    recorder = get_recorder()

    if not recorder.is_recording():
        emit('error', {'message': 'Not recording'})
        return

    realtime_active = False
    audio_path, duration = recorder.stop_recording()

    result = None
    if audio_path:
        result = transcribe_audio(audio_path, language=current_language)
        cleanup_audio_file(audio_path)

        if result['success']:
            final_text = result['text']
        else:
            corrector = get_text_corrector(current_language)
            final_text = corrector.correct_full(' '.join(current_transcription))
    else:
        corrector = get_text_corrector(current_language)
        final_text = corrector.correct_full(' '.join(current_transcription))

    if final_text.strip():
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
        title = f"Voice Note - {timestamp}"

        note_id = db.create_note(
            title=title,
            content=final_text,
            folder_id=folder_id,
            language=current_language,
            audio_duration=duration
        )

        note = db.get_note(note_id)

        emit('recording_stopped', {
            'success': True,
            'note': note,
            'final_text': final_text,
            'duration': duration,
            'used_ai': True
        })
    else:
        emit('recording_stopped', {
            'success': False,
            'message': 'No speech detected'
        })


@socketio.on('set_language')
def handle_set_language(data):
    global current_language
    current_language = data.get('language', 'de')
    emit('language_changed', {'language': current_language})


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
    global current_language
    recorder = get_recorder()
    if not recorder.is_recording():
        return jsonify({'success': False, 'error': 'Not recording'}), 400

    data = request.get_json() or {}
    folder_id = data.get('folder_id')
    language = data.get('language', current_language)

    audio_path, duration = recorder.stop_recording()

    if not audio_path:
        return jsonify({'success': False, 'error': 'No audio recorded'}), 400

    result = transcribe_audio(audio_path, language=language)
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


@app.route('/api/export/database', methods=['GET'])
def export_database():
    folders = db.get_all_folders()
    notes = db.get_notes()
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
    correction = get_correction_status()

    return jsonify({
        'offline_ready': True,
        'ai_correction': correction['ai_correction'],
        'speaker_diarization': correction['speaker_diarization'],
        'whisper': {
            'realtime_model': 'small',
            'accurate_model': 'medium'
        }
    })

if __name__ == '__main__':
    print("\n" + "=" * 50)
    print("  Voice Notes - Real-time Transcription")
    print("  Open http://localhost:5050 in your browser")
    print("=" * 50 + "\n")
    socketio.run(app, host='127.0.0.1', port=5050, debug=False, allow_unsafe_werkzeug=True)
