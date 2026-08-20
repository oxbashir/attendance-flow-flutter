import 'package:flutter/material.dart';

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.textHigh,
    required this.textMid,
    required this.textLow,
    required this.border,
    required this.shadow,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color accent;
  final Color accentSoft;
  final Color success;
  final Color textHigh;
  final Color textMid;
  final Color textLow;
  final Color border;
  final Color shadow;

  static const light = AppPalette(
    bg: Color(0xFFF8F7F4),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0EEE9),
    accent: Color(0xFF4F7EFF),
    accentSoft: Color(0xFFEBF0FF),
    success: Color(0xFF34C47C),
    textHigh: Color(0xFF1A1A2E),
    textMid: Color(0xFF6B6B80),
    textLow: Color(0xFFB0AEBF),
    border: Color(0xFFE8E6E1),
    shadow: Color(0x0D000000),
  );

  static const dark = AppPalette(
    bg: Color(0xFF0C0E14),
    surface: Color(0xFF151821),
    surfaceAlt: Color(0xFF1C2030),
    accent: Color(0xFF6B93FF),
    accentSoft: Color(0xFF1A2340),
    success: Color(0xFF3DDB8F),
    textHigh: Color(0xFFF4F3EE),
    textMid: Color(0xFF9A9CB0),
    textLow: Color(0xFF5C5F73),
    border: Color(0xFF2A2E3C),
    shadow: Color(0x59000000),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? light;
  }

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? accent,
    Color? accentSoft,
    Color? success,
    Color? textHigh,
    Color? textMid,
    Color? textLow,
    Color? border,
    Color? shadow,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      textHigh: textHigh ?? this.textHigh,
      textMid: textMid ?? this.textMid,
      textLow: textLow ?? this.textLow,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      textHigh: Color.lerp(textHigh, other.textHigh, t)!,
      textMid: Color.lerp(textMid, other.textMid, t)!,
      textLow: Color.lerp(textLow, other.textLow, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

class AppTheme {
  static ThemeData get light => _build(Brightness.light, AppPalette.light);
  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: brightness,
      ).copyWith(
        surface: palette.surface,
        primary: palette.accent,
      ),
      extensions: [palette],
    );
  }
}
