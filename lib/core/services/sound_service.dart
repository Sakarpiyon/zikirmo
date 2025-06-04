// lib/core/services/sound_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

// Sound service provider
final soundServiceProvider = Provider<SoundService>((ref) {
  return SoundService();
});

class SoundService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  
  // Ses servisini başlat
  Future<void> initialize() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Ses servisi başlatılamadı: $e');
    }
  }
  
  // Zikir sayma sesi çal
  Future<void> playZikirSound() async {
    if (!_isInitialized) await initialize();
    
    try {
      await _audioPlayer.play(AssetSource('sounds/click.mp3'));
    } catch (e) {
      debugPrint('Zikir sesi çalınamadı: $e');
    }
  }
  
  // Hedef tamamlama sesi çal
  Future<void> playCompletionSound() async {
    if (!_isInitialized) await initialize();
    
    try {
      await _audioPlayer.play(AssetSource('sounds/completion.mp3'));
    } catch (e) {
      debugPrint('Tamamlama sesi çalınamadı: $e');
    }
  }
  
  // Arapça ses oynat
  Future<void> playArabicAudio(String audioUrl) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      debugPrint('Arapça ses çalınamadı: $e');
    }
  }
  
  // Sesli okunuş oynat
  Future<void> playTranslatedAudio(String audioUrl) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      debugPrint('Sesli okunuş çalınamadı: $e');
    }
  }
  
  // Sesi durdur
  Future<void> stopAudio() async {
    if (!_isInitialized) return;
    
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Ses durdurulamadı: $e');
    }
  }
  
  // Kaynakları temizle
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
    } catch (e) {
      debugPrint('Ses kaynakları temizlenemedi: $e');
    }
  }
}