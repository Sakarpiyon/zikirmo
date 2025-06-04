// user_search_screen.dart - v1.0.0
// Kullanıcı arama ekranı
// Klasör: lib/features/friends/user_search_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import 'package:zikirmo_new/core/models/user_model.dart';
import 'package:zikirmo_new/core/services/auth_service.dart';
import 'package:zikirmo_new/core/services/firestore_service.dart';
import 'package:zikirmo_new/routes.dart';

// Arama sonuçları provider'ı
final searchResultsProvider = StateProvider<List<UserModel>>((ref) => []);

// Ülke filtresi provider'ı
final countryFilterProvider = StateProvider<String?>((ref) => null);

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Kullanıcı arama
  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final countryFilter = ref.read(countryFilterProvider);
      
      // Arama yap
      final results = await firestoreService.searchUsers(
        query,
        countryFilter: countryFilter,
      );
      
      // Arama sonuçlarını güncelle
      ref.read(searchResultsProvider.notifier).state = results;
    } catch (e) {
      // Hata durumunda boş liste döndür
      ref.read(searchResultsProvider.notifier).state = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final countryFilter = ref.watch(countryFilterProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Kullanıcı Ara'.tr()),
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'searchUser'.tr(),
                      hintText: 'E-posta, isim veya takma isim'.tr(),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _searchUsers(),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _searchUsers,
                  icon: const Icon(Icons.search),
                  tooltip: 'Ara'.tr(),
                ),
              ],
            ),
          ),
          
          // Filtreler
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text('Filtreler:'.tr()),
                const SizedBox(width: 8),
                
                // Ülke filtresi
                DropdownButton<String?>(
                  value: countryFilter,
                  hint: Text('Ülke'.tr()),
                  onChanged: (value) {
                    ref.read(countryFilterProvider.notifier).state = value;
                  },
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tümü'),
                    ),
                    const DropdownMenuItem(
                      value: 'TR',
                      child: Text('Türkiye'),
                    ),
                    const DropdownMenuItem(
                      value: 'US',
                      child: Text('Amerika Birleşik Devletleri'),
                    ),
                    // Diğer ülkeler eklenebilir
                  ],
                ),
              ],
            ),
          ),
          
          // Yükleniyor göstergesi
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          
          // Arama sonuçları
          Expanded(
            child: searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Kullanıcı aramak için yukarıdaki arama çubuğunu kullanın.'.tr()
                          : 'noUsersFound'.tr(),
                    ),
                  )
                : ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final user = searchResults[index];
                      return _buildUserListItem(context, user);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  // Kullanıcı liste öğesi
  Widget _buildUserListItem(BuildContext context, UserModel user) {
    final authService = ref.read(authServiceProvider);
    final currentUserId = authService.currentUser?.uid;
    
    // Kullanıcı kendisi mi?
    final isSelf = currentUserId == user.id;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          backgroundImage: user.profileImageUrl != null
              ? NetworkImage(user.profileImageUrl!)
              : null,
          child: user.profileImageUrl == null
              ? Text(
                  _getInitials(user.nickname),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Text(user.nickname),
            if (user.isPremium) 
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Icon(
                  Icons.verified,
                  color: Colors.amber[700],
                  size: 16,
                ),
              ),
          ],
        ),
        subtitle: Text('level'.tr(args: [user.level.tr()])),
        trailing: isSelf
            ? const Chip(
                label: Text('Siz'),
                backgroundColor: Colors.grey,
              )
            : IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: 'addFriend'.tr(),
                onPressed: () => _addFriend(user.id),
              ),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.friendProfile,
            arguments: user.id,
          );
        },
      ),
    );
  }
  
  // Arkadaş ekleme
  Future<void> _addFriend(String userId) async {
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
      await firestoreService.addFriend(currentUserId, userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('friendAdded'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorAddingFriend'.tr())),
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
