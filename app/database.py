import sqlite3
import os
from datetime import datetime
from typing import List, Optional, Dict, Any

DATABASE_URL = os.environ.get('DATABASE_URL')
DATABASE_PATH = os.path.expanduser("~/Documents/Nexus/data/nexus.db")

_use_postgres = False
if DATABASE_URL:
    try:
        import psycopg2
        import psycopg2.extras
        _use_postgres = True
    except ImportError:
        print("Warning: DATABASE_URL set but psycopg2 not installed. Using SQLite.")
        _use_postgres = False

def get_connection():
                                                                                
    if _use_postgres:
                               
        conn = psycopg2.connect(DATABASE_URL)
        return conn
    else:
                                               
        os.makedirs(os.path.dirname(DATABASE_PATH), exist_ok=True)
        conn = sqlite3.connect(DATABASE_PATH)
        conn.row_factory = sqlite3.Row
        return conn

def _execute(cursor, query, params=None):
                                                                    
    if _use_postgres:
                                        
        query = query.replace('?', '%s')
    cursor.execute(query, params or ())
    return cursor

def _fetchone_dict(cursor):
                                      
    row = cursor.fetchone()
    if row is None:
        return None
    if _use_postgres:
        columns = [desc[0] for desc in cursor.description]
        return dict(zip(columns, row))
    return dict(row)

def _fetchall_dict(cursor):
                                                 
    rows = cursor.fetchall()
    if _use_postgres:
        columns = [desc[0] for desc in cursor.description]
        return [dict(zip(columns, row)) for row in rows]
    return [dict(row) for row in rows]

