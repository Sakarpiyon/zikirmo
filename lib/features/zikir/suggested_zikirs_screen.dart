// lib/features/zikir/suggested_zikirs_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import 'package:zikirmo_new/core/models/zikir_model.dart';
import 'package:zikirmo_new/core/services/firestore_service.dart';
import 'package:zikirmo_new/features/zikir/components/zikir_card.dart';

// Önerilen zikirler provider'ı
final suggestedZikirsProvider = FutureProvider<List<ZikirModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getSuggestedZikirs();
});

class SuggestedZikirsScreen extends ConsumerWidget {
  const SuggestedZikirsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedZikirsAsync = ref.watch(suggestedZikirsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('suggestedZikirs'.tr()),
      ),
      body: suggestedZikirsAsync.when(
        data: (zikirs) {
          if (zikirs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'noSuggestedZikirs'.tr(),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: zikirs.length,
            itemBuilder: (context, index) {
              final zikir = zikirs[index];
              return ZikirCard(
                zikir: zikir,
                onTap: () {
                  // Zikir detay sayfasına git
                  Navigator.pushNamed(
                    context,
                    '/zikir_detail',
                    arguments: zikir.id,
                  );
                },
                onCounterTap: () {
                  // Zikir sayaç ekranına git
                  Navigator.pushNamed(
                    context,
                    '/zikir_counter',
                    arguments: zikir.id,
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('errorLoadingZikirs'.tr()),
        ),
      ),
    );
  }
}
