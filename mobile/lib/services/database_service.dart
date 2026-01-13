import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/note.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'nexus.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {

    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (parent_id) REFERENCES folders(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        folder_id INTEGER,
        language TEXT,
        audio_duration REAL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        note_type TEXT DEFAULT 'transcription',
        source TEXT,
        template_id INTEGER,
        ai_formatted INTEGER DEFAULT 0,
        last_formatted_at TEXT,
        FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE hub_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        due_time TEXT,
        priority TEXT DEFAULT 'medium',
        category TEXT,
        completed INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        completed_at TEXT,
        repeat_type TEXT DEFAULT 'none',
        repeat_days TEXT,
        repeat_end_date TEXT,
        parent_task_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE note_tags (
        note_id INTEGER,
        tag_id INTEGER,
        PRIMARY KEY (note_id, tag_id),
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_notes_folder ON notes(folder_id)');
    await db.execute('CREATE INDEX idx_tasks_due ON hub_tasks(due_date)');
    await db.execute('CREATE INDEX idx_tasks_completed ON hub_tasks(completed)');
  }

  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('hub_tasks', task.toMap()..remove('id'));
  }

  Future<List<Task>> getTasks({bool? completed, String? category}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (completed != null) {
      whereClause = 'completed = ?';
      whereArgs.add(completed ? 1 : 0);
    }

    if (category != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category = ?';
      whereArgs.add(category);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'hub_tasks',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'due_date ASC, due_time ASC',
    );

    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<Task?> getTask(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'hub_tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'hub_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'hub_tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleTaskComplete(int id) async {
    final db = await database;
    final task = await getTask(id);
    if (task == null) return 0;

    final now = DateTime.now().toIso8601String();
    return await db.update(
      'hub_tasks',
      {
        'completed': task.completed ? 0 : 1,
        'completed_at': task.completed ? null : now,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap()..remove('id'));
  }

  Future<List<Note>> getNotes({int? folderId, String? searchQuery}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (folderId != null) {
      whereClause = 'folder_id = ?';
      whereArgs.add(folderId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(title LIKE ? OR content LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'updated_at DESC',
    );

    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<Note?> getNote(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertFolder(Folder folder) async {
    final db = await database;
    return await db.insert('folders', folder.toMap()..remove('id'));
  }

  Future<List<Folder>> getFolders({int? parentId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'folders',
      where: parentId == null ? 'parent_id IS NULL' : 'parent_id = ?',
      whereArgs: parentId == null ? null : [parentId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Folder.fromMap(maps[i]));
  }

  Future<int> deleteFolder(int id) async {
    final db = await database;
    return await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, int>> getTaskStats() async {
    final db = await database;

    final total = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM hub_tasks'));
    final completed = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM hub_tasks WHERE completed = 1'));
    final pending = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM hub_tasks WHERE completed = 0'));
    final overdue = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM hub_tasks WHERE completed = 0 AND due_date < date('now')"));

    return {
      'total': total ?? 0,
      'completed': completed ?? 0,
      'pending': pending ?? 0,
      'overdue': overdue ?? 0,
    };
  }

  Future<int> getNoteCount() async {
    final db = await database;
    return Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM notes')) ??
        0;
  }
}
