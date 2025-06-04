// Dosya: lib/core/services/firestore_service.dart
// Yol: C:\src\zikirmo_new\lib\core\services\firestore_service.dart
// Açıklama: getZikirs() metodu eklendi ve diğer eksik methodlar tamamlandı

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/zikir_model.dart';
import '../models/category_model.dart';
import '../models/user_zikir_model.dart';
import '../models/friend_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get firestore => _firestore;

  // ==================== KULLANICI İŞLEMLERİ ====================
  
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? UserModel.fromJson(doc.data() ?? {}, userId) : null;
    } catch (e) {
      print('getUser error: $e');
      return null;
    }
  }

  Future<bool> createOrUpdateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('createOrUpdateUser error: $e');
      return false;
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      print('updateUser error: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _deleteUserSubcollections(userId);
      await _firestore.collection('users').doc(userId).delete();
      return true;
    } catch (e) {
      print('deleteUser error: $e');
      return false;
    }
  }

  Future<void> _deleteUserSubcollections(String userId) async {
    try {
      final userZikirs = await _firestore.collection('users').doc(userId).collection('user_zikirs').get();
      for (var doc in userZikirs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('_deleteUserSubcollections error: $e');
      throw e;
    }
  }

  // ==================== ZİKİR İŞLEMLERİ ====================

  // Tüm zikirleri getir - EKSİK OLAN METOD
  Future<List<ZikirModel>> getZikirs({int? limit}) async {
    try {
      Query query = _firestore.collection('zikirler')
          .where('isActive', isEqualTo: true)
          .orderBy('popularity', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => ZikirModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('getZikirs error: $e');
      return [];
    }
  }

  Future<List<ZikirModel>> getPopularZikirs({int limit = 5}) async {
    try {
      final snapshot = await _firestore.collection('zikirler')
          .orderBy('popularity', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => ZikirModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('getPopularZikirs error: $e');
      return [];
    }
  }

  Future<List<ZikirModel>> getSuggestedZikirs({int limit = 10}) async {
    try {
      final now = DateTime.now();
      final weekday = now.weekday;
      
      final snapshot = await _firestore.collection('zikirler')
          .where('suggestedDays', arrayContains: weekday)
          .limit(limit)
          .get();
      
      if (snapshot.docs.length < limit) {
        final additionalSnapshot = await _firestore.collection('zikirler')
            .orderBy('popularity', descending: true)
            .limit(limit - snapshot.docs.length)
            .get();
        
        final result = snapshot.docs.map((doc) => ZikirModel.fromMap(doc.id, doc.data())).toList();
        result.addAll(additionalSnapshot.docs.map((doc) => ZikirModel.fromMap(doc.id, doc.data())));
        return result;
      }
      
      return snapshot.docs.map((doc) => ZikirModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('getSuggestedZikirs error: $e');
      return [];
    }
  }

  Future<ZikirModel?> getZikir(String zikirId) async {
    try {
      final doc = await _firestore.collection('zikirler').doc(zikirId).get();
      return doc.exists ? ZikirModel.fromMap(doc.id, doc.data() ?? {}) : null;
    } catch (e) {
      print('getZikir error: $e');
      return null;
    }
  }

  Future<bool> updateZikirPopularity(String zikirId) async {
    try {
      await _firestore.collection('zikirler').doc(zikirId).update({
        'popularity': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      print('updateZikirPopularity error: $e');
      return false;
    }
  }

  // ==================== KATEGORİ İŞLEMLERİ ====================

  Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('categories')
          .orderBy('orderIndex')
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs.map((doc) => CategoryModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('getCategories error: $e');
      return [];
    }
  }

  Future<CategoryModel?> getCategory(String categoryId) async {
    try {
      final doc = await _firestore.collection('categories').doc(categoryId).get();
      return doc.exists ? CategoryModel.fromMap(doc.id, doc.data() ?? {}) : null;
    } catch (e) {
      print('getCategory error: $e');
      return null;
    }
  }

  Future<List<ZikirModel>> getZikirsByCategory(String categoryId) async {
    try {
      final snapshot = await _firestore.collection('zikirler')
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('popularity', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => ZikirModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      print('getZikirsByCategory error: $e');
      return [];
    }
  }

  // ==================== ARKADAŞ İŞLEMLERİ ====================

  Future<List<UserModel>> getFriends(String userId) async {
    try {
      final user = await getUser(userId);
      if (user == null || user.friends.isEmpty) return [];

      final friends = <UserModel>[];
      for (var friendId in user.friends) {
        final friend = await getUser(friendId);
        if (friend != null) friends.add(friend);
      }
      return friends;
    } catch (e) {
      print('getFriends error: $e');
      return [];
    }
  }

  Future<List<UserModel>> getFriendRequests(String userId) async {
    try {
      final snapshot = await _firestore.collection('friend_requests')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (snapshot.docs.isEmpty) return [];
      
      final requests = <UserModel>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final requesterId = data['requesterId'] as String;
        final requester = await getUser(requesterId);
        if (requester != null) requests.add(requester);
      }
      
      return requests;
    } catch (e) {
      print('getFriendRequests error: $e');
      return [];
    }
  }

  Future<bool> addFriend(String userId, String friendId) async {
    try {
      await _firestore.collection('friend_requests').add({
        'requesterId': userId,
        'receiverId': friendId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('addFriend error: $e');
      return false;
    }
  }

  Future<bool> acceptFriendRequest(String userId, String friendId) async {
    try {
      final requestsSnapshot = await _firestore.collection('friend_requests')
          .where('requesterId', isEqualTo: friendId)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (requestsSnapshot.docs.isEmpty) return false;
      
      await requestsSnapshot.docs.first.reference.update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await _firestore.collection('users').doc(userId).update({
        'friends': FieldValue.arrayUnion([friendId]),
      });
      
      await _firestore.collection('users').doc(friendId).update({
        'friends': FieldValue.arrayUnion([userId]),
      });
      
      return true;
    } catch (e) {
      print('acceptFriendRequest error: $e');
      return false;
    }
  }

  Future<bool> rejectFriendRequest(String userId, String friendId) async {
    try {
      final requestsSnapshot = await _firestore.collection('friend_requests')
          .where('requesterId', isEqualTo: friendId)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (requestsSnapshot.docs.isEmpty) return false;
      
      await requestsSnapshot.docs.first.reference.update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('rejectFriendRequest error: $e');
      return false;
    }
  }

  Future<bool> removeFriend(String userId, String friendId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'friends': FieldValue.arrayRemove([friendId]),
      });
      
      await _firestore.collection('users').doc(friendId).update({
        'friends': FieldValue.arrayRemove([userId]),
      });
      
      return true;
    } catch (e) {
      print('removeFriend error: $e');
      return false;
    }
  }

  Future<List<UserModel>> searchUsers(String query, {String? countryFilter}) async {
    try {
      QuerySnapshot snapshot;
      
      if (countryFilter != null) {
        snapshot = await _firestore.collection('users')
            .where('nickname', isGreaterThanOrEqualTo: query)
            .where('nickname', isLessThanOrEqualTo: query + '\uf8ff')
            .where('country', isEqualTo: countryFilter)
            .limit(10)
            .get();
      } else {
        snapshot = await _firestore.collection('users')
            .where('nickname', isGreaterThanOrEqualTo: query)
            .where('nickname', isLessThanOrEqualTo: query + '\uf8ff')
            .limit(10)
            .get();
      }
      
      return snapshot.docs.map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print('searchUsers error: $e');
      return [];
    }
  }

  // ==================== MESAJLAŞMA İŞLEMLERİ ====================

  Future<bool> sendMessage({
    required String senderId, 
    required String receiverId, 
    required String messageText
  }) async {
    try {
      await _firestore.collection('messages').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
      return true;
    } catch (e) {
      print('sendMessage error: $e');
      return false;
    }
  }

  // ==================== HEDİYE İŞLEMLERİ ====================

  Future<bool> sendGift({
    required String senderId,
    required String receiverId,
    required String giftId,
    required String giftType,
    required int giftPrice
  }) async {
    try {
      await _firestore.collection('users').doc(senderId).update({
        'points': FieldValue.increment(-giftPrice),
      });
      
      await _firestore.collection('gifts').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'giftId': giftId,
        'giftType': giftType,
        'giftPrice': giftPrice,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('sendGift error: $e');
      return false;
    }
  }

  // ==================== PUAN VE LİDERLİK ====================

  Future<int> getUserPoints(String userId) async {
    try {
      final user = await getUser(userId);
      return user?.points ?? 0;
    } catch (e) {
      print('getUserPoints error: $e');
      return 0;
    }
  }

  Future<List<UserModel>> getLeaderboard(String period, {int limit = 20}) async {
    try {
      final usersSnapshot = await _firestore.collection('users')
          .orderBy('points', descending: true)
          .limit(limit)
          .get();
      
      return usersSnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('getLeaderboard error: $e');
      return [];
    }
  }

  // ==================== CHALLENGE İŞLEMLERİ ====================

  Future<bool> startChallenge(String userId, String challengeId) async {
    try {
      await _firestore.collection('user_challenges').add({
        'userId': userId,
        'challengeId': challengeId,
        'progress': 0,
        'completed': false,
        'startedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('startChallenge error: $e');
      return false;
    }
  }

  // ==================== ADMİN AYARLARI (EKSİK METHODLAR) ====================

  /// Admin ayarları için settings koleksiyonuna erişim
  Future<bool> setSettings(Map<String, dynamic> settings) async {
    try {
      await _firestore.collection('settings').doc('app_settings').set(settings, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('setSettings error: $e');
      return false;
    }
  }

  /// Admin ayarlarını getir
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('app_settings').get();
      return doc.exists ? doc.data() ?? {} : {};
    } catch (e) {
      print('getSettings error: $e');
      return {};
    }
  }

  // ==================== KULLANICI ZİKİR İŞLEMLERİ ====================

  /// Kullanıcının zikir ilerlemesini güncelle
  Future<bool> updateUserZikir({
    required String userId,
    required String zikirId,
    required int currentCount,
    required int targetCount,
    bool? isCompleted,
    Duration? timeSpent,
  }) async {
    try {
      final userZikirData = {
        'userId': userId,
        'zikirId': zikirId,
        'currentCount': currentCount,
        'targetCount': targetCount,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isCompleted != null) {
        userZikirData['isCompleted'] = isCompleted;
        if (isCompleted) {
          userZikirData['completedAt'] = FieldValue.serverTimestamp();
        }
      }

      if (timeSpent != null) {
        userZikirData['timeSpentSeconds'] = timeSpent.inSeconds;
      }

      // Kullanıcının bu zikir için mevcut kaydını kontrol et
      final existingQuery = await _firestore
          .collection('user_zikirs')
          .where('userId', isEqualTo: userId)
          .where('zikirId', isEqualTo: zikirId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        // Mevcut kayıt varsa güncelle
        await existingQuery.docs.first.reference.update(userZikirData);
      } else {
        // Yeni kayıt oluştur
        userZikirData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('user_zikirs').add(userZikirData);
      }

      // Kullanıcının toplam zikir sayısını güncelle
      await updateUser(userId, {
        'totalZikirCount': FieldValue.increment(1),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('updateUserZikir error: $e');
      return false;
    }
  }

  /// Kullanıcının zikir istatistiklerini getir
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final user = await getUser(userId);
      if (user == null) return {};

      // Kullanıcının zikir geçmişini getir
      final userZikirsSnapshot = await _firestore
          .collection('user_zikirs')
          .where('userId', isEqualTo: userId)
          .get();

      final totalZikirs = userZikirsSnapshot.docs.length;
      final completedZikirs = userZikirsSnapshot.docs
          .where((doc) => doc.data()['isCompleted'] == true)
          .length;

      // Bu ayın zikirleri
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final thisMonthZikirs = userZikirsSnapshot.docs
          .where((doc) {
            final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
            return createdAt != null && createdAt.isAfter(monthStart);
          })
          .length;

      return {
        'totalZikirs': totalZikirs,
        'completedZikirs': completedZikirs,
        'thisMonthZikirs': thisMonthZikirs,
        'currentStreak': user.currentStreak,
        'longestStreak': user.longestStreak ?? 0,
        'points': user.points,
        'level': user.level,
        'badges': user.badges.length,
      };
    } catch (e) {
      print('getUserStats error: $e');
      return {};
    }
  }

  /// Kullanıcının zikir geçmişini getir
  Future<List<UserZikirModel>> getUserZikirHistory(
    String userId, {
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('user_zikirs')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map((doc) => UserZikirModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('getUserZikirHistory error: $e');
      return [];
    }
  }

  /// Bildirim oluştur
  Future<bool> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('createNotification error: $e');
      return false;
    }
  }

  /// Batch işlemler için helper
  WriteBatch batch() {
    return _firestore.batch();
  }

  /// Transaction işlemler için helper
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction,
  ) async {
    return await _firestore.runTransaction(updateFunction);
  }
}