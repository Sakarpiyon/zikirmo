// Dosya: lib/core/services/auth_service.dart
// Yol: C:\src\zikirmo_new\lib\core\services\auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'firestore_service.dart';
import 'analytics_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService firestoreService;
  final AnalyticsService analyticsService;
  GoogleSignIn? _googleSignIn;

  AuthService({
    required this.firestoreService, 
    required this.analyticsService,
  }) {
    // Google Sign-In'i sadece desteklenen platformlarda initialize et
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }
  }

  User? get currentUser => _auth.currentUser;
  
  bool? get isPremium => null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email doğrulama durumunu kontrol et
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Lokalize hata mesajları
  String _getLocalizedErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'userNotFound'.tr();
      case 'wrong-password':
        return 'wrongPassword'.tr();
      case 'invalid-email':
        return 'invalidEmail'.tr();
      case 'user-disabled':
        return 'userDisabled'.tr();
      case 'too-many-requests':
        return 'tooManyRequests'.tr();
      case 'weak-password':
        return 'weakPassword'.tr();
      case 'email-already-in-use':
        return 'emailAlreadyInUse'.tr();
      case 'operation-not-allowed':
        return 'operationNotAllowed'.tr();
      case 'invalid-credential':
        return 'invalidCredentials'.tr();
      case 'account-exists-with-different-credential':
        return 'accountExistsWithDifferentCredential'.tr();
      case 'network-request-failed':
        return 'networkError'.tr();
      default:
        return 'authError'.tr();
    }
  }

  // E-posta ve şifre ile giriş
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('🔐 Email ile giriş deneniyor: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      debugPrint('✅ Email ile giriş başarılı: ${userCredential.user?.uid}');
      
      if (userCredential.user != null) {
        // Analytics kaydet
        unawaited(analyticsService.logSignIn('email'));
        
        // Son aktiflik zamanını güncelle
        unawaited(_updateLastActiveTime(userCredential.user!.uid));
      }
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth hatası: ${e.code} - ${e.message}');
      throw Exception(_getLocalizedErrorMessage(e));
    } catch (e) {
      debugPrint('❌ Genel auth hatası: $e');
      throw Exception('networkError'.tr());
    }
  }

  // E-posta ve şifre ile kayıt - THREAD SAFE
  Future<User?> createUserWithEmailAndPassword(
      String email, String password, String nickname) async {
    try {
      debugPrint('📝 Yeni kullanıcı kaydı: $email');
      
      // 1. Firebase Auth ile kullanıcı oluştur
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        debugPrint('✅ Kullanıcı oluşturuldu: ${user.uid}');
        
        // 2. Display name güncelle - THREAD SAFE
        try {
          await _safeUpdateDisplayName(user, nickname);
          debugPrint('✅ Display name güncellendi');
        } catch (e) {
          debugPrint('⚠️ Display name güncellenemedi: $e');
        }
        
        // 3. Firestore profili oluştur - ASYNC OLARAK
        _createUserProfileAsync(user.uid, nickname, email.trim(), user);
        
        // 4. Analytics kaydet - ASYNC OLARAK
        unawaited(analyticsService.logEvent('user_registration', {'method': 'email'}));
        
        debugPrint('🎯 Register tamamlandı: ${user.uid}');
      }
      
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Kayıt Firebase hatası: ${e.code} - ${e.message}');
      throw Exception(_getLocalizedErrorMessage(e));
    } catch (e) {
      debugPrint('❌ Genel kayıt hatası: $e');
      throw Exception('registrationError'.tr());
    }
  }

  // Display name güncelleme - THREAD SAFE
  Future<void> _safeUpdateDisplayName(User user, String nickname) async {
    try {
      await user.updateDisplayName(nickname);
      // Reload işlemini gecikmeli yap
      await Future.delayed(const Duration(milliseconds: 100));
      await user.reload();
    } catch (e) {
      debugPrint('⚠️ Display name thread hatası: $e');
      // Thread hatası olsa bile devam et
    }
  }

  // Firestore kullanıcı profili oluşturma - ASYNC
  void _createUserProfileAsync(String uid, String nickname, String email, User user) {
    // Async olarak çalıştır, UI'yi bloklamaz
    Future.delayed(const Duration(milliseconds: 200)).then((_) async {
      try {
        await firestoreService.createOrUpdateUser(uid, {
          'nickname': nickname,
          'email': email,
          'isEmailVerified': true, // Email doğrulanmış olarak işaretle
          'totalZikirCount': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'isPremium': false,
          'friends': [],
          'points': 0,
          'level': 'levelBeginner',
          'currentStreak': 0,
          'longestStreak': 0,
          'badges': [],
          'customClaims': {},
          'socialLinks': {},
          'bio': '',
          'aboutMe': '',
          'country': 'TR',
          'profilePictureUrl': user.photoURL ?? '',
          'profileImageUrl': user.photoURL ?? '',
          'lastActiveAt': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ Firestore profili oluşturuldu (async)');
      } catch (e) {
        debugPrint('❌ Async Firestore profil hatası: $e');
      }
    });
  }

  // Email doğrulama gönderme - PUBLIC METHOD (İSTEĞE BAĞLI)
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint('📧 Email doğrulama gönderildi: ${user.email}');
        unawaited(analyticsService.logEvent('email_verification_sent', {'email': user.email}));
      } else if (user?.emailVerified == true) {
        throw Exception('emailAlreadyVerified'.tr());
      } else {
        throw Exception('userNotFound'.tr());
      }
    } catch (e) {
      debugPrint('❌ Email doğrulama gönderilemedi: $e');
      if (e.toString().contains('emailAlreadyVerified') || e.toString().contains('userNotFound')) {
        rethrow;
      }
      throw Exception('emailVerificationError'.tr());
    }
  }

  // Email doğrulama durumunu yenile
  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
      debugPrint('🔄 Kullanıcı bilgileri yenilendi');
      
      // Firestore'daki email verified durumunu güncelle
      final user = currentUser;
      if (user != null) {
        unawaited(firestoreService.updateUser(user.uid, {
          'isEmailVerified': user.emailVerified,
        }));
      }
    } catch (e) {
      debugPrint('❌ Kullanıcı yenileme hatası: $e');
    }
  }

  // Google ile giriş - PLATFORM KONTROLÜ İLE
  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('🔍 Google ile giriş başlatılıyor...');
      
      // Platform kontrolü
      if (_googleSignIn == null) {
        throw Exception('Google Sign-In bu platformda desteklenmiyor');
      }
      
      // Önceki oturumu temizle
      await _googleSignIn!.signOut();
      
      // Google Sign-In başlat
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      
      if (googleUser == null) {
        debugPrint('⚠️ Google giriş iptal edildi');
        return null;
      }

      debugPrint('📧 Google kullanıcısı: ${googleUser.email}');
      
      // Google kimlik doğrulama bilgilerini al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('googleAuthTokenError'.tr());
      }
      
      // Firebase credential oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase'e giriş yap
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        debugPrint('✅ Google ile giriş başarılı: ${user.uid}');
        
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        if (isNewUser) {
          debugPrint('👤 Yeni Google kullanıcısı - Firestore verisi oluşturuluyor');
          
          _createUserProfileAsync(
            user.uid, 
            user.displayName ?? 'defaultUser'.tr(),
            user.email ?? '',
            user,
          );
          
          unawaited(analyticsService.logEvent('user_registration', {'method': 'google'}));
        } else {
          // Mevcut kullanıcı için son aktiflik zamanını güncelle
          unawaited(_updateLastActiveTime(user.uid));
        }
        
        unawaited(analyticsService.logSignIn('google'));
      }
      
      return user;
    } on PlatformException catch (e) {
      debugPrint('❌ Google Platform hatası: ${e.code} - ${e.message}');
      if (e.code == 'sign_in_canceled') {
        debugPrint('⚠️ Google giriş iptal edildi');
        return null;
      }
      throw Exception('googleSignInError'.tr());
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Google Firebase Auth hatası: ${e.code} - ${e.message}');
      throw Exception(_getLocalizedErrorMessage(e));
    } catch (e) {
      debugPrint('❌ Google giriş hatası: $e');
      throw Exception('Google Sign-In desteklenmiyor veya yapılandırılmamış');
    }
  }

  // Apple ile giriş - PLATFORM KONTROLÜ İLE
  Future<User?> signInWithApple() async {
    try {
      debugPrint('🍎 Apple ile giriş başlatılıyor...');
      
      // Platform kontrolü
      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.macOS) {
        throw Exception('Apple Sign-In bu platformda desteklenmiyor');
      }
      
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;
      
      if (user != null) {
        debugPrint('✅ Apple ile giriş başarılı: ${user.uid}');
        
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        if (isNewUser) {
          String nickname = 'defaultUser'.tr();
          if (appleCredential.givenName != null && appleCredential.familyName != null) {
            nickname = '${appleCredential.givenName} ${appleCredential.familyName}';
          } else if (appleCredential.givenName != null) {
            nickname = appleCredential.givenName!;
          }
          
          _createUserProfileAsync(user.uid, nickname, user.email ?? '', user);
          unawaited(analyticsService.logEvent('user_registration', {'method': 'apple'}));
        } else {
          unawaited(_updateLastActiveTime(user.uid));
        }
        
        unawaited(analyticsService.logSignIn('apple'));
      }
      
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Apple Firebase Auth hatası: ${e.code} - ${e.message}');
      throw Exception(_getLocalizedErrorMessage(e));
    } catch (e) {
      debugPrint('❌ Apple giriş hatası: $e');
      throw Exception('Apple Sign-In desteklenmiyor');
    }
  }

  // Son aktiflik zamanını güncelle - ASYNC
  Future<void> _updateLastActiveTime(String userId) async {
    try {
      await firestoreService.updateUser(userId, {
        'lastActiveAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('⚠️ Son aktiflik zamanı güncellenemedi: $e');
    }
  }

  // Şifre sıfırlama e-postası gönderme
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      unawaited(analyticsService.logEvent('password_reset_requested', {'email': email}));
      debugPrint('📧 Şifre sıfırlama e-postası gönderildi: $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Şifre sıfırlama hatası: ${e.code} - ${e.message}');
      throw Exception(_getLocalizedErrorMessage(e));
    } catch (e) {
      debugPrint('❌ Şifre sıfırlama genel hatası: $e');
      throw Exception('passwordResetError'.tr());
    }
  }

  // Kullanıcının Premium durumunu kontrol etme
  Future<bool> checkIfUserIsPremium() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final userData = await firestoreService.getUser(user.uid);
      return userData?.isPremium ?? false;
    } catch (e) {
      debugPrint('❌ Premium durum kontrolü hatası: $e');
      return false;
    }
  }

  // Kullanıcının admin olup olmadığını kontrol etme
  Future<bool> checkIfUserIsAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final userData = await firestoreService.getUser(user.uid);
      return userData?.customClaims?['admin'] ?? false;
    } catch (e) {
      debugPrint('❌ Admin durum kontrolü hatası: $e');
      return false;
    }
  }

  // Çıkış yapma
  Future<void> signOut() async {
    try {
      unawaited(analyticsService.logEvent('sign_out', null));
      
      // Google Sign-In'den de çıkış yap
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
      
      await _auth.signOut();
      debugPrint('👋 Çıkış yapıldı');
    } catch (e) {
      debugPrint('❌ Çıkış hatası: $e');
      throw Exception('signOutError'.tr());
    }
  }

  // Hesabı silme
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await firestoreService.deleteUser(user.uid);
        await user.delete();
        unawaited(analyticsService.logEvent('account_deleted', null));
        debugPrint('🗑️ Hesap silindi: ${user.uid}');
      }
    } catch (e) {
      debugPrint('❌ Hesap silme hatası: $e');
      throw Exception('deleteAccountError'.tr());
    }
  }
}