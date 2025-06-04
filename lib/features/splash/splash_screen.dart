// Dosya: lib/features/splash/splash_screen.dart
// Yol: C:\src\zikirmo_new\lib\features\splash\splash_screen.dart
// Açıklama: Onboarding kontrolü ve AuthScreen entegrasyonu

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 2 saniye bekle (splash effect için)
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    try {
      debugPrint('🚀 Splash: Uygulama başlatılıyor...');
      
      // Onboarding tamamlandı mı kontrol et
      final prefs = await SharedPreferences.getInstance();
      final isOnboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      
      debugPrint('📱 Onboarding durumu: $isOnboardingCompleted');
      
      // İlk kez gelen kullanıcı - Onboarding göster
      if (!isOnboardingCompleted) {
        debugPrint('🎯 İlk kullanım - Onboarding sayfasına yönlendiriliyor...');
        Navigator.pushReplacementNamed(context, '/onboarding');
        return;
      }
      
      // Daha önce gelmiş kullanıcı - Auth durumunu kontrol et
      debugPrint('🔍 Mevcut kullanıcı - Auth durumu kontrol ediliyor...');
      
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      
      debugPrint('👤 Mevcut kullanıcı: ${user?.email ?? 'null'}');
      
      if (user != null) {
        // Kullanıcı giriş yapmış - Ana sayfaya yönlendir
        debugPrint('✅ Kullanıcı aktif, ana sayfaya yönlendiriliyor');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Kullanıcı giriş yapmamış - Auth ekranına yönlendir (tab yapısı)
        debugPrint('❌ Kullanıcı yok, auth ekranına yönlendiriliyor');
        Navigator.pushReplacementNamed(context, '/auth'); // YENİ - Tab yapısı
      }
    } catch (e) {
      debugPrint('❌ Splash başlatma hatası: $e');
      // Hata durumunda onboarding'e yönlendir
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animasyonu
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.5 + (value * 0.5),
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2 * value),
                              spreadRadius: 5 * value,
                              blurRadius: 15 * value,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.mosque,
                          size: 60,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // App Name animasyonu
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Text(
                        'appName'.tr(), // Lokalize edilmiş app ismi
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'welcomeMessage'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 48),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'loading'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}