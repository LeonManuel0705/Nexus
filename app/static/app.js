const API_BASE = '';
const socket = io();

let modelsInitialized = false;
let initLanguageSelected = false;

function initLanguageSelector() {
    const langBtns = document.querySelectorAll('.init-lang-btn');
    const subtitle = document.getElementById('initSubtitle');

    langBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const lang = btn.dataset.initLang;

            langBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');

            state.uiLanguage = lang;
            state.language = lang;
            localStorage.setItem('voicenotes_ui_lang', lang);
            localStorage.setItem('voicenotes_lang', lang);

            if (subtitle) {
                subtitle.textContent = lang === 'de' ? 'Modelle werden initialisiert...' : 'Initializing models...';
            }

            initLanguageSelected = true;
            updateUI();
        });
    });

    const savedLang = localStorage.getItem('voicenotes_ui_lang') || 'en';
    const savedBtn = document.querySelector(`.init-lang-btn[data-init-lang="${savedLang}"]`);
    if (savedBtn) {
        langBtns.forEach(b => b.classList.remove('active'));
        savedBtn.classList.add('active');
    }
}

function updateInitProgress(data) {
    const overlay = document.getElementById('initOverlay');
    if (!overlay) return;

    const progressFill = document.getElementById('initProgressFill');
    const progressText = document.getElementById('initProgressText');

    if (data.all_progress) {
        let total = 0;
        let completed = 0;
        for (const [model, info] of Object.entries(data.all_progress)) {
            total += 100;
            completed += info.progress || 0;
        }
        const percent = Math.round((completed / total) * 100);
        if (progressFill) progressFill.style.width = percent + '%';
        if (progressText) progressText.textContent = percent + '%';
    }

    if (data.model) {
        const modelEl = document.querySelector(`.init-model[data-model="${data.model}"]`);
        if (modelEl) {
            const statusEl = modelEl.querySelector('.init-model-status');
            const messageEl = modelEl.querySelector('.init-model-message');

            statusEl.className = 'init-model-status ' + data.status;
            if (messageEl) messageEl.textContent = data.message || '';
        }
    }
}

function hideInitOverlay() {
    const overlay = document.getElementById('initOverlay');
    if (overlay) {
        overlay.classList.add('fade-out');
        setTimeout(() => {
            overlay.style.display = 'none';
        }, 500);
    }
    modelsInitialized = true;
}

async function checkInitStatus() {
    try {
        const response = await fetch('/api/models/init-status');
        const data = await response.json();

        if (data.ready) {
            for (const [model, info] of Object.entries(data.progress)) {
                updateInitProgress({ model, ...info, all_progress: data.progress });
            }
            hideInitOverlay();
            return true;
        } else {
            for (const [model, info] of Object.entries(data.progress)) {
                updateInitProgress({ model, ...info, all_progress: data.progress });
            }
            return false;
        }
    } catch (e) {
        console.error('Error checking init status:', e);
        return false;
    }
}

socket.on('model_progress', (data) => {
    updateInitProgress(data);
});

socket.on('models_ready', (data) => {
    if (data.ready) {
        updateInitProgress({ all_progress: data.progress });
        setTimeout(() => hideInitOverlay(), 500);
    }
});

initLanguageSelector();
checkInitStatus();

const i18n = {
    en: {
        folders: 'Folders',
        tags: 'Tags',
        allNotes: 'All Notes',
        searchNotes: 'Search notes...',
        pressToRecord: 'Press to record',
        recording: 'Recording...',
        saving: 'Saving...',
        liveTranscription: 'Live Transcription',
        aiEnhanced: 'AI Enhanced',
        ultraFast: 'Ultra-Fast',
        startRecording: 'Start recording to see live transcription...',
        selectAll: 'Select all',
        export: 'Export',
        delete: 'Delete',
        folder: 'Folder',
        noFolder: 'No folder',
        addTag: 'Add tag...',
        add: 'Add',
        saveChanges: 'Save Changes',
        newFolder: 'New Folder',
        folderName: 'Folder name',
        cancel: 'Cancel',
        create: 'Create',
        exportOptions: 'Export Options',
        rename: 'Rename',
        addSubfolder: 'Add Subfolder',
        backup: 'Backup',
        untitledNote: 'Untitled Note',
        transcriptionPlaceholder: 'Your transcription will appear here...',
        noteSaved: 'Note saved!',
        noteDeleted: 'Note deleted',
        folderCreated: 'Folder created',
        folderRenamed: 'Folder renamed',
        folderDeleted: 'Folder deleted',
        noSpeech: 'No speech detected',
        selected: 'selected',
        notes: 'notes',
        note: 'note',
        words: 'words',
        characters: 'characters',
        deleteConfirm: 'Delete this note?',
        deleteFolderConfirm: 'Delete this folder and all its contents?',
        deleteSelectedConfirm: 'Delete selected notes?',
        noNotesYet: 'No notes yet',
        noNotesDesc: 'Press the record button to create your first voice note',
        listening: 'Listening...',
        voiceFilter: 'Voice Filter',
        voiceFilterDesc: 'Train the system to recognize a specific voice (e.g., teacher) and filter out other speakers.',
        noProfileActive: 'No voice profile active',
        recordToCreate: 'Record a voice sample to create a profile',
        teacherName: 'Teacher/Speaker Name',
        enrollmentHint: 'Speak naturally for at least 30 seconds. Read aloud or talk about any topic.',
        finishEnrollment: 'Finish & Save Profile',
        savedProfiles: 'Saved Profiles',
        noProfilesSaved: 'No profiles saved yet',
        close: 'Close',
        disableFilter: 'Disable Filter',
        profileActive: 'Voice filter active',
        filteringVoice: 'Only transcribing matched voice',
        profileCreated: 'Voice profile created!',
        profileActivated: 'Voice filter activated',
        profileDeactivated: 'Voice filter disabled',
        enrollmentCancelled: 'Enrollment cancelled',
        systemCheck: 'System Check',
        systemCheckDesc: 'Checking required components before recording...',
        downloadingModels: 'Downloading Models',
        installMissing: 'Install Missing',
        modelInstalled: 'Installed',
        modelMissing: 'Missing',
        modelRequired: 'Required',
        modelOptional: 'Optional',
        allModelsReady: 'All systems ready!',
        downloadComplete: 'Download complete',
        downloadFailed: 'Download failed',
        checkingModels: 'Checking models...',
        rateTranscription: 'Rate Transcription',
        howWasQuality: 'How was the transcription quality?',
        additionalComments: 'Additional comments (optional)',
        submitFeedback: 'Submit Feedback',
        skip: 'Skip',
        feedbackThanks: 'Thanks for your feedback!',
        feedbackError: 'Error submitting feedback',
        qualityScore: 'Quality Score',
        issuesFound: 'Issues Found',
        filterModeInclude: 'Include Mode',
        filterModeExclude: 'Exclude Mode',
        filterModeIncludeDesc: 'Only transcribe this voice',
        filterModeExcludeDesc: 'Filter OUT this voice'
    },
    de: {
        folders: 'Ordner',
        tags: 'Tags',
        allNotes: 'Alle Notizen',
        searchNotes: 'Notizen suchen...',
        pressToRecord: 'Zum Aufnehmen drücken',
        recording: 'Nimmt auf...',
        saving: 'Speichern...',
        liveTranscription: 'Live-Transkription',
        aiEnhanced: 'KI-Optimiert',
        ultraFast: 'Ultraschnell',
        startRecording: 'Starte die Aufnahme für Live-Transkription...',
        selectAll: 'Alle auswählen',
        export: 'Exportieren',
        delete: 'Löschen',
        folder: 'Ordner',
        noFolder: 'Kein Ordner',
        addTag: 'Tag hinzufügen...',
        add: 'Hinzufügen',
        saveChanges: 'Änderungen speichern',
        newFolder: 'Neuer Ordner',
        folderName: 'Ordnername',
        cancel: 'Abbrechen',
        create: 'Erstellen',
        exportOptions: 'Export-Optionen',
        rename: 'Umbenennen',
        addSubfolder: 'Unterordner hinzufügen',
        backup: 'Sicherung',
        untitledNote: 'Unbenannte Notiz',
        transcriptionPlaceholder: 'Deine Transkription erscheint hier...',
        noteSaved: 'Notiz gespeichert!',
        noteDeleted: 'Notiz gelöscht',
        folderCreated: 'Ordner erstellt',
        folderRenamed: 'Ordner umbenannt',
        folderDeleted: 'Ordner gelöscht',
        noSpeech: 'Keine Sprache erkannt',
        selected: 'ausgewählt',
        notes: 'Notizen',
        note: 'Notiz',
        words: 'Wörter',
        characters: 'Zeichen',
        deleteConfirm: 'Diese Notiz löschen?',
        deleteFolderConfirm: 'Diesen Ordner und alle Inhalte löschen?',
        deleteSelectedConfirm: 'Ausgewählte Notizen löschen?',
        noNotesYet: 'Noch keine Notizen',
        noNotesDesc: 'Drück den Aufnahme-Button für deine erste Sprachnotiz',
        listening: 'Hört zu...',
        voiceFilter: 'Stimmenfilter',
        voiceFilterDesc: 'Trainiere das System, eine bestimmte Stimme (z.B. Lehrer) zu erkennen und andere Sprecher auszufiltern.',
        noProfileActive: 'Kein Stimmprofil aktiv',
        recordToCreate: 'Nimm eine Stimmprobe auf, um ein Profil zu erstellen',
        teacherName: 'Lehrer-/Sprechername',
        enrollmentHint: 'Sprich natürlich für mindestens 30 Sekunden. Lies laut vor oder sprich über ein beliebiges Thema.',
        finishEnrollment: 'Beenden & Profil speichern',
        savedProfiles: 'Gespeicherte Profile',
        noProfilesSaved: 'Noch keine Profile gespeichert',
        close: 'Schließen',
        disableFilter: 'Filter deaktivieren',
        profileActive: 'Stimmenfilter aktiv',
        filteringVoice: 'Nur passende Stimme wird transkribiert',
        profileCreated: 'Stimmprofil erstellt!',
        profileActivated: 'Stimmenfilter aktiviert',
        profileDeactivated: 'Stimmenfilter deaktiviert',
        enrollmentCancelled: 'Registrierung abgebrochen',
        systemCheck: 'Systemprüfung',
        systemCheckDesc: 'Prüfe erforderliche Komponenten vor der Aufnahme...',
        downloadingModels: 'Modelle herunterladen',
        installMissing: 'Fehlende installieren',
        modelInstalled: 'Installiert',
        modelMissing: 'Fehlt',
        modelRequired: 'Erforderlich',
        modelOptional: 'Optional',
        allModelsReady: 'Alle Systeme bereit!',
        downloadComplete: 'Download abgeschlossen',
        downloadFailed: 'Download fehlgeschlagen',
        checkingModels: 'Modelle prüfen...',
        rateTranscription: 'Transkription bewerten',
        howWasQuality: 'Wie war die Qualität der Transkription?',
        additionalComments: 'Zusätzliche Kommentare (optional)',
        submitFeedback: 'Feedback absenden',
        skip: 'Überspringen',
        feedbackThanks: 'Danke für dein Feedback!',
        feedbackError: 'Fehler beim Senden des Feedbacks',
        qualityScore: 'Qualitätsbewertung',
        issuesFound: 'Probleme gefunden',
        filterModeInclude: 'Einschließen-Modus',
        filterModeExclude: 'Ausschließen-Modus',
        filterModeIncludeDesc: 'Nur diese Stimme transkribieren',
        filterModeExcludeDesc: 'Diese Stimme AUSFILTERN'
    }
};

