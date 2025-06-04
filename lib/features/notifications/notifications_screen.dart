// lib/features/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import 'package:zikirmo_new/core/services/auth_service.dart';
import 'package:zikirmo_new/core/services/firestore_service.dart';

// Bildirim modeli
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'friend_request', 'achievement', 'reminder', 'system'
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.data,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'system',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isRead: map['isRead'] ?? false,
      data: map['data'],
    );
  }
}

// Bildirimleri getiren provider
final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userId = authService.currentUser?.uid;
  
  if (userId == null) return [];
  
  try {
    final snapshot = await firestoreService.firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    
    return snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
        .toList();
  } catch (e) {
    return [];
  }
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  
  // Bildirimi okundu olarak işaretle
  Future<void> _markAsRead(String notificationId) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      
      // Provider'ı yenile
      ref.refresh(notificationsProvider);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }
  
  // Tüm bildirimleri okundu olarak işaretle
  Future<void> _markAllAsRead() async {
    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      final userId = authService.currentUser?.uid;
      
      if (userId == null) return;
      
      final snapshot = await firestoreService.firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = firestoreService.firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      
      // Provider'ı yenile
      ref.refresh(notificationsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('allNotificationsMarkedAsRead'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('operationFailed'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('notifications'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'markAllAsRead'.tr(),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }
          
          // Okunmamış ve okunmuş bildirimleri ayır
          final unreadNotifications = notifications.where((n) => !n.isRead).toList();
          final readNotifications = notifications.where((n) => n.isRead).toList();
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(notificationsProvider);
            },
            child: ListView(
              children: [
                // Okunmamış bildirimler
                if (unreadNotifications.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'newNotifications'.tr(args: [unreadNotifications.length.toString()]),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  ...unreadNotifications.map((notification) =>
                      _buildNotificationTile(notification, isUnread: true)),
                ],
                
                // Okunmuş bildirimler
                if (readNotifications.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'previousNotifications'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  ...readNotifications.map((notification) =>
                      _buildNotificationTile(notification, isUnread: false)),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(),
      ),
    );
  }
  
  // Bildirim tile'ı
  Widget _buildNotificationTile(NotificationModel notification, {required bool isUnread}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isUnread ? Theme.of(context).primaryColor.withOpacity(0.05) : null,
        borderRadius: BorderRadius.circular(12),
        border: isUnread ? Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ) : null,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.type).withOpacity(0.2),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () {
          if (isUnread) {
            _markAsRead(notification.id);
          }
          _handleNotificationTap(notification);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
  
  // Boş durum
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'noNotifications'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'newNotificationsWillAppearHere'.tr(),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
  
  // Hata durumu
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'errorLoadingNotifications'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.refresh(notificationsProvider);
            },
            child: Text('tryAgain'.tr()),
          ),
        ],
      ),
    );
  }
  
  // Bildirim tipine göre ikon
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'friend_request':
        return Icons.person_add;
      case 'achievement':
        return Icons.emoji_events;
      case 'reminder':
        return Icons.access_time;
      case 'message':
        return Icons.message;
      case 'gift':
        return Icons.card_giftcard;
      case 'system':
      default:
        return Icons.info;
    }
  }
  
  // Bildirim tipine göre renk
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'friend_request':
        return Colors.blue;
      case 'achievement':
        return Colors.amber;
      case 'reminder':
        return Colors.orange;
      case 'message':
        return Colors.green;
      case 'gift':
        return Colors.purple;
      case 'system':
      default:
        return Colors.grey;
    }
  }
  
  // Tarih formatlama
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'justNow'.tr();
    } else if (difference.inHours < 1) {
      return 'minutesAgo'.tr(args: [difference.inMinutes.toString()]);
    } else if (difference.inDays < 1) {
      return 'hoursAgo'.tr(args: [difference.inHours.toString()]);
    } else if (difference.inDays < 7) {
      return 'daysAgo'.tr(args: [difference.inDays.toString()]);
    } else {
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    }
  }
  
  // Bildirime tıklama işlemi
  void _handleNotificationTap(NotificationModel notification) {
    switch (notification.type) {
      case 'friend_request':
        Navigator.pushNamed(context, '/friends');
        break;
      case 'achievement':
        Navigator.pushNamed(context, '/challenges');
        break;
      case 'message':
        if (notification.data?['senderId'] != null) {
          Navigator.pushNamed(
            context, 
            '/send_message',
            arguments: notification.data!['senderId'],
          );
        }
        break;
      case 'gift':
        Navigator.pushNamed(context, '/reward_store');
        break;
      default:
        // Varsayılan işlem yok
        break;
    }
  }
}
