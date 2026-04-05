import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── PALETTE ──────────────────────────────────────────────
  static const Color primary      = Color(0xFF6366F1); // Indigo
  static const Color primaryDark  = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color pink         = Color(0xFFF472B6); // Pink accent
  static const Color pinkDark     = Color(0xFFEC4899);
  static const Color success      = Color(0xFF10B981); // Emerald
  static const Color warning      = Color(0xFFF59E0B); // Amber
  static const Color danger       = Color(0xFFEF4444); // Red
  static const Color teal         = Color(0xFF06B6D4); // Cyan
  static const Color purple       = Color(0xFF8B5CF6); // Violet
  static const Color orange       = Color(0xFFF97316); // Orange

  // Backgrounds
  static const Color background     = Color(0xFFF5F3FF); // Indigo-50
  static const Color backgroundDark = Color(0xFF0F0E1A);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceDark    = Color(0xFF1C1B2E);

  // Priority
  static const Color priorityHigh   = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow    = Color(0xFF10B981);

  // ── GRADIENTS ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient pinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF14B8A6)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  );

  // ── SHADOWS ───────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get navShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.18),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];

  // ── LIGHT THEME ───────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: pink,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
    );
    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        titleLarge: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 18),
        titleMedium: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.nunito(fontSize: 15),
        bodyMedium: GoogleFonts.nunito(fontSize: 14),
        labelLarge: GoogleFonts.nunito(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shadowColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F3FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.nunito(color: Colors.grey.shade600),
        hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(space: 1, thickness: 1, color: Color(0xFFF0F0F8)),
      tabBarTheme: TabBarThemeData(
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w500),
      ),
    );
  }

  // ── DARK THEME ────────────────────────────────────────────
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primaryLight,
        secondary: pink,
        surface: surfaceDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
    );
    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF252440),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3D3B5C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3D3B5C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.nunito(color: Colors.white60),
        hintStyle: GoogleFonts.nunito(color: Colors.white38),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(space: 1, thickness: 1, color: Color(0xFF252440)),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────
  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':   return priorityHigh;
      case 'low':    return priorityLow;
      default:       return priorityMedium;
    }
  }

  static LinearGradient priorityGradient(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)]);
      case 'low':
        return successGradient;
      default:
        return warningGradient;
    }
  }

  static Color attendanceColor(String status) {
    switch (status) {
      case 'present': return success;
      case 'absent':  return danger;
      case 'late':    return warning;
      default:        return Colors.grey;
    }
  }

  static Color fromHex(String hex) {
    String h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    try {
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return primaryLight;
    }
  }

  static LinearGradient subjectGradient(String hex) {
    final base = fromHex(hex);
    final lighter = Color.fromARGB(
      255,
      (base.r * 255 + 60).clamp(0, 255).toInt(),
      (base.g * 255 + 60).clamp(0, 255).toInt(),
      (base.b * 255 + 80).clamp(0, 255).toInt(),
    );
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [base, lighter],
    );
  }
}

// ── WAVE CLIPPER ──────────────────────────────────────────────
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width * 0.25, size.height,
      size.width * 0.5, size.height - 25,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height - 50,
      size.width, size.height - 15,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> old) => false;
}
