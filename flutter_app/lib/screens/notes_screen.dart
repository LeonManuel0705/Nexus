import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../theme.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _textController = TextEditingController();
  Timer? _autoSaveTimer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<NotesProvider>().loadNotes();
      _initializeTextController();
    });
  }

  void _initializeTextController() {
    if (_isInitialized) return;
    final provider = context.read<NotesProvider>();
    final activeNote = provider.activeNote;
    if (activeNote != null) {
      _textController.text = activeNote.content;
    }
    _isInitialized = true;
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    final provider = context.read<NotesProvider>();
    provider.markUnsavedChanges();

    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 1), () {
      if (provider.activeNoteId != null) {
        provider.updateNoteContent(provider.activeNoteId!, text);
      }
    });
  }

  void _createNewNote() async {
    final provider = context.read<NotesProvider>();
    await provider.createNote();
    _textController.clear();
  }

  void _switchNote(String noteId) {
    final provider = context.read<NotesProvider>();

    if (provider.activeNoteId != null && provider.hasUnsavedChanges) {
      provider.updateNoteContent(provider.activeNoteId!, _textController.text);
    }

    provider.setActiveNote(noteId);
    final note = provider.notes.firstWhere((n) => n.id == noteId);
    _textController.text = note.content;
  }

  void _deleteCurrentNote() {
    final provider = context.read<NotesProvider>();
    if (provider.activeNoteId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NexusTheme.darkCard,
        title: const Text('Notiz löschen?'),
        content: const Text('Diese Notiz wird dauerhaft gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteNote(provider.activeNoteId!);
              _textController.text = provider.activeNote?.content ?? '';
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NexusTheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Schnelle Notizen'),
        backgroundColor: NexusTheme.darkSurface,
        actions: [
          Consumer<NotesProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  if (provider.hasUnsavedChanges)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: Colors.orange,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: provider.activeNoteId != null
                        ? _deleteCurrentNote
                        : null,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [

              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: NexusTheme.darkSurface,
                  border: Border(
                    bottom: BorderSide(color: NexusTheme.darkBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: provider.notes.isEmpty
                          ? const Center(
                              child: Text(
                                'Keine Notizen',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              itemCount: provider.notes.length,
                              itemBuilder: (context, index) {
                                final note = provider.notes[index];
                                final isActive = note.id == provider.activeNoteId;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _NoteTab(
                                    title: note.preview.isEmpty
                                        ? 'Notiz ${index + 1}'
                                        : note.preview,
                                    isActive: isActive,
                                    onTap: () => _switchNote(note.id),
                                  ),
                                );
                              },
                            ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: NexusTheme.darkBorder),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _createNewNote,
                        tooltip: 'Neue Notiz',
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: provider.notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.note_add_outlined,
                              size: 64,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erstelle eine neue Notiz',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _createNewNote,
                              icon: const Icon(Icons.add),
                              label: const Text('Neue Notiz'),
                            ),
                          ],
                        ),
                      )
                    : TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Schreibe etwas...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(20),
                        ),
                        onChanged: _onTextChanged,
                      ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: NexusTheme.darkSurface,
                  border: Border(
                    top: BorderSide(color: NexusTheme.darkBorder),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Icon(
                        Icons.text_fields,
                        size: 16,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${provider.activeNote?.wordCount ?? 0} Wörter',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${provider.totalNotes} Notiz${provider.totalNotes != 1 ? 'en' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NoteTab extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _NoteTab({
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive
              ? NexusTheme.primary.withOpacity(0.2)
              : NexusTheme.darkCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? NexusTheme.primary : NexusTheme.darkBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title.length > 15 ? '${title.substring(0, 15)}...' : title,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? NexusTheme.primary : Colors.white70,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
