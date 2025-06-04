// Dosya: lib/core/providers/theme_provider.dart
// Yol: C:\src\zikirmo_new\lib\core\providers\theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tema modu provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  static const String _themeModeKey = 'theme_mode';

  // Tema modunu SharedPreferences'tan yükle
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeModeKey);
      
      if (themeModeString != null) {
        switch (themeModeString) {
          case 'light':
            state = ThemeMode.light;
            break;
          case 'dark':
            state = ThemeMode.dark;
            break;
          case 'system':
          default:
            state = ThemeMode.system;
            break;
        }
      }
    } catch (e) {
      debugPrint('❌ Tema modu yüklenemedi: $e');
      state = ThemeMode.system;
    }
  }

  // Tema modunu değiştir ve kaydet
  Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      state = themeMode;
      
      final prefs = await SharedPreferences.getInstance();
      String themeModeString;
      
      switch (themeMode) {
        case ThemeMode.light:
          themeModeString = 'light';
          break;
        case ThemeMode.dark:
          themeModeString = 'dark';
          break;
        case ThemeMode.system:
        default:
          themeModeString = 'system';
          break;
      }
      
      await prefs.setString(_themeModeKey, themeModeString);
      debugPrint('✅ Tema modu kaydedildi: $themeModeString');
    } catch (e) {
      debugPrint('❌ Tema modu kaydedilemedi: $e');
    }
  }

  // Tema modunu toggle et (light <-> dark)
  Future<void> toggleTheme() async {
    switch (state) {
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
        break;
    }
  }

  // Sistem temasını kullan
  Future<void> useSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }
}