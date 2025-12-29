VOICE NOTES APP
===============

A powerful voice-to-text note-taking application that runs 100% offline on your Mac.
All processing happens locally - your voice data never leaves your device.


FEATURES
--------
- Real-time voice transcription using Whisper AI (German & English)
- Voice filtering with TitaNet - isolate specific speakers in noisy environments
- AI-powered grammar correction using MLX (Apple Silicon) or LanguageTool
- Organize notes in folders and subfolders
- Full-text search across all notes
- Tag notes for easy filtering
- Edit transcriptions after recording
- Export notes as Word (.docx), Markdown (.md), or plain text (.txt)
- Light and dark theme support
- Adaptive learning system that improves with your feedback


REQUIREMENTS
------------
1. macOS (Apple Silicon recommended for best AI performance)
2. Python 3.9 or higher
3. ffmpeg (for audio processing)

Install ffmpeg with Homebrew:
    brew install ffmpeg


QUICK START
-----------
1. Open Terminal
2. Navigate to the voice-notes folder:
    cd ~/Documents/voice-notes
3. Run the setup script (first time only):
    ./setup_offline.sh
4. Start the application:
    ./start.sh
5. Open your browser at: http://localhost:5050


FIRST RUN
---------
On first run, the setup script will download:
- Whisper speech recognition models (~650 MB)
- TitaNet speaker verification model (~100 MB) - optimized for noisy environments
- LanguageTool language data (~350 MB)
- MLX AI model for Apple Silicon (~500 MB)

Total: approximately 1.5-2 GB. This only happens once.


USAGE
-----
1. CREATE FOLDERS:
   - Click the "+" button next to "Folders" in the sidebar
   - Right-click a folder to create subfolders

2. RECORD A NOTE:
   - Select a folder (or stay in "All Notes")
   - Click the big record button
   - Speak in German or English (auto-detected)
   - Click again to stop recording
   - Watch real-time transcription appear

3. VOICE FILTER (for classrooms/meetings):
   - Click the person icon to open Voice Profiles
   - Create a profile by recording 30 seconds of the target speaker
   - Enable the filter to only transcribe that person's voice
   - Great for recording lectures in noisy classrooms

4. EDIT & ORGANIZE:
   - Click a note to view/edit it
   - Change the folder using the dropdown
   - Add tags for filtering
   - Edit the transcribed text if needed

5. SEARCH:
   - Use the search box to find notes by content
   - Click a tag in the sidebar to filter by tag

6. EXPORT:
   - Click the export icon on a note to download it
   - Choose Word, Markdown, or plain text format
   - Export entire folders at once


TECHNOLOGIES
------------
- Whisper (OpenAI): State-of-the-art speech recognition
- TitaNet (NVIDIA): Speaker verification optimized for noisy environments
- MLX (Apple): Fast AI inference on Apple Silicon
- LanguageTool: Offline grammar and spell checking
- Flask + SocketIO: Real-time web interface


FILE LOCATIONS
--------------
- Program files:     ~/Documents/voice-notes/app/
- Database:          ~/Documents/voice-notes/data/notes.db
- Voice profiles:    ~/Documents/voice-notes/voice_profiles/
- Temp audio:        ~/Documents/voice-notes/audio_temp/ (auto-cleaned)
- AI models cache:   ~/.cache/huggingface/hub/


TROUBLESHOOTING
---------------
1. "No audio input device found"
   - Make sure your microphone is connected
   - Check System Preferences > Security & Privacy > Microphone
   - Grant Terminal/Python access to your microphone

2. "ffmpeg not found"
   - Install with: brew install ffmpeg

3. "Port 5050 already in use"
   - Another instance may be running
   - Stop it or change the port in app/app.py

4. Transcription is slow
   - First transcription loads the model (takes longer)
   - Subsequent transcriptions are faster
   - Apple Silicon Macs are significantly faster

5. Voice filter not working well
   - Record a longer voice profile (30+ seconds)
   - Speak clearly during profile creation
   - Adjust the threshold in settings if needed

6. Models not loading
   - Run ./setup_offline.sh to download all models
   - Check you have enough disk space (~2 GB free)


STOPPING THE APP
----------------
Press Ctrl+C in the Terminal to stop the server.


PRIVACY
-------
VoiceNotes operates 100% offline. Your voice recordings and transcriptions
are stored only on your local device. No data is ever sent to any server.
You have complete control over your information.


LICENSE
-------
See /app/terms for full terms of use.
