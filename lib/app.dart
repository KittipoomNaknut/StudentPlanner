import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'navigation/bottom_nav.dart';

class StudentPlannerApp extends StatefulWidget {
  const StudentPlannerApp({super.key});

  // Global key เพื่อเข้าถึง state จากภายนอก
  static final GlobalKey<_StudentPlannerAppState> navigatorKey =
      GlobalKey<_StudentPlannerAppState>();

  @override
  State<StudentPlannerApp> createState() => _StudentPlannerAppState();
}

class _StudentPlannerAppState extends State<StudentPlannerApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void changeTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: BottomNav(onThemeChanged: changeTheme),
    );
  }
}
