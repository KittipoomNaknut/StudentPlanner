import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/note.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import 'note_detail_screen.dart';

class NoteScreen extends StatefulWidget {
  const NoteScreen({super.key});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  List<Note> _notes = [];
  List<Subject> _subjects = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _debounce;
  int? _filterSubjectId;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData({String? search}) async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      DatabaseHelper.instance.getNotes(
        subjectId: _filterSubjectId,
        search: search?.isEmpty == true ? null : search,
      ),
      DatabaseHelper.instance.getSubjects(),
    ]);
    setState(() {
      _notes = results[0] as List<Note>;
      _subjects = results[1] as List<Subject>;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = query);
      _loadData(search: query);
    });
  }

  Subject? _getSubject(int subjectId) {
    try {
      return _subjects.firstWhere((s) => s.id == subjectId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showConfirmDelete(
      context,
      title: 'Delete Note',
      content: 'Delete "${note.title}"?',
    );
    if (confirmed) {
      await DatabaseHelper.instance.deleteNote(note.id!);
      _loadData(search: _searchQuery.isEmpty ? null : _searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          if (_filterSubjectId != null)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              tooltip: 'Clear filter',
              onPressed: () {
                setState(() => _filterSubjectId = null);
                _loadData(search: _searchQuery.isEmpty ? null : _searchQuery);
              },
            ),
          PopupMenuButton<int?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by subject',
            onSelected: (id) {
              setState(() => _filterSubjectId = id);
              _loadData(search: _searchQuery.isEmpty ? null : _searchQuery);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All Subjects')),
              ..._subjects.map(
                (s) => PopupMenuItem(
                  value: s.id,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.fromHex(s.color),
                        radius: 6,
                      ),
                      const SizedBox(width: 8),
                      Text(s.name),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search notes…',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
          ? EmptyState(
              icon: Icons.note_outlined,
              title: _searchQuery.isNotEmpty ? 'No notes found' : 'No notes yet',
              subtitle: _searchQuery.isNotEmpty
                  ? 'Try a different search'
                  : 'Tap + to create a note',
            )
          : _buildNoteGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteDetailScreen(subjects: _subjects),
            ),
          );
          _loadData(search: _searchQuery.isEmpty ? null : _searchQuery);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteGrid() {
    return RefreshIndicator(
      onRefresh: () => _loadData(search: _searchQuery.isEmpty ? null : _searchQuery),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          final subject = _getSubject(note.subjectId);
          return _NoteCard(
            note: note,
            subject: subject,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NoteDetailScreen(
                    subjects: _subjects,
                    note: note,
                  ),
                ),
              );
              _loadData(search: _searchQuery.isEmpty ? null : _searchQuery);
            },
            onDelete: () => _deleteNote(note),
          );
        },
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final Subject? subject;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.subject,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = subject != null
        ? AppTheme.fromHex(subject!.color)
        : Colors.blueGrey;
    final updatedDate = DateTime.tryParse(note.updatedAt);
    final dateStr = updatedDate != null
        ? DateFormat('d MMM').format(updatedDate)
        : '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color header bar
            Container(
              height: 6,
              color: color,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(
                            Icons.more_vert,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        note.content,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SubjectDot(color: color, radius: 4),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            subject?.name ?? 'Unknown',
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
