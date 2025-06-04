// send_gift_screen.dart - v1.0.0
// Arkadaşa hediye gönderme ekranı
// Klasör: lib/features/gifts/send_gift_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import 'package:zikirmo_new/core/models/user_model.dart';
import 'package:zikirmo_new/core/services/auth_service.dart';
import 'package:zikirmo_new/core/services/firestore_service.dart';

// Hediye türleri
enum GiftType {
  tespih,
  buton,
  premium,
}

// Hediye modeli
class Gift {
  final String id;
  final String name;
  final String description;
  final GiftType type;
  final int price;
  final String imagePath;
  
  const Gift({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.price,
    required this.imagePath,
  });
}

// Kullanılabilir hediyeler listesi
final gifts = [
  Gift(
    id: 'tespih_1',
    name: 'Ahşap Tespih',
    description: 'Geleneksel ahşap tespih',
    type: GiftType.tespih,
    price: 50,
    imagePath: 'assets/images/gifts/tespih_1.png',
  ),
  Gift(
    id: 'tespih_2',
    name: 'Kehribar Tespih',
    description: 'Lüks kehribar tespih',
    type: GiftType.tespih,
    price: 100,
    imagePath: 'assets/images/gifts/tespih_2.png',
  ),
  Gift(
    id: 'button_1',
    name: 'Altın Buton',
    description: 'Altın renkli zikir butonu',
    type: GiftType.buton,
    price: 75,
    imagePath: 'assets/images/gifts/button_1.png',
  ),
  Gift(
    id: 'button_2',
    name: 'Gümüş Buton',
    description: 'Gümüş renkli zikir butonu',
    type: GiftType.buton,
    price: 75,
    imagePath: 'assets/images/gifts/button_2.png',
  ),
  Gift(
    id: 'premium_1',
    name: '1 Aylık Premium',
    description: 'Bir aylık premium üyelik hediyesi',
    type: GiftType.premium,
    price: 200,
    imagePath: 'assets/images/gifts/premium.png',
  ),
];

// Mevcut kullanıcının puan bilgilerini getiren provider
final userPointsProvider = FutureProvider<int>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userId = authService.currentUser?.uid;
  
  if (userId == null) return 0;
  
  final user = await firestoreService.getUser(userId);
  return user?.points ?? 0;
});

class SendGiftScreen extends ConsumerStatefulWidget {
  final String receiverId;
  
  const SendGiftScreen({
    Key? key,
    required this.receiverId,
  }) : super(key: key);

  @override
  ConsumerState<SendGiftScreen> createState() => _SendGiftScreenState();
}

class _SendGiftScreenState extends ConsumerState<SendGiftScreen> {
  Gift? _selectedGift;
  bool _isLoading = false;
  UserModel? _receiver;
  
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
  
  // Hediye gönder
  Future<void> _sendGift() async {
    if (_selectedGift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir hediye seçin'.tr())),
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
      
      // Kullanıcının puanını kontrol et
      final userPoints = await firestoreService.getUserPoints(currentUserId);
      
      if (userPoints < _selectedGift!.price) {
        throw Exception('Yetersiz puan');
      }
      
      // Hediyeyi gönder
      await firestoreService.sendGift(
        senderId: currentUserId,
        receiverId: widget.receiverId,
        giftId: _selectedGift!.id,
        giftType: _selectedGift!.type.toString(),
        giftPrice: _selectedGift!.price,
      );
      
      if (mounted) {
        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hediye gönderildi'.tr())),
        );
        
        // Kullanıcı puanlarını yenile
        ref.refresh(userPointsProvider);
        
        // Ekranı kapat
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Yetersiz puan')
                  ? 'Yetersiz puan'.tr()
                  : 'Hediye gönderilirken hata oluştu'.tr(),
            ),
          ),
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
    final userPointsAsync = ref.watch(userPointsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Hediye Gönder'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı puanları
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on),
                    const SizedBox(width: 16),
                    userPointsAsync.when(
                      data: (points) => Text(
                        'points'.tr(args: [points.toString()]),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      loading: () => const Text('Yükleniyor...'),
                      error: (_, __) => const Text('Hata'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
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
            
            // Hediye seçimi başlığı
            Text(
              'Bir hediye seçin'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Hediyeler listesi
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  final gift = gifts[index];
                  final isSelected = _selectedGift?.id == gift.id;
                  
                  return Card(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : null,
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
                          _selectedGift = gift;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Hediye resmi
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                gift.imagePath,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.card_giftcard,
                                  size: 64,
                                ),
                              ),
                            ),
                          ),
                          
                          // Hediye bilgileri
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  gift.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  gift.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${gift.price} Puan',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                      onPressed: _selectedGift == null ? null : _sendGift,
                      child: Text('Hediyeyi Gönder'.tr()),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
