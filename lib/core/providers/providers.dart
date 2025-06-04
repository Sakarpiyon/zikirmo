// Dosya: lib/core/providers/providers.dart
// Yol: C:\src\zikirmo_new\lib\core\providers\providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';
import '../services/purchase_service.dart';
import '../models/user_model.dart';
import '../models/zikir_model.dart';
import '../models/category_model.dart';
import 'theme_provider.dart';

// =====================================
// SERVICE PROVIDERS
// =====================================

// Analytics Service Provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

// Firestore Service Provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final analyticsService = ref.watch(analyticsServiceProvider);
  
  return AuthService(
    firestoreService: firestoreService,
    analyticsService: analyticsService,
  );
});

// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Purchase Service Provider
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return PurchaseService(authService);
});

// Haptic Service Provider
final hapticServiceProvider = Provider<HapticService>((ref) {
  return HapticService();
});

// =====================================
// AUTH PROVIDERS
// =====================================

// Auth state provider - Firebase User stream
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Kullanıcının email doğrulama durumunu kontrol eden provider
final isEmailVerifiedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user?.emailVerified ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Premium durumu kontrol eden provider
final isPremiumProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.checkIfUserIsPremium();
});

// =====================================
// USER PROVIDERS
// =====================================

// Kullanıcı bilgilerini getiren provider
final userProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userId = authService.currentUser?.uid;
  
  if (userId == null) return null;
  
  return await firestoreService.getUser(userId);
});

// Diğer kullanıcı bilgilerini getiren provider (family)
final otherUserProviderFamily = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getUser(userId);
});

// Kullanıcı istatistiklerini getiren provider
final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userId = authService.currentUser?.uid;
  
  if (userId == null) return {};
  
  return await firestoreService.getUserStats(userId);
});

// =====================================
// ZIKIR PROVIDERS
// =====================================

// Tüm zikirleri getiren provider
final zikirsProvider = FutureProvider<List<ZikirModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  // getZikirs() metodu eksikti, getPopularZikirs() ile değiştirdik
  return await firestoreService.getPopularZikirs(limit: 50);
});

// Belirli bir zikiri getiren provider (family)
final zikirProviderFamily = FutureProvider.family<ZikirModel?, String>((ref, zikirId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getZikir(zikirId);
});

// Popüler zikirleri getiren provider
final popularZikirsProvider = FutureProvider<List<ZikirModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getPopularZikirs();
});

// Önerilen zikirleri getiren provider
final suggestedZikirsProvider = FutureProvider<List<ZikirModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getSuggestedZikirs();
});

// Zikir sayacı provider
final zikirCounterProvider = StateNotifierProvider<ZikirCounterNotifier, int>((ref) {
  return ZikirCounterNotifier();
});

// =====================================
// CATEGORY PROVIDERS
// =====================================

// Tüm kategorileri getiren provider
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getCategories();
});

// Belirli bir kategoriyi getiren provider (family)
final categoryProviderFamily = FutureProvider.family<CategoryModel?, String>((ref, categoryId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getCategory(categoryId);
});

// Kategoriye göre zikirleri getiren provider (family)
final zikirsByCategoryProvider = FutureProvider.family<List<ZikirModel>, String>((ref, categoryId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getZikirsByCategory(categoryId);
});

// =====================================
// FRIEND PROVIDERS
// =====================================

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

// Liderlik tablosunu getiren provider
final leaderboardProvider = FutureProvider<List<UserModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getLeaderboard('weekly'); // Varsayılan olarak haftalık
});

// =====================================
// STATE NOTIFIERS
// =====================================

// Zikir sayacı state notifier
class ZikirCounterNotifier extends StateNotifier<int> {
  ZikirCounterNotifier() : super(0);

  void increment() {
    state++;
  }

  void reset() {
    state = 0;
  }

  void setCount(int count) {
    state = count;
  }
}

// Haptic Service (basit implementation)
class HapticService {
  Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Haptic feedback error: $e');
    }
  }

  Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Haptic feedback error: $e');
    }
  }

  Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Haptic feedback error: $e');
    }
  }

  Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Haptic feedback error: $e');
    }
  }
}