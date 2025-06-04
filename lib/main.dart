import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  // Widget binding'i başlat
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Firebase başlatma - güvenli
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase başlatıldı');
  } catch (e) {
    debugPrint('❌ Firebase başlatma hatası: $e');
  }
  
  try {
    // EasyLocalization başlatma - güvenli
    await EasyLocalization.ensureInitialized();
    debugPrint('✅ EasyLocalization başlatıldı');
  } catch (e) {
    debugPrint('❌ EasyLocalization başlatma hatası: $e');
  }
  
  // Ana uygulamayı başlat
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      path: 'assets/lang',
      fallbackLocale: const Locale('tr'),
      startLocale: const Locale('tr'),
      useOnlyLangCode: true,
      child: const ProviderScope(
        child: ZikirMatikApp(),
      ),
    ),
  );
}