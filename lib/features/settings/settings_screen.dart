import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final key = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
        ? 'dark'
        : 'system';
    await prefs.setString('theme_mode', key);
    setState(() => _themeMode = mode);
    widget.onThemeChanged(mode);
  }

  Future<void> _toggleNotifications(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', val);
    setState(() => _notificationsEnabled = val);
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final data = await DatabaseHelper.instance.exportAll();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      await Clipboard.setData(ClipboardData(text: jsonStr));

      if (mounted) {
        setState(() => _isExporting = false);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.success),
                SizedBox(width: 10),
                Text('Data Exported'),
              ],
            ),
            content: const Text(
              'Your data has been copied to the clipboard as JSON.\n\n'
              'You can paste it into any text editor or document to save it.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // ── APPEARANCE ──────────────────────────────
          _buildSectionLabel('Appearance'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('System default'),
                  subtitle: const Text('Follow device theme'),
                  secondary: const Icon(Icons.brightness_auto_outlined),
                  value: ThemeMode.system,
                  groupValue: _themeMode,
                  onChanged: (v) => _setTheme(v!),
                  activeColor: AppTheme.primary,
                ),
                const Divider(height: 1, indent: 16),
                RadioListTile<ThemeMode>(
                  title: const Text('Light mode'),
                  secondary: const Icon(Icons.light_mode_outlined),
                  value: ThemeMode.light,
                  groupValue: _themeMode,
                  onChanged: (v) => _setTheme(v!),
                  activeColor: AppTheme.primary,
                ),
                const Divider(height: 1, indent: 16),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark mode'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: ThemeMode.dark,
                  groupValue: _themeMode,
                  onChanged: (v) => _setTheme(v!),
                  activeColor: AppTheme.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── NOTIFICATIONS ────────────────────────────
          _buildSectionLabel('Notifications'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              title: const Text('Deadline Reminders'),
              subtitle: const Text('Get notified before assignment deadlines'),
              secondary: const Icon(Icons.notifications_outlined),
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeThumbColor: AppTheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          // ── DATA ─────────────────────────────────────
          _buildSectionLabel('Data'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: _isExporting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_outlined),
              title: const Text('Export Data'),
              subtitle: const Text('Copy all data as JSON to clipboard'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _isExporting ? null : _exportData,
            ),
          ),

          const SizedBox(height: 16),

          // ── ABOUT ────────────────────────────────────
          _buildSectionLabel('About'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('Student Planner'),
                  subtitle: const Text('Version 2.0.0'),
                ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Built with Flutter'),
                  subtitle: const Text('Material Design 3'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
