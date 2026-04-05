import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/i18n/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'navigation/bottom_nav.dart';

class StudentPlannerApp extends StatefulWidget {
  const StudentPlannerApp({super.key});

  static final GlobalKey<_StudentPlannerAppState> navigatorKey =
      GlobalKey<_StudentPlannerAppState>();

  @override
  State<StudentPlannerApp> createState() => _StudentPlannerAppState();
}

class _StudentPlannerAppState extends State<StudentPlannerApp> {
  ThemeMode _themeMode = ThemeMode.system;
  String _lang = 'th'; // default Thai

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode') ?? 'system';
    final savedLang  = prefs.getString('app_lang') ?? 'th';
    setState(() {
      _themeMode = savedTheme == 'light'
          ? ThemeMode.light
          : savedTheme == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system;
      _lang = savedLang;
    });
  }

  void changeTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void changeLanguage(String lang) {
    setState(() => _lang = lang);
  }

  @override
  Widget build(BuildContext context) {
    return AppStrings(
      lang: _lang,
      child: MaterialApp(
        title: 'Student Planner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        home: BottomNav(
          onThemeChanged: changeTheme,
          onLanguageChanged: changeLanguage,
        ),
      ),
    );
  }
}
