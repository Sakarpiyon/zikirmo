// Dosya: lib/features/admin/admin_settings_screen.dart
// Açıklama: Admin'in puanlama sistemi değerlerini düzenleyebileceği ekran.
// Klasör: lib/features/admin
// Firebase User hatası düzeltildi

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/providers.dart';
import '../../core/services/firestore_service.dart';

final adminSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final firestoreService = FirestoreService();
  final doc = await firestoreService.firestore.collection('settings').doc('points').get();
  return doc.data() ?? {};
});

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'clickPoints': TextEditingController(),
    'dailyGoalPoints': TextEditingController(),
    'streak5DaysPoints': TextEditingController(),
    'streak7DaysPoints': TextEditingController(),
    'streak30DaysPoints': TextEditingController(),
    'customZikirPoints': TextEditingController(),
    'profileCompletePoints': TextEditingController(),
    'friendInvitePoints': TextEditingController(),
    'perfectWeekPoints': TextEditingController(),
    'levelUpBonusPoints': TextEditingController(),
  };

  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // Admin statüsünü kontrol et - Firebase User hatası düzeltildi
  Future<void> _checkAdminStatus() async {
    try {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      
      if (user != null) {
        // customClaims yerine getIdTokenResult() kullan
        final idTokenResult = await user.getIdTokenResult();
        final claims = idTokenResult.claims;
        
        setState(() {
          _isAdmin = claims?['admin'] == true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAdmin = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final firestoreService = FirestoreService();
      final settings = _controllers.map((key, controller) => MapEntry(key, double.parse(controller.text)));
      await firestoreService.setSettings(settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('settingsSaved'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading kontrolü
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Admin kontrolü - düzeltildi
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: Text('adminSettings'.tr()),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'adminAccessRequired'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'contactAdminForAccess'.tr(),
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('goBack'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    final settingsAsync = ref.watch(adminSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('adminSettingsTitle'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('adminModeActive'.tr())),
              );
            },
          ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) {
          // Controller'ları güncelle
          _controllers.forEach((key, controller) {
            controller.text = (settings[key] ?? _getDefaultValue(key)).toString();
          });
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık ve açıklama
                    Card(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.settings,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'pointsSettings'.tr(),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'pointsSettingsDescription'.tr(),
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Form alanları
                    ..._controllers.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: _getFieldLabel(entry.key),
                          hintText: _getFieldHint(entry.key),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(_getFieldIcon(entry.key)),
                          suffix: const Text('puan'),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'valueRequired'.tr();
                          }
                          if (double.tryParse(value) == null) {
                            return 'invalidNumber'.tr();
                          }
                          final number = double.parse(value);
                          if (number < 0) {
                            return 'valueCannotBeNegative'.tr();
                          }
                          return null;
                        },
                      ),
                    )),
                    
                    const SizedBox(height: 32),
                    
                    // Kaydet butonu
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: Text('save'.tr()),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Sıfırla butonu
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _resetToDefaults,
                        icon: const Icon(Icons.refresh),
                        label: Text('resetToDefaults'.tr()),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text('errorLoadingSettings'.tr()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(adminSettingsProvider),
                child: Text('retry'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Varsayılan değerleri sıfırla
  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('resetToDefaults'.tr()),
        content: Text('resetToDefaultsConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _controllers.forEach((key, controller) {
                controller.text = _getDefaultValue(key).toString();
              });
            },
            child: Text('reset'.tr()),
          ),
        ],
      ),
    );
  }

  // Varsayılan değerleri getir
  double _getDefaultValue(String key) {
    switch (key) {
      case 'clickPoints':
        return 1;
      case 'dailyGoalPoints':
        return 10;
      case 'streak5DaysPoints':
        return 20;
      case 'streak7DaysPoints':
        return 40;
      case 'streak30DaysPoints':
        return 200;
      case 'customZikirPoints':
        return 5;
      case 'profileCompletePoints':
        return 10;
      case 'friendInvitePoints':
        return 15;
      case 'perfectWeekPoints':
        return 50;
      case 'levelUpBonusPoints':
        return 30;
      default:
        return 0;
    }
  }

  // Alan etiketlerini getir
  String _getFieldLabel(String key) {
    switch (key) {
      case 'clickPoints':
        return 'clickPointsLabel'.tr();
      case 'dailyGoalPoints':
        return 'dailyGoalPointsLabel'.tr();
      case 'streak5DaysPoints':
        return 'streak5DaysPointsLabel'.tr();
      case 'streak7DaysPoints':
        return 'streak7DaysPointsLabel'.tr();
      case 'streak30DaysPoints':
        return 'streak30DaysPointsLabel'.tr();
      case 'customZikirPoints':
        return 'customZikirPointsLabel'.tr();
      case 'profileCompletePoints':
        return 'profileCompletePointsLabel'.tr();
      case 'friendInvitePoints':
        return 'friendInvitePointsLabel'.tr();
      case 'perfectWeekPoints':
        return 'perfectWeekPointsLabel'.tr();
      case 'levelUpBonusPoints':
        return 'levelUpBonusPointsLabel'.tr();
      default:
        return key.tr();
    }
  }

  // Alan ipuçlarını getir
  String _getFieldHint(String key) {
    switch (key) {
      case 'clickPoints':
        return 'clickPointsHint'.tr();
      case 'dailyGoalPoints':
        return 'dailyGoalPointsHint'.tr();
      case 'streak5DaysPoints':
        return 'streakPointsHint'.tr();
      case 'streak7DaysPoints':
        return 'streakPointsHint'.tr();
      case 'streak30DaysPoints':
        return 'streakPointsHint'.tr();
      case 'customZikirPoints':
        return 'customZikirPointsHint'.tr();
      case 'profileCompletePoints':
        return 'profileCompletePointsHint'.tr();
      case 'friendInvitePoints':
        return 'friendInvitePointsHint'.tr();
      case 'perfectWeekPoints':
        return 'perfectWeekPointsHint'.tr();
      case 'levelUpBonusPoints':
        return 'levelUpBonusPointsHint'.tr();
      default:
        return '';
    }
  }

  // Alan ikonlarını getir
  IconData _getFieldIcon(String key) {
    switch (key) {
      case 'clickPoints':
        return Icons.touch_app;
      case 'dailyGoalPoints':
        return Icons.today;
      case 'streak5DaysPoints':
      case 'streak7DaysPoints':
      case 'streak30DaysPoints':
        return Icons.local_fire_department;
      case 'customZikirPoints':
        return Icons.create;
      case 'profileCompletePoints':
        return Icons.account_circle;
      case 'friendInvitePoints':
        return Icons.person_add;
      case 'perfectWeekPoints':
        return Icons.star;
      case 'levelUpBonusPoints':
        return Icons.trending_up;
      default:
        return Icons.settings;
    }
  }
}