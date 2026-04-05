import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/database_helper.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(ThemeMode) onThemeChanged;
  final void Function(String) onLanguageChanged;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode           = ThemeMode.system;
  bool      _notificationsEnabled = true;
  bool      _isExporting          = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      final saved = prefs.getString('theme_mode') ?? 'system';
      _themeMode = saved == 'light'
          ? ThemeMode.light
          : saved == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system;
    });
  }

  Future<void> _setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      mode == ThemeMode.light ? 'light' : mode == ThemeMode.dark ? 'dark' : 'system',
    );
    setState(() => _themeMode = mode);
    widget.onThemeChanged(mode);
  }

  Future<void> _setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
    widget.onLanguageChanged(lang);
  }

  Future<void> _exportData() async {
    final s = AppStrings.of(context);
    setState(() => _isExporting = true);
    try {
      final data = await DatabaseHelper.instance.exportAll();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      await Clipboard.setData(ClipboardData(text: json));
      setState(() => _isExporting = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(gradient: AppTheme.successGradient, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text(s.exportedTitle,
                  style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(s.exportedBody,
                  style: GoogleFonts.nunito(color: Colors.grey.shade500, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(s.gotIt,
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        );
      }
    } catch (_) {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(s.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _sectionLabel(s.sectionAppearance),
          _buildThemeCard(s),
          const SizedBox(height: 20),
          _sectionLabel(s.sectionLanguage),
          _buildLanguageCard(s),
          const SizedBox(height: 20),
          _sectionLabel(s.sectionNotif),
          _card(child: SwitchListTile(
            title: Text(s.deadlineReminders,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15)),
            subtitle: Text(s.deadlineRemindersDesc,
                style: GoogleFonts.nunito(color: Colors.grey.shade500, fontSize: 13)),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.notifications_rounded, color: AppTheme.warning, size: 20),
            ),
            value: _notificationsEnabled,
            onChanged: (v) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications_enabled', v);
              setState(() => _notificationsEnabled = v);
            },
            activeColor: AppTheme.primary,
          )),
          const SizedBox(height: 20),
          _sectionLabel(s.sectionData),
          _card(child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: _isExporting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_rounded, color: AppTheme.teal, size: 20),
            ),
            title: Text(s.exportData,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15)),
            subtitle: Text(s.exportDataDesc,
                style: GoogleFonts.nunito(color: Colors.grey.shade500, fontSize: 13)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: _isExporting ? null : _exportData,
          )),
          const SizedBox(height: 20),
          _sectionLabel(s.sectionAbout),
          _card(child: Column(children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
              ),
              title: Text('Student Planner',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15)),
              subtitle: Text(s.appVersion,
                  style: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 13)),
            ),
            const Divider(height: 1, indent: 70),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.flutter_dash_rounded, color: Colors.blue, size: 20),
              ),
              title: Text(s.builtWith,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15)),
              subtitle: Text(s.builtWithDesc,
                  style: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 13)),
            ),
          ])),
        ],
      ),
    );
  }

  Widget _buildThemeCard(AppStrings s) {
    return _card(
      child: Column(children: [
        _themeOption(ThemeMode.system, Icons.brightness_auto_rounded, s.themeSystem,   s.themeSystemDesc, s),
        const Divider(height: 1, indent: 70),
        _themeOption(ThemeMode.light,  Icons.light_mode_rounded,      s.themeLight,    s.themeLightDesc,  s),
        const Divider(height: 1, indent: 70),
        _themeOption(ThemeMode.dark,   Icons.dark_mode_rounded,       s.themeDark,     s.themeDarkDesc,   s),
      ]),
    );
  }

  Widget _buildLanguageCard(AppStrings s) {
    return _card(
      child: Column(children: [
        _languageOption('th', '🇹🇭', s.langThai,    s.langThaiDesc,    s),
        const Divider(height: 1, indent: 70),
        _languageOption('en', '🇬🇧', s.langEnglish, s.langEnglishDesc, s),
      ]),
    );
  }

  Widget _themeOption(
      ThemeMode mode, IconData icon, String title, String sub, AppStrings s) {
    final selected = _themeMode == mode;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: selected ? AppTheme.primary : Colors.grey.shade400, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15)),
      subtitle: Text(sub,
          style: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 13)),
      trailing: selected
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
            )
          : null,
      onTap: () => _setTheme(mode),
    );
  }

  Widget _languageOption(
      String lang, String flag, String title, String sub, AppStrings s) {
    final selected = s.lang == lang;
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(flag, style: const TextStyle(fontSize: 20)),
        ),
      ),
      title: Text(title,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15)),
      subtitle: Text(sub,
          style: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 13)),
      trailing: selected
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
            )
          : null,
      onTap: () => _setLanguage(lang),
    );
  }

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary.withValues(alpha: 0.6),
            letterSpacing: 1.5,
          ),
        ),
      );
}
