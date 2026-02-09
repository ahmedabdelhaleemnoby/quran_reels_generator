import 'package:flutter/material.dart';

/// Enum representing available filter types
enum FilterType {
  blur,
  grayscale,
  sepia,
  brightness,
  contrast,
  saturation,
  fadeIn,
  fadeOut,
}

/// Model representing a single filter with its properties
class FilterModel {
  final FilterType type;
  final String name;
  final String nameAr;
  final IconData icon;
  final double minValue;
  final double maxValue;
  final double defaultValue;
  final String unit;

  const FilterModel({
    required this.type,
    required this.name,
    required this.nameAr,
    required this.icon,
    required this.minValue,
    required this.maxValue,
    required this.defaultValue,
    this.unit = '',
  });

  /// Get display name based on locale
  String getDisplayName(bool isArabic) {
    return isArabic ? nameAr : name;
  }
}

/// Available filters configuration
class Filters {
  Filters._();

  static const List<FilterModel> allFilters = [
    FilterModel(
      type: FilterType.blur,
      name: 'Blur',
      nameAr: 'ضبابية',
      icon: Icons.blur_on,
      minValue: 0,
      maxValue: 20,
      defaultValue: 0,
    ),
    FilterModel(
      type: FilterType.grayscale,
      name: 'Grayscale',
      nameAr: 'رمادي',
      icon: Icons.filter_b_and_w,
      minValue: 0,
      maxValue: 1,
      defaultValue: 0,
    ),
    FilterModel(
      type: FilterType.sepia,
      name: 'Sepia',
      nameAr: 'بني',
      icon: Icons.filter_vintage,
      minValue: 0,
      maxValue: 1,
      defaultValue: 0,
    ),
    FilterModel(
      type: FilterType.brightness,
      name: 'Brightness',
      nameAr: 'السطوع',
      icon: Icons.brightness_6,
      minValue: -1.0,
      maxValue: 1.0,
      defaultValue: 0,
    ),
    FilterModel(
      type: FilterType.contrast,
      name: 'Contrast',
      nameAr: 'التباين',
      icon: Icons.contrast,
      minValue: 0,
      maxValue: 2,
      defaultValue: 1,
    ),
    FilterModel(
      type: FilterType.saturation,
      name: 'Saturation',
      nameAr: 'التشبع',
      icon: Icons.palette,
      minValue: 0,
      maxValue: 3,
      defaultValue: 1,
    ),
    FilterModel(
      type: FilterType.fadeIn,
      name: 'Fade In',
      nameAr: 'ظهور تدريجي',
      icon: Icons.looks_one,
      minValue: 0,
      maxValue: 120,
      defaultValue: 0,
      unit: 'frames',
    ),
    FilterModel(
      type: FilterType.fadeOut,
      name: 'Fade Out',
      nameAr: 'اختفاء تدريجي',
      icon: Icons. looks_two,
      minValue: 0,
      maxValue: 120,
      defaultValue: 0,
      unit: 'frames',
    ),
  ];

  /// Get filter by type
  static FilterModel? getFilterByType(FilterType type) {
    try {
      return allFilters.firstWhere((filter) => filter.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Get filters applicable to images only
  static List<FilterModel> get imageFilters {
    return allFilters.where((filter) {
      return filter.type != FilterType.fadeIn && 
             filter.type != FilterType.fadeOut;
    }).toList();
  }

  /// Get filters applicable to videos
  static List<FilterModel> get videoFilters {
    return allFilters;
  }
}

/// Extension to help convert filter values to FFmpeg parameters
extension FilterTypeExtension on FilterType {
  /// Get the FFmpeg parameter name for this filter type
  String get ffmpegKey {
    switch (this) {
      case FilterType.blur:
        return 'blur';
      case FilterType.grayscale:
        return 'grayscale';
      case FilterType.sepia:
        return 'sepia';
      case FilterType.brightness:
        return 'brightness';
      case FilterType.contrast:
        return 'contrast';
      case FilterType.saturation:
        return 'saturation';
      case FilterType.fadeIn:
        return 'fade_in';
      case FilterType.fadeOut:
        return 'fade_out';
    }
  }
}
