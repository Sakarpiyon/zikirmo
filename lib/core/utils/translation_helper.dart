// lib/core/utils/translation_helper.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

class TranslationHelper {
  static String translate(String key, [List<String>? args]) {
    try {
      return key.tr(args: args);
    } catch (e) {
      debugPrint('⚠️ Translation fallback used for: $key');
      return _getFallbackTranslation(key, args);
    }
  }
  
  static String _getFallbackTranslation(String key, List<String>? args) {
    String translation = _fallbackTranslations[key] ?? key;
    
    // Args varsa replace et
    if (args != null && args.isNotEmpty) {
      for (int i = 0; i < args.length; i++) {
        translation = translation.replaceAll('{$i}', args[i]);
      }
    }
    
    return translation;
  }

  // Fallback çeviriler
  static const Map<String, String> _fallbackTranslations = {
    'levelBeginner': 'Başlangıç',
    'home': 'Ana Sayfa',
    'profile': 'Profil',
    'settings': 'Ayarlar',
    'signOut': 'Çıkış Yap',
    'loading': 'Yükleniyor',
    'error': 'Hata',
    'success': 'Başarılı',
    'goBack': 'Geri Dön',
    'zikirNotFound': 'Zikir bulunamadı',
    'categoryNotFound': 'Kategori bulunamadı',
    'userNotFound': 'Kullanıcı bulunamadı',
    'pageNotFound': 'Sayfa bulunamadı',
    'invalidReceiver': 'Geçersiz alıcı',
    'detailedStatistics': 'Detaylı İstatistikler',
    'statisticsComingSoon': 'İstatistikler yakında geliyor',
    'privacyPolicy': 'Gizlilik Politikası',
    'termsOfService': 'Kullanım Şartları',
    'pageInPreparation': 'Sayfa hazırlanıyor',
    'purchaseHistory': 'Satın Alma Geçmişi',
    'subscriptionManagement': 'Abonelik Yönetimi',
    'featureComingSoon': 'Bu özellik yakında geliyor',
  };
}