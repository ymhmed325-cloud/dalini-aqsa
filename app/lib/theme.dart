import 'package:flutter/material.dart';

Color aa(Color c, double o) => c.withAlpha((o * 255).round());

class AQ {
  static const Color ink = Color(0xFF082F2C);
  static const Color teal = Color(0xFF0F766E);
  static const Color tealLight = Color(0xFF14A697);
  static const Color gold = Color(0xFFC9A24B);
  static const Color goldSoft = Color(0xFFF1E2B8);
  static const Color sand = Color(0xFFF7F2E7);
  static const Color text = Color(0xFF12302D);
  static const Color muted = Color(0xFF6B7C79);
  static const Color danger = Color(0xFFC0392B);
  static const Color ok = Color(0xFF2E9E5B);

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(seedColor: teal, brightness: Brightness.light)
        .copyWith(primary: teal, secondary: gold);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: sand,
    );
  }
}
