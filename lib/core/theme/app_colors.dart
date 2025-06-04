// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Ana renkler
  static const Color primary = Color(0xFF2E7D32); // Yeşil
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);
  
  // İkincil renkler
  static const Color secondary = Color(0xFF4A90E2); // Mavi
  static const Color secondaryLight = Color(0xFF7BB3F0);
  static const Color secondaryDark = Color(0xFF2E5984);
  
  // Accent renkler
  static const Color accent = Color(0xFFFF9800); // Turuncu
  static const Color accentLight = Color(0xFFFFB74D);
  static const Color accentDark = Color(0xFFEF6C00);
  
  // Başarı ve hata renkleri
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Arka plan renkleri
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF424242);
  
  // Metin renkleri
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Colors.white;
  
  // Gri tonları
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // Özel zikir renkleri
  static const Color zikirCounter = Color(0xFF4CAF50);
  static const Color zikirCompleted = Color(0xFF8BC34A);
  static const Color zikirInProgress = Color(0xFF2196F3);
  
  // Premium renkleri
  static const Color premium = Color(0xFFFFD700); // Altın
  static const Color premiumDark = Color(0xFFB8860B);
  
  // Şeffaf renkler
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
  
  AppColors._(); // Private constructor
}