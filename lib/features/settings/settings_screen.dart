import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(ThemeMode) onThemeChanged;
  const SettingsScreen({super.key, required this.onThemeChanged});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  bool _isExporting = false;

  @override
  void initState() { super.initState(); _loadPrefs(); }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      final saved = prefs.getString('theme_mode') ?? 'system';
      _themeMode = saved == 'light' ? ThemeMode.light : saved == 'dark' ? ThemeMode.dark : ThemeMode.system;
    });
  }

  Future<void> _setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode == ThemeMode.light ? 'light' : mode == ThemeMode.dark ? 'dark' : 'system');
    setState(() => _themeMode = mode);
    widget.onThemeChanged(mode);
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final data   = await DatabaseHelper.instance.exportAll();
      final json   = const JsonEncoder.withIndent('  ').convert(data);
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
              Text('Data Exported!', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Your data has been copied to clipboard as JSON. Paste it into any text editor to save.',
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
                  child: Text('Got it', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _sectionLabel('Appearance'),
          _buildThemeCard(),
          const SizedBox(height: 20),
          _sectionLabel('Notifications'),
          _card(child: SwitchListTile(
            title: Text('Deadline Reminders', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            subtitle: Text('Get notified before assignment deadlines',
              style: GoogleFonts.nunito(color: Colors.grey.shade500, fontSize: 12)),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), shape: BoxShape.circle),
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
          _sectionLabel('Data'),
          _card(child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.teal.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: _isExporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_rounded, color: AppTheme.teal, size: 20),
            ),
            title: Text('Export Data', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            subtitle: Text('Copy all data as JSON to clipboard',
              style: GoogleFonts.nunito(color: Colors.grey.shade500, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: _isExporting ? null : _exportData,
          )),
          const SizedBox(height: 20),
          _sectionLabel('About'),
          _card(child: Column(children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
              ),
              title: Text('Student Planner', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              subtitle: Text('Version 2.0.0', style: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 12)),
            ),
            const Divider(height: 1, indent: 70),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.flutter_dash_rounded, color: Colors.blue, size: 20),
              ),
              title: Text('Built with Flutter', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              subtitle: Text('Material Design 3 + Nunito Font',
                style: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 12)),
            ),
          ])),
        ],
      ),
    );
  }

  Widget _buildThemeCard() {
    return _card(
      child: Column(
        children: [
          _themeOption(ThemeMode.system, Icons.brightness_auto_rounded, 'System default', 'Follow device theme'),
          const Divider(height: 1, indent: 70),
          _themeOption(ThemeMode.light,  Icons.light_mode_rounded,      'Light mode',     'Bright & clean'),
          const Divider(height: 1, indent: 70),
          _themeOption(ThemeMode.dark,   Icons.dark_mode_rounded,       'Dark mode',      'Easy on the eyes'),
        ],
      ),
    );
  }

  Widget _themeOption(ThemeMode mode, IconData icon, String title, String sub) {
    final selected = _themeMode == mode;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: selected ? AppTheme.primary : Colors.grey.shade400, size: 20),
      ),
      title: Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      subtitle: Text(sub, style: GoogleFonts.nunito(color: Colors.grey.shade400, fontSize: 12)),
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
        fontSize: 11, fontWeight: FontWeight.w800,
        color: AppTheme.primary.withValues(alpha: 0.6),
        letterSpacing: 1.5,
      ),
    ),
  );
}
