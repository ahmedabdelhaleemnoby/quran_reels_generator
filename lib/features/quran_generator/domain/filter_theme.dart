import 'package:flutter/material.dart';

enum BackgroundType {
  solidColor,
  gradientImage,
  imageFile,
  videoFile,
}

enum TextPosition { center, bottom }

enum TextAnimation { none, fade, slideUp }

class FilterTheme {
  final String id;
  final String name;
  final BackgroundType backgroundType;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final String? backgroundPath;
  final String fontFamily;
  final double fontSize;
  final Color textColor;
  final Color strokeColor;
  final double strokeWidth;
  final TextPosition textPosition;
  final TextAnimation textAnimation;
  final double lineSpacing;

  const FilterTheme({
    required this.id,
    required this.name,
    required this.backgroundType,
    required this.fontFamily,
    required this.fontSize,
    required this.textColor,
    required this.strokeColor,
    required this.strokeWidth,
    required this.textPosition,
    required this.textAnimation,
    this.backgroundColor,
    this.gradientColors,
    this.backgroundPath,
    this.lineSpacing = 12,
  });
}

class FilterThemes {
  FilterThemes._();

  static const List<FilterTheme> all = [
    FilterTheme(
      id: 'calm_night',
      name: 'فلتر هادئ',
      backgroundType: BackgroundType.solidColor,
      backgroundColor: Color(0xFF0D1B2A),
      fontFamily: 'Amiri',
      fontSize: 58,
      textColor: Color(0xFFFFFFFF),
      strokeColor: Color(0xFF000000),
      strokeWidth: 2,
      textPosition: TextPosition.center,
      textAnimation: TextAnimation.fade,
      lineSpacing: 14,
    ),
    FilterTheme(
      id: 'warm_glow',
      name: 'فلتر مضيء',
      backgroundType: BackgroundType.gradientImage,
      gradientColors: [Color(0xFF1E3C72), Color(0xFFF6D365)],
      fontFamily: 'Amiri',
      fontSize: 56,
      textColor: Color(0xFFF4D06F),
      strokeColor: Color(0xFF1A1A1A),
      strokeWidth: 2.5,
      textPosition: TextPosition.bottom,
      textAnimation: TextAnimation.slideUp,
      lineSpacing: 12,
    ),
    FilterTheme(
      id: 'minimal_sand',
      name: 'فلتر Minimal',
      backgroundType: BackgroundType.solidColor,
      backgroundColor: Color(0xFFF3F1E9),
      fontFamily: 'Amiri',
      fontSize: 54,
      textColor: Color(0xFF1F1F1F),
      strokeColor: Color(0x00000000),
      strokeWidth: 0,
      textPosition: TextPosition.center,
      textAnimation: TextAnimation.none,
      lineSpacing: 10,
    ),
  ];
}