let state = {
    folders: [],
    notes: [],
    tags: [],
    currentFolder: null,
    currentNote: null,
    isRecording: false,
    recordingInterval: null,
    searchQuery: '',
    contextMenuTarget: null,
    waveformAnimationId: null,
    currentLanguage: 'de',
    uiLanguage: 'en',
    selectedNotes: new Set(),
    voiceFilterEnabled: false,
    voiceProfiles: [],
    currentProfile: null,
    isEnrolling: false,
    modelsChecked: false,
    modelsReady: false,
    pendingDownloads: [],
    downloadProgressInterval: null,
    voiceFilterMode: 'include',
    lastRecordingNoteId: null,
    feedbackRating: 0
};

const elements = {
    folderTree: document.getElementById('folderTree'),
    tagsList: document.getElementById('tagsList'),
    notesList: document.getElementById('notesList'),
    breadcrumb: document.getElementById('breadcrumb'),
    recordBtn: document.getElementById('recordBtn'),
    recordLabel: document.getElementById('recordLabel'),
    recordingDuration: document.getElementById('recordingDuration'),
    searchInput: document.getElementById('searchInput'),
    detailPanel: document.getElementById('detailPanel'),
    noteTitle: document.getElementById('noteTitle'),
    noteContent: document.getElementById('noteContent'),
    noteDate: document.getElementById('noteDate'),
    noteLanguage: document.getElementById('noteLanguage'),
    noteDuration: document.getElementById('noteDuration'),
    noteFolderSelect: document.getElementById('noteFolderSelect'),
    noteTags: document.getElementById('noteTags'),
    newTagInput: document.getElementById('newTagInput'),
    folderModal: document.getElementById('folderModal'),
    folderModalTitle: document.getElementById('folderModalTitle'),
    folderNameInput: document.getElementById('folderNameInput'),
    exportModal: document.getElementById('exportModal'),
    contextMenu: document.getElementById('contextMenu'),
    liveTranscription: document.getElementById('liveTranscription'),
    liveTranscriptionContent: document.getElementById('liveTranscriptionContent'),
    waveformCanvas: document.getElementById('waveformCanvas'),
    noteCount: document.getElementById('noteCount'),
    wordCount: document.getElementById('wordCount'),
    charCount: document.getElementById('charCount'),
    detailWordCount: document.getElementById('detailWordCount'),
    detailCharCount: document.getElementById('detailCharCount'),
    themeToggle: document.getElementById('themeToggle'),
    toastContainer: document.getElementById('toastContainer'),
    notesToolbar: document.getElementById('notesToolbar'),
    selectAllCheckbox: document.getElementById('selectAllCheckbox'),
    selectionCount: document.getElementById('selectionCount'),
    deleteSelectedBtn: document.getElementById('deleteSelectedBtn'),
    exportSelectedBtn: document.getElementById('exportSelectedBtn'),
    voiceFilterBtn: document.getElementById('voiceFilterBtn'),
    filterStatus: document.getElementById('filterStatus'),
    voiceProfileModal: document.getElementById('voiceProfileModal'),
    profileStatus: document.getElementById('profileStatus'),
    teacherNameInput: document.getElementById('teacherNameInput'),
    enrollmentProgress: document.getElementById('enrollmentProgress'),
    enrollmentProgressFill: document.getElementById('enrollmentProgressFill'),
    enrollmentDuration: document.getElementById('enrollmentDuration'),
    startEnrollmentBtn: document.getElementById('startEnrollmentBtn'),
    stopEnrollmentBtn: document.getElementById('stopEnrollmentBtn'),
    cancelEnrollmentBtn: document.getElementById('cancelEnrollmentBtn'),
    profilesList: document.getElementById('profilesList'),
    closeVoiceProfileBtn: document.getElementById('closeVoiceProfileBtn'),
    disableFilterBtn: document.getElementById('disableFilterBtn'),
    modelCheckModal: document.getElementById('modelCheckModal'),
    modelList: document.getElementById('modelList'),
    downloadProgressSection: document.getElementById('downloadProgressSection'),
    downloadList: document.getElementById('downloadList'),
    cancelModelCheckBtn: document.getElementById('cancelModelCheckBtn'),
    installModelsBtn: document.getElementById('installModelsBtn'),
    startRecordingBtn: document.getElementById('startRecordingBtn'),
    feedbackModal: document.getElementById('feedbackModal'),
    starRating: document.getElementById('starRating'),
    qualityAnalysis: document.getElementById('qualityAnalysis'),
    qualityScoreValue: document.getElementById('qualityScoreValue'),
    issuesCountValue: document.getElementById('issuesCountValue'),
    feedbackComments: document.getElementById('feedbackComments'),
    skipFeedbackBtn: document.getElementById('skipFeedbackBtn'),
    submitFeedbackBtn: document.getElementById('submitFeedbackBtn')
};

