import 'package:flutter/foundation.dart';

class AnalyticsService {
  // Analytics'i geçici olarak devre dışı bırakıyoruz
  
  Future<void> logEvent(String eventName, Map<String, dynamic>? parameters) async {
    try {
      // Geçici olarak sadece debug log
      if (kDebugMode) {
        debugPrint('📊 Analytics Event: $eventName - $parameters');
      }
      // Firebase Analytics çağrısını geçici olarak kaldırıyoruz
    } catch (e) {
      debugPrint('⚠️ Analytics hatası (görmezden geliniyor): $e');
    }
  }

  Future<void> logSignIn(String method) async {
    await logEvent('sign_in', {'method': method});
  }

  Future<void> logSignOut() async {
    await logEvent('sign_out', null);
  }

  Future<void> logRegistration(String method) async {
    await logEvent('user_registration', {'method': method});
  }

  Future<void> setUserId(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('📊 Analytics User ID: $userId');
      }
      // Firebase Analytics çağrısını geçici olarak kaldırıyoruz
    } catch (e) {
      debugPrint('⚠️ Analytics setUserId hatası (görmezden geliniyor): $e');
    }
  }

  Future<void> setUserProperty(String name, String value) async {
    try {
      if (kDebugMode) {
        debugPrint('📊 Analytics User Property: $name = $value');
      }
      // Firebase Analytics çağrısını geçici olarak kaldırıyoruz
    } catch (e) {
      debugPrint('⚠️ Analytics setUserProperty hatası (görmezden geliniyor): $e');
    }
  }
}