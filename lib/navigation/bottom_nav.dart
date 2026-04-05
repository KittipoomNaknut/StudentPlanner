import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../features/assignment/assignment_screen.dart';
import '../features/grade/grade_screen.dart';
import '../features/note/note_screen.dart';
import '../core/theme/app_theme.dart';

class BottomNav extends StatefulWidget {
  final void Function(ThemeMode) onThemeChanged;
  const BottomNav({super.key, required this.onThemeChanged});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  static const _navItems = [
    _NavItem(icon: Icons.home_rounded,           outline: Icons.home_outlined,            label: 'Home'),
    _NavItem(icon: Icons.calendar_month_rounded, outline: Icons.calendar_month_outlined,  label: 'Schedule'),
    _NavItem(icon: Icons.check_circle_rounded,   outline: Icons.check_circle_outline,     label: 'Tasks'),
    _NavItem(icon: Icons.bar_chart_rounded,      outline: Icons.bar_chart_outlined,       label: 'Grades'),
    _NavItem(icon: Icons.sticky_note_2_rounded,  outline: Icons.sticky_note_2_outlined,   label: 'Notes'),
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onThemeChanged: widget.onThemeChanged),
      const ScheduleScreen(),
      const AssignmentScreen(),
      const GradeScreen(),
      const NoteScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: _screens),
      extendBody: true,
      bottomNavigationBar: _buildFloatingNav(isDark),
    );
  }

  Widget _buildFloatingNav(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppTheme.navShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_navItems.length, (i) {
          final item = _navItems[i];
          final selected = _currentIndex == i;
          return _buildNavBtn(
            icon: selected ? item.icon : item.outline,
            label: item.label,
            selected: selected,
            onTap: () => setState(() => _currentIndex = i),
          );
        }),
      ),
    );
  }

  Widget _buildNavBtn({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 16 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: selected ? Colors.white : Colors.grey.shade400),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              child: selected
                  ? Row(
                      children: [
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData outline;
  final String label;
  const _NavItem({required this.icon, required this.outline, required this.label});
}
