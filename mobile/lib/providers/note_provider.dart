import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/database_service.dart';

class NoteProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Note> _notes = [];
  List<Folder> _folders = [];
  bool _isLoading = false;
  int? _currentFolderId;

  List<Note> get notes => _notes;
  List<Folder> get folders => _folders;
  bool get isLoading => _isLoading;
  int? get currentFolderId => _currentFolderId;

  Future<void> loadNotes({int? folderId, String? searchQuery}) async {
    _isLoading = true;
    _currentFolderId = folderId;
    notifyListeners();

    try {
      _notes = await _db.getNotes(folderId: folderId, searchQuery: searchQuery);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFolders({int? parentId}) async {
    _folders = await _db.getFolders(parentId: parentId);
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    final id = await _db.insertNote(note);
    _notes.insert(0, note.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateNote(Note note) async {
    await _db.updateNote(note);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
    }
    notifyListeners();
  }

  Future<void> deleteNote(int id) async {
    await _db.deleteNote(id);
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<void> addFolder(Folder folder) async {
    final id = await _db.insertFolder(folder);
    _folders.add(Folder(
      id: id,
      name: folder.name,
      parentId: folder.parentId,
      createdAt: folder.createdAt,
    ));
    notifyListeners();
  }

  Future<void> deleteFolder(int id) async {
    await _db.deleteFolder(id);
    _folders.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  Future<int> getNoteCount() async {
    return await _db.getNoteCount();
  }

  List<Note> searchNotes(String query) {
    if (query.isEmpty) return _notes;
    final lowerQuery = query.toLowerCase();
    return _notes.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
          note.content.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
