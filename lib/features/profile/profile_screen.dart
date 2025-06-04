// Dosya: lib/features/profile/profile_screen.dart
// Yol: C:\src\zikirmo_new\lib\features\profile\profile_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/providers.dart';
import '../../core/guards/email_verification_guard.dart';
import '../../routes.dart';
import 'components/profile_header.dart';
import 'components/stats_card.dart';
import 'components/badge_list.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isCheckingVerification = false;

  // Email doğrulama durumunu kontrol et
  Future<void> _checkEmailVerification() async {
    setState(() {
      _isCheckingVerification = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.reloadUser();
      
      // Provider'ı yenile
      ref.refresh(authStateProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('verificationStatusUpdated'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorCheckingVerification'.tr(args: [e.toString()]))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  // Email doğrulama gönder
  Future<void> _sendVerificationEmail() async {
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

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final authStateAsync = ref.watch(authStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr()),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('noUser'.tr()),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.auth);
                    },
                    child: Text('signIn'.tr()),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(userProvider);
              ref.refresh(authStateProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email doğrulama durumu banner'ı
                    authStateAsync.when(
                      data: (authUser) => authUser != null ? _buildEmailVerificationSection(authUser) : const SizedBox(),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Profil başlığı - avatar, kullanıcı adı, seviye vb.
                    ProfileHeader(user: user),
                    const SizedBox(height: 24),
                    
                    // İstatistikler kartı
                    StatsCard(user: user),
                    const SizedBox(height: 24),
                    
                    // Rozetler listesi
                    BadgeList(badges: user.badges),
                    const SizedBox(height: 24),
                    
                    // Kişisel bilgiler kartı
                    _buildPersonalInfoCard(user),
                    const SizedBox(height: 24),
                    
                    // Sosyal medya bağlantıları
                    _buildSocialMediaCard(user),
                    const SizedBox(height: 24),
                    
                    // Hesap işlemleri
                    _buildAccountActionsCard(),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 64),
              const SizedBox(height: 16),
              Text('errorLoadingProfile'.tr()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userProvider),
                child: Text('tryAgain'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Email doğrulama bölümü
  Widget _buildEmailVerificationSection(user) {
    final isEmailVerified = user.emailVerified;
    
    return Card(
      color: isEmailVerified ? Colors.green.shade50 : Colors.orange.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEmailVerified ? Icons.verified : Icons.warning_amber,
                  color: isEmailVerified ? Colors.green.shade600 : Colors.orange.shade600,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEmailVerified ? 'emailVerified'.tr() : 'emailNotVerified'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isEmailVerified ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEmailVerified 
                            ? 'fullAccessEnabled'.tr()
                            : 'verifyToUnlockFeatures'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: isEmailVerified ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                      if (user.email != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.email!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            if (!isEmailVerified) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sendVerificationEmail,
                      icon: const Icon(Icons.email_outlined),
                      label: Text('sendVerificationEmail'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _isCheckingVerification ? null : _checkEmailVerification,
                    icon: _isCheckingVerification 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text('checkStatus'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'emailVerificationHelp'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Kişisel bilgiler kartı
  Widget _buildPersonalInfoCard(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'personalInfo'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.editProfile);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Kullanıcı adı
            _buildInfoRow('nickname'.tr(), user.nickname),
            const SizedBox(height: 12),
            
            // Hakkımda
            _buildInfoRow(
              'aboutMe'.tr(), 
              user.aboutMe?.isNotEmpty == true ? user.aboutMe! : 'noAboutMe'.tr(),
            ),
            const SizedBox(height: 12),
            
            // Seviye
            _buildInfoRow('level'.tr(), user.level),
            const SizedBox(height: 12),
            
            // Katılma tarihi
            if (user.createdAt.isNotEmpty)
              _buildInfoRow(
                'joinDate'.tr(), 
                _formatDate(user.createdAt),
              ),
          ],
        ),
      ),
    );
  }

  // Sosyal medya kartı
  Widget _buildSocialMediaCard(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'socialMedia'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.socialLinks);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSocialLinks(user),
          ],
        ),
      ),
    );
  }

  // Hesap işlemleri kartı
  Widget _buildAccountActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'accountActions'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Premium'a yükselt
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: Text('upgradeToPremium'.tr()),
              subtitle: Text('unlockAllFeatures'.tr()),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.pushNamed(context, AppRoutes.premium),
            ),
            
            const Divider(),
            
            // Çıkış yap
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: Text('signOut'.tr()),
              subtitle: Text('signOutFromAccount'.tr()),
              onTap: () => _showSignOutDialog(),
            ),
          ],
        ),
      ),
    );
  }

  // Bilgi satırı
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Sosyal medya bağlantıları
  Widget _buildSocialLinks(UserModel user) {
    final socialLinks = user.socialLinks ?? {};
    
    if (socialLinks.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.link_off, color: Colors.grey.shade400, size: 40),
            const SizedBox(height: 8),
            Text(
              'noSocialLinks'.tr(),
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        if (socialLinks.containsKey('instagram'))
          _buildSocialLinkTile(
            'Instagram',
            socialLinks['instagram']!,
            Icons.camera_alt,
            Colors.pink,
          ),
        if (socialLinks.containsKey('twitter'))
          _buildSocialLinkTile(
            'Twitter',
            socialLinks['twitter']!,
            Icons.alternate_email,
            Colors.blue,
          ),
        if (socialLinks.containsKey('facebook'))
          _buildSocialLinkTile(
            'Facebook',
            socialLinks['facebook']!,
            Icons.facebook,
            Colors.indigo,
          ),
        if (socialLinks.containsKey('spotify'))
          _buildSocialLinkTile(
            'Spotify',
            socialLinks['spotify']!,
            Icons.music_note,
            Colors.green,
          ),
        if (socialLinks.containsKey('bluesky'))
          _buildSocialLinkTile(
            'Bluesky',
            socialLinks['bluesky']!,
            Icons.cloud,
            Colors.lightBlue,
          ),
      ],
    );
  }
  
  // Sosyal medya bağlantısı
  Widget _buildSocialLinkTile(String name, String username, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, color: color),
      ),
      title: Text(name),
      subtitle: Text(username),
      trailing: const Icon(Icons.open_in_new),
      onTap: () {
        // TODO: Sosyal medya bağlantısını aç
      },
    );
  }

  // Çıkış yap dialog'u
  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('signOut'.tr()),
        content: Text('signOutConfirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('signOut'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Tarih formatla
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}