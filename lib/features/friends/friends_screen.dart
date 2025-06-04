// Dosya: lib/features/friends/friends_screen.dart
// Yol: C:\src\zikirmo_new\lib\features\friends\friends_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/guards/email_verification_guard.dart';
import '../../routes.dart';

// Arkadaş listesini getiren provider
final friendsProvider = FutureProvider<List<UserModel>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userId = authService.currentUser?.uid;
  
  if (userId == null) return [];
  
  return await firestoreService.getFriends(userId);
});

// Arkadaşlık isteklerini getiren provider
final friendRequestsProvider = FutureProvider<List<UserModel>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userId = authService.currentUser?.uid;
  
  if (userId == null) return [];
  
  return await firestoreService.getFriendRequests(userId);
});

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkEmailVerification();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Email doğrulama durumunu kontrol et
  void _checkEmailVerification() {
    final authStateAsync = ref.read(authStateProvider);
    authStateAsync.whenData((user) {
      if (mounted) {
        setState(() {
          _isEmailVerified = user?.emailVerified ?? false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final friendRequestsAsync = ref.watch(friendRequestsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('friends'.tr()),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            tooltip: 'searchUsers'.tr(),
            onPressed: () {
              if (_isEmailVerified) {
                Navigator.pushNamed(context, AppRoutes.userSearch);
              } else {
                EmailVerificationDialog.show(
                  context,
                  customMessage: 'searchUsersRequiresVerification'.tr(),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Email doğrulama banner'ı
          const EmailVerificationBanner(),
          
          // Email doğrulanmamışsa kısıtlama mesajı
          if (!_isEmailVerified) _buildRestrictedAccessBanner(),
          
          // Tab bar
          Container(
            color: Theme.of(context).primaryColor,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: 'friends'.tr()),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('friendRequests'.tr()),
                      const SizedBox(width: 4),
                      friendRequestsAsync.when(
                        data: (requests) => requests.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  requests.length.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : const SizedBox(),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tab içerikleri
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (_isEmailVerified) {
                  ref.refresh(friendsProvider);
                  ref.refresh(friendRequestsProvider);
                }
              },
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Arkadaşlar tab'ı
                  _isEmailVerified 
                    ? friendsAsync.when(
                        data: (friends) => friends.isEmpty
                            ? _buildEmptyState(
                                context,
                                Icons.people,
                                'noFriendsYet'.tr(),
                                'addFriendsToSeeThemHere'.tr(),
                              )
                            : _buildFriendsList(context, ref, friends),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => Center(
                          child: Text('errorLoadingFriends'.tr()),
                        ),
                      )
                    : _buildVerificationRequiredState(),
                  
                  // İstekler tab'ı
                  _isEmailVerified
                    ? friendRequestsAsync.when(
                        data: (requests) => requests.isEmpty
                            ? _buildEmptyState(
                                context,
                                Icons.inbox,
                                'noFriendRequests'.tr(),
                                'friendRequestsWillAppearHere'.tr(),
                              )
                            : _buildRequestsList(context, ref, requests),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => Center(
                          child: Text('errorLoadingFriendRequests'.tr()),
                        ),
                      )
                    : _buildVerificationRequiredState(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_isEmailVerified) {
            Navigator.pushNamed(context, AppRoutes.userSearch);
          } else {
            EmailVerificationDialog.show(
              context,
              customMessage: 'addFriendsRequiresVerification'.tr(),
            );
          }
        },
        tooltip: _isEmailVerified ? 'searchUsers'.tr() : 'verificationRequired'.tr(),
        backgroundColor: _isEmailVerified ? Theme.of(context).primaryColor : Colors.grey,
        child: Icon(
          _isEmailVerified ? Icons.person_add : Icons.lock,
          color: Colors.white,
        ),
      ),
    );
  }

  // Kısıtlı erişim banner'ı
  Widget _buildRestrictedAccessBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'friendsRequireVerification'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                Text(
                  'verifyToUseFriendFeatures'.tr(),
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/email_verification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text('verifyNow'.tr()),
          ),
        ],
      ),
    );
  }

  // Email doğrulama gerekli durumu
  Widget _buildVerificationRequiredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user,
              size: 80,
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'emailVerificationRequired'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'verifyToAccessFriends'.tr(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/email_verification'),
              icon: const Icon(Icons.email),
              label: Text('verifyEmailNow'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Boş durum widget'ı
  Widget _buildEmptyState(
    BuildContext context,
    IconData icon,
    String title,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.userSearch),
              icon: const Icon(Icons.person_add),
              label: Text('addFirstFriend'.tr()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Arkadaş listesi widget'ı
  Widget _buildFriendsList(
    BuildContext context,
    WidgetRef ref,
    List<UserModel> friends,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: friend.profileImageUrl?.isNotEmpty == true
                  ? NetworkImage(friend.profileImageUrl!)
                  : null,
              child: friend.profileImageUrl?.isEmpty != false
                  ? Text(
                      _getInitials(friend.nickname),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    friend.nickname,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (friend.isPremium) 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber.shade700,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Premium',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('level'.tr() + ': ${friend.level}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.emoji_events, size: 14, color: Colors.orange.shade600),
                    const SizedBox(width: 4),
                    Text('${friend.points} puan'),
                    const SizedBox(width: 16),
                    Icon(Icons.local_fire_department, size: 14, color: Colors.red.shade600),
                    const SizedBox(width: 4),
                    Text('${friend.currentStreak} gün'),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleFriendAction(context, ref, friend, value),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      Text('viewProfile'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'message',
                  child: Row(
                    children: [
                      const Icon(Icons.message),
                      const SizedBox(width: 8),
                      Text('sendMessage'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'gift',
                  child: Row(
                    children: [
                      const Icon(Icons.card_giftcard),
                      const SizedBox(width: 8),
                      Text('sendGift'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'dua',
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('sendDua'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clap',
                  child: Row(
                    children: [
                      const Icon(Icons.thumb_up, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('sendClap'.tr()),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(Icons.person_remove, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('removeFriend'.tr(), style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.friendProfile,
                arguments: friend.id,
              );
            },
          ),
        );
      },
    );
  }
  
  // Arkadaşlık istekleri listesi widget'ı
  Widget _buildRequestsList(
    BuildContext context,
    WidgetRef ref,
    List<UserModel> requests,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: request.profileImageUrl?.isNotEmpty == true
                  ? NetworkImage(request.profileImageUrl!)
                  : null,
              child: request.profileImageUrl?.isEmpty != false
                  ? Text(
                      _getInitials(request.nickname),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : null,
            ),
            title: Text(
              request.nickname,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text('friendRequestSent'.tr()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Kabul et butonu
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  tooltip: 'accept'.tr(),
                  onPressed: () => _acceptFriendRequest(context, ref, request.id),
                ),
                // Reddet butonu
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  tooltip: 'reject'.tr(),
                  onPressed: () => _rejectFriendRequest(context, ref, request.id),
                ),
              ],
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.friendProfile,
                arguments: request.id,
              );
            },
          ),
        );
      },
    );
  }
  
  // Arkadaş işlemlerini yönet
  void _handleFriendAction(
    BuildContext context,
    WidgetRef ref,
    UserModel friend,
    String action,
  ) async {
    switch (action) {
      case 'profile':
        Navigator.pushNamed(
          context,
          AppRoutes.friendProfile,
          arguments: friend.id,
        );
        break;
      case 'message':
        Navigator.pushNamed(
          context,
          AppRoutes.sendMessage,
          arguments: friend.id,
        );
        break;
      case 'gift':
        Navigator.pushNamed(
          context,
          AppRoutes.sendGift,
          arguments: friend.id,
        );
        break;
      case 'dua':
        await _sendDua(context, ref, friend);
        break;
      case 'clap':
        await _sendClap(context, ref, friend);
        break;
      case 'remove':
        await _removeFriend(context, ref, friend);
        break;
    }
  }

  // Dua gönder
  Future<void> _sendDua(BuildContext context, WidgetRef ref, UserModel friend) async {
    try {
      // TODO: Implement send dua functionality
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('duaSentTo'.tr(args: [friend.nickname]))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('errorSendingDua'.tr())),
      );
    }
  }

  // Alkış gönder
  Future<void> _sendClap(BuildContext context, WidgetRef ref, UserModel friend) async {
    try {
      // TODO: Implement send clap functionality
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('clapSentTo'.tr(args: [friend.nickname]))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('errorSendingClap'.tr())),
      );
    }
  }
  
  // Arkadaşlık isteğini kabul et
  Future<void> _acceptFriendRequest(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final authService = ref.read(authServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    final currentUserId = authService.currentUser?.uid;
    
    if (currentUserId == null) return;
    
    try {
      await firestoreService.acceptFriendRequest(currentUserId, userId);
      
      // Listeleri yenile
      ref.refresh(friendsProvider);
      ref.refresh(friendRequestsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('friendRequestAccepted'.tr())),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorAcceptingRequest'.tr())),
        );
      }
    }
  }
  
  // Arkadaşlık isteğini reddet
  Future<void> _rejectFriendRequest(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final authService = ref.read(authServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    final currentUserId = authService.currentUser?.uid;
    
    if (currentUserId == null) return;
    
    try {
      await firestoreService.rejectFriendRequest(currentUserId, userId);
      
      // İstekleri yenile
      ref.refresh(friendRequestsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('friendRequestRejected'.tr())),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorRejectingRequest'.tr())),
        );
      }
    }
  }
  
  // Arkadaşı kaldır
  Future<void> _removeFriend(
    BuildContext context,
    WidgetRef ref,
    UserModel friend,
  ) async {
    final authService = ref.read(authServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    final currentUserId = authService.currentUser?.uid;
    
    if (currentUserId == null) return;
    
    // Onay dialog'u
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('removeFriend'.tr()),
        content: Text('removeFriendConfirm'.tr(args: [friend.nickname])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('remove'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      await firestoreService.removeFriend(currentUserId, friend.id);
      
      // Arkadaş listesini yenile
      ref.refresh(friendsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('friendRemoved'.tr())),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorRemovingFriend'.tr())),
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