function t(key) {
    return i18n[state.uiLanguage][key] || i18n['en'][key] || key;
}

function updateUILanguage() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        el.textContent = t(key);
    });
    document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
        const key = el.getAttribute('data-i18n-placeholder');
        el.placeholder = t(key);
    });
    updateSelectionUI();
    renderNotes();
}

function setUILanguage(lang) {
    state.uiLanguage = lang;
    localStorage.setItem('uiLanguage', lang);
    document.querySelectorAll('[data-ui-lang]').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.uiLang === lang);
    });
    updateUILanguage();
}

socket.on('connect', () => console.log('Connected to server'));

socket.on('recording_started', (data) => {
    elements.liveTranscription.classList.add('active');
    elements.liveTranscriptionContent.innerHTML = `<p class="listening">${t('listening')}</p>`;
    startWaveformAnimation();
});

socket.on('transcription_update', (data) => {
    const newSpan = document.createElement('span');
    newSpan.className = 'new-text';
    newSpan.textContent = data.text + ' ';

    const placeholder = elements.liveTranscriptionContent.querySelector('.placeholder, .listening');
    if (placeholder) placeholder.remove();

    elements.liveTranscriptionContent.appendChild(newSpan);
    elements.liveTranscriptionContent.scrollTop = elements.liveTranscriptionContent.scrollHeight;

    updateTranscriptionStats(data.full_text);

    setTimeout(() => newSpan.classList.remove('new-text'), 800);
});

socket.on('correction_update', (data) => {
    const correctionIndicator = elements.liveTranscriptionContent.querySelector('.correction-indicator');
    if (!correctionIndicator) {
        const indicator = document.createElement('div');
        indicator.className = 'correction-indicator';
        indicator.innerHTML = '<span class="correction-dot"></span> Grammar corrected';
        elements.liveTranscriptionContent.insertBefore(indicator, elements.liveTranscriptionContent.firstChild);
    }
});

socket.on('recording_stopping', (data) => {
    state.isRecording = false;
    clearInterval(state.recordingInterval);
    stopWaveformAnimation();

    elements.recordBtn.classList.remove('recording');
    elements.recordBtn.classList.add('processing');
    elements.recordLabel.textContent = 'Saving...';
    elements.liveTranscriptionContent.innerHTML = `<p class="processing-text"><span class="spinner"></span> Processing and saving...</p>`;
});

socket.on('recording_stopped', async (data) => {
    state.isRecording = false;
    clearInterval(state.recordingInterval);
    stopWaveformAnimation();

    elements.recordBtn.classList.remove('recording', 'processing');
    elements.recordLabel.textContent = t('pressToRecord');
    elements.recordingDuration.textContent = '00:00';
    elements.liveTranscription.classList.remove('active');

    if (data.success) {
        elements.liveTranscriptionContent.innerHTML = `<p style="color: var(--success)">${escapeHtml(data.final_text)}</p>`;
        showToast(t('noteSaved'), 'success');
        await loadNotes();
        selectNote(data.note.id);

        if (data.note && data.final_text && data.final_text.length > 20) {
            setTimeout(() => {
                showFeedbackModal(data.note.id, data.final_text);
            }, 1000);
        }

        setTimeout(() => {
            elements.liveTranscriptionContent.innerHTML = `<p class="placeholder">${t('startRecording')}</p>`;
        }, 2000);
    } else {
        elements.liveTranscriptionContent.innerHTML = `<p style="color: var(--danger)">${data.message || t('noSpeech')}</p>`;
        setTimeout(() => {
            elements.liveTranscriptionContent.innerHTML = `<p class="placeholder">${t('startRecording')}</p>`;
        }, 3000);
    }
});

socket.on('error', (data) => {
    showToast('Error: ' + data.message, 'error');
});

function startWaveformAnimation() {
    const canvas = elements.waveformCanvas;
    const ctx = canvas.getContext('2d');
    const bars = 60;

    function resize() {
        canvas.width = canvas.offsetWidth * 2;
        canvas.height = canvas.offsetHeight * 2;
    }
    resize();
    window.addEventListener('resize', resize);

    function animate() {
        if (!state.isRecording) return;

        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--accent');

        const barWidth = canvas.width / bars;
        const centerY = canvas.height / 2;

        for (let i = 0; i < bars; i++) {
            const height = Math.random() * canvas.height * 0.6 + 10;
            ctx.fillRect(
                i * barWidth + 2,
                centerY - height / 2,
                barWidth - 4,
                height
            );
        }

        state.waveformAnimationId = requestAnimationFrame(animate);
    }

    animate();
}

function stopWaveformAnimation() {
    if (state.waveformAnimationId) {
        cancelAnimationFrame(state.waveformAnimationId);
        state.waveformAnimationId = null;
    }
    const ctx = elements.waveformCanvas.getContext('2d');
    ctx.clearRect(0, 0, elements.waveformCanvas.width, elements.waveformCanvas.height);
}

function updateTranscriptionStats(text) {
    if (!text) {
        elements.wordCount.textContent = `0 ${t('words')}`;
        elements.charCount.textContent = `0 ${t('characters')}`;
        return;
    }
    const words = text.trim().split(/\s+/).filter(w => w.length > 0).length;
    const chars = text.length;
    elements.wordCount.textContent = `${words} ${t('words')}`;
    elements.charCount.textContent = `${chars} ${t('characters')}`;
}

function updateDetailStats() {
    const text = elements.noteContent.value;
    const words = text.trim().split(/\s+/).filter(w => w.length > 0).length;
    const chars = text.length;
    elements.detailWordCount.textContent = `${words} ${t('words')}`;
    elements.detailCharCount.textContent = `${chars} ${t('characters')}`;
}

async function api(url, options = {}) {
    const defaultOptions = {
        headers: { 'Content-Type': 'application/json' },
    };
    const response = await fetch(API_BASE + url, { ...defaultOptions, ...options });
    return response.json();
}

async function loadFolders() {
    const data = await api('/api/folders?all=true');
    state.folders = data.folders;
    renderFolderTree();
    updateFolderSelect();
}

function buildFolderHierarchy(folders) {
    const map = new Map();
    folders.forEach(f => map.set(f.id, { ...f, children: [] }));

    const roots = [];
    map.forEach(folder => {
        if (folder.parent_id && map.has(folder.parent_id)) {
            map.get(folder.parent_id).children.push(folder);
        } else {
            roots.push(folder);
        }
    });

    return roots.sort((a, b) => a.name.localeCompare(b.name));
}

function renderFolderTree() {
    const hierarchy = buildFolderHierarchy(state.folders);

    let html = `
        <div class="folder-item all-notes-item ${state.currentFolder === null ? 'active' : ''}" data-folder-id="null">
            <span class="folder-icon">📁</span>
            <span class="folder-name">${t('allNotes')}</span>
        </div>
    `;

    html += renderFolderItems(hierarchy, 0);
    elements.folderTree.innerHTML = html;

    document.querySelectorAll('.folder-item').forEach(item => {
        item.addEventListener('click', (e) => {
            const folderId = item.dataset.folderId;
            selectFolder(folderId === 'null' ? null : parseInt(folderId));
        });

        item.addEventListener('contextmenu', (e) => {
            e.preventDefault();
            if (item.dataset.folderId !== 'null') {
                showContextMenu(e, item.dataset.folderId);
            }
        });
    });
}

