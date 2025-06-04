// Dosya: lib/core/guards/email_verification_guard.dart
// Yol: C:\src\zikirmo_new\lib\core\guards\email_verification_guard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/providers.dart';

/// Email doğrulama koruması - Kapsamlı kısıtlamalar
class EmailVerificationGuard extends ConsumerWidget {
  final Widget child;
  final bool requireVerification;
  final bool allowBasicUsage; // Temel kullanım izni (sayaç, kategori görüntüleme)
  final String? customMessage;

  const EmailVerificationGuard({
    Key? key,
    required this.child,
    this.requireVerification = true,
    this.allowBasicUsage = false,
    this.customMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auth durumunu izle
    final authStateAsync = ref.watch(authStateProvider);
    
    return authStateAsync.when(
      data: (user) {
        // Kullanıcı yoksa auth sayfasına yönlendir
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
          });
          return _buildLoadingScreen();
        }

        // Email doğrulama gerekli değilse direkt geç
        if (!requireVerification) {
          return child;
        }

        // Email doğrulanmış mı kontrol et
        final isEmailVerified = user.emailVerified;
        
        if (isEmailVerified) {
          return child; // Doğrulanmışsa direkt geç
        }

        // Temel kullanıma izin varsa ve doğrulama yoksa kısıtlı erişim
        if (allowBasicUsage) {
          return _buildRestrictedAccessOverlay(context, ref);
        }

        // Tam kısıtlama - Email doğrulama ekranı göster
        return _buildVerificationRequiredScreen(context, ref, user.email);
      },
      loading: () => _buildLoadingScreen(),
      error: (error, stack) => _buildErrorScreen(context, error),
    );
  }

  /// Yükleniyor ekranı
  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Yükleniyor...'),
          ],
        ),
      ),
    );
  }

  /// Hata ekranı
  Widget _buildErrorScreen(BuildContext context, Object error) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text('errorLoadingProfile'.tr()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false),
              child: Text('tryAgain'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  /// Kısıtlı erişim overlay'i - temel özelliklere izin var ama kısıtlı
  Widget _buildRestrictedAccessOverlay(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        child, // Ana içerik
        
        // Doğrulama uyarı banner'ı
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'emailVerificationPending'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'verifyForFullAccess'.tr(),
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/email_verification'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.orange.shade200,
                      foregroundColor: Colors.orange.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text('verify'.tr(), style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tam email doğrulama gerekli ekranı
  Widget _buildVerificationRequiredScreen(BuildContext context, WidgetRef ref, String? email) {
    return Scaffold(
      appBar: AppBar(
        title: Text('emailVerificationRequired'.tr()),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              size: 80,
              color: Colors.orange.shade600,
            ),
            const SizedBox(height: 24),
            
            Text(
              'emailVerificationRequired'.tr(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            Text(
              customMessage ?? 'verificationRequiredMessage'.tr(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Doğrulama ekranına git butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/email_verification'),
                icon: const Icon(Icons.email),
                label: Text('verifyNow'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Ana sayfaya dön (kısıtlı erişim)
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
              child: Text('backToHome'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Email doğrulama durumu kontrol widget'ı
class EmailVerificationChecker extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onVerificationRequired;

  const EmailVerificationChecker({
    Key? key,
    required this.child,
    this.onVerificationRequired,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);
    
    return authStateAsync.when(
      data: (user) {
        if (user != null && !user.emailVerified) {
          if (onVerificationRequired != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onVerificationRequired!();
            });
          }
        }
        return child;
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}

/// Email doğrulama kısıtlama dialog'u
class EmailVerificationDialog {
  static void show(BuildContext context, {String? customMessage}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text('emailVerificationRequired'.tr()),
          ],
        ),
        content: Text(
          customMessage ?? 'featureRequiresVerification'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/email_verification');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('verifyNow'.tr()),
          ),
        ],
      ),
    );
  }
}

/// Email doğrulama durumu banner widget'ı
class EmailVerificationBanner extends ConsumerWidget {
  final bool showIfVerified;

  const EmailVerificationBanner({
    Key? key,
    this.showIfVerified = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);
    
    return authStateAsync.when(
      data: (user) {
        if (user == null) return const SizedBox();
        
        final isVerified = user.emailVerified;
        
        // Doğrulanmışsa ve gösterilmek istenmiyorsa gizle
        if (isVerified && !showIfVerified) {
          return const SizedBox();
        }
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isVerified ? Colors.green.shade100 : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isVerified ? Colors.green.shade300 : Colors.orange.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isVerified ? Icons.verified : Icons.warning_amber,
                color: isVerified ? Colors.green.shade700 : Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isVerified ? 'emailVerified'.tr() : 'emailNotVerified'.tr(),
                  style: TextStyle(
                    color: isVerified ? Colors.green.shade800 : Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!isVerified)
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/email_verification'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.orange.shade200,
                    foregroundColor: Colors.orange.shade800,
                  ),
                  child: Text('verify'.tr()),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}