// lib/core/services/messaging_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';

final messagingServiceProvider = Provider<MessagingService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return MessagingService(notificationService);
});

class MessagingService {
  final NotificationService _notificationService;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  MessagingService(this._notificationService);

  Future<void> initialize() async {
    try {
      // İzinleri iste
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      debugPrint('Firebase Messaging permission status: ${settings.authorizationStatus}');

      // FCM token al
      final token = await _messaging.getToken();
      debugPrint('Firebase Messaging token: $token');

      // Mesaj geldiğinde
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          _notificationService.showNotification(
            notification.title ?? 'Yeni Bildirim',
            notification.body ?? '',
          );
        }
      });

      debugPrint('Messaging service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing messaging service: $e');
    }
  }
}
