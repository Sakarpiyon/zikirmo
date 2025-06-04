// Dosya: lib/core/services/firestore_service.dart
// Yol: C:\src\zikirmo_new\lib\core\services\firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/zikir_model.dart';
import '../models/category_model.dart';
import '../models/user_zikir_model.dart';
import '../models/friend_model.dart';

// FieldValue artık Cloud Firestore paketinden geliyor - ek import gerekmez

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

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
        final additional = await _firestore.collection('zikirler')
            .orderBy('popularity', descending: true)
            .limit(limit - snapshot.docs.length)
            .get();
        final result = snapshot.docs.map((d) => ZikirModel.fromMap(d.id, d.data())).toList();
        result.addAll(additional.docs.map((d) => ZikirModel.fromMap(d.id, d.data())));
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
      final list = <UserModel>[];
      for (var fid in user.friends) {
        final f = await getUser(fid);
        if (f != null) list.add(f);
      }
      return list;
    } catch (e) {
      print('getFriends error: $e');
      return [];
    }
  }

  Future<List<UserModel>> getFriendRequests(String userId) async {
    try {
      final snap = await _firestore.collection('friend_requests')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      if (snap.docs.isEmpty) return [];
      final reqs = <UserModel>[];
      for (var doc in snap.docs) {
        final data = doc.data();
        final rid = data['requesterId'] as String;
        final u = await getUser(rid);
        if (u != null) reqs.add(u);
      }
      return reqs;
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
      final snap = await _firestore.collection('friend_requests')
          .where('requesterId', isEqualTo: friendId)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      if (snap.docs.isEmpty) return false;
      await snap.docs.first.reference.update({
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
      final snap = await _firestore.collection('friend_requests')
          .where('requesterId', isEqualTo: friendId)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      if (snap.docs.isEmpty) return false;
      await snap.docs.first.reference.update({
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
      QuerySnapshot snap;
      if (countryFilter != null) {
        snap = await _firestore.collection('users')
            .where('nickname', isGreaterThanOrEqualTo: query)
            .where('nickname', isLessThanOrEqualTo: query + '\uf8ff')
            .where('country', isEqualTo: countryFilter)
            .limit(10)
            .get();
      } else {
        snap = await _firestore.collection('users')
            .where('nickname', isGreaterThanOrEqualTo: query)
            .where('nickname', isLessThanOrEqualTo: query + '\uf8ff')
            .limit(10)
            .get();
      }
      return snap.docs.map((d) => UserModel.fromJson(d.data() as Map<String,dynamic>, d.id)).toList();
    } catch (e) {
      print('searchUsers error: $e');
      return [];
    }
  }

  // ==================== MESAJLAŞMA İŞLEMLERİ ====================

  Future<bool> sendMessage({required String senderId, required String receiverId, required String messageText}) async {
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

  Future<bool> sendGift({required String senderId, required String receiverId,	required String giftId, required String giftType, required int giftPrice}) async {
    try {
      await _firestore.collection('users').doc(senderId).update({'points': FieldValue.increment(-giftPrice)});
      await _firestore.collection('gifts').add({'senderId': senderId,'receiverId': receiverId,'giftId': giftId,'giftType': giftType,'giftPrice': giftPrice,'timestamp': FieldValue.serverTimestamp(),});
      return true;
    } catch (e) {
      print('sendGift error: $e');
      return false;
    }
  }

  // ==================== PUAN VE LİDERLİK ====================

  Future<int> getUserPoints(String userId) async { ... } // (Devamı yukarıdaki pattern ile)
  
  /// Admin ayarları için settings koleksiyonuna erişim
  Future<bool> setSettings(Map<String, dynamic> settings) async { ... }
  Future<Map<String, dynamic>> getSettings() async { ... }

  /// Kullanıcının zikir ilerlemesini güncelle
  Future<bool> updateUserZikir({ required String userId, required String zikirId, required int currentCount, required int targetCount, bool? isCompleted, Duration? timeSpent, }) async { ... }

  Future<Map<String, dynamic>> getUserStats(String userId) async { ... }

  Future<List<UserZikirModel>> getUserZikirHistory(String userId, {int limit = 50, DateTime? startDate, DateTime? endDate,}) async { ... }

  /// Bildirim oluştur
  Future<bool> createNotification({required String userId, required String title, required String message, required String type, Map<String, dynamic>? data,}) async { ... }

  /// Batch işlemler için helper
  WriteBatch batch() => _firestore.batch();

  /// Transaction işlemler için helper
  Future<T> runTransaction<T>(Future<T> Function(Transaction) updateFunction) async => _firestore.runTransaction(updateFunction);   
}

// Dosya Sonu: lib/core/services/firestore_service.dart
// Yol: C:\src\zikirmo_new\lib\core\services\firestore_service.dart
