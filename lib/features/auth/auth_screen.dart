// Dosya: lib/features/auth/auth_screen.dart
// Yol: C:\src\zikirmo_new\lib\features\auth\auth_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Login form controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscurePassword = true;
  
  // Register form controllers
  final _registerFormKey = GlobalKey<FormState>();
  final _registerNicknameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  bool _registerObscurePassword = true;
  bool _registerObscureConfirmPassword = true;
  bool _acceptTerms = false;
  
  // Common state
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Tab değişikliklerini dinle
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _errorMessage = null; // Tab değiştiğinde hata mesajını temizle
        });
      }
    });
  }

  @override
  void dispose() {
    // TabController'ı güvenli şekilde dispose et
    if (_tabController.hasListeners) {
      _tabController.removeListener(() {});
    }
    _tabController.dispose();
    
    // Text controller'ları dispose et
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNicknameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_loginFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = ref.read(authServiceProvider);
        
        final user = await authService.signInWithEmailAndPassword(
          _loginEmailController.text.trim(),
          _loginPasswordController.text,
        );
        
        if (user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('welcomeUser'.tr(args: [user.displayName ?? 'defaultUser'.tr()])),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Direkt ana sayfaya git - email doğrulama kontrolü kaldırıldı
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            String errorMsg = e.toString();
            if (errorMsg.contains('Exception:')) {
              errorMsg = errorMsg.replaceAll('Exception:', '').trim();
            }
            _errorMessage = errorMsg;
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Register method - NAVIGATION SORUNU ÇÖZÜLDİ
  Future<void> _register() async {
    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'acceptTermsRequired'.tr();
      });
      return;
    }
    
    if (_registerFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        debugPrint('🔄 Register başlatılıyor...');
        
        final authService = ref.read(authServiceProvider);
        final user = await authService.createUserWithEmailAndPassword(
          _registerEmailController.text.trim(),
          _registerPasswordController.text,
          _registerNicknameController.text.trim(),
        );
        
        debugPrint('🎯 AuthService sonucu: ${user?.uid}');
        
        if (user != null && mounted) {
          debugPrint('✅ Register başarılı! Ana sayfaya geçiliyor...');
          
          // Loading'i kapat
          setState(() {
            _isLoading = false;
          });
          
          // Başarı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('registrationSuccessful'.tr()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Kısa bekle ve ana sayfaya git - TÜM ÖNCEKİ ROUTE'LARI TEMİZLE
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            debugPrint('🚀 Navigation başlatılıyor...');
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/home',
              (route) => false, // Tüm önceki route'ları temizle
            );
            debugPrint('🚀 Ana sayfaya geçildi!');
          }
        } else {
          debugPrint('❌ User null döndü');
          setState(() {
            _errorMessage = 'registrationError'.tr();
          });
        }
      } catch (e) {
        debugPrint('❌ Register UI hatası: $e');
        if (mounted) {
          setState(() {
            _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();
      
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('googleSignInSuccess'.tr()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          String errorMsg = e.toString();
          if (errorMsg.contains('Exception:')) {
            errorMsg = errorMsg.replaceAll('Exception:', '').trim();
          }
          _errorMessage = errorMsg;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithApple();
      
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('appleSignInSuccess'.tr()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          String errorMsg = e.toString();
          if (errorMsg.contains('Exception:')) {
            errorMsg = errorMsg.replaceAll('Exception:', '').trim();
          }
          _errorMessage = errorMsg;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('welcome'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'buttonSignIn'.tr()),
            Tab(text: 'buttonSignUp'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoginTab(),
          _buildRegisterTab(),
        ],
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _loginFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              
              // Başlık
              Text(
                'welcomeMessage'.tr(),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Email alanı
              TextFormField(
                controller: _loginEmailController,
                decoration: InputDecoration(
                  labelText: 'email'.tr(),
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'emailRequired'.tr();
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'invalidEmail'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Şifre alanı
              TextFormField(
                controller: _loginPasswordController,
                decoration: InputDecoration(
                  labelText: 'password'.tr(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _loginObscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _loginObscurePassword = !_loginObscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: _loginObscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'passwordRequired'.tr();
                  }
                  return null;
                },
              ),
              
              // Şifremi unuttum bağlantısı
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot_password');
                  },
                  child: Text('forgotPassword'.tr()),
                ),
              ),
              
              // Hata mesajı
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Giriş butonu
              SizedBox(
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'buttonSignIn'.tr(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              
              // Sosyal medya butonları
              _buildSocialButtons(),
              const SizedBox(height: 24),
              
              // Register'a yönlendirme
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('noAccountYet'.tr()),
                    TextButton(
                      onPressed: () => _tabController.animateTo(1),
                      child: Text('buttonSignUp'.tr()),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Üyelik bilgileri
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/membership_info');
                },
                child: Text('learnMembership'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _registerFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              
              // Başlık
              Text(
                'createAccount'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Takma ad alanı
              TextFormField(
                controller: _registerNicknameController,
                decoration: InputDecoration(
                  labelText: 'nickname'.tr(),
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'nicknameRequired'.tr();
                  }
                  if (value.length < 3) {
                    return 'nicknameTooShort'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Email alanı
              TextFormField(
                controller: _registerEmailController,
                decoration: InputDecoration(
                  labelText: 'email'.tr(),
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'emailRequired'.tr();
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'invalidEmail'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Şifre alanı
              TextFormField(
                controller: _registerPasswordController,
                decoration: InputDecoration(
                  labelText: 'password'.tr(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _registerObscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _registerObscurePassword = !_registerObscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: _registerObscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'passwordRequired'.tr();
                  }
                  if (value.length < 6) {
                    return 'passwordTooShort'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Şifre onay alanı
              TextFormField(
                controller: _registerConfirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'confirmPassword'.tr(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _registerObscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _registerObscureConfirmPassword = !_registerObscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: _registerObscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'confirmPasswordRequired'.tr();
                  }
                  if (value != _registerPasswordController.text) {
                    return 'passwordsDoNotMatch'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Kullanım şartları onay kutusu
              CheckboxListTile(
                title: Text('acceptTerms'.tr()),
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptTerms = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              
              // Şartları görüntüle bağlantısı
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/terms_of_service');
                  },
                  child: Text('readTerms'.tr()),
                ),
              ),
              
              // Hata mesajı
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Kayıt ol butonu
              SizedBox(
                height: 56,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'buttonSignUp'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              
              // Login'e yönlendirme
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('alreadyHaveAccountQuestion'.tr()),
                    TextButton(
                      onPressed: () => _tabController.animateTo(0),
                      child: Text('buttonSignIn'.tr()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        // Veya divider
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('or'.tr(), style: const TextStyle(color: Colors.grey)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        
        // Sosyal medya butonları
        Row(
          children: [
            // Google ile giriş
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 24),
                label: const Text('Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Apple ile giriş
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInWithApple,
                icon: const Icon(Icons.apple, size: 24),
                label: const Text('Apple'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}