def init_db():
    conn = get_connection()
    cursor = conn.cursor()

    if _use_postgres:
                           
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS folders (
                id SERIAL PRIMARY KEY,
                name TEXT NOT NULL,
                parent_id INTEGER REFERENCES folders(id) ON DELETE CASCADE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS notes (
                id SERIAL PRIMARY KEY,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                folder_id INTEGER REFERENCES folders(id) ON DELETE SET NULL,
                language TEXT,
                audio_duration REAL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                note_type TEXT DEFAULT 'transcription',
                source TEXT,
                template_id INTEGER,
                ai_formatted INTEGER DEFAULT 0,
                last_formatted_at TIMESTAMP
            )
        ''')

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS tags (
                id SERIAL PRIMARY KEY,
                name TEXT NOT NULL UNIQUE
            )
        ''')

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS note_tags (
                note_id INTEGER REFERENCES notes(id) ON DELETE CASCADE,
                tag_id INTEGER REFERENCES tags(id) ON DELETE CASCADE,
                PRIMARY KEY (note_id, tag_id)
            )
        ''')

        cursor.execute('''
            CREATE INDEX IF NOT EXISTS notes_search_idx
            ON notes USING gin(to_tsvector('german', coalesce(title, '') || ' ' || coalesce(content, '')))
        ''')
    else:
                       
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

    if not _use_postgres:
        try:
            cursor.execute('ALTER TABLE notes ADD COLUMN note_type TEXT DEFAULT "transcription"')
        except sqlite3.OperationalError:
            pass                         

        try:
            cursor.execute('ALTER TABLE notes ADD COLUMN source TEXT')
        except sqlite3.OperationalError:
            pass

        try:
            cursor.execute('ALTER TABLE notes ADD COLUMN template_id INTEGER')
        except sqlite3.OperationalError:
            pass

        try:
            cursor.execute('ALTER TABLE notes ADD COLUMN ai_formatted INTEGER DEFAULT 0')
        except sqlite3.OperationalError:
            pass

        try:
            cursor.execute('ALTER TABLE notes ADD COLUMN last_formatted_at TIMESTAMP')
        except sqlite3.OperationalError:
            pass

        # Add user_id columns to all hub_* tables for multi-user support
        hub_tables_needing_user_id = [
            'hub_tasks',
            'hub_projects',
            'hub_knowledge',
            'hub_reviews',
            'hub_training_sessions',
            'hub_training_health',
            'hub_training_goals',
            'hub_training_schedule_settings',
            'hub_training_schedule_entries',
            'hub_timetable_settings',
            'hub_timetable_entries'
        ]
        for table in hub_tables_needing_user_id:
            try:
                cursor.execute(f'ALTER TABLE {table} ADD COLUMN user_id TEXT')
            except sqlite3.OperationalError:
                pass  # Column already exists

        # Add repeat columns to hub_tasks for task repetition feature
        repeat_columns = [
            ('repeat_type', "TEXT DEFAULT 'none'"),
            ('repeat_days', 'TEXT'),
            ('repeat_end_date', 'TEXT'),
            ('parent_task_id', 'INTEGER')
        ]
        for col_name, col_def in repeat_columns:
            try:
                cursor.execute(f'ALTER TABLE hub_tasks ADD COLUMN {col_name} {col_def}')
            except sqlite3.OperationalError:
                pass  # Column already exists

    pk = 'SERIAL PRIMARY KEY' if _use_postgres else 'INTEGER PRIMARY KEY AUTOINCREMENT'

    cursor.execute(f'''
        CREATE TABLE IF NOT EXISTS note_templates (
            id {pk},
            name TEXT NOT NULL,
            description TEXT,
            content_structure TEXT NOT NULL,
            icon TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    cursor.execute(f'''
        CREATE TABLE IF NOT EXISTS note_versions (
            id {pk},
            note_id INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
            content TEXT NOT NULL,
            title TEXT NOT NULL,
            version_number INTEGER NOT NULL,
            change_summary TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_note_versions_note_id
        ON note_versions(note_id, version_number DESC)
    ''')

    cursor.execute(f'''
        CREATE TABLE IF NOT EXISTS note_sessions (
            id {pk},
            note_id INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
            session_started TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            ai_formatted_during_session INTEGER DEFAULT 0
        )
    ''')

    cursor.execute(f'''
        CREATE TABLE IF NOT EXISTS hub_tasks (
            id {pk},
            title TEXT NOT NULL,
            description TEXT,
            due_date TEXT,
            due_time TEXT,
            priority TEXT DEFAULT 'medium',
            category TEXT,
            completed INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            completed_at TIMESTAMP,
            repeat_type TEXT DEFAULT 'none',
            repeat_days TEXT,
            repeat_end_date TEXT,
            parent_task_id INTEGER
        )
    ''')

    cursor.execute(f'''
        CREATE TABLE IF NOT EXISTS hub_projects (
            id {pk},
            name TEXT NOT NULL,
            goal TEXT,
            status TEXT DEFAULT 'active',
            deadline TEXT,
            next_step TEXT,
            notes TEXT,
            progress INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    cursor.execute(f'''
        CREATE TABLE IF NOT EXISTS hub_knowledge (
            id {pk},
            title TEXT NOT NULL,
            topic TEXT DEFAULT 'general',
            content TEXT,
            tags TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    cursor.execute(f'''
        CREATE TABLE IF NOT EXISTS hub_reviews (
            id {pk},
            type TEXT DEFAULT 'daily',
            date TEXT NOT NULL,
            data TEXT,
            energy INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    cursor.execute(f'''
        CREATE TABLE IF NOT EXISTS hub_training_sessions (
            id {pk},
            type TEXT NOT NULL,
            date TEXT NOT NULL,
            duration INTEGER,
            notes TEXT,
            calories INTEGER,
            exercises TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    cursor.execute(f'''
        CREATE TABLE IF NOT EXISTS hub_training_health (
            id {pk},
            date TEXT NOT NULL,
            sleep REAL,
            energy INTEGER,
            stress INTEGER,
            recovery INTEGER,
            weight REAL,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    cursor.execute(f'''
        CREATE TABLE IF NOT EXISTS hub_training_goals (
            id {pk},
            title TEXT NOT NULL,
            target REAL,
            current REAL DEFAULT 0,
            unit TEXT,
            deadline TEXT,
            completed INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # Training schedule tables (persistent weekly training plan)
    cursor.execute(f'''
        CREATE TABLE IF NOT EXISTS hub_training_schedule_settings (
            id {pk},
            schedule_mode TEXT DEFAULT 'regular',
            auto_detect_holiday INTEGER DEFAULT 1,
            setup_completed INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    cursor.execute(f'''
        CREATE TABLE IF NOT EXISTS hub_training_schedule_entries (
            id {pk},
            day INTEGER NOT NULL,
            schedule_type TEXT DEFAULT 'regular',
            training_type TEXT NOT NULL,
            title TEXT NOT NULL,
            time TEXT,
            duration INTEGER,
            location TEXT,
            muscle_groups TEXT,
            notes TEXT,
            icon TEXT,
            color TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_training_schedule_day_type
        ON hub_training_schedule_entries(day, schedule_type)
    ''')

    cursor.execute(f'''
        CREATE TABLE IF NOT EXISTS hub_timetable_settings (
            id {pk},
            has_ab_weeks INTEGER DEFAULT 1,
            block_count INTEGER DEFAULT 4,
            reference_date TEXT,
            setup_completed INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    cursor.execute(f'''
        CREATE TABLE IF NOT EXISTS hub_timetable_entries (
            id {pk},
            day INTEGER NOT NULL,
            block INTEGER NOT NULL,
            week TEXT DEFAULT 'both',
            subject TEXT NOT NULL,
            subject_type TEXT DEFAULT 'GK',
            room TEXT,
            teacher TEXT,
            color TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_timetable_day_block
        ON hub_timetable_entries(day, block, week)
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
        'INSERT INTO notes (title, content, folder_id, language, audio_duration) VALUES (?, ?, ?, ?, ?)',
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

    if _use_postgres:
                                     
        _execute(cursor, '''
            SELECT * FROM notes
            WHERE to_tsvector('german', coalesce(title, '') || ' ' || coalesce(content, ''))
                  @@ plainto_tsquery('german', ?)
            ORDER BY created_at DESC
        ''', (query,))
    else:
                            
        cursor.execute('''
            SELECT notes.* FROM notes
            JOIN notes_fts ON notes.id = notes_fts.rowid
            WHERE notes_fts MATCH ?
            ORDER BY rank
        ''', (query,))

    notes = _fetchall_dict(cursor)
    conn.close()

    for note in notes:
        note['tags'] = get_note_tags(note['id'])

    return notes

def create_tag(name: str) -> int:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        _execute(cursor, 'INSERT INTO tags (name) VALUES (?)', (name.lower(),))
        if _use_postgres:
            _execute(cursor, 'SELECT id FROM tags WHERE name = ?', (name.lower(),))
            tag_id = cursor.fetchone()[0]
        else:
            tag_id = cursor.lastrowid
    except Exception as e:
                                                                                   
        if 'UNIQUE' in str(e).upper() or 'unique' in str(e) or 'duplicate' in str(e).lower():
            conn.rollback()
            _execute(cursor, 'SELECT id FROM tags WHERE name = ?', (name.lower(),))
            tag_id = cursor.fetchone()[0]
        else:
            raise
    conn.commit()
    conn.close()
    return tag_id

def get_all_tags() -> List[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM tags ORDER BY name')
    tags = _fetchall_dict(cursor)
    conn.close()
    return tags

def add_tag_to_note(note_id: int, tag_name: str) -> bool:
    tag_id = create_tag(tag_name)
    conn = get_connection()
    cursor = conn.cursor()
    try:
        _execute(cursor, 'INSERT INTO note_tags (note_id, tag_id) VALUES (?, ?)', (note_id, tag_id))
        conn.commit()
        result = True
    except Exception as e:
                                            
        if 'UNIQUE' in str(e).upper() or 'unique' in str(e) or 'duplicate' in str(e).lower():
            result = False
        else:
            raise
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

def create_template(name: str, description: str, content_structure: str, icon: str = None) -> int:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        'INSERT INTO note_templates (name, description, content_structure, icon) VALUES (?, ?, ?, ?)',
        (name, description, content_structure, icon)
    )
    template_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return template_id

def get_templates() -> List[Dict[str, Any]]:
                                 
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM note_templates ORDER BY name')
    templates = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return templates

def get_template(template_id: int) -> Optional[Dict[str, Any]]:
                                        
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM note_templates WHERE id = ?', (template_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def update_template(template_id: int, name: str = None, description: str = None,
                   content_structure: str = None, icon: str = None) -> bool:
                            
    conn = get_connection()
    cursor = conn.cursor()

    updates = []
    params = []

    if name is not None:
        updates.append('name = ?')
        params.append(name)
    if description is not None:
        updates.append('description = ?')
        params.append(description)
    if content_structure is not None:
        updates.append('content_structure = ?')
        params.append(content_structure)
    if icon is not None:
        updates.append('icon = ?')
        params.append(icon)

    if not updates:
        return False

    params.append(template_id)
    query = f'UPDATE note_templates SET {", ".join(updates)} WHERE id = ?'
    cursor.execute(query, params)
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def delete_template(template_id: int) -> bool:
                            
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM note_templates WHERE id = ?', (template_id,))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def create_note_version(note_id: int, content: str, title: str, change_summary: str = None) -> int:
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        'SELECT COALESCE(MAX(version_number), 0) + 1 FROM note_versions WHERE note_id = ?',
        (note_id,)
    )
    version_number = cursor.fetchone()[0]

    cursor.execute(
        'INSERT INTO note_versions (note_id, content, title, version_number, change_summary) VALUES (?, ?, ?, ?, ?)',
        (note_id, content, title, version_number, change_summary)
    )
    version_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return version_id

def get_note_versions(note_id: int, limit: int = 20) -> List[Dict[str, Any]]:
                                         
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT * FROM note_versions
        WHERE note_id = ?
        ORDER BY version_number DESC
        LIMIT ?
    ''', (note_id, limit))
    versions = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return versions

def get_note_version(version_id: int) -> Optional[Dict[str, Any]]:
                                       
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM note_versions WHERE id = ?', (version_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def revert_to_version(note_id: int, version_id: int) -> bool:
                                              
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute('SELECT content, title FROM note_versions WHERE id = ? AND note_id = ?',
                  (version_id, note_id))
    row = cursor.fetchone()
    if not row:
        conn.close()
        return False

    cursor.execute('''
        UPDATE notes SET content = ?, title = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
    ''', (row['content'], row['title'], note_id))

    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def delete_old_versions(note_id: int, keep_count: int = 20) -> int:
                                                                 
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        DELETE FROM note_versions
        WHERE note_id = ? AND id NOT IN (
            SELECT id FROM note_versions
            WHERE note_id = ?
            ORDER BY version_number DESC
            LIMIT ?
        )
    ''', (note_id, note_id, keep_count))
    deleted = cursor.rowcount
    conn.commit()
    conn.close()
    return deleted

def create_note_session(note_id: int) -> int:
                                                 
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute('DELETE FROM note_sessions WHERE note_id = ?', (note_id,))

    cursor.execute(
        'INSERT INTO note_sessions (note_id) VALUES (?)',
        (note_id,)
    )
    session_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return session_id

def mark_session_formatted(note_id: int) -> bool:
                                                                      
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        UPDATE note_sessions SET ai_formatted_during_session = 1
        WHERE note_id = ?
    ''', (note_id,))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def get_active_session(note_id: int) -> Optional[Dict[str, Any]]:
                                            
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT * FROM note_sessions WHERE note_id = ?
        ORDER BY session_started DESC LIMIT 1
    ''', (note_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def clear_session(note_id: int) -> bool:
                                           
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM note_sessions WHERE note_id = ?', (note_id,))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def create_smart_note(title: str, content: str, note_type: str = 'smart_note',
                     source: str = 'text', template_id: int = None,
                     folder_id: int = None, language: str = None) -> int:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        'INSERT INTO notes (title, content, folder_id, language, note_type, source, template_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
        (title, content, folder_id, language, note_type, source, template_id)
    )
    note_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return note_id

def update_note_formatting_status(note_id: int, ai_formatted: bool) -> bool:
                                                    
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        UPDATE notes SET ai_formatted = ?, last_formatted_at = CURRENT_TIMESTAMP
        WHERE id = ?
    ''', (1 if ai_formatted else 0, note_id))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def get_smart_notes(note_type: str = None, source: str = None,
                   folder_id: int = None) -> List[Dict[str, Any]]:
                                                  
    conn = get_connection()
    cursor = conn.cursor()

    query = 'SELECT * FROM notes WHERE 1=1'
    params = []

    if note_type:
        query += ' AND note_type = ?'
        params.append(note_type)
    if source:
        query += ' AND source = ?'
        params.append(source)
    if folder_id is not None:
        query += ' AND folder_id = ?'
        params.append(folder_id)

    query += ' ORDER BY updated_at DESC'

    cursor.execute(query, params)
    notes = [dict(row) for row in cursor.fetchall()]
    conn.close()

    for note in notes:
        note['tags'] = get_note_tags(note['id'])

    return notes

def get_recent_smart_notes(limit: int = 10) -> List[Dict[str, Any]]:
                                                    
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT * FROM notes
        WHERE note_type = 'smart_note'
        ORDER BY updated_at DESC
        LIMIT ?
    ''', (limit,))
    notes = [dict(row) for row in cursor.fetchall()]
    conn.close()

    for note in notes:
        note['tags'] = get_note_tags(note['id'])

    return notes

def get_hub_tasks(filter_type: str = 'all', user_id: str = None) -> List[Dict[str, Any]]:
    """Get hub tasks, optionally filtered by user_id"""
    conn = get_connection()
    cursor = conn.cursor()

    user_filter = 'AND user_id = ?' if user_id else 'AND (user_id IS NULL OR user_id = "")'
    user_param = (user_id,) if user_id else ()

    if filter_type == 'today':
        today = datetime.now().strftime('%Y-%m-%d')
        cursor.execute(f'''
            SELECT * FROM hub_tasks
            WHERE due_date = ? AND completed = 0 {user_filter}
            ORDER BY due_time ASC, priority DESC, created_at DESC
        ''', (today,) + user_param)
    elif filter_type == 'upcoming':
        today = datetime.now().strftime('%Y-%m-%d')
        cursor.execute(f'''
            SELECT * FROM hub_tasks
            WHERE due_date > ? AND completed = 0 {user_filter}
            ORDER BY due_date ASC, due_time ASC, priority DESC
        ''', (today,) + user_param)
    elif filter_type == 'overdue':
        today = datetime.now().strftime('%Y-%m-%d')
        cursor.execute(f'''
            SELECT * FROM hub_tasks
            WHERE due_date < ? AND completed = 0 {user_filter}
            ORDER BY due_date ASC, priority DESC
        ''', (today,) + user_param)
    elif filter_type == 'completed':
        cursor.execute(f'''
            SELECT * FROM hub_tasks
            WHERE completed = 1 {user_filter}
            ORDER BY completed_at DESC
        ''', user_param)
    else:
        cursor.execute(f'''
            SELECT * FROM hub_tasks
            WHERE 1=1 {user_filter}
            ORDER BY completed ASC, due_date ASC, due_time ASC, priority DESC, created_at DESC
        ''', user_param)

    tasks = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return tasks

def get_hub_task(task_id: int) -> Optional[Dict[str, Any]]:
                                        
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM hub_tasks WHERE id = ?', (task_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def create_hub_task(title: str, description: str = None, due_date: str = None,
                    due_time: str = None, priority: str = 'medium', category: str = None,
                    user_id: str = None, repeat_type: str = 'none', repeat_days: str = None,
                    repeat_end_date: str = None, parent_task_id: int = None) -> int:
    """Create a hub task with optional user_id and repeat settings"""
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO hub_tasks (title, description, due_date, due_time, priority, category, user_id,
                              repeat_type, repeat_days, repeat_end_date, parent_task_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (title, description, due_date, due_time, priority, category, user_id,
          repeat_type, repeat_days, repeat_end_date, parent_task_id))
    task_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return task_id

def update_hub_task(task_id: int, title: str = None, description: str = None,
                    due_date: str = None, due_time: str = None, priority: str = None,
                    category: str = None, repeat_type: str = None, repeat_days: str = None,
                    repeat_end_date: str = None) -> bool:
    """Update a hub task"""
    conn = get_connection()
    cursor = conn.cursor()

    updates = []
    params = []

    if title is not None:
        updates.append('title = ?')
        params.append(title)
    if description is not None:
        updates.append('description = ?')
        params.append(description)
    if due_date is not None:
        updates.append('due_date = ?')
        params.append(due_date)
    if due_time is not None:
        updates.append('due_time = ?')
        params.append(due_time)
    if priority is not None:
        updates.append('priority = ?')
        params.append(priority)
    if category is not None:
        updates.append('category = ?')
        params.append(category)
    if repeat_type is not None:
        updates.append('repeat_type = ?')
        params.append(repeat_type)
    if repeat_days is not None:
        updates.append('repeat_days = ?')
        params.append(repeat_days)
    if repeat_end_date is not None:
        updates.append('repeat_end_date = ?')
        params.append(repeat_end_date if repeat_end_date != '' else None)

    if not updates:
        conn.close()
        return False

    updates.append('updated_at = CURRENT_TIMESTAMP')
    params.append(task_id)

    cursor.execute(f'''
        UPDATE hub_tasks SET {', '.join(updates)} WHERE id = ?
    ''', params)
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def toggle_hub_task(task_id: int) -> dict:
    """Toggle task completion. Returns dict with success status and next_task_id if created."""
    from datetime import timedelta
    import json

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute('SELECT * FROM hub_tasks WHERE id = ?', (task_id,))
    row = cursor.fetchone()
    if not row:
        conn.close()
        return {'success': False}

    task = dict(row)
    new_status = 0 if task['completed'] else 1
    completed_at = datetime.now().isoformat() if new_status else None

    cursor.execute('''
        UPDATE hub_tasks
        SET completed = ?, completed_at = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
    ''', (new_status, completed_at, task_id))

    next_task_id = None

    # If completing a repeating task, create the next occurrence
    if new_status == 1 and task.get('repeat_type') and task['repeat_type'] != 'none':
        next_due_date = calculate_next_due_date(
            task.get('due_date'),
            task['repeat_type'],
            task.get('repeat_days')
        )

        # Check if next date is within end date (if set)
        should_create = True
        if task.get('repeat_end_date') and next_due_date:
            if next_due_date > task['repeat_end_date']:
                should_create = False

        if should_create and next_due_date:
            cursor.execute('''
                INSERT INTO hub_tasks (title, description, due_date, due_time, priority, category, user_id,
                                      repeat_type, repeat_days, repeat_end_date, parent_task_id)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (task['title'], task.get('description'), next_due_date, task.get('due_time'),
                  task.get('priority', 'medium'), task.get('category'), task.get('user_id'),
                  task['repeat_type'], task.get('repeat_days'), task.get('repeat_end_date'),
                  task.get('parent_task_id') or task_id))
            next_task_id = cursor.lastrowid

    conn.commit()
    conn.close()
    return {'success': True, 'next_task_id': next_task_id}


def calculate_next_due_date(current_due: str, repeat_type: str, repeat_days: str = None) -> str:
    """Calculate the next due date based on repeat settings."""
    from datetime import timedelta
    import json

    if not current_due:
        # No due date, use today
        current_date = datetime.now().date()
    else:
        current_date = datetime.strptime(current_due[:10], '%Y-%m-%d').date()

    if repeat_type == 'daily':
        next_date = current_date + timedelta(days=1)
    elif repeat_type == 'weekly':
        next_date = current_date + timedelta(weeks=1)
    elif repeat_type == 'monthly':
        # Add one month
        month = current_date.month + 1
        year = current_date.year
        if month > 12:
            month = 1
            year += 1
        day = min(current_date.day, 28)  # Avoid day overflow issues
        next_date = current_date.replace(year=year, month=month, day=day)
    elif repeat_type == 'yearly':
        next_date = current_date.replace(year=current_date.year + 1)
    elif repeat_type == 'custom' and repeat_days:
        # repeat_days is a JSON array of weekday numbers (0=Sunday, 1=Monday, etc.)
        try:
            days = json.loads(repeat_days) if isinstance(repeat_days, str) else repeat_days
            if days:
                # Find the next day that matches
                for i in range(1, 8):  # Check next 7 days
                    check_date = current_date + timedelta(days=i)
                    # Python weekday: 0=Monday, 6=Sunday
                    # JavaScript weekday: 0=Sunday, 6=Saturday
                    js_weekday = (check_date.weekday() + 1) % 7
                    if js_weekday in days:
                        next_date = check_date
                        break
                else:
                    next_date = current_date + timedelta(weeks=1)
            else:
                next_date = current_date + timedelta(weeks=1)
        except (json.JSONDecodeError, TypeError):
            next_date = current_date + timedelta(weeks=1)
    else:
        return None

    return next_date.isoformat()

def delete_hub_task(task_id: int) -> bool:
                            
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM hub_tasks WHERE id = ?', (task_id,))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def get_hub_projects(status: str = None, user_id: str = None) -> List[Dict[str, Any]]:
    """Get hub projects, optionally filtered by user_id"""
    conn = get_connection()
    cursor = conn.cursor()

    user_filter = 'AND user_id = ?' if user_id else 'AND (user_id IS NULL OR user_id = "")'
    user_param = (user_id,) if user_id else ()

    if status:
        cursor.execute(f'''
            SELECT * FROM hub_projects WHERE status = ? {user_filter}
            ORDER BY deadline ASC, created_at DESC
        ''', (status,) + user_param)
    else:
        cursor.execute(f'''
            SELECT * FROM hub_projects
            WHERE 1=1 {user_filter}
            ORDER BY status ASC, deadline ASC, created_at DESC
        ''', user_param)

    projects = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return projects

def get_hub_project(project_id: int) -> Optional[Dict[str, Any]]:
                                           
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM hub_projects WHERE id = ?', (project_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def create_hub_project(name: str, goal: str = None, status: str = 'active',
                       deadline: str = None, next_step: str = None, notes: str = None,
                       progress: int = 0, user_id: str = None) -> int:
    """Create a hub project with optional user_id"""
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO hub_projects (name, goal, status, deadline, next_step, notes, progress, user_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', (name, goal, status, deadline, next_step, notes, progress, user_id))
    project_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return project_id

def update_hub_project(project_id: int, name: str = None, goal: str = None,
                       status: str = None, deadline: str = None, next_step: str = None,
                       notes: str = None, progress: int = None) -> bool:
                                         
    conn = get_connection()
    cursor = conn.cursor()

    updates = []
    params = []

    if name is not None:
        updates.append('name = ?')
        params.append(name)
    if goal is not None:
        updates.append('goal = ?')
        params.append(goal)
    if status is not None:
        updates.append('status = ?')
        params.append(status)
    if deadline is not None:
        updates.append('deadline = ?')
        params.append(deadline)
    if next_step is not None:
        updates.append('next_step = ?')
        params.append(next_step)
    if notes is not None:
        updates.append('notes = ?')
        params.append(notes)
    if progress is not None:
        updates.append('progress = ?')
        params.append(progress)

    if not updates:
        conn.close()
        return False

    updates.append('updated_at = CURRENT_TIMESTAMP')
    params.append(project_id)

    cursor.execute(f'''
        UPDATE hub_projects SET {', '.join(updates)} WHERE id = ?
    ''', params)
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def delete_hub_project(project_id: int) -> bool:
                               
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM hub_projects WHERE id = ?', (project_id,))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def get_hub_knowledge(topic: str = None, search: str = None, user_id: str = None) -> List[Dict[str, Any]]:
    """Get hub knowledge entries, optionally filtered by user_id"""
    conn = get_connection()
    cursor = conn.cursor()

    user_filter = 'AND user_id = ?' if user_id else 'AND (user_id IS NULL OR user_id = "")'
    user_param = (user_id,) if user_id else ()

    if search:
        search_term = f'%{search}%'
        cursor.execute(f'''
            SELECT * FROM hub_knowledge
            WHERE (title LIKE ? OR content LIKE ? OR tags LIKE ?) {user_filter}
            ORDER BY updated_at DESC
        ''', (search_term, search_term, search_term) + user_param)
    elif topic and topic != 'all':
        cursor.execute(f'''
            SELECT * FROM hub_knowledge WHERE topic = ? {user_filter}
            ORDER BY updated_at DESC
        ''', (topic,) + user_param)
    else:
        cursor.execute(f'''
            SELECT * FROM hub_knowledge
            WHERE 1=1 {user_filter}
            ORDER BY updated_at DESC
        ''', user_param)

    entries = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return entries

def get_hub_knowledge_entry(entry_id: int) -> Optional[Dict[str, Any]]:
                                               
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM hub_knowledge WHERE id = ?', (entry_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def create_hub_knowledge(title: str, topic: str = 'general', content: str = None,
                         tags: str = None, user_id: str = None) -> int:
    """Create a hub knowledge entry with optional user_id"""
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO hub_knowledge (title, topic, content, tags, user_id)
        VALUES (?, ?, ?, ?, ?)
    ''', (title, topic, content, tags, user_id))
    entry_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return entry_id

def update_hub_knowledge(entry_id: int, title: str = None, topic: str = None,
                         content: str = None, tags: str = None) -> bool:
                                             
    conn = get_connection()
    cursor = conn.cursor()

    updates = []
    params = []

    if title is not None:
        updates.append('title = ?')
        params.append(title)
    if topic is not None:
        updates.append('topic = ?')
        params.append(topic)
    if content is not None:
        updates.append('content = ?')
        params.append(content)
    if tags is not None:
        updates.append('tags = ?')
        params.append(tags)

    if not updates:
        conn.close()
        return False

    updates.append('updated_at = CURRENT_TIMESTAMP')
    params.append(entry_id)

    cursor.execute(f'''
        UPDATE hub_knowledge SET {', '.join(updates)} WHERE id = ?
    ''', params)
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def delete_hub_knowledge(entry_id: int) -> bool:
                                   
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM hub_knowledge WHERE id = ?', (entry_id,))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def get_hub_reviews(review_type: str = None, limit: int = 50) -> List[Dict[str, Any]]:
                                                   
    conn = get_connection()
    cursor = conn.cursor()

    if review_type:
        cursor.execute('''
            SELECT * FROM hub_reviews WHERE type = ?
            ORDER BY date DESC LIMIT ?
        ''', (review_type, limit))
    else:
        cursor.execute('''
            SELECT * FROM hub_reviews
            ORDER BY date DESC LIMIT ?
        ''', (limit,))

    reviews = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return reviews

def get_hub_review(review_id: int) -> Optional[Dict[str, Any]]:
                                      
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM hub_reviews WHERE id = ?', (review_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def get_hub_review_by_date(date: str, review_type: str = 'daily') -> Optional[Dict[str, Any]]:
                                        
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM hub_reviews WHERE date = ? AND type = ?', (date, review_type))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def create_hub_review(review_type: str, date: str, data: str = None, energy: int = None) -> int:
                              
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO hub_reviews (type, date, data, energy)
        VALUES (?, ?, ?, ?)
    ''', (review_type, date, data, energy))
    review_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return review_id

def update_hub_review(review_id: int, data: str = None, energy: int = None) -> bool:
                                    
    conn = get_connection()
    cursor = conn.cursor()

    updates = []
    params = []

    if data is not None:
        updates.append('data = ?')
        params.append(data)
    if energy is not None:
        updates.append('energy = ?')
        params.append(energy)

    if not updates:
        conn.close()
        return False

    updates.append('updated_at = CURRENT_TIMESTAMP')
    params.append(review_id)

    cursor.execute(f'''
        UPDATE hub_reviews SET {', '.join(updates)} WHERE id = ?
    ''', params)
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def delete_hub_review(review_id: int) -> bool:
                          
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM hub_reviews WHERE id = ?', (review_id,))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def get_hub_training_sessions(session_type: str = None, limit: int = 50) -> List[Dict[str, Any]]:
                                                             
    conn = get_connection()
    cursor = conn.cursor()

    if session_type:
        cursor.execute('''
            SELECT * FROM hub_training_sessions WHERE type = ?
            ORDER BY date DESC LIMIT ?
        ''', (session_type, limit))
    else:
        cursor.execute('''
            SELECT * FROM hub_training_sessions
            ORDER BY date DESC LIMIT ?
        ''', (limit,))

    sessions = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return sessions

def get_hub_training_session(session_id: int) -> Optional[Dict[str, Any]]:
                                                
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM hub_training_sessions WHERE id = ?', (session_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def create_hub_training_session(session_type: str, date: str, duration: int = None,
                                 notes: str = None, calories: int = None,
                                 exercises: str = None) -> int:
                                        
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO hub_training_sessions (type, date, duration, notes, calories, exercises)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (session_type, date, duration, notes, calories, exercises))
    session_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return session_id

def update_hub_training_session(session_id: int, session_type: str = None, date: str = None,
                                 duration: int = None, notes: str = None, calories: int = None,
                                 exercises: str = None) -> bool:
                                              
    conn = get_connection()
    cursor = conn.cursor()

    updates = []
    params = []

    if session_type is not None:
        updates.append('type = ?')
        params.append(session_type)
    if date is not None:
        updates.append('date = ?')
        params.append(date)
    if duration is not None:
        updates.append('duration = ?')
        params.append(duration)
    if notes is not None:
        updates.append('notes = ?')
        params.append(notes)
    if calories is not None:
        updates.append('calories = ?')
        params.append(calories)
    if exercises is not None:
        updates.append('exercises = ?')
        params.append(exercises)

    if not updates:
        conn.close()
        return False

    params.append(session_id)

    cursor.execute(f'''
        UPDATE hub_training_sessions SET {', '.join(updates)} WHERE id = ?
    ''', params)
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def delete_hub_training_session(session_id: int) -> bool:
                                    
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM hub_training_sessions WHERE id = ?', (session_id,))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def get_hub_training_health(limit: int = 30) -> List[Dict[str, Any]]:
                          
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT * FROM hub_training_health
        ORDER BY date DESC LIMIT ?
    ''', (limit,))
    logs = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return logs

def get_hub_training_health_by_date(date: str) -> Optional[Dict[str, Any]]:
                                             
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM hub_training_health WHERE date = ?', (date,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def create_hub_training_health(date: str, sleep: float = None, energy: int = None,
                                stress: int = None, recovery: int = None,
                                weight: float = None, notes: str = None) -> int:
                                        
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO hub_training_health (date, sleep, energy, stress, recovery, weight, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', (date, sleep, energy, stress, recovery, weight, notes))
    log_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return log_id

def update_hub_training_health(log_id: int, sleep: float = None, energy: int = None,
                                stress: int = None, recovery: int = None,
                                weight: float = None, notes: str = None) -> bool:
                                        
    conn = get_connection()
    cursor = conn.cursor()

    updates = []
    params = []

    if sleep is not None:
        updates.append('sleep = ?')
        params.append(sleep)
    if energy is not None:
        updates.append('energy = ?')
        params.append(energy)
    if stress is not None:
        updates.append('stress = ?')
        params.append(stress)
    if recovery is not None:
        updates.append('recovery = ?')
        params.append(recovery)
    if weight is not None:
        updates.append('weight = ?')
        params.append(weight)
    if notes is not None:
        updates.append('notes = ?')
        params.append(notes)

    if not updates:
        conn.close()
        return False

    params.append(log_id)

    cursor.execute(f'''
        UPDATE hub_training_health SET {', '.join(updates)} WHERE id = ?
    ''', params)
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def get_hub_training_goals(completed: bool = None) -> List[Dict[str, Any]]:
                                                                
    conn = get_connection()
    cursor = conn.cursor()

    if completed is not None:
        cursor.execute('''
            SELECT * FROM hub_training_goals WHERE completed = ?
            ORDER BY deadline ASC, created_at DESC
        ''', (1 if completed else 0,))
    else:
        cursor.execute('''
            SELECT * FROM hub_training_goals
            ORDER BY completed ASC, deadline ASC, created_at DESC
        ''')

    goals = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return goals

def get_hub_training_goal(goal_id: int) -> Optional[Dict[str, Any]]:
                                             
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM hub_training_goals WHERE id = ?', (goal_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def create_hub_training_goal(title: str, target: float = None, current: float = 0,
                              unit: str = None, deadline: str = None) -> int:
                                     
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO hub_training_goals (title, target, current, unit, deadline)
        VALUES (?, ?, ?, ?, ?)
    ''', (title, target, current, unit, deadline))
    goal_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return goal_id

def update_hub_training_goal(goal_id: int, title: str = None, target: float = None,
                              current: float = None, unit: str = None, deadline: str = None,
                              completed: bool = None) -> bool:
                                           
    conn = get_connection()
    cursor = conn.cursor()

    updates = []
    params = []

    if title is not None:
        updates.append('title = ?')
        params.append(title)
    if target is not None:
        updates.append('target = ?')
        params.append(target)
    if current is not None:
        updates.append('current = ?')
        params.append(current)
    if unit is not None:
        updates.append('unit = ?')
        params.append(unit)
    if deadline is not None:
        updates.append('deadline = ?')
        params.append(deadline)
    if completed is not None:
        updates.append('completed = ?')
        params.append(1 if completed else 0)

    if not updates:
        conn.close()
        return False

    updates.append('updated_at = CURRENT_TIMESTAMP')
    params.append(goal_id)

    cursor.execute(f'''
        UPDATE hub_training_goals SET {', '.join(updates)} WHERE id = ?
    ''', params)
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def delete_hub_training_goal(goal_id: int) -> bool:
                                 
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM hub_training_goals WHERE id = ?', (goal_id,))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def get_timetable_settings(user_id: str = None) -> Optional[Dict[str, Any]]:
    """Get timetable settings, optionally filtered by user_id"""
    conn = get_connection()
    cursor = conn.cursor()
    if user_id:
        cursor.execute('SELECT * FROM hub_timetable_settings WHERE user_id = ? ORDER BY id DESC LIMIT 1', (user_id,))
    else:
        cursor.execute('SELECT * FROM hub_timetable_settings WHERE (user_id IS NULL OR user_id = "") ORDER BY id DESC LIMIT 1')
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def save_timetable_settings(has_ab_weeks: bool = True, block_count: int = 4,
                            reference_date: str = None, setup_completed: bool = False,
                            user_id: str = None) -> int:
    """Save timetable settings with optional user_id"""
    conn = get_connection()
    cursor = conn.cursor()

    if user_id:
        cursor.execute('SELECT id FROM hub_timetable_settings WHERE user_id = ? LIMIT 1', (user_id,))
    else:
        cursor.execute('SELECT id FROM hub_timetable_settings WHERE (user_id IS NULL OR user_id = "") LIMIT 1')
    existing = cursor.fetchone()

    if existing:
        cursor.execute('''
            UPDATE hub_timetable_settings
            SET has_ab_weeks = ?, block_count = ?, reference_date = ?,
                setup_completed = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ''', (1 if has_ab_weeks else 0, block_count, reference_date,
              1 if setup_completed else 0, existing['id']))
        settings_id = existing['id']
    else:
        cursor.execute('''
            INSERT INTO hub_timetable_settings (has_ab_weeks, block_count, reference_date, setup_completed, user_id)
            VALUES (?, ?, ?, ?, ?)
        ''', (1 if has_ab_weeks else 0, block_count, reference_date, 1 if setup_completed else 0, user_id))
        settings_id = cursor.lastrowid

    conn.commit()
    conn.close()
    return settings_id

def get_timetable_entries(day: int = None, week: str = None, user_id: str = None) -> List[Dict[str, Any]]:
    """Get timetable entries, optionally filtered by user_id"""
    conn = get_connection()
    cursor = conn.cursor()

    query = 'SELECT * FROM hub_timetable_entries WHERE 1=1'
    params = []

    if user_id:
        query += ' AND user_id = ?'
        params.append(user_id)
    else:
        query += ' AND (user_id IS NULL OR user_id = "")'

    if day is not None:
        query += ' AND day = ?'
        params.append(day)

    if week is not None:
        query += ' AND (week = ? OR week = "both")'
        params.append(week)

    query += ' ORDER BY day, block'
    cursor.execute(query, params)
    entries = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return entries

def get_timetable_entry(entry_id: int) -> Optional[Dict[str, Any]]:
                                       
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM hub_timetable_entries WHERE id = ?', (entry_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def create_timetable_entry(day: int, block: int, subject: str, week: str = 'both',
                           subject_type: str = 'GK', room: str = None,
                           teacher: str = None, color: str = None, user_id: str = None) -> int:
    """Create timetable entry with optional user_id"""
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO hub_timetable_entries (day, block, week, subject, subject_type, room, teacher, color, user_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (day, block, week, subject, subject_type, room, teacher, color, user_id))
    entry_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return entry_id

def update_timetable_entry(entry_id: int, day: int = None, block: int = None,
                           subject: str = None, week: str = None, subject_type: str = None,
                           room: str = None, teacher: str = None, color: str = None) -> bool:
                                   
    conn = get_connection()
    cursor = conn.cursor()

    updates = []
    params = []

    if day is not None:
        updates.append('day = ?')
        params.append(day)
    if block is not None:
        updates.append('block = ?')
        params.append(block)
    if subject is not None:
        updates.append('subject = ?')
        params.append(subject)
    if week is not None:
        updates.append('week = ?')
        params.append(week)
    if subject_type is not None:
        updates.append('subject_type = ?')
        params.append(subject_type)
    if room is not None:
        updates.append('room = ?')
        params.append(room)
    if teacher is not None:
        updates.append('teacher = ?')
        params.append(teacher)
    if color is not None:
        updates.append('color = ?')
        params.append(color)

    if not updates:
        conn.close()
        return False

    updates.append('updated_at = CURRENT_TIMESTAMP')
    params.append(entry_id)

    cursor.execute(f'''
        UPDATE hub_timetable_entries SET {', '.join(updates)} WHERE id = ?
    ''', params)
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def delete_timetable_entry(entry_id: int) -> bool:
                                   
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM hub_timetable_entries WHERE id = ?', (entry_id,))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def clear_timetable(user_id: str = None) -> int:
    """Clear timetable entries, optionally filtered by user_id"""
    conn = get_connection()
    cursor = conn.cursor()
    if user_id:
        cursor.execute('DELETE FROM hub_timetable_entries WHERE user_id = ?', (user_id,))
    else:
        cursor.execute('DELETE FROM hub_timetable_entries WHERE (user_id IS NULL OR user_id = "")')
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected

def import_timetable_template(entries: List[Dict[str, Any]], user_id: str = None) -> int:
    """Import timetable template entries with optional user_id"""
    conn = get_connection()
    cursor = conn.cursor()

    count = 0
    for entry in entries:
        cursor.execute('''
            INSERT INTO hub_timetable_entries (day, block, week, subject, subject_type, room, teacher, color, user_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            entry.get('day'),
            entry.get('block'),
            entry.get('week', 'both'),
            entry.get('subject'),
            entry.get('subject_type', 'GK'),
            entry.get('room'),
            entry.get('teacher'),
            entry.get('color'),
            user_id
        ))
        count += 1

    conn.commit()
    conn.close()
    return count

# Training Schedule Functions

def get_training_schedule_settings(user_id: str = None) -> Optional[Dict[str, Any]]:
    """Get training schedule settings, optionally filtered by user_id"""
    conn = get_connection()
    cursor = conn.cursor()
    if user_id:
        cursor.execute('SELECT * FROM hub_training_schedule_settings WHERE user_id = ? ORDER BY id DESC LIMIT 1', (user_id,))
    else:
        cursor.execute('SELECT * FROM hub_training_schedule_settings WHERE (user_id IS NULL OR user_id = "") ORDER BY id DESC LIMIT 1')
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def save_training_schedule_settings(schedule_mode: str = 'regular',
                                    auto_detect_holiday: bool = True,
                                    setup_completed: bool = False,
                                    user_id: str = None) -> int:
    """Save training schedule settings with optional user_id"""
    conn = get_connection()
    cursor = conn.cursor()

    if user_id:
        cursor.execute('SELECT id FROM hub_training_schedule_settings WHERE user_id = ? LIMIT 1', (user_id,))
    else:
        cursor.execute('SELECT id FROM hub_training_schedule_settings WHERE (user_id IS NULL OR user_id = "") LIMIT 1')
    existing = cursor.fetchone()

    if existing:
        cursor.execute('''
            UPDATE hub_training_schedule_settings
            SET schedule_mode = ?, auto_detect_holiday = ?,
                setup_completed = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ''', (schedule_mode, 1 if auto_detect_holiday else 0,
              1 if setup_completed else 0, existing['id']))
        settings_id = existing['id']
    else:
        cursor.execute('''
            INSERT INTO hub_training_schedule_settings (schedule_mode, auto_detect_holiday, setup_completed, user_id)
            VALUES (?, ?, ?, ?)
        ''', (schedule_mode, 1 if auto_detect_holiday else 0, 1 if setup_completed else 0, user_id))
        settings_id = cursor.lastrowid

    conn.commit()
    conn.close()
    return settings_id

def get_training_schedule_entries(day: int = None, schedule_type: str = None, user_id: str = None) -> List[Dict[str, Any]]:
    """Get training schedule entries, optionally filtered by user_id"""
    conn = get_connection()
    cursor = conn.cursor()

    query = 'SELECT * FROM hub_training_schedule_entries WHERE 1=1'
    params = []

    if user_id:
        query += ' AND user_id = ?'
        params.append(user_id)
    else:
        query += ' AND (user_id IS NULL OR user_id = "")'

    if day is not None:
        query += ' AND day = ?'
        params.append(day)

    if schedule_type is not None:
        query += ' AND schedule_type = ?'
        params.append(schedule_type)

    query += ' ORDER BY day'
    cursor.execute(query, params)
    entries = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return entries

def get_training_schedule_entry(entry_id: int) -> Optional[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM hub_training_schedule_entries WHERE id = ?', (entry_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def create_training_schedule_entry(day: int, training_type: str, title: str,
                                   schedule_type: str = 'regular', time: str = None,
                                   duration: int = None, location: str = None,
                                   muscle_groups: str = None, notes: str = None,
                                   icon: str = None, color: str = None, user_id: str = None) -> int:
    """Create training schedule entry with optional user_id"""
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO hub_training_schedule_entries
        (day, schedule_type, training_type, title, time, duration, location, muscle_groups, notes, icon, color, user_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (day, schedule_type, training_type, title, time, duration, location, muscle_groups, notes, icon, color, user_id))
    entry_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return entry_id

def update_training_schedule_entry(entry_id: int, day: int = None, schedule_type: str = None,
                                   training_type: str = None, title: str = None,
                                   time: str = None, duration: int = None,
                                   location: str = None, muscle_groups: str = None,
                                   notes: str = None, icon: str = None, color: str = None) -> bool:
    conn = get_connection()
    cursor = conn.cursor()

    updates = []
    params = []

    if day is not None:
        updates.append('day = ?')
        params.append(day)
    if schedule_type is not None:
        updates.append('schedule_type = ?')
        params.append(schedule_type)
    if training_type is not None:
        updates.append('training_type = ?')
        params.append(training_type)
    if title is not None:
        updates.append('title = ?')
        params.append(title)
    if time is not None:
        updates.append('time = ?')
        params.append(time)
    if duration is not None:
        updates.append('duration = ?')
        params.append(duration)
    if location is not None:
        updates.append('location = ?')
        params.append(location)
    if muscle_groups is not None:
        updates.append('muscle_groups = ?')
        params.append(muscle_groups)
    if notes is not None:
        updates.append('notes = ?')
        params.append(notes)
    if icon is not None:
        updates.append('icon = ?')
        params.append(icon)
    if color is not None:
        updates.append('color = ?')
        params.append(color)

    if not updates:
        conn.close()
        return False

    updates.append('updated_at = CURRENT_TIMESTAMP')
    params.append(entry_id)

    cursor.execute(f'''
        UPDATE hub_training_schedule_entries SET {', '.join(updates)} WHERE id = ?
    ''', params)
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def delete_training_schedule_entry(entry_id: int) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM hub_training_schedule_entries WHERE id = ?', (entry_id,))
    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected > 0

def clear_training_schedule(schedule_type: str = None, user_id: str = None) -> int:
    """Clear training schedule entries, optionally filtered by user_id"""
    conn = get_connection()
    cursor = conn.cursor()

    if user_id:
        if schedule_type:
            cursor.execute('DELETE FROM hub_training_schedule_entries WHERE schedule_type = ? AND user_id = ?', (schedule_type, user_id))
        else:
            cursor.execute('DELETE FROM hub_training_schedule_entries WHERE user_id = ?', (user_id,))
    else:
        if schedule_type:
            cursor.execute('DELETE FROM hub_training_schedule_entries WHERE schedule_type = ? AND (user_id IS NULL OR user_id = "")', (schedule_type,))
        else:
            cursor.execute('DELETE FROM hub_training_schedule_entries WHERE (user_id IS NULL OR user_id = "")')

    affected = cursor.rowcount
    conn.commit()
    conn.close()
    return affected

def import_training_schedule_template(entries: List[Dict[str, Any]], user_id: str = None) -> int:
    """Import training schedule template entries with optional user_id"""
    conn = get_connection()
    cursor = conn.cursor()

    count = 0
    for entry in entries:
        cursor.execute('''
            INSERT INTO hub_training_schedule_entries
            (day, schedule_type, training_type, title, time, duration, location, muscle_groups, notes, icon, color, user_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            entry.get('day'),
            entry.get('schedule_type', 'regular'),
            entry.get('training_type'),
            entry.get('title'),
            entry.get('time'),
            entry.get('duration'),
            entry.get('location'),
            entry.get('muscle_groups'),
            entry.get('notes'),
            entry.get('icon'),
            entry.get('color'),
            user_id
        ))
        count += 1

    conn.commit()
    conn.close()
    return count

init_db()
