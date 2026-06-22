import 'package:flutter/material.dart';

/// Centralized pink & pastel color palette for the whole app.
class AppColors {
  AppColors._();

  static const Color primaryPink = Color(0xFFFF6B9D);
  static const Color deepPink = Color(0xFFE8527A);
  static const Color softPink = Color(0xFFFFC2D6);
  static const Color blushPink = Color(0xFFFFE4ED);
  static const Color lavender = Color(0xFFE8C8F0);
  static const Color pastelPeach = Color(0xFFFFD9C7);
  static const Color creamWhite = Color(0xFFFFF8FA);
  static const Color deepPlum = Color(0xFF6B3654);
  static const Color textDark = Color(0xFF4A2940);
  static const Color textMuted = Color(0xFF9C7488);
  static const Color heartRed = Color(0xFFFF4D6D);
  static const Color gold = Color(0xFFFFD700);

  static const List<Color> backgroundGradient = [
    Color(0xFFFFE4ED),
    Color(0xFFFFC2D6),
    Color(0xFFE8C8F0),
  ];

  static const List<Color> ringingGradient = [
    Color(0xFF6B3654),
    Color(0xFFB4548A),
    Color(0xFFFF6B9D),
  ];

  static const List<Color> cardGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFFFF0F5),
  ];
}