function renderFolderItems(folders, level) {
    let html = '';
    for (const folder of folders) {
        const isActive = state.currentFolder === folder.id;
        html += `
            <div class="folder-item ${isActive ? 'active' : ''}" data-folder-id="${folder.id}" style="padding-left: ${20 + level * 15}px">
                <span class="folder-icon">${folder.children.length > 0 ? '📂' : '📁'}</span>
                <span class="folder-name">${escapeHtml(folder.name)}</span>
            </div>
        `;
        if (folder.children.length > 0) {
            html += renderFolderItems(folder.children, level + 1);
        }
    }
    return html;
}

async function selectFolder(folderId) {
    state.currentFolder = folderId;
    state.searchQuery = '';
    state.selectedNotes.clear();
    elements.searchInput.value = '';
    renderFolderTree();
    updateBreadcrumb();
    await loadNotes();
    updateSelectionUI();
}

function updateBreadcrumb() {
    if (state.currentFolder === null) {
        elements.breadcrumb.innerHTML = `<span>${t('allNotes')}</span>`;
    } else {
        const path = getFolderPath(state.currentFolder);
        elements.breadcrumb.innerHTML = path.map(f => `<span>${escapeHtml(f.name)}</span>`).join('');
    }
}

function getFolderPath(folderId) {
    const path = [];
    let current = state.folders.find(f => f.id === folderId);
    while (current) {
        path.unshift(current);
        current = state.folders.find(f => f.id === current.parent_id);
    }
    return path;
}

async function createFolder(name, parentId = null) {
    await api('/api/folders', { method: 'POST', body: JSON.stringify({ name, parent_id: parentId }) });
    await loadFolders();
    showToast(t('folderCreated'), 'success');
}

async function renameFolder(folderId, newName) {
    await api(`/api/folders/${folderId}`, { method: 'PUT', body: JSON.stringify({ name: newName }) });
    await loadFolders();
    showToast(t('folderRenamed'), 'success');
}

async function deleteFolder(folderId) {
    if (confirm(t('deleteFolderConfirm'))) {
        await api(`/api/folders/${folderId}`, { method: 'DELETE' });
        if (state.currentFolder === folderId) state.currentFolder = null;
        await loadFolders();
        await loadNotes();
        showToast(t('folderDeleted'), 'success');
    }
}

async function loadNotes() {
    let data;
    if (state.searchQuery) {
        data = await api(`/api/notes/search?q=${encodeURIComponent(state.searchQuery)}`);
    } else if (state.currentFolder !== null) {
        data = await api(`/api/notes?folder_id=${state.currentFolder}`);
    } else {
        data = await api('/api/notes');
    }
    state.notes = data.notes;
    renderNotes();
    const noteWord = state.notes.length === 1 ? t('note') : t('notes');
    elements.noteCount.textContent = `${state.notes.length} ${noteWord}`;
}

function renderNotes() {
    if (state.notes.length === 0) {
        elements.notesList.innerHTML = `
            <div class="empty-state">
                <h3>${t('noNotesYet')}</h3>
                <p>${t('noNotesDesc')}</p>
            </div>
        `;
        elements.notesToolbar.classList.add('hidden');
        return;
    }

    elements.notesToolbar.classList.remove('hidden');

    elements.notesList.innerHTML = state.notes.map(note => `
        <div class="note-card ${state.currentNote?.id === note.id ? 'active' : ''} ${state.selectedNotes.has(note.id) ? 'selected' : ''}" data-note-id="${note.id}">
            <input type="checkbox" class="note-checkbox" ${state.selectedNotes.has(note.id) ? 'checked' : ''} data-note-id="${note.id}">
            <div class="note-card-header">
                <span class="note-card-title">${escapeHtml(note.title)}</span>
                <span class="note-card-date">${formatDate(note.created_at)}</span>
            </div>
            <div class="note-card-preview">${escapeHtml(note.content.substring(0, 150))}${note.content.length > 150 ? '...' : ''}</div>
            ${note.tags.length > 0 ? `
                <div class="note-card-tags">
                    ${note.tags.map(tag => `<span class="tag">${escapeHtml(tag)}</span>`).join('')}
                </div>
            ` : ''}
            <div class="note-card-meta">
                ${note.language ? `<span>🌐 ${note.language.toUpperCase()}</span>` : ''}
                ${note.audio_duration ? `<span>🎤 ${formatDuration(note.audio_duration)}</span>` : ''}
            </div>
        </div>
    `).join('');

    document.querySelectorAll('.note-card').forEach(card => {
        card.addEventListener('click', (e) => {
            if (e.target.classList.contains('note-checkbox')) return;
            selectNote(parseInt(card.dataset.noteId));
        });
    });

    document.querySelectorAll('.note-checkbox').forEach(checkbox => {
        checkbox.addEventListener('change', (e) => {
            e.stopPropagation();
            const noteId = parseInt(checkbox.dataset.noteId);
            if (checkbox.checked) {
                state.selectedNotes.add(noteId);
            } else {
                state.selectedNotes.delete(noteId);
            }
            updateSelectionUI();
            renderNotes();
        });
    });
}

function updateSelectionUI() {
    const count = state.selectedNotes.size;
    elements.selectionCount.textContent = `${count} ${t('selected')}`;
    elements.selectAllCheckbox.checked = count === state.notes.length && count > 0;
    elements.selectAllCheckbox.indeterminate = count > 0 && count < state.notes.length;
}

async function deleteSelectedNotes() {
    if (state.selectedNotes.size === 0) return;

    if (confirm(t('deleteSelectedConfirm'))) {
        for (const noteId of state.selectedNotes) {
            await api(`/api/notes/${noteId}`, { method: 'DELETE' });
        }
        state.selectedNotes.clear();
        state.currentNote = null;
        elements.detailPanel.classList.add('hidden');
        await loadNotes();
        showToast(t('noteDeleted'), 'success');
    }
}

async function selectNote(noteId) {
    const data = await api(`/api/notes/${noteId}`);
    state.currentNote = data.note;
    renderNotes();
    showNoteDetail();
}

function showNoteDetail() {
    const note = state.currentNote;
    if (!note) return;

    elements.noteTitle.value = note.title;
    elements.noteContent.value = note.content;
    elements.noteDate.textContent = formatDate(note.created_at);
    elements.noteLanguage.textContent = note.language ? note.language.toUpperCase() : '';
    elements.noteDuration.textContent = note.audio_duration ? formatDuration(note.audio_duration) : '';
    elements.noteFolderSelect.value = note.folder_id || '';

    renderNoteTags();
    updateDetailStats();
    elements.detailPanel.classList.remove('hidden');
}

function hideNoteDetail() {
    elements.detailPanel.classList.add('hidden');
    state.currentNote = null;
    renderNotes();
}

function renderNoteTags() {
    const note = state.currentNote;
    if (!note) return;

    elements.noteTags.innerHTML = note.tags.map(tag => `
        <span class="tag">
            ${escapeHtml(tag)}
            <span class="remove-tag" data-tag="${escapeHtml(tag)}">×</span>
        </span>
    `).join('');

    document.querySelectorAll('.remove-tag').forEach(btn => {
        btn.addEventListener('click', async () => {
            await removeTag(state.currentNote.id, btn.dataset.tag);
        });
    });
}

async function saveNote() {
    if (!state.currentNote) return;

    const folderValue = elements.noteFolderSelect.value;
    const folderId = folderValue && folderValue !== '' ? parseInt(folderValue) : null;

    await api(`/api/notes/${state.currentNote.id}`, {
        method: 'PUT',
        body: JSON.stringify({
            title: elements.noteTitle.value,
            content: elements.noteContent.value,
            folder_id: folderId
        })
    });

    await loadNotes();
    const data = await api(`/api/notes/${state.currentNote.id}`);
    state.currentNote = data.note;
    showToast(t('noteSaved'), 'success');
}

