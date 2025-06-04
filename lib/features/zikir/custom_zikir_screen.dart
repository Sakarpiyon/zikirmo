// lib/features/zikir/custom_zikir_screen.dart
// TextDirection hatası tamamen düzeltildi

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // FieldValue için gerekli
import '../../core/providers/providers.dart'; // Sadece bu import
import '../../core/models/category_model.dart';
import '../../routes.dart';

// Kategorileri getiren provider
final categoriesForCustomZikirProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getCategories();
});

class CustomZikirScreen extends ConsumerStatefulWidget {
  const CustomZikirScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CustomZikirScreen> createState() => _CustomZikirScreenState();
}

class _CustomZikirScreenState extends ConsumerState<CustomZikirScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controller'ları
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _arabicTextController = TextEditingController();
  final _transliterationController = TextEditingController();
  final _purposeController = TextEditingController();
  final _sourceController = TextEditingController();
  
  // Form değişkenleri
  String? _selectedCategoryId;
  int _targetCount = 33;
  bool _isPublic = false;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _arabicTextController.dispose();
    _transliterationController.dispose();
    _purposeController.dispose();
    _sourceController.dispose();
    super.dispose();
  }
  
  // Özel zikir oluşturma
  Future<void> _createCustomZikir() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      final userId = authService.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('pleaseLogin'.tr());
      }
      
      // Premium kontrolü
      final isPremium = await authService.checkIfUserIsPremium();
      if (!isPremium) {
        if (mounted) {
          _showPremiumDialog();
          return;
        }
      }
      
      // Zikir verilerini hazırla
      final zikirData = {
        'title': {
          'tr': _titleController.text.trim(),
          'en': _titleController.text.trim(),
        },
        'description': {
          'tr': _descriptionController.text.trim(),
          'en': _descriptionController.text.trim(),
        },
        'purpose': {
          'tr': _purposeController.text.trim(),
          'en': _purposeController.text.trim(),
        },
        'categoryId': _selectedCategoryId ?? 'personal',
        'targetCount': _targetCount,
        'arabicText': _arabicTextController.text.trim().isNotEmpty 
            ? _arabicTextController.text.trim() 
            : null,
        'transliteration': _transliterationController.text.trim().isNotEmpty 
            ? _transliterationController.text.trim() 
            : null,
        'source': _sourceController.text.trim().isNotEmpty 
            ? _sourceController.text.trim() 
            : null,
        'isPersonal': !_isPublic,
        'createdBy': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'popularity': 0,
      };
      
      // Firestore'a kaydet
      final docRef = await firestoreService.firestore
          .collection('zikirler')
          .add(zikirData);
      
      // Kullanıcının puanını artır
      await firestoreService.updateUser(userId, {
        'points': FieldValue.increment(5), // Özel zikir oluşturma bonusu
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('customZikirCreated'.tr())),
        );
        
        // Oluşturulan zikir sayaç ekranına git
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.zikirCounter,
          arguments: docRef.id,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorCreatingZikir'.tr(args: [e.toString()]))),
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
  
  // Premium dialog'u
  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('premiumFeature'.tr()),
        content: Text('customZikirPremiumMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.premium);
            },
            child: Text('becomePremium'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesForCustomZikirProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('createCustomZikir'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Açıklama kartı
              Card(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'customZikirDescription'.tr(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Temel bilgiler
              _buildSectionTitle('basicInfo'.tr()),
              const SizedBox(height: 16),
              
              // Zikir başlığı (zorunlu)
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '${'zikirTitle'.tr()} *',
                  hintText: 'zikirTitleHint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'zikirTitleRequired'.tr();
                  }
                  if (value.trim().length < 3) {
                    return 'zikirTitleTooShort'.tr();
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              
              // Açıklama
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'description'.tr(),
                  hintText: 'descriptionHint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 16),
              
              // Kategori seçimi
              categoriesAsync.when(
                data: (categories) => DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'category'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text('selectCategory'.tr()),
                    ),
                    ...categories.map((category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(category.getLocalizedName(context.locale.languageCode)),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
                loading: () => Container(
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 16),
              
              // Hedef sayısı
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'targetCountLabel'.tr(args: [_targetCount.toString()]),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: Slider(
                      value: _targetCount.toDouble(),
                      min: 1,
                      max: 1000,
                      divisions: 100,
                      label: _targetCount.toString(),
                      onChanged: (value) {
                        setState(() {
                          _targetCount = value.round();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Arapça metin ve okunuş
              _buildSectionTitle('arabicTextSection'.tr()),
              const SizedBox(height: 16),
              
              // Arapça yazılış - HATA TAMAMEN DÜZELTİLDİ
              TextFormField(
                controller: _arabicTextController,
                decoration: InputDecoration(
                  labelText: 'arabicText'.tr(),
                  hintText: 'arabicTextHint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // DÜZELTME: Direkt TextDirection.rtl kullan
	        textAlign: TextAlign.right,
               // textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 18),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // Okunuş
              TextFormField(
                controller: _transliterationController,
                decoration: InputDecoration(
                  labelText: 'transliteration'.tr(),
                  hintText: 'transliterationHint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              // Ek bilgiler
              _buildSectionTitle('additionalInfo'.tr()),
              const SizedBox(height: 16),
              
              // Amaç/Fayda
              TextFormField(
                controller: _purposeController,
                decoration: InputDecoration(
                  labelText: 'purpose'.tr(),
                  hintText: 'purposeHint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                maxLength: 300,
              ),
              const SizedBox(height: 16),
              
              // Kaynak
              TextFormField(
                controller: _sourceController,
                decoration: InputDecoration(
                  labelText: 'source'.tr(),
                  hintText: 'sourceHint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Paylaşım ayarları
              _buildSectionTitle('shareSettings'.tr()),
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: Text('shareWithEveryone'.tr()),
                subtitle: Text(
                  _isPublic 
                      ? 'shareWithEveryoneDesc'.tr()
                      : 'privateZikirDesc'.tr()
                ),
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
              ),
              const SizedBox(height: 32),
              
              // Oluştur butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _createCustomZikir,
                        icon: const Icon(Icons.add_circle),
                        label: Text('createZikir'.tr()),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  // Bölüm başlığı
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
  
  // Yardım dialog'u
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('customZikirGuide'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem('📝', 'helpGuideTitle'.tr(), 'helpGuideZikirName'.tr()),
              _buildHelpItem('📖', 'helpGuideDescription'.tr(), 'helpGuideZikirMeaning'.tr()),
              _buildHelpItem('🏷️', 'helpGuideCategory'.tr(), 'helpGuideSelectCategory'.tr()),
              _buildHelpItem('🎯', 'helpGuideTarget'.tr(), 'helpGuideDailyTarget'.tr()),
              _buildHelpItem('🔤', 'helpGuideArabic'.tr(), 'helpGuideArabicText'.tr()),
              _buildHelpItem('💎', 'helpGuidePurpose'.tr(), 'helpGuideSpiritualBenefits'.tr()),
              _buildHelpItem('📚', 'helpGuideSource'.tr(), 'helpGuideReference'.tr()),
              _buildHelpItem('🌐', 'helpGuideSharing'.tr(), 'helpGuideShareOption'.tr()),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('understood'.tr()),
          ),
        ],
      ),
    );
  }
  
  // Yardım öğesi
  Widget _buildHelpItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}