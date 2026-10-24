import 'package:flutter/material.dart';

/// QRLink design system color palette — space-tech dark theme
class AppColors {
  AppColors._();

  // ── Core Background ──
  static const Color black = Color(0xFF050810);
  static const Color slate = Color(0xFF0D1525);
  static const Color panel = Color(0xFF111827);

  // ── Accent Colors ──
  static const Color cyan = Color(0xFF00F5FF);
  static const Color violet = Color(0xFF7B2FFF);
  static const Color amber = Color(0xFFFF6B35);

  // ── Text Colors ──
  static const Color white = Color(0xFFE8F4FD);
  static const Color muted = Color(0xFF4A5568);

  // ── Status Colors ──
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // ── Derived Colors ──
  static const Color border = Color(0x1F00F5FF); // cyan at 12%
  static const Color cardBg = Color(0xFF0F1729);
  static const Color surfaceDim = Color(0xFF0A0E1A);

  // ── Gradients ──
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [cyan, Color(0xFF0088CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetGradient = LinearGradient(
    colors: [violet, Color(0xFF5B1FCC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanVioletGradient = LinearGradient(
    colors: [cyan, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [black, slate, black],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Glow Shadows ──
  static List<BoxShadow> cyanGlow({double blur = 30, double opacity = 0.25}) => [
        BoxShadow(
          color: cyan.withOpacity(opacity),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> violetGlow({double blur = 30, double opacity = 0.25}) => [
        BoxShadow(
          color: violet.withOpacity(opacity),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ];
}
