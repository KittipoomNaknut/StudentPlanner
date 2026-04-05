import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/models/assignment.dart';
import '../../core/models/attendance.dart';
import '../../core/models/schedule.dart';
import '../../core/models/subject.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../subject/subject_screen.dart';
import '../settings/settings_screen.dart';
import '../attendance/attendance_screen.dart';
import '../timer/pomodoro_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(ThemeMode) onThemeChanged;
  final void Function(String) onLanguageChanged;
  const DashboardScreen({
    super.key,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  List<Subject>    _subjects        = [];
  List<Assignment> _pendingTasks    = [];
  List<Schedule>   _todayClasses    = [];
  List<Schedule>   _upcomingExams   = [];
  Map<int, double> _attendanceRates = {};
  bool _isLoading = true;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;
    final results = await Future.wait([
      db.getSubjects(),
      db.getAssignments(status: 'pending'),
      db.getSchedules(type: 'class'),
      db.getSchedules(type: 'exam'),
      db.getAttendance(),
    ]);

    final subjects      = results[0] as List<Subject>;
    final pending       = results[1] as List<Assignment>;
    final classes       = results[2] as List<Schedule>;
    final exams         = results[3] as List<Schedule>;
    final allAttendance = results[4] as List<Attendance>;

    final todayIndex  = DateTime.now().weekday - 1;
    final todayClasses = classes.where((s) => s.dayOfWeek == todayIndex).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final now      = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    final upcoming = exams.where((e) {
      final d = DateTime.tryParse(e.date ?? '');
      return d != null && d.isAfter(now) && d.isBefore(nextWeek);
    }).toList();

    final rates = <int, double>{};
    for (final s in subjects) {
      final recs = allAttendance.where((a) => a.subjectId == s.id).toList();
      if (recs.isNotEmpty) {
        rates[s.id!] = recs.where((a) => a.isPresent || a.isLate).length / recs.length;
      }
    }

    setState(() {
      _subjects        = subjects;
      _pendingTasks    = pending;
      _todayClasses    = todayClasses;
      _upcomingExams   = upcoming;
      _attendanceRates = rates;
      _isLoading       = false;
    });
    _fadeCtrl
      ..reset()
      ..forward();
  }

  Subject? _getSubject(int id) {
    try { return _subjects.firstWhere((s) => s.id == id); }
    catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primary,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: CustomScrollView(
                  slivers: [
                    _buildHeroHeader(),
                    SliverToBoxAdapter(child: _buildBody()),
                  ],
                ),
              ),
            ),
    );
  }

  // ── HERO HEADER ─────────────────────────────────────────
  Widget _buildHeroHeader() {
    final s       = AppStrings.of(context);
    final hour    = DateTime.now().hour;
    final greeting = hour < 12 ? s.greetingMorning
                   : hour < 17 ? s.greetingAfternoon
                   : s.greetingEvening;
    final today   = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final overdue = _pendingTasks.where((a) => a.isOverdue).length;

    return SliverToBoxAdapter(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Wave gradient background
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: 230,
              decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -30, right: -20,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30, right: 60,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  // Text content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 120, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: GoogleFonts.nunito(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          today,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (overdue > 0) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  s.overdueAlert(overdue),
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons top-right
          Positioned(
            top: 48, right: 8,
            child: Row(
              children: [
                _iconBtn(Icons.refresh_rounded, _loadData),
                _iconBtn(Icons.settings_outlined, () async {
                  await Navigator.push(context, _slide(
                    SettingsScreen(
                      onThemeChanged: widget.onThemeChanged,
                      onLanguageChanged: widget.onLanguageChanged,
                    ),
                  ));
                  _loadData();
                }),
              ],
            ),
          ),

          // Floating stat cards overlapping the wave
          Positioned(
            bottom: -50,
            left: 16, right: 16,
            child: _buildStatCards(),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 22),
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildStatCards() {
    final s = AppStrings.of(context);
    final overdue = _pendingTasks.where((a) => a.isOverdue).length;
    return Row(
      children: [
        StatCard(
          label: s.statSubjects,
          value: '${_subjects.length}',
          icon: Icons.menu_book_rounded,
          color: AppTheme.primary,
          onTap: () async {
            await Navigator.push(context, _slide(const SubjectScreen()));
            _loadData();
          },
        ),
        const SizedBox(width: 10),
        StatCard(
          label: s.statPending,
          value: '${_pendingTasks.length}',
          icon: Icons.assignment_rounded,
          color: AppTheme.warning,
        ),
        const SizedBox(width: 10),
        StatCard(
          label: s.statOverdue,
          value: '$overdue',
          icon: Icons.warning_rounded,
          color: overdue > 0 ? AppTheme.danger : Colors.grey,
        ),
      ],
    );
  }

  // ── BODY ─────────────────────────────────────────────────
  Widget _buildBody() {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 66, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActions(),
          const SizedBox(height: 28),

          // Attendance warnings
          ..._buildAttendanceSection(),

          // Today's Classes
          if (_todayClasses.isNotEmpty) ...[
            SectionHeader(title: s.todayClasses, icon: Icons.class_rounded, color: AppTheme.teal),
            ..._todayClasses.map(_buildClassCard),
            const SizedBox(height: 24),
          ],

          // Pending Tasks
          SectionHeader(
            title: s.pendingTasksHeader(_pendingTasks.length),
            icon: Icons.task_alt_rounded,
            color: AppTheme.warning,
          ),
          if (_pendingTasks.isEmpty)
            _buildSuccessBanner(s.allTasksDone)
          else
            ..._pendingTasks.take(5).map(_buildTaskCard),
          if (_pendingTasks.length > 5)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: Text(
                  s.moreTasks(_pendingTasks.length - 5),
                  style: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
            ),

          // Upcoming Exams
          if (_upcomingExams.isNotEmpty) ...[
            const SizedBox(height: 24),
            SectionHeader(title: s.upcomingExams, icon: Icons.event_rounded, color: AppTheme.danger),
            ..._upcomingExams.map(_buildExamCard),
          ],
        ],
      ),
    );
  }

  // ── QUICK ACTIONS ────────────────────────────────────────
  Widget _buildQuickActions() {
    final s = AppStrings.of(context);
    return Row(
      children: [
        _buildActionTile(
          gradient: AppTheme.pinkGradient,
          icon: Icons.timer_rounded,
          label: s.actionPomodoro,
          onTap: () => Navigator.push(context, _slide(const PomodoroScreen())),
        ),
        const SizedBox(width: 10),
        _buildActionTile(
          gradient: AppTheme.tealGradient,
          icon: Icons.fact_check_rounded,
          label: s.actionAttendance,
          onTap: () async {
            await Navigator.push(context, _slide(AttendanceScreen(subjects: _subjects)));
            _loadData();
          },
        ),
        const SizedBox(width: 10),
        _buildActionTile(
          gradient: AppTheme.primaryGradient,
          icon: Icons.menu_book_rounded,
          label: s.actionSubjects,
          onTap: () async {
            await Navigator.push(context, _slide(const SubjectScreen()));
            _loadData();
          },
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required LinearGradient gradient,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 5),
              Text(
                label,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ATTENDANCE SECTION ────────────────────────────────────
  List<Widget> _buildAttendanceSection() {
    final str = AppStrings.of(context);
    final lowList = _subjects
        .where((s) => (_attendanceRates[s.id] ?? 1.0) < 0.75 && (_attendanceRates[s.id] ?? -1) >= 0)
        .toList();
    if (lowList.isEmpty) return [];

    return [
      SectionHeader(title: str.attendanceAlert, icon: Icons.warning_amber_rounded, color: AppTheme.danger),
      ...lowList.map((s) {
        final rate = _attendanceRates[s.id!] ?? 0.0;
        final pct  = (rate * 100).toStringAsFixed(0);
        final color = AppTheme.fromHex(s.color);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.danger.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 4, height: 36,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                    Text(str.attendancePct(pct),
                      style: GoogleFonts.nunito(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
            ],
          ),
        );
      }),
      const SizedBox(height: 24),
    ];
  }

  Widget _buildSuccessBanner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.success.withValues(alpha: 0.08), AppTheme.teal.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 22),
          const SizedBox(width: 10),
          Text(text, style: GoogleFonts.nunito(color: AppTheme.success, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── CLASS CARD ───────────────────────────────────────────
  Widget _buildClassCard(Schedule s) {
    final subject = _getSubject(s.subjectId);
    final color   = subject != null ? AppTheme.fromHex(subject.color) : AppTheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(6, 4, 16, 4),
        leading: Container(
          width: 5, height: 44,
          margin: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.5)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        title: Text(subject?.name ?? 'Unknown', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${s.startTime} – ${s.endTime}${s.room.isNotEmpty ? '  ·  ${s.room}' : ''}',
          style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey.shade500),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.class_rounded, color: color, size: 18),
        ),
      ),
    );
  }

  // ── TASK CARD ─────────────────────────────────────────────
  Widget _buildTaskCard(Assignment a) {
    final subject      = _getSubject(a.subjectId);
    final subjectColor = subject != null ? AppTheme.fromHex(subject.color) : Colors.grey;
    final pColor       = AppTheme.priorityColor(a.priority);
    final deadlineDate = DateTime.tryParse(a.deadline);
    final deadlineStr  = deadlineDate != null ? DateFormat('d MMM').format(deadlineDate) : a.deadline;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Priority dot
            Container(
              width: 5, height: 46,
              decoration: BoxDecoration(
                gradient: AppTheme.priorityGradient(a.priority),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title,
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SubjectDot(color: subjectColor, radius: 4),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(subject?.name ?? '',
                          style: GoogleFonts.nunito(fontSize: 13, color: subjectColor, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriorityBadge(priority: a.priority),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 13,
                      color: a.isOverdue ? AppTheme.danger : Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text(deadlineStr,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: a.isOverdue ? AppTheme.danger : Colors.grey.shade400,
                        fontWeight: a.isOverdue ? FontWeight.w700 : FontWeight.w500,
                      )),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── EXAM CARD ─────────────────────────────────────────────
  Widget _buildExamCard(Schedule s) {
    final subject  = _getSubject(s.subjectId);
    final color    = subject != null ? AppTheme.fromHex(subject.color) : AppTheme.danger;
    final examDate = DateTime.tryParse(s.date ?? '');
    final daysLeft = examDate != null ? examDate.difference(DateTime.now()).inDays : 0;
    final isUrgent = daysLeft <= 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ListTile(
        leading: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.event_rounded, color: Colors.white, size: 22),
        ),
        title: Text(subject?.name ?? 'Unknown', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${s.date}  ·  ${s.startTime}${s.room.isNotEmpty ? '  ·  ${s.room}' : ''}',
          style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey.shade500),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (isUrgent ? AppTheme.danger : AppTheme.warning).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$daysLeft',
                style: GoogleFonts.nunito(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: isUrgent ? AppTheme.danger : AppTheme.warning,
                )),
              Text('days', style: GoogleFonts.nunito(fontSize: 13, color: Colors.grey.shade400)),
            ],
          ),
        ),
      ),
    );
  }

  PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
    pageBuilder: (_, a1, a2) => page,
    transitionsBuilder: (_, a1, a2, child) =>
      SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
        child: child,
      ),
  );
}
