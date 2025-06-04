// lib/features/zikir/components/zikir_card.dart
// TextDirection hatası tamamen düzeltildi

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/models/zikir_model.dart';

class ZikirCard extends StatelessWidget {
  final ZikirModel zikir;
  final VoidCallback onTap;
  final VoidCallback onCounterTap;
  final bool showFavorite;
  
  const ZikirCard({
    Key? key,
    required this.zikir,
    required this.onTap,
    required this.onCounterTap,
    this.showFavorite = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık satırı
              Row(
                children: [
                  Expanded(
                    child: Text(
                      zikir.getLocalizedTitle(context.locale.languageCode),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  
                  // Hedef sayısı
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      zikir.targetCount.toString(),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Favori ikonu (premium özelliği)
                  if (showFavorite)
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {
                        // Favori ekleme/çıkarma (Premium)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('premiumRequired'.tr())),
                        );
                      },
                      iconSize: 20,
                      splashRadius: 20,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              
              // Açıklama (varsa)
              if (zikir.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  zikir.getLocalizedDescription(context.locale.languageCode),
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Arapça yazılış (varsa)
              if (zikir.arabicText != null && zikir.arabicText!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    zikir.arabicText!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Amiri', // Arapça yazı tipi
                    ),
                     // DÜZELTME: Direkt TextDirection.rtl kullan
		    textAlign: TextAlign.right,
                    // textDirection: TextDirection.rtl,
                  ),
                ),
              ],
              
              // Alt butonlar
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Dinleme butonu (ses varsa)
                  if (zikir.audioUrlArabic != null || zikir.audioUrlTranslated != null)
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Ses oynatma işlevi
                      },
                      icon: const Icon(Icons.volume_up),
                      label: Text('listen'.tr()),
                    ),
                  
                  // Zikir çekme butonu
                  ElevatedButton.icon(
                    onPressed: onCounterTap,
                    icon: const Icon(Icons.touch_app),
                    label: Text('startZikir'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}