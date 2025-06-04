// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authService = ref.read(authServiceProvider);
        
        debugPrint('🔐 Giriş denemesi başlatılıyor...');
        
        final user = await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        debugPrint('👤 Giriş sonucu: ${user?.uid}');
        
        if (user != null && mounted) {
          debugPrint('✅ Giriş başarılı, ana sayfaya yönlendiriliyor...');
          
          // Başarılı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hoş geldiniz!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Navigation debug
          debugPrint('🚀 Navigation çağrısı: /home');
          try {
            Navigator.pushReplacementNamed(context, '/home');
            debugPrint('🚀 Navigation çağrısı tamamlandı');
          } catch (navError) {
            debugPrint('❌ Navigation hatası: $navError');
            setState(() {
              _errorMessage = 'Navigation hatası: $navError';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Giriş yapılamadı';
          });
        }
      } catch (e) {
        debugPrint('❌ Giriş hatası: $e');
        
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      
      debugPrint('🔍 Google giriş denemesi başlatılıyor...');
      
      final user = await authService.signInWithGoogle();
      
      if (user != null && mounted) {
        debugPrint('✅ Google giriş başarılı, ana sayfaya yönlendiriliyor...');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google ile giriş başarılı!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        debugPrint('🚀 Google Navigation çağrısı: /home');
        Navigator.pushReplacementNamed(context, '/home');
        debugPrint('🚀 Google Navigation çağrısı tamamlandı');
      } else {
        debugPrint('⚠️ Google giriş iptal edildi');
      }
    } catch (e) {
      debugPrint('❌ Google giriş hatası: $e');
      
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
      
      debugPrint('🍎 Apple giriş denemesi başlatılıyor...');
      
      final user = await authService.signInWithApple();
      
      if (user != null && mounted) {
        debugPrint('✅ Apple giriş başarılı, ana sayfaya yönlendiriliyor...');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple ile giriş başarılı!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        debugPrint('🚀 Apple Navigation çağrısı: /home');
        Navigator.pushReplacementNamed(context, '/home');
        debugPrint('🚀 Apple Navigation çağrısı tamamlandı');
      } else {
        debugPrint('⚠️ Apple giriş iptal edildi');
      }
    } catch (e) {
      debugPrint('❌ Apple giriş hatası: $e');
      
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
        title: Text('buttonSignIn'.tr()),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Başlık ve açıklama
                Text(
                  'welcomeMessage'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Email alanı
                TextFormField(
                  controller: _emailController,
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
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'password'.tr(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: _obscurePassword,
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
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
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
                
                // Veya ile ayrılma çizgisi
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
                        label: Text('Google'),
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
                        label: Text('Apple'),
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
                const SizedBox(height: 24),
                
                // Kayıt ol bağlantısı
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('alreadyHaveAccount'.tr()),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text('buttonSignUp'.tr()),
                    ),
                  ],
                ),
                
                // Üyelik bilgileri bağlantısı
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
      ),
    );
  }
}