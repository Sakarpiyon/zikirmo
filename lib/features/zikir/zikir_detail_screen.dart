import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/zikir_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/providers/providers.dart';

class ZikirDetailScreen extends ConsumerWidget {
  final String zikirId;
  
  const ZikirDetailScreen({
    Key? key,
    required this.zikirId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zikirAsync = ref.watch(zikirProviderFamily(zikirId));
    final isPremiumAsync = ref.watch(isPremiumProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: zikirAsync.when(
          data: (zikir) => Text(
            zikir?.getLocalizedTitle(context.locale.languageCode) ?? 'Zikir Detayı',
          ),
          loading: () => Text('Yükleniyor...'),
          error: (_, __) => Text('Zikir Detayı'),
        ),
        actions: [
          // Favori butonu (premium)
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              isPremiumAsync.when(
                data: (isPremium) {
                  if (isPremium) {
                    // TODO: Favoriye ekleme/çıkarma işlevi
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Premium özellik gerekli')),
                    );
                  }
                },
                loading: () => {},
                error: (_, __) => {},
              );
            },
          ),
          
          // Paylaşım butonu
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Paylaşım işlevi
            },
          ),
        ],
      ),
      body: zikirAsync.when(
        data: (zikir) {
          if (zikir == null) {
            return Center(
              child: Text('Zikir bulunamadı'),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Text(
                  zikir.getLocalizedTitle(context.locale.languageCode),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                
                // Hedef sayısı
                _buildInfoCard(
                  context,
                  'Hedef Sayısı',
                  zikir.targetCount.toString(),
                  Icons.format_list_numbered,
                ),
                const SizedBox(height: 16),
                
                // Arapça metin (varsa)
                if (zikir.arabicText != null && zikir.arabicText!.isNotEmpty) ...[
                  _buildSection(context, 'Arapça Yazılış'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      zikir.arabicText!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontFamily: 'Amiri', // Arapça yazı tipi
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Okunuşu (varsa)
                if (zikir.transliteration != null && zikir.transliteration!.isNotEmpty) ...[
                  _buildSection(context, 'Okunuşu'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      zikir.transliteration!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Anlamı
                _buildSection(context, 'Anlamı'),
                Text(
                  zikir.getLocalizedDescription(context.locale.languageCode),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                
                // Amacı (varsa)
                if (zikir.purpose.isNotEmpty) ...[
                  _buildSection(context, 'Amacı'),
                  Text(
                    zikir.getLocalizedPurpose(context.locale.languageCode),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Kaynak (varsa)
                if (zikir.source != null && zikir.source!.isNotEmpty) ...[
                  _buildSection(context, 'Kaynak'),
                  Text(
                    zikir.source!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Ses dosyaları bölümü (varsa)
                if (zikir.audioUrlArabic != null || zikir.audioUrlTranslated != null) ...[
                  _buildSection(context, 'Sesli Dinleme'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (zikir.audioUrlArabic != null)
                        _buildAudioButton(
                          context,
                          'Arapça Dinle',
                          () {
                            // TODO: Arapça ses oynatma
                          },
                        ),
                      
                      if (zikir.audioUrlTranslated != null)
                        _buildAudioButton(
                          context,
                          'Türkçe Dinle',
                          () {
                            // TODO: Yerel dilde ses oynatma
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                
                // İstatistikler bölümü (Premium)
                isPremiumAsync.when(
                  data: (isPremium) {
                    if (isPremium) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(context, 'İstatistikler'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCard(
                                context,
                                'Popüler',
                                zikir.popularity > 100 ? 'Evet' : 'Hayır',
                              ),
                              _buildStatCard(
                                context,
                                'Sayımınız',
                                '0', // TODO: Kullanıcının bu zikiri çekme sayısı
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Zikir yüklenirken hata oluştu'),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              // Zikir sayaç ekranına git
              Navigator.pushNamed(
                context,
                '/zikir_counter',
                arguments: zikirId,
              );
            },
            icon: const Icon(Icons.touch_app),
            label: Text('Zikre Başla'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
    );
  }
  
  // Bilgi kartı
  Widget _buildInfoCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 32,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Bölüm başlığı
  Widget _buildSection(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
  
  // Ses oynatma butonu
  Widget _buildAudioButton(BuildContext context, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.volume_up),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black87,
      ),
    );
  }
  
  // İstatistik kartı
  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}