async function deleteNote() {
    if (!state.currentNote) return;

    if (confirm(t('deleteConfirm'))) {
        await api(`/api/notes/${state.currentNote.id}`, { method: 'DELETE' });
        state.currentNote = null;
        elements.detailPanel.classList.add('hidden');
        await loadNotes();
        showToast(t('noteDeleted'), 'success');
    }
}

async function loadTags() {
    const data = await api('/api/tags');
    state.tags = data.tags;
    renderTags();
}

function renderTags() {
    elements.tagsList.innerHTML = state.tags.map(tag => `
        <span class="tag-item" data-tag="${escapeHtml(tag.name)}">${escapeHtml(tag.name)}</span>
    `).join('');

    document.querySelectorAll('.tag-item').forEach(item => {
        item.addEventListener('click', async () => {
            const data = await api(`/api/tags/${encodeURIComponent(item.dataset.tag)}/notes`);
            state.notes = data.notes;
            state.currentFolder = null;
            state.searchQuery = '';
            state.selectedNotes.clear();
            elements.searchInput.value = '';
            elements.breadcrumb.innerHTML = `<span>Tag: ${escapeHtml(item.dataset.tag)}</span>`;
            renderFolderTree();
            renderNotes();
            updateSelectionUI();
        });
    });
}

async function addTag(noteId, tagName) {
    await api(`/api/notes/${noteId}/tags`, { method: 'POST', body: JSON.stringify({ tag: tagName }) });
    const data = await api(`/api/notes/${noteId}`);
    state.currentNote = data.note;
    renderNoteTags();
    await loadTags();
}

async function removeTag(noteId, tagName) {
    await api(`/api/notes/${noteId}/tags/${encodeURIComponent(tagName)}`, { method: 'DELETE' });
    const data = await api(`/api/notes/${noteId}`);
    state.currentNote = data.note;
    renderNoteTags();
    await loadTags();
}

function toggleRecording() {
    if (state.isRecording) {
        stopRecording();
    } else {
        preflightRecordCheck();
    }
}

function actuallyStartRecording() {
    socket.emit('start_realtime', {
        folder_id: state.currentFolder,
        language: state.currentLanguage
    });

    state.isRecording = true;
    elements.recordBtn.classList.add('recording');
    elements.recordLabel.textContent = t('recording');

    if (state.voiceFilterEnabled) {
        showVoiceDashboard();
    }

    let seconds = 0;
    state.recordingInterval = setInterval(() => {
        seconds++;
        elements.recordingDuration.textContent = formatDuration(seconds);
    }, 1000);
}

function setLanguage(lang) {
    state.currentLanguage = lang;
    document.querySelectorAll('.lang-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.lang === lang);
    });
    socket.emit('set_language', { language: lang });
}

function stopRecording() {
    elements.recordLabel.textContent = t('saving');
    socket.emit('stop_realtime', { folder_id: state.currentFolder });
}

function showExportModal(type, id) {
    elements.exportModal.classList.add('active');
    elements.exportModal.dataset.type = type;
    elements.exportModal.dataset.id = id;
}

function exportFile(format) {
    const type = elements.exportModal.dataset.type;
    const id = elements.exportModal.dataset.id;
    const url = type === 'note' ? `/api/notes/${id}/export?format=${format}` : `/api/folders/${id}/export?format=${format}`;
    window.open(url, '_blank');
    elements.exportModal.classList.remove('active');
}

function showContextMenu(e, folderId) {
    state.contextMenuTarget = folderId;
    elements.contextMenu.style.left = e.pageX + 'px';
    elements.contextMenu.style.top = e.pageY + 'px';
    elements.contextMenu.classList.add('active');
}

function hideContextMenu() {
    elements.contextMenu.classList.remove('active');
    state.contextMenuTarget = null;
}

function updateFolderSelect() {
    const hierarchy = buildFolderHierarchy(state.folders);
    let options = `<option value="">${t('noFolder')}</option>`;
    options += buildFolderOptions(hierarchy, 0);
    elements.noteFolderSelect.innerHTML = options;
}

function buildFolderOptions(folders, level) {
    let options = '';
    for (const folder of folders) {
        const indent = '— '.repeat(level);
        options += `<option value="${folder.id}">${indent}${escapeHtml(folder.name)}</option>`;
        if (folder.children.length > 0) {
            options += buildFolderOptions(folder.children, level + 1);
        }
    }
    return options;
}

let searchTimeout;
function handleSearch(query) {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(async () => {
        state.searchQuery = query;
        state.selectedNotes.clear();
        if (query) {
            state.currentFolder = null;
            elements.breadcrumb.innerHTML = `<span>Search: "${escapeHtml(query)}"</span>`;
            renderFolderTree();
        }
        await loadNotes();
        updateSelectionUI();
    }, 300);
}

function showToast(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    elements.toastContainer.appendChild(toast);
    setTimeout(() => toast.remove(), 3000);
}

function toggleTheme() {
    const current = document.body.getAttribute('data-theme');
    const newTheme = current === 'dark' ? 'light' : 'dark';
    document.body.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
}

