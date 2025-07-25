﻿// Dosya: lib/features/leaderboard/leaderboard_screen.dart
// Açıklama: Günlük, haftalık, aylık ve arkadaş grupları için lider tablolarını gösterir.
// Klasör: lib/features/leaderboard

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import 'package:zikirmo_new/core/models/user_model.dart';
import 'package:zikirmo_new/core/services/auth_service.dart';
import 'package:zikirmo_new/core/services/firestore_service.dart';
import 'package:zikirmo_new/core/config/theme_config.dart';

// Lider tablosu provider
final leaderboardProvider = FutureProvider.family<List<UserModel>, String>((ref, period) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getLeaderboard(period);
});

// Arkadaş lider tablosu provider
final friendsLeaderboardProvider = FutureProvider<List<UserModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userId = ref.watch(authServiceProvider).currentUser?.uid;
  if (userId == null) return [];
  return await firestoreService.getFriends(userId);
});

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  String _selectedPeriod = 'weekly';
  late TabController _tabController;
  int _selectedTabIndex = 0;
  
  // Medaller için renkler
  final List<Color> _medalColors = [
    const Color(0xFFFFD700), // Altın
    const Color(0xFFC0C0C0), // Gümüş
    const Color(0xFFCD7F32), // Bronz
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider(_selectedPeriod));
    final friendsLeaderboardAsync = ref.watch(friendsLeaderboardProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('leaderboard'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'topUsers'.tr()),
            Tab(text: 'friendsLeaderboard'.tr()),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Süre filtresi
          if (_selectedTabIndex == 0) // Sadece genel tabloda göster
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildPeriodFilter(),
            ),
          
          // Lider tablosu içeriği
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Genel lider tablosu
                leaderboardAsync.when(
                  data: (users) => _buildLeaderboardList(users),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('errorLoadingLeaderboard'.tr()),
                  ),
                ),
                
                // Arkadaşlar lider tablosu
                friendsLeaderboardAsync.when(
                  data: (friends) => _buildLeaderboardList(friends),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('errorLoadingFriends'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Süre filtresi widget'ı
  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'period'.tr() + ':',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip('daily'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('weekly'),
                  const SizedBox(width: 8),
                  _buildPeriodChip('monthly'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Süre filtresi seçimi widget'ı
  Widget _buildPeriodChip(String period) {
    final isSelected = _selectedPeriod == period;
    
    return FilterChip(
      label: Text(period.tr()),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPeriod = period;
        });
      },
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: ThemeConfig.primaryColor.withOpacity(0.2),
      checkmarkColor: ThemeConfig.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? ThemeConfig.primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
  
  // Lider tablosu listesi
  Widget _buildLeaderboardList(List<UserModel> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.leaderboard, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _selectedTabIndex == 0 ? 'noUsers'.tr() : 'noFriends'.tr(),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Puanlarına göre kullanıcıları sırala
    users.sort((a, b) => b.points.compareTo(a.points));
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length + 1, // +1 başlık için
      itemBuilder: (context, index) {
        // Başlık satırı
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40), // Sıra numarası için boşluk
                Expanded(
                  flex: 2,
                  child: Text(
                    'user'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'points'.tr(args: ['']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'level'.tr(args: ['']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }
        
        final userIndex = index - 1; // Başlık satırını çıkar
        final user = users[userIndex];
        final isCurrentUser = user.id == ref.read(authServiceProvider).currentUser?.uid;
        
        // Kullanıcı sırası 
        final rank = userIndex + 1;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isCurrentUser 
                ? ThemeConfig.primaryColor.withOpacity(0.1)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: isCurrentUser
                ? Border.all(color: ThemeConfig.primaryColor, width: 1.5)
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: _buildRankWidget(rank),
            title: Row(
              children: [
                // Kullanıcı adı ve premium işareti
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getAvatarColor(user.nickname),
                        radius: 18,
                        child: Text(
                          user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.nickname,
                                    style: TextStyle(
                                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (user.isPremium) 
                                  const Icon(
                                    Icons.verified,
                                    color: ThemeConfig.primaryColor,
                                    size: 16,
                                  ),
                              ],
                            ),
                            if (isCurrentUser)
                              Text(
                                'you'.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ThemeConfig.primaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Puan
                Expanded(
                  child: Text(
                    user.points.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser ? ThemeConfig.primaryColor : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Seviye
                Expanded(
                  child: Text(
                    user.level.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isCurrentUser ? ThemeConfig.primaryColor : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            onTap: () {
              // Kullanıcı profiline git veya detay göster
              if (user.id == ref.read(authServiceProvider).currentUser?.uid) {
                Navigator.pushNamed(context, '/profile');
              } else {
                _showUserDetailDialog(user);
              }
            },
          ),
        );
      },
    );
  }
  
  // Sıralama widget'ı (madalya veya numara)
  Widget _buildRankWidget(int rank) {
    // İlk 3 için madalya
    if (rank <= 3) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _medalColors[rank - 1].withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.emoji_events,
            color: _medalColors[rank - 1],
            size: 24,
          ),
        ),
      );
    }
    
    // Diğerleri için sıra numarası
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          rank.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ),
    );
  }
  
  // Kullanıcı detay diyaloğu
  void _showUserDetailDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Üst kısım (arka plan ve avatar)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeConfig.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 40,
                      child: Text(
                        user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _getAvatarColor(user.nickname),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.nickname,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (user.isPremium) 
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.level.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Alt kısım (istatistikler)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildUserStat(
                      Icons.grade,
                      'points'.tr(args: [user.points.toString()]),
                    ),
                    const SizedBox(height: 12),
                    _buildUserStat(
                      Icons.auto_awesome,
                      'totalZikirs'.tr(args: [user.totalZikirCount.toString()]),
                    ),
                    const SizedBox(height: 12),
                    _buildUserStat(
                      Icons.whatshot,
                      'currentStreak'.tr(args: [user.currentStreak.toString()]),
                    ),
                    const SizedBox(height: 12),
                    _buildUserStat(
                      Icons.badge,
                      'badges'.tr() + ': ' + user.badges.length.toString(),
                    ),
                  ],
                ),
              ),
              
              // Aksiyon butonları
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Arkadaş ekleme/çıkarma butonu
                    _buildActionButton(
                      _isUserFriend(user.id) ? Icons.person_remove : Icons.person_add,
                      _isUserFriend(user.id) ? 'removeFriend'.tr() : 'addFriend'.tr(),
                      () => _toggleFriendship(user.id),
                    ),
                    
                    // Dua gönderme butonu
                    _buildActionButton(
                      Icons.favorite,
                      'sendDua'.tr(),
                      () => _sendDua(user.id),
                    ),
                    
                    // Alkış gönderme butonu
                    _buildActionButton(
                      Icons.emoji_events,
                      'sendClap'.tr(),
                      () => _sendClap(user.id),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('close'.tr()),
            ),
          ],
        );
      },
    );
  }
  
  // Kullanıcı istatistiği widget'ı
  Widget _buildUserStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: ThemeConfig.primaryColor, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
  
  // Aksiyon butonu widget'ı
  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: ThemeConfig.primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Kullanıcının arkadaş olup olmadığını kontrol et
  bool _isUserFriend(String userId) {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return false;
    
    final friendsAsync = ref.read(friendsLeaderboardProvider);
    return friendsAsync.maybeWhen(
      data: (friends) => friends.any((friend) => friend.id == userId),
      orElse: () => false,
    );
  }
  
  // Arkadaşlık durumunu değiştir
  Future<void> _toggleFriendship(String friendId) async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) {
      _showAuthError();
      return;
    }
    
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final isFriend = _isUserFriend(friendId);
      
      if (isFriend) {
        await firestoreService.removeFriend(currentUser.uid, friendId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('friendRemoved'.tr())),
          );
        }
      } else {
        final user = await firestoreService.getUser(currentUser.uid);
        if (user != null && !user.canAddMoreFriends() && !user.isPremium) {
          if (mounted) {
            Navigator.pop(context);
            _showPremiumRequiredDialog('friendLimitReached'.tr());
          }
          return;
        }
        
        await firestoreService.addFriend(currentUser.uid, friendId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('friendAdded'.tr())),
          );
        }
      }
      
      // Arkadaş listesini yenile
      ref.refresh(friendsLeaderboardProvider);
      
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorFriendAction'.tr())),
        );
      }
    }
  }
  
  // Dua gönder
  Future<void> _sendDua(String receiverId) async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) {
      _showAuthError();
      return;
    }
    
    try {
      // Burada dua gönderme işlemi yapılabilir
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('duaSent'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorSendingDua'.tr())),
        );
      }
    }
  }
  
  // Alkış gönder
  Future<void> _sendClap(String receiverId) async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) {
      _showAuthError();
      return;
    }
    
    try {
      // Burada alkış gönderme işlemi yapılabilir
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('clapSent'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorSendingClap'.tr())),
        );
      }
    }
  }
  
  // Yetkilendirme hatası
  void _showAuthError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('pleaseLogin'.tr())),
    );
  }
  
  // Premium gerektiği durumda dialog göster
  void _showPremiumRequiredDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('premiumRequired'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/membership_info');
            },
            child: Text('upgradeToPremium'.tr()),
          ),
        ],
      ),
    );
  }
  
  // Avatar arka plan rengi oluştur
  Color _getAvatarColor(String nickname) {
    if (nickname.isEmpty) return ThemeConfig.primaryColor;
    
    // Hash kodu kullanarak tutarlı renk oluştur
    final int hash = nickname.codeUnits.fold(0, (prev, element) => prev + element);
    final colors = [
      Colors.teal,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.green,
      Colors.amber,
      Colors.deepOrange,
      Colors.lightBlue,
      Colors.lime,
      Colors.cyan,
    ];
    
    return colors[hash % colors.length];
  }
}

// Dosya Sonu: lib/features/leaderboard/leaderboard_screen.dart

