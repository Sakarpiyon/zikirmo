// Dosya: lib/features/friends/friend_profile_screen.dart
// Yol: C:\src\zikirmo_new\lib\features\friends\friend_profile_screen.dart
// Açıklama: Arkadaş profil ekranı - doğru konuma taşındı ve i18n düzeltildi

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/providers/providers.dart';
import '../../routes.dart';
import '../profile/components/badge_list.dart';

class FriendProfileScreen extends ConsumerWidget {
  final String userId;
  
  const FriendProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(otherUserProviderFamily(userId));
    final isFriendAsync = ref.watch(_isFriendProvider(userId));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context, ref),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text('userNotFound'.tr()));
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
                  
                  // Hakkında bölümü
                  if (user.aboutMe != null && user.aboutMe!.isNotEmpty)
                    _buildAboutSection(context, user),
                  
                  const SizedBox(height: 24),
                  
                  // Arkadaşlık butonu
                  isFriendAsync.when(
                    data: (isFriend) => _buildFriendshipButton(context, ref, isFriend),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                  ),
                  
                  const SizedBox(height: 16),
                  
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
              'userLevel'.tr(args: [user.level.tr()]),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            // Puan bilgisi
            Text(
              'userPoints'.tr(args: [user.points.toString()]),
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
                  'totalZikirs'.tr(),
                  user.totalZikirCount.toString(),
                ),
                _buildStatItem(
                  context,
                  Icons.whatshot,
                  'currentStreak'.tr(),
                  user.currentStreak.toString(),
                ),
                _buildStatItem(
                  context,
                  Icons.emoji_events,
                  'badges'.tr(),
                  user.badges.length.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // İstatistik öğesi
  Widget _buildStatItem(BuildContext context, IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  // Hakkında bölümü
  Widget _buildAboutSection(BuildContext context, UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'aboutMe'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(user.aboutMe ?? ''),
          ],
        ),
      ),
    );
  }
  
  // Arkadaşlık butonu
  Widget _buildFriendshipButton(BuildContext context, WidgetRef ref, bool isFriend) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => _toggleFriendship(context, ref, isFriend),
        icon: Icon(isFriend ? Icons.person_remove : Icons.person_add),
        label: Text(isFriend ? 'removeFriend'.tr() : 'addFriend'.tr()),
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
              'communication'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context, 
                  Icons.message,
                  'sendMessage'.tr(),
                  () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.sendMessage,
                      arguments: userId,
                    );
                  },
                ),
                _buildActionButton(
                  context, 
                  Icons.card_giftcard,
                  'sendGift'.tr(),
                  () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.sendGift,
                      arguments: userId,
                    );
                  },
                ),
                _buildActionButton(
                  context, 
                  Icons.share,
                  'shareProfile'.tr(),
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('shareFeatureComingSoon'.tr())),
                    );
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
  
  // Seçenekler menüsü
  void _showOptionsMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.block),
                title: Text('blockUser'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('blockFeatureComingSoon'.tr())),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.report),
                title: Text('reportUser'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('reportFeatureComingSoon'.tr())),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Arkadaşlık durumunu değiştir
  Future<void> _toggleFriendship(BuildContext context, WidgetRef ref, bool isFriend) async {
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
        await firestoreService.removeFriend(currentUserId, userId);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('friendRemoved'.tr())),
          );
        }
      } else {
        await firestoreService.addFriend(currentUserId, userId);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('friendRequestSent'.tr())),
          );
        }
      }
      
      // Arkadaşlık durumunu yenile
      ref.refresh(_isFriendProvider(userId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('operationFailed'.tr())),
        );
      }
    }
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

// Arkadaş durumu provider'ı
final _isFriendProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUserId = authService.currentUser?.uid;
  
  if (currentUserId == null) return false;
  
  final currentUser = await firestoreService.getUser(currentUserId);
  if (currentUser == null) return false;
  
  return currentUser.friends.contains(userId);
});