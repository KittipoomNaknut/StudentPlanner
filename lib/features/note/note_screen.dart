import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/i18n/app_strings.dart';
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
  List<Note>    _notes    = [];
  List<Subject> _subjects = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int? _filterSubjectId;
  Timer? _debounce;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _loadData(); }

  @override
  void dispose() { _debounce?.cancel(); _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadData({String? search}) async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      DatabaseHelper.instance.getNotes(
        subjectId: _filterSubjectId,
        search: (search?.isEmpty ?? true) ? null : search,
      ),
      DatabaseHelper.instance.getSubjects(),
    ]);
    setState(() {
      _notes    = results[0] as List<Note>;
      _subjects = results[1] as List<Subject>;
      _isLoading = false;
    });
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = q);
      _loadData(search: q);
    });
  }

  Subject? _getSubject(int id) {
    try { return _subjects.firstWhere((s) => s.id == id); }
    catch (_) { return null; }
  }

  Future<void> _deleteNote(Note n) async {
    final str = AppStrings.of(context);
    final ok = await showConfirmDelete(context, title: str.deleteNote, content: '"${n.title}"?');
    if (ok) {
      await DatabaseHelper.instance.deleteNote(n.id!);
      _loadData(search: _searchQuery.isEmpty ? null : _searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(s.notes),
        actions: [
          PopupMenuButton<int?>(
            icon: Icon(Icons.filter_list_rounded,
              color: _filterSubjectId != null ? Colors.orange : Colors.white),
            tooltip: 'Filter by subject',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (id) {
              setState(() => _filterSubjectId = id);
              _loadData(search: _searchQuery.isEmpty ? null : _searchQuery);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: null,
                child: Text('All Subjects', style: GoogleFonts.nunito(fontWeight: FontWeight.w600))),
              ..._subjects.map((s) => PopupMenuItem(value: s.id,
                child: Row(children: [
                  CircleAvatar(backgroundColor: AppTheme.fromHex(s.color), radius: 6),
                  const SizedBox(width: 8),
                  Text(s.name, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                ]))),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: s.search,
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                        onPressed: () { _searchCtrl.clear(); _onSearch(''); })
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
              icon: Icons.sticky_note_2_rounded,
              title: s.noNotesYet,
              subtitle: _searchQuery.isNotEmpty ? 'Try a different search' : s.noNotesSubtitle,
            )
          : _buildGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => NoteDetailScreen(subjects: _subjects),
          ));
          _loadData(search: _searchQuery.isEmpty ? null : _searchQuery);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGrid() {
    return RefreshIndicator(
      onRefresh: () => _loadData(search: _searchQuery.isEmpty ? null : _searchQuery),
      color: AppTheme.primary,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.82,
        ),
        itemCount: _notes.length,
        itemBuilder: (_, i) {
          final n       = _notes[i];
          final subject = _getSubject(n.subjectId);
          return _NoteCard(
            note: n, subject: subject,
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => NoteDetailScreen(subjects: _subjects, note: n),
              ));
              _loadData(search: _searchQuery.isEmpty ? null : _searchQuery);
            },
            onDelete: () => _deleteNote(n),
          );
        },
      ),
    );
  }
}

// ── NOTE CARD ─────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final Note note; final Subject? subject;
  final VoidCallback onTap, onDelete;

  const _NoteCard({required this.note, required this.subject, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color   = subject != null ? AppTheme.fromHex(subject!.color) : AppTheme.primary;
    final bgColor = Color.lerp(color.withValues(alpha: 0.08), Colors.white, 0.5)!;
    final updated = DateTime.tryParse(note.updatedAt);
    final dateStr = updated != null ? DateFormat('d MMM').format(updated) : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient top bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade300),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        note.content,
                        style: GoogleFonts.nunito(color: Colors.grey.shade500, fontSize: 13, height: 1.5),
                        maxLines: 4, overflow: TextOverflow.fade,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            subject?.name ?? 'Unknown',
                            style: GoogleFonts.nunito(color: color, fontSize: 13, fontWeight: FontWeight.w700),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        Text(dateStr, style: GoogleFonts.nunito(color: Colors.grey.shade300, fontSize: 13)),
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
