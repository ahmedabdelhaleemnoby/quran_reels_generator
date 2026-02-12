import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing the application theme mode (light, dark, or system)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
