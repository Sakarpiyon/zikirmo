// lib/core/services/haptic_service.dart

import 'package:flutter/services.dart';

class HapticService {
  // Hafif titreşim (zikir sayarken)
  Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }
  
  // Orta şiddetli titreşim
  Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }
  
  // Güçlü titreşim (hedef tamamlama)
  Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }
  
  // Titreşim (temel)
  Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }
  
  // Seçim tıklaması
  Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }
}