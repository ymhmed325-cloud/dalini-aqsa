// ألوان وهوية "دليني" - كحلي غامق وذهبي، هوية عراقية واضحة
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Color aa(Color c, double o) => c.withAlpha((o * 255).round());

class AQ {
  static const Color navy = Color(0xFF1B3A5C);
  static const Color gold = Color(0xFFF5B400);
  static const Color white = Color(0xFFFFFFFF);
  static const Color sand = Color(0xFFF5F7FA);

  static const Color ink = navy;
  static const Color teal = navy;
  static const Color tealLight = Color(0xFF2C557D);
  static const Color goldSoft = Color(0xFFFCE4A0);
  static const Color text = Color(0xFF1A2733);
  static const Color muted = Color(0xFF6B7C8A);
  static const Color danger = Color(0xFFC0392B);
  static const Color ok = Color(0xFF2E9E5B);

  static const Color svcEmergency = Color(0xFFE74C3C);
  static const Color svcCars = Color(0xFF2E7DD1);
  static const Color svcTransport = Color(0xFF3CB371);
  static const Color svcCleaning = Color(0xFF17A2B8);
  static const Color svcMaintenance = Color(0xFF808B96);
  static const Color svcAC = Color(0xFF5DADE2);
  static const Color svcPlumbing = Color(0xFF16A085);
  static const Color svcElectric = Color(0xFFF39C12);

  static ThemeData theme() {
    final base = GoogleFonts.cairoTextTheme();
    final scheme = ColorScheme.fromSeed(seedColor: navy, brightness: Brightness.light)
        .copyWith(primary: navy, secondary: gold);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: sand,
      fontFamily: GoogleFonts.cairo().fontFamily,
      textTheme: base.apply(bodyColor: text, displayColor: text),
    );
  }
}
