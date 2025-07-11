﻿// lib/features/messages/messages_list_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import 'package:zikirmo_new/core/services/auth_service.dart';
import 'package:zikirmo_new/core/services/firestore_service.dart';
import 'package:zikirmo_new/core/models/user_model.dart';
import 'package:zikirmo_new/routes.dart';

// Mesaj modeli
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.isRead,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      isRead: map['isRead'] ?? false,
    );
  }
}

// Konuşma modeli
class ConversationModel {
  final String otherUserId;
  final UserModel? otherUser;
  final MessageModel? lastMessage;
  final int unreadCount;

  ConversationModel({
    required this.otherUserId,
    this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
  });
}

// Konuşmaları getiren provider
final conversationsProvider = FutureProvider<List<ConversationModel>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUserId = authService.currentUser?.uid;
  
  if (currentUserId == null) return [];
  
  try {
    // Kullanıcının mesajlarını getir
    final sentMessages = await firestoreService.firestore
        .collection('messages')
        .where('senderId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .get();
    
    final receivedMessages = await firestoreService.firestore
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .get();
    
    // Tüm mesajları birleştir
    final allMessages = <MessageModel>[];
    
    for (var doc in sentMessages.docs) {
      allMessages.add(MessageModel.fromMap(doc.data(), doc.id));
    }
    
    for (var doc in receivedMessages.docs) {
      allMessages.add(MessageModel.fromMap(doc.data(), doc.id));
    }
    
    // Konuşmaları grupla
    final conversations = <String, List<MessageModel>>{};
    
    for (var message in allMessages) {
      final otherUserId = message.senderId == currentUserId 
          ? message.receiverId 
          : message.senderId;
      
      if (!conversations.containsKey(otherUserId)) {
        conversations[otherUserId] = [];
      }
      conversations[otherUserId]!.add(message);
    }
    
    // ConversationModel listesi oluştur
    final result = <ConversationModel>[];
    
    for (var entry in conversations.entries) {
      final otherUserId = entry.key;
      final messages = entry.value;
      
      // En son mesajı bul
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final lastMessage = messages.isNotEmpty ? messages.first : null;
      
      // Okunmamış mesaj sayısını hesapla
      final unreadCount = messages
          .where((m) => m.receiverId == currentUserId && !m.isRead)
          .length;
      
      // Diğer kullanıcının bilgilerini getir
      final otherUser = await firestoreService.getUser(otherUserId);
      
      result.add(ConversationModel(
        otherUserId: otherUserId,
        otherUser: otherUser,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
      ));
    }
    
    // En son mesaja göre sırala
    result.sort((a, b) {
      final aTime = a.lastMessage?.timestamp ?? DateTime(2000);
      final bTime = b.lastMessage?.timestamp ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    
    return result;
  } catch (e) {
    return [];
  }
});

class MessagesListScreen extends ConsumerStatefulWidget {
  const MessagesListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends ConsumerState<MessagesListScreen> {
  
  // Mesajı okundu olarak işaretle
  Future<void> _markAsRead(String messageId) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.firestore
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true});
      
      // Provider'ı yenile
      ref.refresh(conversationsProvider);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }
  
  // Konuşmayı sil
  Future<void> _deleteConversation(String otherUserId) async {
    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      final currentUserId = authService.currentUser?.uid;
      
      if (currentUserId == null) return;
      
      // Bu konuşmadaki tüm mesajları sil
      final sentMessages = await firestoreService.firestore
          .collection('messages')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: otherUserId)
          .get();
      
      final receivedMessages = await firestoreService.firestore
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .get();
      
      final batch = firestoreService.firestore.batch();
      
      for (var doc in sentMessages.docs) {
        batch.delete(doc.reference);
      }
      
      for (var doc in receivedMessages.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // Provider'ı yenile
      ref.refresh(conversationsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('conversationDeleted'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('deleteOperationFailed'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('messages'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            tooltip: 'newMessage'.tr(),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.userSearch);
            },
          ),
        ],
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(conversationsProvider);
            },
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return _buildConversationTile(conversation);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(),
      ),
    );
  }
  
  // Konuşma tile'ı
  Widget _buildConversationTile(ConversationModel conversation) {
    final hasUnread = conversation.unreadCount > 0;
    final otherUser = conversation.otherUser;
    final lastMessage = conversation.lastMessage;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: hasUnread ? 3 : 1,
      color: hasUnread ? Theme.of(context).primaryColor.withOpacity(0.05) : null,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              backgroundImage: otherUser?.profileImageUrl != null
                  ? NetworkImage(otherUser!.profileImageUrl!)
                  : null,
              child: otherUser?.profileImageUrl == null
                  ? Text(
                      _getInitials(otherUser?.nickname ?? 'U'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            if (hasUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      conversation.unreadCount > 9 ? '9+' : conversation.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherUser?.nickname ?? 'unknownUser'.tr(),
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (otherUser?.isPremium == true)
              Icon(
                Icons.verified,
                color: Colors.amber[700],
                size: 16,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                lastMessage.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                  color: hasUnread ? Colors.black87 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatMessageTime(lastMessage.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, conversation),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'mark_read',
              child: Row(
                children: [
                  const Icon(Icons.mark_email_read),
                  const SizedBox(width: 8),
                  Text('markAsRead'.tr()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('deleteConversation'.tr(), style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          // Mesaj ekranına git
          Navigator.pushNamed(
            context,
            AppRoutes.sendMessage,
            arguments: conversation.otherUserId,
          ).then((_) {
            // Geri dönüldüğünde konuşmaları yenile
            ref.refresh(conversationsProvider);
          });
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
  
  // Menü aksiyonları
  void _handleMenuAction(String action, ConversationModel conversation) {
    switch (action) {
      case 'mark_read':
        _markConversationAsRead(conversation);
        break;
      case 'delete':
        _showDeleteConfirmation(conversation);
        break;
    }
  }
  
  // Konuşmayı okundu olarak işaretle
  Future<void> _markConversationAsRead(ConversationModel conversation) async {
    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      final currentUserId = authService.currentUser?.uid;
      
      if (currentUserId == null) return;
      
      // Bu konuşmadaki okunmamış mesajları bul ve okundu işaretle
      final unreadMessages = await firestoreService.firestore
          .collection('messages')
          .where('senderId', isEqualTo: conversation.otherUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = firestoreService.firestore.batch();
      
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
      
      // Provider'ı yenile
      ref.refresh(conversationsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('messagesMarkedAsRead'.tr())),
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
  
  // Silme onayı
  void _showDeleteConfirmation(ConversationModel conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('deleteConversationTitle'.tr()),
        content: Text(
          'deleteConversationConfirm'.tr(args: [conversation.otherUser?.nickname ?? 'unknownUser'.tr()])
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteConversation(conversation.otherUserId);
            },
            child: Text('delete'.tr(), style: TextStyle(color: Colors.red)),
          ),
        ],
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
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'noMessages'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'startMessagingWithFriends'.tr(),
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.userSearch);
            },
            icon: const Icon(Icons.person_search),
            label: Text('searchUsers'.tr()),
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
            'errorLoadingMessages'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.refresh(conversationsProvider);
            },
            child: Text('tryAgain'.tr()),
          ),
        ],
      ),
    );
  }
  
  // İsmin baş harfleri
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    
    final parts = name.split(' ');
    String initials = '';
    
    for (var part in parts) {
      if (part.isNotEmpty) {
        initials += part[0].toUpperCase();
        if (initials.length >= 2) break;
      }
    }
    
    return initials.isEmpty ? 'U' : initials;
  }
  
  // Mesaj zamanını formatla
  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'justNow'.tr();
    } else if (difference.inHours < 1) {
      return 'minutesAgo'.tr(args: [difference.inMinutes.toString()]);
    } else if (difference.inDays < 1) {
      return 'hoursAgo'.tr(args: [difference.inHours.toString()]);
    } else if (difference.inDays < 7) {
      return 'daysAgo'.tr(args: [difference.inDays.toString()]);
    } else {
      return DateFormat('dd.MM.yyyy').format(timestamp);
    }
  }
}
