VOICE NOTES APP
===============

A voice-to-text note-taking application that runs 100% offline on your Mac.


FEATURES
--------
- Record voice notes with a single click
- Automatic transcription using Whisper (German & English)
- Organize notes in folders and subfolders
- Full-text search across all notes
- Tag notes for easy filtering
- Edit transcriptions after recording
- Export notes as .txt or .md files


REQUIREMENTS
------------
1. Python 3.9 or higher
2. ffmpeg (for audio processing)

Install ffmpeg with Homebrew:
    brew install ffmpeg


HOW TO START
------------
1. Open Terminal
2. Navigate to the voice-notes folder:
    cd ~/Documents/voice-notes
3. Run the startup script:
    ./start.sh
4. Open your browser at: http://localhost:5000


FIRST RUN
---------
On first run, the program will:
- Create a virtual environment
- Install Python dependencies
- Download the Whisper "base" model (~150 MB)

This may take a few minutes. Subsequent starts are faster.


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
   - Wait for transcription (a few seconds)

3. EDIT & ORGANIZE:
   - Click a note to view/edit it
   - Change the folder using the dropdown
   - Add tags for filtering
   - Edit the transcribed text if needed

4. SEARCH:
   - Use the search box to find notes by content
   - Click a tag in the sidebar to filter by tag

5. EXPORT:
   - Click the export icon on a note to download it
   - Click "Export" in the top bar to export all notes in a folder


FILE LOCATIONS
--------------
- Program files:     ~/Documents/voice-notes/app/
- Database:      ~/Documents/voice-notes/data/notes.db
- Temp audio:    ~/Documents/voice-notes/audio_temp/ (auto-cleaned)


TROUBLESHOOTING
---------------
1. "No audio input device found"
   - Make sure your microphone is connected
   - Check System Preferences > Security & Privacy > Microphone
   - Grant Terminal/Python access to your microphone

2. "ffmpeg not found"
   - Install with: brew install ffmpeg

3. Transcription is slow
   - First transcription loads the model (takes longer)
   - Subsequent transcriptions are faster
   - Shorter recordings transcribe faster

4. Wrong language detected
   - Whisper auto-detects, but longer audio helps accuracy
   - Speak for at least 5-10 seconds for better detection


STOPPING THE APP
----------------
Press Ctrl+C in the Terminal to stop the server.
