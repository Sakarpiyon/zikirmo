// Dosya: lib/core/services/email_verification_service.dart
// Yol: C:\src\zikirmo_new\lib\core\services\email_verification_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Email doğrulama durumunu yöneten servis
class EmailVerificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authStateSubscription;
  final StreamController<bool> _verificationStatusController = StreamController<bool>.broadcast();

  /// Email doğrulama durumu stream'i
  Stream<bool> get verificationStatusStream => _verificationStatusController.stream;

  /// Servis başlatma
  void initialize() {
    _startListening();
  }

  /// Auth state değişikliklerini dinle
  void _startListening() {
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _checkEmailVerificationStatus(user);
      } else {
        _verificationStatusController.add(false);
      }
    });
  }

  /// Email doğrulama durumunu kontrol et
  Future<void> _checkEmailVerificationStatus(User user) async {
    try {
      // Kullanıcı durumunu yenile
      await user.reload();
      
      final isVerified = user.emailVerified;
      debugPrint('📧 EMAIL STATUS: ${user.email} - Verified: $isVerified');
      
      // Stream'e durumu gönder
      _verificationStatusController.add(isVerified);
      
    } catch (e) {
      debugPrint('❌ Email verification check error: $e');
      _verificationStatusController.add(false);
    }
  }

  /// Manuel email doğrulama kontrolü
  Future<bool> checkEmailVerificationManually() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      debugPrint('🔍 Manuel email verification check başlatılıyor...');
      
      // Firebase Auth'dan güncel durumu al
      await user.reload();
      
      final isVerified = user.emailVerified;
      debugPrint('📧 Manuel check sonucu: $isVerified');
      
      // Stream'e durumu gönder
      _verificationStatusController.add(isVerified);
      
      return isVerified;
    } catch (e) {
      debugPrint('❌ Manuel email check hatası: $e');
      return false;
    }
  }

  /// Email doğrulama gerekli mi?
  bool get isEmailVerificationRequired {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    // Email/password ile kayıt olan kullanıcılar için doğrulama gerekli
    final hasEmailProvider = user.providerData.any(
      (info) => info.providerId == 'password',
    );
    
    return hasEmailProvider && !user.emailVerified;
  }

  /// Mevcut kullanıcının email doğrulama durumu
  bool get isCurrentUserEmailVerified {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  /// Kullanıcının email adresi
  String? get currentUserEmail {
    return _auth.currentUser?.email;
  }

  /// Freemium kısıtlamaları için email doğrulama kontrolü
  bool canAccessPremiumFeatures() {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    // Google/Apple ile giriş yapan kullanıcılar direkt erişebilir
    final hasThirdPartyProvider = user.providerData.any(
      (info) => info.providerId == 'google.com' || info.providerId == 'apple.com',
    );
    
    if (hasThirdPartyProvider) return true;
    
    // Email/password kullanıcıları için doğrulama gerekli
    return user.emailVerified;
  }

  /// Freemium özellik erişim kontrolü
  Map<String, dynamic> getFeatureAccessStatus() {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'canAddFriends': false,
        'canCreateCustomZikir': false,
        'canAccessPremiumStats': false,
        'canUseAdvancedFeatures': false,
        'requiresVerification': true,
        'reason': 'Giriş yapmanız gerekiyor',
      };
    }

    final isVerified = canAccessPremiumFeatures();
    
    if (!isVerified) {
      return {
        'canAddFriends': false,
        'canCreateCustomZikir': false,
        'canAccessPremiumStats': false,
        'canUseAdvancedFeatures': false,
        'requiresVerification': true,
        'reason': 'Email doğrulaması gerekli',
      };
    }

    return {
      'canAddFriends': true,
      'canCreateCustomZikir': false, // Premium özellik
      'canAccessPremiumStats': false, // Premium özellik
      'canUseAdvancedFeatures': true,
      'requiresVerification': false,
      'reason': null,
    };
  }

  /// Servisi kapat
  void dispose() {
    _authStateSubscription?.cancel();
    _verificationStatusController.close();
  }
}