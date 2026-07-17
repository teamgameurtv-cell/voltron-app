import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette et thème global de l'application Voltron.
/// Identité : cyberpunk / premium / futuriste, dark mode uniquement.
class VoltronColors {
  static const Color electricBlue = Color(0xFF1E7BFF);
  static const Color electricBlueGlow = Color(0xFF3FA0FF);
  static const Color electricYellow = Color(0xFFFFD400);
  static const Color deepBlack = Color(0xFF0A0A0F);
  static const Color surfaceBlack = Color(0xFF14141C);
  static const Color cardBlack = Color(0xFF1B1B26);
  static const Color white = Color(0xFFFFFFFF);
  static const Color greyText = Color(0xFF8E8E9A);
  static const Color success = Color(0xFF3DDC97);
  static const Color warning = Color(0xFFFFB020);

  static const LinearGradient blueGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricBlue, Color(0xFF0D3E8C)],
  );
}

class VoltronRadii {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 26;
  static const double pill = 100;
}

class VoltronTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: VoltronColors.white,
      displayColor: VoltronColors.white,
    );

    return base.copyWith(
      scaffoldBackgroundColor: VoltronColors.deepBlack,
      primaryColor: VoltronColors.electricBlue,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: VoltronColors.electricBlue,
        secondary: VoltronColors.electricYellow,
        surface: VoltronColors.surfaceBlack,
        error: const Color(0xFFFF5C5C),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VoltronColors.electricYellow,
          foregroundColor: VoltronColors.deepBlack,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VoltronRadii.pill),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VoltronColors.white,
          side: const BorderSide(color: Colors.white24),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VoltronRadii.pill),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: VoltronColors.cardBlack,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VoltronRadii.md),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: VoltronColors.surfaceBlack,
        selectedItemColor: VoltronColors.electricYellow,
        unselectedItemColor: VoltronColors.greyText,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VoltronColors.cardBlack,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VoltronRadii.md),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