function loadTheme() {
    const saved = localStorage.getItem('theme') || 'light';
    document.body.setAttribute('data-theme', saved);
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function formatDate(dateStr) {
    const date = new Date(dateStr);
    const locale = state.uiLanguage === 'de' ? 'de-DE' : 'en-US';
    return date.toLocaleDateString(locale, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

function formatDuration(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

function initEventListeners() {
    elements.recordBtn.addEventListener('click', toggleRecording);
    elements.searchInput.addEventListener('input', (e) => handleSearch(e.target.value));
    elements.themeToggle.addEventListener('click', toggleTheme);
    elements.noteContent.addEventListener('input', updateDetailStats);

    document.querySelectorAll('.lang-btn').forEach(btn => {
        btn.addEventListener('click', () => setLanguage(btn.dataset.lang));
    });

    document.querySelectorAll('[data-ui-lang]').forEach(btn => {
        btn.addEventListener('click', () => setUILanguage(btn.dataset.uiLang));
    });

    elements.selectAllCheckbox.addEventListener('change', () => {
        if (elements.selectAllCheckbox.checked) {
            state.notes.forEach(note => state.selectedNotes.add(note.id));
        } else {
            state.selectedNotes.clear();
        }
        updateSelectionUI();
        renderNotes();
    });

    elements.deleteSelectedBtn.addEventListener('click', deleteSelectedNotes);

    elements.exportSelectedBtn.addEventListener('click', () => {
        if (state.selectedNotes.size > 0) {
            const firstNoteId = Array.from(state.selectedNotes)[0];
            showExportModal('note', firstNoteId);
        }
    });

    document.getElementById('addFolderBtn').addEventListener('click', () => {
        elements.folderModalTitle.textContent = t('newFolder');
        elements.folderNameInput.value = '';
        elements.folderModal.dataset.mode = 'create';
        elements.folderModal.dataset.parentId = state.currentFolder || '';
        elements.folderModal.classList.add('active');
        elements.folderNameInput.focus();
    });

    document.getElementById('cancelFolderBtn').addEventListener('click', () => {
        elements.folderModal.classList.remove('active');
    });

    document.getElementById('saveFolderBtn').addEventListener('click', async () => {
        const name = elements.folderNameInput.value.trim();
        if (!name) return;

        const mode = elements.folderModal.dataset.mode;
        if (mode === 'create') {
            const parentId = elements.folderModal.dataset.parentId;
            await createFolder(name, parentId ? parseInt(parentId) : null);
        } else if (mode === 'rename') {
            const folderId = elements.folderModal.dataset.folderId;
            await renameFolder(parseInt(folderId), name);
        }

        elements.folderModal.classList.remove('active');
    });

    elements.folderNameInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') document.getElementById('saveFolderBtn').click();
    });

    document.getElementById('saveNoteBtn').addEventListener('click', saveNote);
    document.getElementById('deleteNoteBtn').addEventListener('click', deleteNote);
    document.getElementById('closeDetailBtn').addEventListener('click', hideNoteDetail);
    document.getElementById('exportNoteBtn').addEventListener('click', () => {
        if (state.currentNote) showExportModal('note', state.currentNote.id);
    });

    document.getElementById('exportFolderBtn').addEventListener('click', () => {
        if (state.currentFolder) showExportModal('folder', state.currentFolder);
    });

    document.getElementById('addTagBtn').addEventListener('click', async () => {
        const tagName = elements.newTagInput.value.trim();
        if (tagName && state.currentNote) {
            await addTag(state.currentNote.id, tagName);
            elements.newTagInput.value = '';
        }
    });

    elements.newTagInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') document.getElementById('addTagBtn').click();
    });

    document.querySelectorAll('.export-option').forEach(btn => {
        btn.addEventListener('click', () => exportFile(btn.dataset.format));
    });

    document.getElementById('cancelExportBtn').addEventListener('click', () => {
        elements.exportModal.classList.remove('active');
    });

    document.querySelectorAll('.modal-backdrop').forEach(backdrop => {
        backdrop.addEventListener('click', () => {
            backdrop.closest('.modal').classList.remove('active');
        });
    });

    document.querySelectorAll('.context-menu-item').forEach(item => {
        item.addEventListener('click', async () => {
            const action = item.dataset.action;
            const folderId = parseInt(state.contextMenuTarget);

            if (action === 'rename') {
                const folder = state.folders.find(f => f.id === folderId);
                elements.folderModalTitle.textContent = t('rename');
                elements.folderNameInput.value = folder.name;
                elements.folderModal.dataset.mode = 'rename';
                elements.folderModal.dataset.folderId = folderId;
                elements.folderModal.classList.add('active');
                elements.folderNameInput.focus();
            } else if (action === 'subfolder') {
                elements.folderModalTitle.textContent = t('newFolder');
                elements.folderNameInput.value = '';
                elements.folderModal.dataset.mode = 'create';
                elements.folderModal.dataset.parentId = folderId;
                elements.folderModal.classList.add('active');
                elements.folderNameInput.focus();
            } else if (action === 'delete') {
                await deleteFolder(folderId);
            }

            hideContextMenu();
        });
    });

    document.getElementById('backupBtn').addEventListener('click', () => {
        window.open('/api/export/database', '_blank');
    });

    document.addEventListener('click', (e) => {
        if (!elements.contextMenu.contains(e.target)) {
            hideContextMenu();
        }
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            hideContextMenu();
            elements.folderModal.classList.remove('active');
            elements.exportModal.classList.remove('active');
        }

        if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
            e.preventDefault();
            elements.searchInput.focus();
        }

        if (e.code === 'Space' && !['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName)) {
            e.preventDefault();
            toggleRecording();
        }

        if ((e.ctrlKey || e.metaKey) && e.key === 's') {
            e.preventDefault();
            if (state.currentNote) saveNote();
        }
    });
}

async function loadVoiceProfiles() {
    try {
        const data = await api('/api/voice-profiles');
        state.voiceProfiles = data.profiles || [];
        state.currentProfile = data.current_profile;
        state.voiceFilterEnabled = data.filter_enabled;
        updateVoiceFilterUI();
        renderProfilesList();
    } catch (e) {
        console.error('Failed to load voice profiles:', e);
    }
}

function updateVoiceFilterUI() {
    if (state.voiceFilterEnabled && state.currentProfile) {
        elements.voiceFilterBtn.classList.add('active');
        elements.profileStatus.classList.add('active');
        elements.profileStatus.querySelector('strong').textContent = state.currentProfile.name;
        elements.profileStatus.querySelector('span').textContent = t('filteringVoice');
        elements.disableFilterBtn.classList.remove('hidden');
    } else {
        elements.voiceFilterBtn.classList.remove('active');
        elements.profileStatus.classList.remove('active');
        elements.profileStatus.querySelector('strong').textContent = t('noProfileActive');
        elements.profileStatus.querySelector('span').textContent = t('recordToCreate');
        elements.disableFilterBtn.classList.add('hidden');
    }
}

function renderProfilesList() {
    if (state.voiceProfiles.length === 0) {
        elements.profilesList.innerHTML = `<p class="no-profiles">${t('noProfilesSaved')}</p>`;
        return;
    }

    elements.profilesList.innerHTML = state.voiceProfiles.map(profile => `
        <div class="profile-item ${state.currentProfile?.profile_id === profile.profile_id ? 'active' : ''}" data-profile-id="${profile.profile_id}">
            <div class="profile-info">
                <span class="profile-name">${escapeHtml(profile.name)}</span>
                <span class="profile-meta">${Math.round(profile.duration)}s recorded</span>
            </div>
            <div class="profile-actions">
                ${state.currentProfile?.profile_id !== profile.profile_id ?
                    `<button class="btn-activate" data-action="activate">${t('profileActivated').split(' ')[0]}</button>` :
                    ''
                }
                <button class="btn-delete" data-action="delete">×</button>
            </div>
        </div>
    `).join('');

    elements.profilesList.querySelectorAll('.profile-item').forEach(item => {
        const profileId = item.dataset.profileId;

        item.querySelector('.btn-activate')?.addEventListener('click', async (e) => {
            e.stopPropagation();
            await activateProfile(profileId);
        });

        item.querySelector('.btn-delete')?.addEventListener('click', async (e) => {
            e.stopPropagation();
            await deleteProfile(profileId);
        });
    });
}

async function activateProfile(profileId) {
    try {
        const data = await api(`/api/voice-profiles/${profileId}/activate`, { method: 'POST' });
        if (data.success) {
            state.voiceFilterEnabled = true;
            state.currentProfile = data.profile;
            updateVoiceFilterUI();
            renderProfilesList();
            showToast(t('profileActivated'), 'success');

            if (data.adaptive && data.adaptive.loaded) {
                const threshold = data.adaptive.params?.voice_threshold || 0.30;
                const slider = document.getElementById('thresholdSlider');
                if (slider) slider.value = threshold;
                document.getElementById('thresholdValue').textContent = threshold.toFixed(2);
            }
        }
    } catch (e) {
        console.error('Failed to activate profile:', e);
    }
}

async function deactivateFilter() {
    try {
        await api('/api/voice-profiles/deactivate', { method: 'POST' });
        state.voiceFilterEnabled = false;
        state.currentProfile = null;
        updateVoiceFilterUI();
        renderProfilesList();
        hideVoiceDashboard();
        showToast(t('profileDeactivated'), 'success');
    } catch (e) {
        console.error('Failed to deactivate filter:', e);
    }
}

async function deleteProfile(profileId) {
    try {
        await api(`/api/voice-profiles/${profileId}`, { method: 'DELETE' });
        await loadVoiceProfiles();
    } catch (e) {
        console.error('Failed to delete profile:', e);
    }
}

function showVoiceProfileModal() {
    loadVoiceProfiles();
    elements.voiceProfileModal.classList.add('active');
}

function hideVoiceProfileModal() {
    elements.voiceProfileModal.classList.remove('active');
    if (state.isEnrolling) {
        socket.emit('cancel_enrollment');
    }
}

function startEnrollment() {
    const name = elements.teacherNameInput.value.trim() || 'Teacher';
    state.isEnrolling = true;

    elements.startEnrollmentBtn.classList.add('hidden');
    elements.stopEnrollmentBtn.classList.remove('hidden');
    elements.cancelEnrollmentBtn.classList.remove('hidden');
    elements.enrollmentProgress.classList.remove('hidden');
    elements.teacherNameInput.disabled = true;

    socket.emit('start_enrollment', { name });
}

