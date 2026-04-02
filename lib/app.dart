import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'navigation/bottom_nav.dart';

class StudentPlannerApp extends StatelessWidget {
  const StudentPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // ตามระบบ
      home: const BottomNav(),
    );
  }
}
