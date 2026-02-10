import 'package:flutter/material.dart';

enum BackgroundType { solidColor, gradientImage, videoFile, imageFile }

enum TextPosition { center, bottom }

enum TextAnimation { fade, slide, none }

enum DecorationPattern { none, hexagon, dots, islamic }

class FilterTheme {
  final String id;
  final String name;
  final BackgroundType backgroundType;
  final Color? backgroundColor;
  final Color? secondaryColor;
  final List<Color>? gradientColors;
  final List<String>? backgroundPaths;
  final String fontFamily;
  final double fontSize;
  final Color textColor;
  final Color strokeColor;
  final double strokeWidth;
  final TextPosition textPosition;
  final TextAnimation textAnimation;
  final double lineSpacing;
  final double? letterSpacing;
  final Color? highlightColor;
  final bool showSurahName;
  final bool showAyahNumber;
  final bool showReciterName;
  final DecorationPattern decorationPattern;
  final String? defaultBackgroundUrl;

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
    this.secondaryColor,
    this.gradientColors,
    this.backgroundPaths,
    this.lineSpacing = 12,
    this.letterSpacing,
    this.highlightColor,
    this.showSurahName = true,
    this.showAyahNumber = true,
    this.showReciterName = true,
    this.decorationPattern = DecorationPattern.none,
    this.defaultBackgroundUrl,
  });

  FilterTheme copyWith({
    String? id,
    String? name,
    BackgroundType? backgroundType,
    Color? backgroundColor,
    Color? secondaryColor,
    List<Color>? gradientColors,
    List<String>? backgroundPaths,
    String? fontFamily,
    double? fontSize,
    Color? textColor,
    Color? strokeColor,
    double? strokeWidth,
    TextPosition? textPosition,
    TextAnimation? textAnimation,
    double? lineSpacing,
    double? letterSpacing,
    Color? highlightColor,
    bool? showSurahName,
    bool? showAyahNumber,
    bool? showReciterName,
    DecorationPattern? decorationPattern,
    String? defaultBackgroundUrl,
  }) {
    return FilterTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      backgroundType: backgroundType ?? this.backgroundType,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      gradientColors: gradientColors ?? this.gradientColors,
      backgroundPaths: backgroundPaths ?? this.backgroundPaths,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      textPosition: textPosition ?? this.textPosition,
      textAnimation: textAnimation ?? this.textAnimation,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      highlightColor: highlightColor ?? this.highlightColor,
      showSurahName: showSurahName ?? this.showSurahName,
      showAyahNumber: showAyahNumber ?? this.showAyahNumber,
      showReciterName: showReciterName ?? this.showReciterName,
      decorationPattern: decorationPattern ?? this.decorationPattern,
      defaultBackgroundUrl: defaultBackgroundUrl ?? this.defaultBackgroundUrl,
    );
  }
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
      textAnimation: TextAnimation.slide,
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
    FilterTheme(
      id: 'mountain_serenity',
      name: 'جمال الجبال',
      backgroundType: BackgroundType.imageFile,
      fontFamily: 'Amiri',
      fontSize: 60,
      textColor: Color(0xFFF0F0F0),
      strokeColor: Color(0xFF1A3A5A),
      strokeWidth: 2.0,
      textPosition: TextPosition.center,
      textAnimation: TextAnimation.fade,
      lineSpacing: 16,
      defaultBackgroundUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&q=80&w=1080&h=1920',
    ),
    FilterTheme(
      id: 'forest_echo',
      name: 'سكينة الغابة',
      backgroundType: BackgroundType.imageFile,
      fontFamily: 'Amiri',
      fontSize: 58,
      textColor: Color(0xFFE8F5E9),
      strokeColor: Color(0xFF1B5E20),
      strokeWidth: 2.0,
      textPosition: TextPosition.bottom,
      textAnimation: TextAnimation.fade,
      lineSpacing: 14,
      defaultBackgroundUrl: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&q=80&w=1080&h=1920',
    ),
  ];
}
