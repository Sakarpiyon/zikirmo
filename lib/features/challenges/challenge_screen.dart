// Dosya: lib/features/challenges/challenge_screen.dart
// Açıklama: Zorlukları listeler ve başlatmayı sağlar.
// Klasör: lib/features/challenges

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';

final challengesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final firestoreService = FirestoreService();
  final snapshot = await firestoreService.firestore.collection('challenges').get();
  return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
});

final userChallengesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final firestoreService = FirestoreService();
  final snapshot = await firestoreService.firestore
      .collection('user_challenges')
      .where('userId', isEqualTo: userId)
      .get();
  return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
});

class ChallengeScreen extends ConsumerWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(challengesProvider);
    final authService = ref.watch(authServiceProvider);
    final userId = authService.currentUser?.uid ?? '';
    final userChallengesAsync = ref.watch(userChallengesProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('challenges'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: challengesAsync.when(
          data: (challenges) => userChallengesAsync.when(
            data: (userChallenges) => challenges.isEmpty
                ? Center(child: Text('noChallenges'.tr()))
                : ListView.builder(
                    itemCount: challenges.length,
                    itemBuilder: (context, index) {
                      final challenge = challenges[index];
                      final userChallenge = userChallenges.firstWhere(
                        (uc) => uc['challengeId'] == challenge['id'],
                        orElse: () => {},
                      );
                      final isActive = userChallenge.isNotEmpty;
                      final isCompleted = isActive && userChallenge['completed'] == true;
                      final progress = isActive ? userChallenge['progress'] ?? 0 : 0;
                      return Card(
                        elevation: 4,
                        child: ListTile(
                          title: Text(challenge['name']),
                          subtitle: Text(isActive
                              ? 'progress'.tr(args: ['$progress/${challenge['targetZikirCount']}'])
                              : challenge['description']),
                          trailing: isCompleted
                              ? Text('completed'.tr())
                              : isActive
                                  ? Text('active'.tr())
                                  : ElevatedButton(
                                      onPressed: () async {
                                        final firestoreService = FirestoreService();
                                        await firestoreService.startChallenge(userId, challenge['id']);
                                        ref.invalidate(userChallengesProvider);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('challengeStarted'.tr())),
                                        );
                                      },
                                      child: Text('startChallenge'.tr()),
                                    ),
                        ),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('errorLoadingChallenges'.tr())),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('errorLoadingChallenges'.tr())),
        ),
      ),
    );
  }
}

// Dosya Sonu: lib/features/challenges/challenge_screen.dart