function stopEnrollment() {
    socket.emit('stop_enrollment', {});
}

function cancelEnrollment() {
    socket.emit('cancel_enrollment');
    resetEnrollmentUI();
    showToast(t('enrollmentCancelled'), 'error');
}

function resetEnrollmentUI() {
    state.isEnrolling = false;
    elements.startEnrollmentBtn.classList.remove('hidden');
    elements.stopEnrollmentBtn.classList.add('hidden');
    elements.cancelEnrollmentBtn.classList.add('hidden');
    elements.enrollmentProgress.classList.add('hidden');
    elements.enrollmentProgressFill.style.width = '0%';
    elements.enrollmentDuration.textContent = '0s';
    elements.teacherNameInput.disabled = false;
    elements.teacherNameInput.value = '';
}

socket.on('enrollment_started', (data) => {
    console.log('Enrollment started:', data);
});

socket.on('enrollment_progress', (data) => {
    const duration = Math.round(data.duration || 0);
    const progress = Math.min(100, (duration / 30) * 100);

    elements.enrollmentDuration.textContent = `${duration}s`;
    elements.enrollmentProgressFill.style.width = `${progress}%`;

    if (data.is_ready) {
        elements.stopEnrollmentBtn.classList.add('ready');
    }
});

socket.on('enrollment_complete', (data) => {
    resetEnrollmentUI();

    if (data.status === 'success') {
        state.voiceFilterEnabled = true;
        state.currentProfile = { profile_id: data.profile_id, name: data.name };
        updateVoiceFilterUI();
        loadVoiceProfiles();
        showToast(t('profileCreated'), 'success');
    } else {
        showToast(data.error || 'Enrollment failed', 'error');
    }
});

socket.on('enrollment_cancelled', () => {
    resetEnrollmentUI();
});

socket.on('enrollment_error', (data) => {
    resetEnrollmentUI();
    showToast(data.error || 'Failed to start enrollment recording', 'error');
});

socket.on('voice_filter_status', (data) => {
    console.log('Voice filter:', data);
});

socket.on('voice_filter_dashboard', (data) => {
    updateVoiceDashboard(data);
});

function updateVoiceDashboard(data) {
    const dashboard = document.getElementById('voiceDashboard');
    if (!dashboard || dashboard.classList.contains('hidden')) return;

    document.getElementById('dashSimilarity').textContent = (data.similarity * 100).toFixed(0) + '%';
    document.getElementById('dashAccepted').textContent = data.accepted;
    document.getElementById('dashRejected').textContent = data.rejected;

    if (data.audio_quality) {
        document.getElementById('dashQuality').textContent = data.audio_quality.score;
        document.getElementById('dashSnr').textContent = data.audio_quality.snr + 'dB';

        const issuesEl = document.getElementById('qualityIssues');
        if (data.audio_quality.issues && data.audio_quality.issues.length > 0) {
            issuesEl.textContent = data.audio_quality.issues.join(', ');
        } else {
            issuesEl.textContent = '';
        }
    }

    const similarityFill = document.getElementById('similarityFill');
    similarityFill.style.width = (data.similarity * 100) + '%';
    similarityFill.className = 'similarity-fill ' + (data.is_match ? 'match' : 'no-match');

    const thresholdMarker = document.getElementById('thresholdMarker');
    thresholdMarker.style.left = (data.threshold * 100) + '%';

    if (data.similarity_history && data.similarity_history.length > 0) {
        drawHistogram(data.similarity_history, data.threshold);
    }
}

function drawHistogram(history, threshold) {
    const canvas = document.getElementById('histogramCanvas');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;

    ctx.clearRect(0, 0, width, height);

    const barWidth = width / history.length;
    const thresholdY = height - (threshold * height);

    ctx.strokeStyle = 'rgba(255, 255, 255, 0.3)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, thresholdY);
    ctx.lineTo(width, thresholdY);
    ctx.stroke();

    history.forEach((value, index) => {
        const barHeight = value * height;
        const x = index * barWidth;
        const y = height - barHeight;

        ctx.fillStyle = value >= threshold ? '#10b981' : '#ef4444';
        ctx.fillRect(x, y, barWidth - 1, barHeight);
    });
}

function showVoiceDashboard() {
    const dashboard = document.getElementById('voiceDashboard');
    if (dashboard) {
        dashboard.classList.remove('hidden');
    }
}

function hideVoiceDashboard() {
    const dashboard = document.getElementById('voiceDashboard');
    if (dashboard) {
        dashboard.classList.add('hidden');
    }
}

async function setThresholdLive(value) {
    try {
        await api('/api/adaptive/threshold', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ threshold: parseFloat(value) })
        });
        document.getElementById('thresholdValue').textContent = value;
    } catch (e) {
        console.error('Failed to set threshold:', e);
    }
}

async function markChunkError(chunkIndex, text, errorType) {
    try {
        await api('/api/chunk-error', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                chunk_index: chunkIndex,
                text: text,
                error_type: errorType,
                note_id: state.currentNote ? state.currentNote.id : null
            })
        });
        showToast('Error marked', 'success');
    } catch (e) {
        console.error('Failed to mark error:', e);
    }
}

function initDashboardListeners() {
    const closeDashboard = document.getElementById('closeDashboard');
    if (closeDashboard) {
        closeDashboard.addEventListener('click', hideVoiceDashboard);
    }

    const thresholdSlider = document.getElementById('thresholdSlider');
    if (thresholdSlider) {
        thresholdSlider.addEventListener('input', (e) => {
            document.getElementById('thresholdValue').textContent = e.target.value;
        });
        thresholdSlider.addEventListener('change', (e) => {
            setThresholdLive(e.target.value);
        });
    }
}

function showFeedbackModal(noteId, transcription) {
    state.lastRecordingNoteId = noteId;
    state.feedbackRating = 0;

    elements.starRating.querySelectorAll('.star').forEach(star => {
        star.classList.remove('active');
    });
    elements.feedbackComments.value = '';
    elements.qualityAnalysis.classList.add('hidden');

    analyzeTranscriptionQuality(transcription);

    elements.feedbackModal.classList.add('active');
}

function hideFeedbackModal() {
    elements.feedbackModal.classList.remove('active');
}

async function analyzeTranscriptionQuality(text) {
    try {
        const result = await api('/api/feedback/analyze', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ text, language: state.currentLanguage })
        });

        elements.qualityScoreValue.textContent = result.quality_score || '--';
        elements.issuesCountValue.textContent = result.issue_count || '0';
        elements.qualityAnalysis.classList.remove('hidden');
    } catch (e) {
        console.error('Failed to analyze quality:', e);
    }
}

async function submitFeedback() {
    if (state.feedbackRating === 0) {
        showToast('Please select a rating', 'error');
        return;
    }

    try {
        const currentNote = state.currentNote;
        await api('/api/feedback', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                note_id: state.lastRecordingNoteId || (currentNote ? currentNote.id : 'unknown'),
                transcription: currentNote ? currentNote.content : '',
                rating: state.feedbackRating,
                folder_id: state.currentFolder,
                user_comments: elements.feedbackComments.value,
                language: state.currentLanguage
            })
        });

        showToast(t('feedbackThanks'), 'success');
        hideFeedbackModal();
    } catch (e) {
        console.error('Failed to submit feedback:', e);
        showToast(t('feedbackError'), 'error');
    }
}

