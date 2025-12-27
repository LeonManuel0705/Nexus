const API_BASE = '';
const socket = io();

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
        listening: 'Listening...'
    },
    de: {
        folders: 'Ordner',
        tags: 'Tags',
        allNotes: 'Alle Notizen',
        searchNotes: 'Notizen suchen...',
        pressToRecord: 'Zum Aufnehmen drücken',
        recording: 'Aufnahme...',
        saving: 'Speichern...',
        liveTranscription: 'Live-Transkription',
        aiEnhanced: 'KI-Optimiert',
        ultraFast: 'Ultraschnell',
        startRecording: 'Aufnahme starten für Live-Transkription...',
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
        transcriptionPlaceholder: 'Ihre Transkription erscheint hier...',
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
        noNotesDesc: 'Drücken Sie den Aufnahme-Button für Ihre erste Sprachnotiz',
        listening: 'Hören...'
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
    selectedNotes: new Set()
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
    exportSelectedBtn: document.getElementById('exportSelectedBtn')
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

socket.on('recording_stopped', async (data) => {
    state.isRecording = false;
    clearInterval(state.recordingInterval);
    stopWaveformAnimation();

    elements.recordBtn.classList.remove('recording');
    elements.recordLabel.textContent = t('pressToRecord');
    elements.recordingDuration.textContent = '00:00';
    elements.liveTranscription.classList.remove('active');

    if (data.success) {
        elements.liveTranscriptionContent.innerHTML = `<p style="color: var(--success)">${escapeHtml(data.final_text)}</p>`;
        showToast(t('noteSaved'), 'success');
        await loadNotes();
        selectNote(data.note.id);
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

    await api(`/api/notes/${state.currentNote.id}`, {
        method: 'PUT',
        body: JSON.stringify({
            title: elements.noteTitle.value,
            content: elements.noteContent.value,
            folder_id: elements.noteFolderSelect.value ? parseInt(elements.noteFolderSelect.value) : 0
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
    state.isRecording ? stopRecording() : startRecording();
}

function startRecording() {
    socket.emit('start_realtime', {
        folder_id: state.currentFolder,
        language: state.currentLanguage
    });

    state.isRecording = true;
    elements.recordBtn.classList.add('recording');
    elements.recordLabel.textContent = t('recording');

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

async function init() {
    loadTheme();
    const savedUILang = localStorage.getItem('uiLanguage') || 'en';
    setUILanguage(savedUILang);
    initEventListeners();
    await loadFolders();
    await loadNotes();
    await loadTags();
}

init();
