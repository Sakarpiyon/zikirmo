// Dosya: lib/features/profile/edit_profile_screen.dart
// Yol: C:\src\zikirmo_new\lib\features\profile\edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/providers/providers.dart';
import '../../core/guards/email_verification_guard.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nicknameController;
  late TextEditingController _aboutMeController;
  late TextEditingController _emailController;
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEmailVerified = false;
  UserModel? _currentUser;
  
  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _aboutMeController = TextEditingController();
    _emailController = TextEditingController();
    
    // Kullanıcı bilgilerini yükle
    _loadUserData();
  }
  
  @override
  void dispose() {
    _nicknameController.dispose();
    _aboutMeController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  // Kullanıcı bilgilerini yükle
  Future<void> _loadUserData() async {
    final userAsync = ref.read(userProvider);
    final authStateAsync = ref.read(authStateProvider);
    
    userAsync.whenData((user) {
      if (user != null) {
        setState(() {
          _currentUser = user;
          _nicknameController.text = user.nickname;
          _aboutMeController.text = user.aboutMe ?? '';
        });
      }
    });

    authStateAsync.whenData((authUser) {
      if (authUser != null) {
        setState(() {
          _isEmailVerified = authUser.emailVerified;
          _emailController.text = authUser.email ?? '';
        });
      }
    });
  }
  
  // Email doğrulama gönder
  Future<void> _sendEmailVerification() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendEmailVerification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('verificationEmailSent'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorSendingVerification'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  // Email doğrulama durumunu kontrol et
  Future<void> _checkEmailVerification() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.reloadUser();
      
      // Provider'ı yenile
      ref.refresh(authStateProvider);
      
      final authStateAsync = ref.read(authStateProvider);
      authStateAsync.whenData((authUser) {
        if (authUser != null) {
          setState(() {
            _isEmailVerified = authUser.emailVerified;
          });
          
          if (authUser.emailVerified && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('emailVerificationSuccessful'.tr())),
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorCheckingVerification'.tr(args: [e.toString()]))),
        );
      }
    }
  }
  
  // Profil bilgilerini güncelle
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      final userId = authService.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('userNotFound'.tr());
      }
      
      // Email doğrulanmamışsa sadece temel bilgileri güncelle
      Map<String, dynamic> updateData = {
        'nickname': _nicknameController.text.trim(),
      };
      
      // Email doğrulandıysa tüm bilgileri güncelle
      if (_isEmailVerified) {
        updateData['aboutMe'] = _aboutMeController.text.trim();
      }
      
      // Profil bilgilerini güncelle
      await firestoreService.updateUser(userId, updateData);
      
      // Display name'i de güncelle
      await authService.currentUser?.updateDisplayName(_nicknameController.text.trim());
      
      // Kullanıcı verilerini yenile
      ref.refresh(userProvider);
      
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profileUpdatedSuccessfully'.tr())),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'errorUpdatingProfile'.tr(args: [e.toString()]);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('editProfile'.tr()),
        actions: [
          if (!_isEmailVerified)
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => _showVerificationHelpDialog(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email doğrulama durumu banner'ı
                if (!_isEmailVerified) _buildEmailVerificationBanner(),
                const SizedBox(height: 16),
                
                // Email alanı (salt okunur)
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'email'.tr(),
                    prefixIcon: const Icon(Icons.email),
                    suffixIcon: _isEmailVerified 
                        ? Icon(Icons.verified, color: Colors.green.shade600)
                        : Icon(Icons.warning_amber, color: Colors.orange.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                
                // Kullanıcı adı alanı (her zaman düzenlenebilir)
                TextFormField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    labelText: '${'nickname'.tr()} *',
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
                
                // Hakkımda alanı (sadece doğrulanmış kullanıcılar)
                TextFormField(
                  controller: _aboutMeController,
                  decoration: InputDecoration(
                    labelText: 'aboutMe'.tr(),
                    prefixIcon: const Icon(Icons.info_outline),
                    suffixIcon: !_isEmailVerified 
                        ? Icon(Icons.lock, color: Colors.grey.shade400)
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: !_isEmailVerified 
                        ? 'verificationRequiredForField'.tr()
                        : null,
                  ),
                  enabled: _isEmailVerified,
                  maxLines: 5,
                  maxLength: 500,
                ),
                const SizedBox(height: 24),
                
                // Email doğrulama yapılmamışsa uyarı ve butonlar
                if (!_isEmailVerified) _buildVerificationActions(),
                const SizedBox(height: 16),
                
                // Hata mesajı
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
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
                  const SizedBox(height: 16),
                ],
                
                // Kaydet butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _updateProfile,
                          icon: const Icon(Icons.save),
                          label: Text('saveChanges'.tr()),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Bilgi metni
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isEmailVerified 
                              ? 'allFieldsEditable'.tr()
                              : 'limitedEditingInfo'.tr(),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Email doğrulama banner'ı
  Widget _buildEmailVerificationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              Text(
                'emailVerificationRequired'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'verifyEmailToEditProfile'.tr(),
            style: TextStyle(
              color: Colors.orange.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Doğrulama aksiyonları
  Widget _buildVerificationActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'emailVerificationActions'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sendEmailVerification,
                  icon: const Icon(Icons.email_outlined),
                  label: Text('sendVerification'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _checkEmailVerification,
                  icon: const Icon(Icons.refresh),
                  label: Text('checkStatus'.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(color: Colors.orange.shade300),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Text(
            'verificationInstructions'.tr(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Doğrulama yardım dialog'u
  void _showVerificationHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('emailVerificationHelp'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('verificationHelpContent'.tr()),
            const SizedBox(height: 16),
            Text(
              'verificationSteps'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('• ${'checkEmailInbox'.tr()}'),
            Text('• ${'checkSpamFolder'.tr()}'),
            Text('• ${'clickVerificationLink'.tr()}'),
            Text('• ${'returnToAppAndRefresh'.tr()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('understood'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/email_verification');
            },
            child: Text('goToVerification'.tr()),
          ),
        ],
      ),
    );
  }
}