function initFeedbackListeners() {
    elements.starRating.querySelectorAll('.star').forEach(star => {
        star.addEventListener('click', () => {
            const rating = parseInt(star.dataset.rating);
            state.feedbackRating = rating;

            elements.starRating.querySelectorAll('.star').forEach((s, i) => {
                s.classList.toggle('active', i < rating);
            });
        });

        star.addEventListener('mouseenter', () => {
            const rating = parseInt(star.dataset.rating);
            elements.starRating.querySelectorAll('.star').forEach((s, i) => {
                s.classList.toggle('hover', i < rating);
            });
        });

        star.addEventListener('mouseleave', () => {
            elements.starRating.querySelectorAll('.star').forEach(s => {
                s.classList.remove('hover');
            });
        });
    });

    elements.skipFeedbackBtn.addEventListener('click', hideFeedbackModal);
    elements.submitFeedbackBtn.addEventListener('click', submitFeedback);
    elements.feedbackModal.querySelector('.modal-backdrop').addEventListener('click', hideFeedbackModal);
}

async function setVoiceFilterMode(mode) {
    try {
        await api('/api/voice-profiles/set-mode', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ mode })
        });
        state.voiceFilterMode = mode;
        updateVoiceFilterUI();
    } catch (e) {
        console.error('Failed to set voice filter mode:', e);
    }
}

function initVoiceProfileListeners() {
    elements.voiceFilterBtn.addEventListener('click', showVoiceProfileModal);
    elements.closeVoiceProfileBtn.addEventListener('click', hideVoiceProfileModal);
    elements.disableFilterBtn.addEventListener('click', deactivateFilter);
    elements.startEnrollmentBtn.addEventListener('click', startEnrollment);
    elements.stopEnrollmentBtn.addEventListener('click', stopEnrollment);
    elements.cancelEnrollmentBtn.addEventListener('click', cancelEnrollment);

    elements.voiceProfileModal.querySelector('.modal-backdrop').addEventListener('click', hideVoiceProfileModal);
}

async function checkModels() {
    try {
        const data = await api('/api/models/check');
        return data;
    } catch (e) {
        console.error('Failed to check models:', e);
        return { ready: true, models: {} };
    }
}

function showModelCheckModal() {
    elements.modelList.innerHTML = '<div class="model-check-spinner"><div class="spinner"></div></div>';
    elements.downloadProgressSection.classList.add('hidden');
    elements.installModelsBtn.classList.add('hidden');
    elements.startRecordingBtn.classList.add('hidden');
    elements.modelCheckModal.classList.add('active');

    performModelCheck();
}

function hideModelCheckModal() {
    elements.modelCheckModal.classList.remove('active');
    if (state.downloadProgressInterval) {
        clearInterval(state.downloadProgressInterval);
        state.downloadProgressInterval = null;
    }
}

async function performModelCheck() {
    const data = await checkModels();
    const models = data.models || {};

    let html = '';
    let missingModels = [];

    for (const [key, model] of Object.entries(models)) {
        const statusClass = model.installed ? 'installed' : 'missing';
        const badgeClass = model.installed ? 'installed' : (model.required ? 'required' : 'optional');
        const badgeText = model.installed ? t('modelInstalled') : (model.required ? t('modelRequired') : t('modelOptional'));

        if (!model.installed && model.available !== false) {
            missingModels.push(key);
        }

        html += `
            <div class="model-item ${statusClass}" data-model="${key}">
                <div class="model-info">
                    <span class="model-name">${escapeHtml(model.display_name)}</span>
                    <span class="model-meta">${model.size || ''} ${model.message || ''}</span>
                </div>
                <div class="model-status">
                    <span class="status-badge ${badgeClass}">${badgeText}</span>
                </div>
            </div>
        `;
    }

    elements.modelList.innerHTML = html;

    state.pendingDownloads = missingModels.filter(m => models[m]?.required);
    const optionalMissing = missingModels.filter(m => !models[m]?.required);

    if (data.ready) {
        state.modelsReady = true;
        elements.startRecordingBtn.classList.remove('hidden');
        elements.installModelsBtn.classList.add('hidden');

        if (optionalMissing.length > 0) {
            elements.installModelsBtn.textContent = t('installMissing') + ` (${optionalMissing.length})`;
            elements.installModelsBtn.classList.remove('hidden');
            state.pendingDownloads = optionalMissing;
        }
    } else {
        state.modelsReady = false;
        elements.startRecordingBtn.classList.add('hidden');
        elements.installModelsBtn.classList.remove('hidden');
        elements.installModelsBtn.textContent = t('installMissing') + ` (${state.pendingDownloads.length})`;
    }

    state.modelsChecked = true;
}

async function installMissingModels() {
    if (state.pendingDownloads.length === 0) return;

    elements.downloadProgressSection.classList.remove('hidden');
    elements.installModelsBtn.classList.add('hidden');
    elements.startRecordingBtn.classList.add('hidden');

    let downloadHtml = '';
    for (const modelName of state.pendingDownloads) {
        downloadHtml += `
            <div class="download-item" id="download-${modelName}">
                <div class="download-header">
                    <span class="download-name">${modelName}</span>
                    <span class="download-status">${t('checkingModels')}</span>
                </div>
                <div class="download-progress-bar">
                    <div class="download-progress-fill" id="progress-${modelName}"></div>
                </div>
                <div class="download-message" id="message-${modelName}"></div>
            </div>
        `;
    }
    elements.downloadList.innerHTML = downloadHtml;

    for (const modelName of state.pendingDownloads) {
        await api(`/api/models/download/${modelName}`, { method: 'POST' });
    }

    startDownloadProgressPolling();
}

function startDownloadProgressPolling() {
    if (state.downloadProgressInterval) {
        clearInterval(state.downloadProgressInterval);
    }

    state.downloadProgressInterval = setInterval(async () => {
        try {
            const data = await api('/api/models/progress');
            const downloads = data.downloads || {};

            let allComplete = true;
            let anyActive = false;

            for (const modelName of state.pendingDownloads) {
                const item = document.getElementById(`download-${modelName}`);
                const progressFill = document.getElementById(`progress-${modelName}`);
                const statusEl = item?.querySelector('.download-status');
                const messageEl = document.getElementById(`message-${modelName}`);

                const downloadInfo = downloads[modelName];

                if (downloadInfo) {
                    anyActive = true;
                    if (progressFill) progressFill.style.width = `${downloadInfo.progress}%`;
                    if (statusEl) statusEl.textContent = downloadInfo.status;
                    if (messageEl) messageEl.textContent = downloadInfo.message || '';

                    if (downloadInfo.status === 'complete') {
                        item?.classList.add('complete');
                    } else if (downloadInfo.status === 'error') {
                        item?.classList.add('error');
                    } else {
                        allComplete = false;
                    }
                } else {
                    if (progressFill) progressFill.style.width = '100%';
                    if (statusEl) statusEl.textContent = t('downloadComplete');
                    item?.classList.add('complete');
                }
            }

            if (!anyActive || allComplete) {
                clearInterval(state.downloadProgressInterval);
                state.downloadProgressInterval = null;

                setTimeout(() => {
                    performModelCheck();
                }, 1000);
            }
        } catch (e) {
            console.error('Failed to get download progress:', e);
        }
    }, 500);
}

function initModelCheckListeners() {
    elements.cancelModelCheckBtn.addEventListener('click', hideModelCheckModal);
    elements.installModelsBtn.addEventListener('click', installMissingModels);
    elements.startRecordingBtn.addEventListener('click', () => {
        hideModelCheckModal();
        actuallyStartRecording();
    });
    elements.modelCheckModal.querySelector('.modal-backdrop').addEventListener('click', hideModelCheckModal);
}

async function preflightRecordCheck() {
    if (state.modelsChecked && state.modelsReady) {
        actuallyStartRecording();
    } else {
        showModelCheckModal();
    }
}

async function init() {
    loadTheme();
    const savedUILang = localStorage.getItem('uiLanguage') || 'en';
    setUILanguage(savedUILang);
    initEventListeners();
    initVoiceProfileListeners();
    initModelCheckListeners();
    initFeedbackListeners();
    initDashboardListeners();
    await loadFolders();
    await loadNotes();
    await loadTags();
    await loadVoiceProfiles();

    checkModels().then(data => {
        state.modelsChecked = true;
        state.modelsReady = data.ready;
    });
}

init();
