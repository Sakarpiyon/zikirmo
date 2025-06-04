// send_message_screen.dart - v1.0.0
// Hazır mesajlar gönderme ekranı
// Klasör: lib/features/messages/send_message_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import 'package:zikirmo_new/core/models/user_model.dart';
import 'package:zikirmo_new/core/services/auth_service.dart';
import 'package:zikirmo_new/core/services/firestore_service.dart';

class SendMessageScreen extends ConsumerStatefulWidget {
  final String receiverId;
  
  const SendMessageScreen({
    Key? key,
    required this.receiverId,
  }) : super(key: key);

  @override
  ConsumerState<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends ConsumerState<SendMessageScreen> {
  String? _selectedMessage;
  bool _isLoading = false;
  UserModel? _receiver;
  
  // Hazır mesajlar listesi
  final List<String> _predefinedMessages = [
    'Tebrikler!',
    'Helâl Olsun',
    'Allah Razı Olsun',
    'Allah\'a Emanet Ol',
    'Seni İslama Davet Ediyorum',
    'Allahû Ekber',
    'Lâ İlahe İllallah',
    'Maaşallah',
    'Hayırlı Günler Dilerim',
    'Selamün Aleyküm',
    'Allah Kolaylık Versin',
  ];
  
  @override
  void initState() {
    super.initState();
    _loadReceiverData();
  }
  
  // Alıcı kullanıcı bilgilerini yükle
  Future<void> _loadReceiverData() async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final user = await firestoreService.getUser(widget.receiverId);
    
    if (mounted) {
      setState(() {
        _receiver = user;
      });
    }
  }
  
  // Mesaj gönder
  Future<void> _sendMessage() async {
    if (_selectedMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir mesaj seçin'.tr())),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      final currentUserId = authService.currentUser?.uid;
      
      if (currentUserId == null) {
        throw Exception('Kullanıcı girişi gerekli');
      }
      
      // Mesajı gönder
      await firestoreService.sendMessage(
        senderId: currentUserId,
        receiverId: widget.receiverId,
        messageText: _selectedMessage!,
      );
      
      if (mounted) {
        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj gönderildi'.tr())),
        );
        
        // Ekranı kapat
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj gönderilirken hata oluştu'.tr())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mesaj Gönder'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alıcı bilgisi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kime:'.tr(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _receiver?.nickname ?? 'Yükleniyor...'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Mesaj seçimi başlığı
            Text(
              'Bir mesaj seçin'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Hazır mesajlar listesi
            Expanded(
              child: ListView.builder(
                itemCount: _predefinedMessages.length,
                itemBuilder: (context, index) {
                  final message = _predefinedMessages[index];
                  final isSelected = _selectedMessage == message;
                  
                  return Card(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : null,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            )
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMessage = message;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                message,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).primaryColor,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Gönder butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _selectedMessage == null ? null : _sendMessage,
                      child: Text('Gönder'.tr()),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
