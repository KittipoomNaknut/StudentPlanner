import 'package:flutter/material.dart';

class AppTheme {
  // ── COLORS ──────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0);
  static const Color secondary = Color(0xFFFF6F00);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57F17);
  static const Color danger = Color(0xFFC62828);
  static const Color background = Color(0xFFF5F5F5);

  // Priority colors
  static const Color priorityHigh = Color(0xFFC62828);
  static const Color priorityMedium = Color(0xFFF57F17);
  static const Color priorityLow = Color(0xFF2E7D32);

  // ── LIGHT THEME ─────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondary,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  // ── DARK THEME ──────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      // ปรับสีพื้นผิวในโหมดมืดให้ดูสบายตาขึ้น
      surface: const Color(0xFF1E1E1E),
    ),
    // กำหนดสีพื้นหลังโหมดมืดให้ชัดเจน (เกือบดำ)
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E), // สี Card ในโหมดมืด
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    // ปรับสีปุ่มในโหมดมืดให้ไม่ออกมาเป็นสีน้ำเงินสว่างเกินไป
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  // ── HELPERS ─────────────────────────────────────────
  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      // ป้องกันตัวพิมพ์ใหญ่-เล็ก
      case 'high':
        return priorityHigh;
      case 'low':
        return priorityLow;
      default:
        return priorityMedium;
    }
  }

  /// แปลง Hex String เป็น Color รองรับทั้ง #RRGGBB และ #AARRGGBB
  static Color fromHex(String hex) {
    String h = hex.replaceFirst('#', '');
    if (h.length == 6) {
      h = 'FF$h'; // ถ้าไม่มี Alpha ให้เติม FF (ทึบแสง 100%)
    }
    try {
      return Color(int.parse(h, radix: 16));
    } catch (e) {
      return Colors.grey; // ถ้า Error ให้คืนค่าสีเทาแทนแอปแครช
    }
  }
}
