// lib/features/zikir/category_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zikirmo_new/core/models/category_model.dart';
import 'package:zikirmo_new/core/models/zikir_model.dart';
import 'package:zikirmo_new/core/services/firestore_service.dart';
import 'package:zikirmo_new/features/zikir/components/zikir_card.dart';

// Kategori detayı provider'ı
final categoryProvider = FutureProvider.family<CategoryModel?, String>((ref, categoryId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getCategory(categoryId);
});

// Kategoriye ait zikirler provider'ı
final categoryZikirsProvider = FutureProvider.family<List<ZikirModel>, String>((ref, categoryId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getZikirsByCategory(categoryId);
});

class CategoryDetailScreen extends ConsumerWidget {
  final String categoryId;
  
  const CategoryDetailScreen({
    Key? key,
    required this.categoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryProvider(categoryId));
    final zikirsAsync = ref.watch(categoryZikirsProvider(categoryId));
    
    return Scaffold(
      appBar: AppBar(
        title: categoryAsync.when(
          data: (category) => Text(
            category?.getLocalizedName(context.locale.languageCode) ?? 'category'.tr(),
          ),
          loading: () => Text('loading'.tr()),
          error: (_, __) => Text('category'.tr()),
        ),
      ),
      body: zikirsAsync.when(
        data: (zikirs) {
          if (zikirs.isEmpty) {
            return Center(
              child: Column(
	        mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_dissatisfied,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'noCategoryZikirs'.tr(),
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
