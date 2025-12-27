const API_BASE = '';
const socket = io();

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
    systemStatus: null,
    waveformAnimationId: null
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
    toastContainer: document.getElementById('toastContainer')
};

socket.on('connect', () => console.log('Connected to server'));

socket.on('recording_started', (data) => {
    elements.liveTranscription.classList.add('active');
    elements.liveTranscriptionContent.innerHTML = '<p class="listening">Listening...</p>';
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

socket.on('recording_stopped', async (data) => {
    state.isRecording = false;
    clearInterval(state.recordingInterval);
    stopWaveformAnimation();

    elements.recordBtn.classList.remove('recording');
    elements.recordLabel.textContent = 'Press to record';
    elements.recordingDuration.textContent = '00:00';
    elements.liveTranscription.classList.remove('active');

    if (data.success) {
        elements.liveTranscriptionContent.innerHTML = `<p style="color: var(--success)">${escapeHtml(data.final_text)}</p>`;
        showToast('Note saved successfully!', 'success');
        await loadNotes();
        selectNote(data.note.id);
        setTimeout(() => {
            elements.liveTranscriptionContent.innerHTML = '<p class="placeholder">Start recording to see live transcription...</p>';
        }, 2000);
    } else {
        elements.liveTranscriptionContent.innerHTML = `<p style="color: var(--danger)">${data.message || 'No speech detected'}</p>`;
        setTimeout(() => {
            elements.liveTranscriptionContent.innerHTML = '<p class="placeholder">Start recording to see live transcription...</p>';
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
    const canvas = elements.waveformCanvas;
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);
}

function updateTranscriptionStats(text) {
    const words = text.trim().split(/\s+/).filter(w => w).length;
    const chars = text.length;
    elements.wordCount.textContent = `${words} words`;
    elements.charCount.textContent = `${chars} characters`;
}

function updateDetailStats() {
    const text = elements.noteContent.value;
    const words = text.trim().split(/\s+/).filter(w => w).length;
    const chars = text.length;
    elements.detailWordCount.textContent = `${words} words`;
    elements.detailCharCount.textContent = `${chars} characters`;
}

async function api(endpoint, options = {}) {
    const response = await fetch(`${API_BASE}${endpoint}`, {
        ...options,
        headers: { 'Content-Type': 'application/json', ...options.headers }
    });
    return response.json();
}

async function loadFolders() {
    const data = await api('/api/folders?all=true');
    state.folders = data.folders;
    renderFolderTree();
    updateFolderSelect();
}

function buildFolderHierarchy(folders, parentId = null) {
    return folders
        .filter(f => f.parent_id === parentId)
        .map(folder => ({
            ...folder,
            children: buildFolderHierarchy(folders, folder.id)
        }));
}

function renderFolderTree() {
    const hierarchy = buildFolderHierarchy(state.folders);

    let html = `
        <div class="folder-item all-notes-item ${state.currentFolder === null ? 'active' : ''}" data-folder-id="null">
            <span class="folder-icon">📁</span>
            <span class="folder-name">All Notes</span>
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
    elements.searchInput.value = '';
    renderFolderTree();
    updateBreadcrumb();
    await loadNotes();
}

function updateBreadcrumb() {
    if (state.currentFolder === null) {
        elements.breadcrumb.innerHTML = '<span>All Notes</span>';
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
    showToast('Folder created', 'success');
}

async function renameFolder(folderId, newName) {
    await api(`/api/folders/${folderId}`, { method: 'PUT', body: JSON.stringify({ name: newName }) });
    await loadFolders();
    showToast('Folder renamed', 'success');
}

async function deleteFolder(folderId) {
    if (confirm('Delete this folder and all its contents?')) {
        await api(`/api/folders/${folderId}`, { method: 'DELETE' });
        if (state.currentFolder === folderId) state.currentFolder = null;
        await loadFolders();
        await loadNotes();
        showToast('Folder deleted', 'success');
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
    elements.noteCount.textContent = `${state.notes.length} note${state.notes.length !== 1 ? 's' : ''}`;
}

function renderNotes() {
    if (state.notes.length === 0) {
        elements.notesList.innerHTML = `
            <div class="empty-state">
                <h3>No notes yet</h3>
                <p>Press the record button to create your first voice note</p>
            </div>
        `;
        return;
    }

    elements.notesList.innerHTML = state.notes.map(note => `
        <div class="note-card ${state.currentNote?.id === note.id ? 'active' : ''}" data-note-id="${note.id}">
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
        card.addEventListener('click', () => selectNote(parseInt(card.dataset.noteId)));
    });
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
    showToast('Note saved', 'success');
}

async function deleteNote() {
    if (!state.currentNote) return;

    if (confirm('Delete this note?')) {
        await api(`/api/notes/${state.currentNote.id}`, { method: 'DELETE' });
        state.currentNote = null;
        elements.detailPanel.classList.add('hidden');
        await loadNotes();
        showToast('Note deleted', 'success');
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
            elements.searchInput.value = '';
            elements.breadcrumb.innerHTML = `<span>Tag: ${escapeHtml(item.dataset.tag)}</span>`;
            renderFolderTree();
            renderNotes();
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
    socket.emit('start_realtime', { folder_id: state.currentFolder });

    state.isRecording = true;
    elements.recordBtn.classList.add('recording');
    elements.recordLabel.textContent = 'Recording...';

    let seconds = 0;
    state.recordingInterval = setInterval(() => {
        seconds++;
        elements.recordingDuration.textContent = formatDuration(seconds);
    }, 1000);
}

function stopRecording() {
    elements.recordLabel.textContent = 'Processing...';
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
    let options = '<option value="">No folder</option>';
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
        if (query) {
            state.currentFolder = null;
            elements.breadcrumb.innerHTML = `<span>Search: "${escapeHtml(query)}"</span>`;
            renderFolderTree();
        }
        await loadNotes();
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
    const newTheme = current === 'light' ? 'dark' : 'light';
    document.body.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
}

function loadTheme() {
    const saved = localStorage.getItem('theme') || 'dark';
    document.body.setAttribute('data-theme', saved);
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function formatDate(dateStr) {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
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

    document.getElementById('addFolderBtn').addEventListener('click', () => {
        elements.folderModalTitle.textContent = 'New Folder';
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
        const tag = elements.newTagInput.value.trim();
        if (tag && state.currentNote) {
            await addTag(state.currentNote.id, tag);
            elements.newTagInput.value = '';
        }
    });

    elements.newTagInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') document.getElementById('addTagBtn').click();
    });

    document.getElementById('cancelExportBtn').addEventListener('click', () => {
        elements.exportModal.classList.remove('active');
    });

    elements.exportModal.querySelectorAll('[data-format]').forEach(btn => {
        btn.addEventListener('click', () => exportFile(btn.dataset.format));
    });

    document.addEventListener('click', hideContextMenu);

    elements.contextMenu.querySelectorAll('.context-menu-item').forEach(item => {
        item.addEventListener('click', async () => {
            const action = item.dataset.action;
            const folderId = state.contextMenuTarget;

            if (action === 'rename') {
                const folder = state.folders.find(f => f.id === parseInt(folderId));
                elements.folderModalTitle.textContent = 'Rename Folder';
                elements.folderNameInput.value = folder.name;
                elements.folderModal.dataset.mode = 'rename';
                elements.folderModal.dataset.folderId = folderId;
                elements.folderModal.classList.add('active');
                elements.folderNameInput.focus();
            } else if (action === 'subfolder') {
                elements.folderModalTitle.textContent = 'New Subfolder';
                elements.folderNameInput.value = '';
                elements.folderModal.dataset.mode = 'create';
                elements.folderModal.dataset.parentId = folderId;
                elements.folderModal.classList.add('active');
                elements.folderNameInput.focus();
            } else if (action === 'delete') {
                await deleteFolder(parseInt(folderId));
            }

            hideContextMenu();
        });
    });

    document.querySelectorAll('.modal-backdrop').forEach(backdrop => {
        backdrop.addEventListener('click', () => {
            backdrop.parentElement.classList.remove('active');
        });
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === ' ' && document.activeElement.tagName !== 'INPUT' && document.activeElement.tagName !== 'TEXTAREA') {
            e.preventDefault();
            toggleRecording();
        }
        if ((e.ctrlKey || e.metaKey) && e.key === 's') {
            e.preventDefault();
            if (state.currentNote) saveNote();
        }
        if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
            e.preventDefault();
            elements.searchInput.focus();
        }
        if (e.key === 'Escape') {
            elements.folderModal.classList.remove('active');
            elements.exportModal.classList.remove('active');
            hideContextMenu();
        }
    });
}

async function loadSystemStatus() {
    try {
        const data = await api('/api/settings/status');
        state.systemStatus = data;
        updateStatusBar();
    } catch (e) {
        console.error('Failed to load system status:', e);
    }
}

function updateStatusBar() {
    const status = state.systemStatus;
    if (!status) return;

    const offlineStatus = document.getElementById('offlineStatus');
    if (offlineStatus) {
        const dot = offlineStatus.querySelector('.status-dot');
        dot.className = 'status-dot online';
    }

    const aiStatus = document.getElementById('aiStatus');
    if (aiStatus && status.ai_correction) {
        const dot = aiStatus.querySelector('.status-dot');
        dot.className = status.ai_correction.mlx_available ? 'status-dot online' : 'status-dot warning';
        aiStatus.querySelector('span:last-child').textContent = status.ai_correction.mlx_available ? 'AI (MLX)' : 'LanguageTool';
    }

    const speakerStatus = document.getElementById('speakerStatus');
    if (speakerStatus) {
        const dot = speakerStatus.querySelector('.status-dot');
        dot.className = 'status-dot online';
    }
}

function downloadBackup() {
    window.open('/api/export/database', '_blank');
    showToast('Backup download started', 'success');
}

async function init() {
    loadTheme();
    initEventListeners();

    const backupBtn = document.getElementById('backupBtn');
    if (backupBtn) backupBtn.addEventListener('click', downloadBackup);

    await loadFolders();
    await loadNotes();
    await loadTags();
    await loadSystemStatus();
}

init();
