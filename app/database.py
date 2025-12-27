import sqlite3
import os
from datetime import datetime
from typing import List, Optional, Dict, Any

DATABASE_PATH = os.path.expanduser("~/Documents/voice-notes/data/notes.db")

def get_connection():
    os.makedirs(os.path.dirname(DATABASE_PATH), exist_ok=True)
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS folders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            parent_id INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (parent_id) REFERENCES folders(id) ON DELETE CASCADE
        )
    ''')

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            folder_id INTEGER,
            language TEXT,
            audio_duration REAL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL
        )
    ''')

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
        )
    ''')

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS note_tags (
            note_id INTEGER,
            tag_id INTEGER,
            PRIMARY KEY (note_id, tag_id),
            FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
            FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
        )
    ''')

    cursor.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
            title, content, content='notes', content_rowid='id'
        )
    ''')

    cursor.execute('''
        CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON notes BEGIN
            INSERT INTO notes_fts(rowid, title, content) VALUES (new.id, new.title, new.content);
        END
    ''')

    cursor.execute('''
        CREATE TRIGGER IF NOT EXISTS notes_ad AFTER DELETE ON notes BEGIN
            INSERT INTO notes_fts(notes_fts, rowid, title, content) VALUES('delete', old.id, old.title, old.content);
        END
    ''')

    cursor.execute('''
        CREATE TRIGGER IF NOT EXISTS notes_au AFTER UPDATE ON notes BEGIN
            INSERT INTO notes_fts(notes_fts, rowid, title, content) VALUES('delete', old.id, old.title, old.content);
            INSERT INTO notes_fts(rowid, title, content) VALUES (new.id, new.title, new.content);
        END
    ''')

    conn.commit()
    conn.close()


def create_folder(name: str, parent_id: Optional[int] = None) -> int:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        'INSERT INTO folders (name, parent_id) VALUES (?, ?)',
        (name, parent_id)
    )
    folder_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return folder_id

def get_folders(parent_id: Optional[int] = None) -> List[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    if parent_id is None:
        cursor.execute('SELECT * FROM folders WHERE parent_id IS NULL ORDER BY name')
    else:
        cursor.execute('SELECT * FROM folders WHERE parent_id = ? ORDER BY name', (parent_id,))
    folders = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return folders

def get_all_folders() -> List[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM folders ORDER BY name')
    folders = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return folders

def get_folder(folder_id: int) -> Optional[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM folders WHERE id = ?', (folder_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def delete_folder(folder_id: int) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM folders WHERE id = ?', (folder_id,))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def rename_folder(folder_id: int, new_name: str) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('UPDATE folders SET name = ? WHERE id = ?', (new_name, folder_id))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0


def create_note(title: str, content: str, folder_id: Optional[int] = None,
                language: Optional[str] = None, audio_duration: Optional[float] = None) -> int:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        '''INSERT INTO notes (title, content, folder_id, language, audio_duration)
           VALUES (?, ?, ?, ?, ?)''',
        (title, content, folder_id, language, audio_duration)
    )
    note_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return note_id

def get_notes(folder_id: Optional[int] = None) -> List[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    if folder_id is None:
        cursor.execute('SELECT * FROM notes ORDER BY created_at DESC')
    else:
        cursor.execute('SELECT * FROM notes WHERE folder_id = ? ORDER BY created_at DESC', (folder_id,))
    notes = [dict(row) for row in cursor.fetchall()]
    conn.close()

    for note in notes:
        note['tags'] = get_note_tags(note['id'])

    return notes

def get_note(note_id: int) -> Optional[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM notes WHERE id = ?', (note_id,))
    row = cursor.fetchone()
    conn.close()
    if row:
        note = dict(row)
        note['tags'] = get_note_tags(note_id)
        return note
    return None

def update_note(note_id: int, title: Optional[str] = None, content: Optional[str] = None,
                folder_id = "NOT_SET") -> bool:
    conn = get_connection()
    cursor = conn.cursor()

    updates = []
    params = []

    if title is not None:
        updates.append('title = ?')
        params.append(title)
    if content is not None:
        updates.append('content = ?')
        params.append(content)
    if folder_id != "NOT_SET":
        updates.append('folder_id = ?')
        params.append(folder_id if folder_id and folder_id != 0 else None)

    if not updates:
        return False

    updates.append('updated_at = CURRENT_TIMESTAMP')
    params.append(note_id)

    query = f'UPDATE notes SET {", ".join(updates)} WHERE id = ?'
    cursor.execute(query, params)
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def delete_note(note_id: int) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM notes WHERE id = ?', (note_id,))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def search_notes(query: str) -> List[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT notes.* FROM notes
        JOIN notes_fts ON notes.id = notes_fts.rowid
        WHERE notes_fts MATCH ?
        ORDER BY rank
    ''', (query,))
    notes = [dict(row) for row in cursor.fetchall()]
    conn.close()

    for note in notes:
        note['tags'] = get_note_tags(note['id'])

    return notes


def create_tag(name: str) -> int:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('INSERT INTO tags (name) VALUES (?)', (name.lower(),))
        tag_id = cursor.lastrowid
    except sqlite3.IntegrityError:
        cursor.execute('SELECT id FROM tags WHERE name = ?', (name.lower(),))
        tag_id = cursor.fetchone()[0]
    conn.commit()
    conn.close()
    return tag_id

def get_all_tags() -> List[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM tags ORDER BY name')
    tags = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return tags

def add_tag_to_note(note_id: int, tag_name: str) -> bool:
    tag_id = create_tag(tag_name)
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('INSERT INTO note_tags (note_id, tag_id) VALUES (?, ?)', (note_id, tag_id))
        conn.commit()
        result = True
    except sqlite3.IntegrityError:
        result = False
    conn.close()
    return result

def remove_tag_from_note(note_id: int, tag_name: str) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        DELETE FROM note_tags WHERE note_id = ? AND tag_id = (
            SELECT id FROM tags WHERE name = ?
        )
    ''', (note_id, tag_name.lower()))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def get_note_tags(note_id: int) -> List[str]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT tags.name FROM tags
        JOIN note_tags ON tags.id = note_tags.tag_id
        WHERE note_tags.note_id = ?
        ORDER BY tags.name
    ''', (note_id,))
    tags = [row[0] for row in cursor.fetchall()]
    conn.close()
    return tags

def get_notes_by_tag(tag_name: str) -> List[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT notes.* FROM notes
        JOIN note_tags ON notes.id = note_tags.note_id
        JOIN tags ON note_tags.tag_id = tags.id
        WHERE tags.name = ?
        ORDER BY notes.created_at DESC
    ''', (tag_name.lower(),))
    notes = [dict(row) for row in cursor.fetchall()]
    conn.close()

    for note in notes:
        note['tags'] = get_note_tags(note['id'])

    return notes


init_db()
