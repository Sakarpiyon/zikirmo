// friend_profile_screen.dart - v1.0.0
// Başka kullanıcıların profil ekranı
// Klasör: lib/features/profile/friend_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zikirmo_new/core/models/user_model.dart';
import 'package:zikirmo_new/core/services/auth_service.dart';
import 'package:zikirmo_new/core/services/firestore_service.dart';
import 'package:zikirmo_new/routes.dart';
import 'package:zikirmo_new/features/profile/components/badge_list.dart';

// Kullanıcı bilgilerini getiren provider
final otherUserProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getUser(userId);
});

// Arkadaş durumunu kontrol eden provider
final isFriendProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUserId = authService.currentUser?.uid;
  
  if (currentUserId == null) return false;
  
  final currentUser = await firestoreService.getUser(currentUserId);
  if (currentUser == null) return false;
  
  return currentUser.friends.contains(userId);
});

class FriendProfileScreen extends ConsumerWidget {
  final String userId;
  
  const FriendProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(otherUserProvider(userId));
    final isFriendAsync = ref.watch(isFriendProvider(userId));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'.tr()),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text('noUser'.tr()));
          }
          
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil başlığı
                  _buildProfileHeader(context, user),
                  const SizedBox(height: 24),
                  
                  // İstatistikler
                  _buildStatsCard(context, user),
                  const SizedBox(height: 24),
                  
                  // Rozetler
                  BadgeList(badges: user.badges),
                  const SizedBox(height: 24),
                  
                  // Kişisel bilgi
                  if (user.aboutMe != null && user.aboutMe!.isNotEmpty)
                    _buildAboutMeCard(context, user),
                    const SizedBox(height: 24),
                  
                  // Sosyal medya bağlantıları
                  if (user.socialLinks != null && user.socialLinks!.isNotEmpty)
                    _buildSocialLinksCard(context, user),
                    const SizedBox(height: 24),
                  
                  // Arkadaşlık butonu
                  isFriendAsync.when(
                    data: (isFriend) => _buildFriendshipButton(context, ref, isFriend),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                  ),
                  
                  // İletişim butonları
                  _buildCommunicationButtons(context),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('errorLoadingProfile'.tr()),
        ),
      ),
    );
  }
  
  // Profil başlığı
  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Kullanıcı avatarı
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(
                      _getInitials(user.nickname),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            
            // Kullanıcı adı ve Premium rozeti
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.nickname,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user.isPremium) 
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.verified,
                      color: Colors.amber[700],
                      size: 24,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Seviye bilgisi
            Text(
              'level'.tr(args: [user.level.tr()]),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            // Puan bilgisi
            Text(
              'points'.tr(args: [user.points.toString()]),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  // İstatistikler kartı
  Widget _buildStatsCard(BuildContext context, UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'statistics'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  context,
                  Icons.touch_app,
                  'totalZikirs'.tr(args: [user.totalZikirCount.toString()]),
                ),
                _buildStatItem(
                  context,
                  Icons.whatshot,
                  'currentStreak'.tr(args: [user.currentStreak.toString()]),
                ),
                _buildStatItem(
                  context,
                  Icons.emoji_events,
                  'badges'.tr(),
                  subtitle: user.badges.length.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // İstatistik öğesi
  Widget _buildStatItem(BuildContext context, IconData icon, String title, {String? subtitle}) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
  
  // Hakkında kartı
  Widget _buildAboutMeCard(BuildContext context, UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hakkında'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(user.aboutMe ?? ''),
          ],
        ),
      ),
    );
  }
  
  // Sosyal medya bağlantıları kartı
  Widget _buildSocialLinksCard(BuildContext context, UserModel user) {
    final socialLinks = user.socialLinks!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sosyal Medya'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
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
                Icons.mode_comment,
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
        ),
      ),
    );
  }
  
  // Sosyal medya bağlantı öğesi
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
  
  // Arkadaşlık butonu
  Widget _buildFriendshipButton(BuildContext context, WidgetRef ref, bool isFriend) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          final authService = ref.read(authServiceProvider);
          final firestoreService = ref.read(firestoreServiceProvider);
          final currentUserId = authService.currentUser?.uid;
          
          if (currentUserId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('pleaseLogin'.tr())),
            );
            return;
          }
          
          try {
            if (isFriend) {
              // Arkadaşlıktan çıkar
              await firestoreService.removeFriend(currentUserId, userId);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Arkadaşlıktan çıkarıldı'.tr())),
                );
              }
            } else {
              // Arkadaş ekle
              await firestoreService.addFriend(currentUserId, userId);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Arkadaş olarak eklendi'.tr())),
                );
              }
            }
            
            // Arkadaşlık durumunu yenile
            ref.refresh(isFriendProvider(userId));
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Bir hata oluştu'.tr())),
              );
            }
          }
        },
        icon: Icon(isFriend ? Icons.person_remove : Icons.person_add),
        label: Text(isFriend ? 'Arkadaşlıktan Çıkar'.tr() : 'Arkadaş Ekle'.tr()),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFriend ? Colors.red : Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
  
  // İletişim butonları
  Widget _buildCommunicationButtons(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İletişim'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context, 
                  Icons.message,
                  'Mesaj Gönder'.tr(),
                  () {
                    // TODO: Mesaj gönderme sayfasına git
                  },
                ),
                _buildActionButton(
                  context, 
                  Icons.card_giftcard,
                  'Hediye Gönder'.tr(),
                  () {
                    // TODO: Hediye gönderme sayfasına git
                  },
                ),
                _buildActionButton(
                  context, 
                  Icons.share,
                  'Profili Paylaş'.tr(),
                  () {
                    // TODO: Profil paylaşma işlemi
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Aksiyon butonu
  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 28),
          color: Theme.of(context).primaryColor,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  // İsmin baş harflerini al
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    
    final nameParts = name.split(' ');
    String initials = '';
    
    for (var part in nameParts) {
      if (part.isNotEmpty) {
        initials += part[0].toUpperCase();
        if (initials.length >= 2) break;
      }
    }
    
    return initials;
  }
}