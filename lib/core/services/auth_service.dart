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
  StreamSubscription<User?>? _authStateSubscription;

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
    
    // ⚡ EMAIL DOĞRULAMA LISTENER - OTOMATIK SYNC
    _startEmailVerificationListener();
  }

  User? get currentUser => _auth.currentUser;
  
  bool? get isPremium => null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email doğrulama durumunu kontrol et
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // ⚡ EMAIL DOĞRULAMA LISTENER - FIRESTORE SYNC
  void _startEmailVerificationListener() {
    _authStateSubscription = _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // Kullanıcı durumunu kontrol et
        await _checkAndUpdateEmailVerificationStatus(user);
      }
    });
  }

  // Email doğrulama durumunu kontrol et ve Firestore'u güncelle
  Future<void> _checkAndUpdateEmailVerificationStatus(User user) async {
    try {
      // Firebase Auth'dan son durumu al
      await user.reload();
      final isVerified = user.emailVerified;
      
      debugPrint('🔄 EMAIL SYNC: Kontrol ediliyor - ${user.email}');
      debugPrint('🔄 EMAIL SYNC: Firebase Auth verified: $isVerified');
      
      // Firestore'daki mevcut durumu al
      final userData = await firestoreService.getUser(user.uid);
      final firestoreVerified = userData?.isEmailVerified ?? false;
      
      debugPrint('🔄 EMAIL SYNC: Firestore verified: $firestoreVerified');
      
      // Eğer Firebase Auth'da doğrulanmış ama Firestore'da değilse güncelle
      if (isVerified && !firestoreVerified) {
        debugPrint('✅ EMAIL SYNC: Firestore güncelleniyor...');
        
        await firestoreService.updateUser(user.uid, {
          'isEmailVerified': true,
          'emailVerifiedAt': DateTime.now().toIso8601String(),
        });
        
        debugPrint('🎉 EMAIL SYNC: Firestore başarıyla güncellendi!');
        
        // Analytics kaydet
        unawaited(analyticsService.logEvent('email_verified', {
          'email': user.email,
          'verifiedAt': DateTime.now().toIso8601String(),
        }));
      }
    } catch (e) {
      debugPrint('❌ EMAIL SYNC HATASI: $e');
    }
  }

  // Manuel email doğrulama durumu kontrol metodu - PUBLIC
  Future<bool> checkEmailVerificationStatus() async {
    try {
      final user = currentUser;
      if (user == null) return false;
      
      debugPrint('🔍 MANUEL EMAIL CHECK: ${user.email}');
      
      // Firebase Auth'dan güncel durumu al
      await user.reload();
      
      // Firestore'u da güncelle
      await _checkAndUpdateEmailVerificationStatus(user);
      
      return user.emailVerified;
    } catch (e) {
      debugPrint('❌ Manuel email check hatası: $e');
      return false;
    }
  }

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
      case 'invalid-action-code':
        return 'invalidActionCode'.tr();
      case 'expired-action-code':
        return 'expiredActionCode'.tr();
      case 'quota-exceeded':
        return 'emailQuotaExceeded'.tr();
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

  // E-posta ve şifre ile kayıt - GÜVENLI EMAIL GÖNDERME
  Future<User?> createUserWithEmailAndPassword(
      String email, String password, String nickname) async {
    try {
      debugPrint('📝 Yeni kullanıcı kaydı: $email');
      
      // 1. Firebase Auth ile kullanıcı oluştur (otomatik login yapar)
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        debugPrint('✅ Kullanıcı oluşturuldu ve login yapıldı: ${user.uid}');
        
        // 2. Display name güncelle
        try {
          await user.updateDisplayName(nickname);
          await user.reload();
          debugPrint('✅ Display name güncellendi');
        } catch (e) {
          debugPrint('⚠️ Display name güncellenemedi: $e');
        }
        
        // 3. Firestore kullanıcı profili oluştur
        try {
          await _createUserProfile(user.uid, nickname, email.trim(), user);
          debugPrint('✅ Firestore profili oluşturuldu');
        } catch (e) {
          debugPrint('❌ Firestore profil hatası: $e');
          // Firestore hatası olsa bile devam et
        }
        
        // 4. Email doğrulama gönder - GÜVENLİ YÖNTEM
        _sendEmailVerificationSafe(user);
        
        // 5. Analytics kaydet (arka planda)
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

  // Firestore kullanıcı profili oluşturma - SYNC
  Future<void> _createUserProfile(String uid, String nickname, String email, User user) async {
    await firestoreService.createOrUpdateUser(uid, {
      'nickname': nickname,
      'email': email,
      'isEmailVerified': user.emailVerified,
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
      'country': 'TR',
      'profilePictureUrl': user.photoURL ?? '',
      'lastActiveAt': DateTime.now().toIso8601String(),
    });
  }

  // ⚡ GÜVENLİ EMAIL GÖNDERME - CRASH FİX
  void _sendEmailVerificationSafe(User user) {
    // Timer ile geciktirme + try-catch + isolate koruması
    Timer(const Duration(milliseconds: 500), () {
      _attemptEmailVerification(user);
    });
  }

  Future<void> _attemptEmailVerification(User user) async {
    try {
      debugPrint('📧 🔄 Email doğrulama gönderiliyor...');
      
      // Önce kullanıcının hala geçerli olduğunu kontrol et
      await user.reload();
      
      if (user.emailVerified) {
        debugPrint('📧 ✅ Email zaten doğrulanmış');
        return;
      }

      // ActionCodeSettings ile daha güvenli gönderim
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://zikirmatik-be5c0.firebaseapp.com/__/auth/action',
        handleCodeInApp: false,
        iOSBundleId: 'com.zikirmo.zikirmoNew',
        androidPackageName: 'com.zikirmo.zikirmo_new',
        androidInstallApp: false,
        androidMinimumVersion: '1',
      );

      await user.sendEmailVerification(actionCodeSettings);
      
      debugPrint('📧 ✅ Email doğrulama başarıyla gönderildi: ${user.email}');
      unawaited(analyticsService.logEvent('email_verification_sent', {'email': user.email}));
      
    } catch (e) {
      debugPrint('📧 ⚠️ Email doğrulama hatası (göz ardı edildi): $e');
      // Hata oluşsa bile uygulamayı çökertmeyin
    }
  }

  // ⚡ PUBLIK EMAIL DOĞRULAMA - CRASH SAFE
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('userNotFound'.tr());
      }

      debugPrint('📧 🔄 Manuel email doğrulama başlatılıyor...');
      
      // Kullanıcı durumunu yenile
      await user.reload();
      
      if (user.emailVerified) {
        throw Exception('emailAlreadyVerified'.tr());
      }

      // Rate limiting kontrolü
      await _checkEmailSendingRate(user.uid);

      // ActionCodeSettings ile güvenli gönderim
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://zikirmatik-be5c0.firebaseapp.com/__/auth/action',
        handleCodeInApp: false,
        iOSBundleId: 'com.zikirmo.zikirmoNew',
        androidPackageName: 'com.zikirmo.zikirmo_new',
        androidInstallApp: false,
        androidMinimumVersion: '1',
      );

      await user.sendEmailVerification(actionCodeSettings);
      
      debugPrint('📧 ✅ Manuel email doğrulama gönderildi: ${user.email}');
      unawaited(analyticsService.logEvent('email_verification_resent', {'email': user.email}));
      
      // Son gönderim zamanını kaydet
      await _recordEmailSendTime(user.uid);
      
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase email hatası: ${e.code} - ${e.message}');
      throw Exception(_getLocalizedErrorMessage(e));
    } catch (e) {
      if (e.toString().contains('emailAlreadyVerified') || 
          e.toString().contains('userNotFound') ||
          e.toString().contains('tooManyRequests')) {
        rethrow;
      }
      debugPrint('❌ Email doğrulama genel hatası: $e');
      throw Exception('emailVerificationError'.tr());
    }
  }

  // Rate limiting için yardımcı metodlar
  Future<void> _checkEmailSendingRate(String userId) async {
    try {
      final userData = await firestoreService.getUser(userId);
      final lastEmailSent = userData?.customClaims?['lastEmailSent'] as String?;
      
      if (lastEmailSent != null) {
        final lastSentTime = DateTime.parse(lastEmailSent);
        final timeDiff = DateTime.now().difference(lastSentTime);
        
        if (timeDiff.inMinutes < 2) {
          throw Exception('tooManyRequests'.tr());
        }
      }
    } catch (e) {
      if (e.toString().contains('tooManyRequests')) {
        rethrow;
      }
      // Diğer hatalar göz ardı edilir
    }
  }

  Future<void> _recordEmailSendTime(String userId) async {
    try {
      await firestoreService.updateUser(userId, {
        'customClaims.lastEmailSent': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Kaydetme hatası göz ardı edilir
    }
  }

  // Email doğrulama durumunu yenile - GÜNCELLENDİ
  Future<void> reloadUser() async {
    try {
      final user = currentUser;
      if (user == null) return;
      
      await user.reload();
      debugPrint('🔄 Kullanıcı bilgileri yenilendi');
      
      // Email doğrulama durumunu kontrol et ve güncelle
      await _checkAndUpdateEmailVerificationStatus(user);
      
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
          
          unawaited(_createUserProfile(
            user.uid, 
            user.displayName ?? 'defaultUser'.tr(),
            user.email ?? '',
            user,
          ));
          
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
          
          unawaited(_createUserProfile(user.uid, nickname, user.email ?? '', user));
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

  // AuthService dispose metodu
  void dispose() {
    _authStateSubscription?.cancel();
  }
}