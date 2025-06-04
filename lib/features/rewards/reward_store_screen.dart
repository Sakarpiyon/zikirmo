import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/providers.dart';

final rewardsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final snapshot = await firestoreService.firestore.collection('rewards').get();
  return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
});

class RewardStoreScreen extends ConsumerWidget {
  const RewardStoreScreen({super.key});

  Future<void> _purchaseReward(BuildContext context, WidgetRef ref, String userId, Map<String, dynamic> reward) async {
    final user = ref.read(userProvider).value;
    if (user == null || user.points < reward['cost']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yetersiz puan')),
      );
      return;
    }

    final firestoreService = ref.read(firestoreServiceProvider);
    await firestoreService.updateUser(userId, {
      'points': user.points - reward['cost'], // FieldValue yerine manual hesaplama
    });

    // Satın alınan ürünü kullanıcıya ekle
    final purchasedItems = List<String>.from(user.toJson()[reward['type']] ?? []);
    purchasedItems.add(reward['id']);
    
    await firestoreService.updateUser(userId, {
      reward['type']: purchasedItems,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${reward['name']} satın alındı!')),
    );
    
    // Provider'ı yenile
    ref.refresh(userProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final rewardsAsync = ref.watch(rewardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ödül Mağazası'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text('Lütfen giriş yapın'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puanlarınız: ${user.points}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: rewardsAsync.when(
                    data: (rewards) => rewards.isEmpty
                        ? Center(child: Text('Henüz ödül yok'))
                        : ListView.builder(
                            itemCount: rewards.length,
                            itemBuilder: (context, index) {
                              final reward = rewards[index];
                              final isOwned = user.toJson()[reward['type']]?.contains(reward['id']) ?? false;
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Icon(_getRewardIcon(reward['type'])),
                                  title: Text(reward['name']),
                                  subtitle: Text('Maliyet: ${reward['cost']} puan'),
                                  trailing: isOwned
                                      ? Chip(
                                          label: Text('Sahip'),
                                          backgroundColor: Colors.green[100],
                                        )
                                      : ElevatedButton(
                                          onPressed: user.points >= reward['cost']
                                              ? () => _purchaseReward(context, ref, user.id, reward)
                                              : null,
                                          child: Text('Satın Al'),
                                        ),
                                ),
                              );
                            },
                          ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text('Ödüller yüklenirken hata oluştu')),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Kullanıcı bilgileri yüklenirken hata oluştu')),
      ),
    );
  }

  IconData _getRewardIcon(String type) {
    switch (type) {
      case 'themes':
        return Icons.color_lens;
      case 'ringtones':
        return Icons.music_note;
      case 'avatars':
        return Icons.person;
      default:
        return Icons.card_giftcard;
    }
  }
}