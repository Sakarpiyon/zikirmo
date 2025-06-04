// Dosya: lib/features/settings/settings_screen.dart
// Yol: C:\src\zikirmo_new\lib\features\settings\settings_screen.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../routes.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Zikir sayacı ayarları
  bool _useVibration = true;
  bool _useSound = true;
  double _counterSize = 80.0;
  
  // Bildirim ayarları
  bool _enableDailyReminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  
  // Uygulama içi satın alımları gizleme
  bool _hideInAppPurchases = false;

  // Email test için loading state
  bool _emailTestLoading = false;

  @override
  void initState() {
    super.initState();
    // TODO: Ayarları SharedPreferences'dan yükle
  }

  // EMAIL TEST BUTONU - Geçici test için
  Future<void> _testEmailVerification() async {
    setState(() {
      _emailTestLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      
      if (user == null) {
        _showTestResult('❌ Test Hatası', 'Kullanıcı oturum açmamış');
        return;
      }

      debugPrint('🧪 EMAIL TEST: ${user.email} için doğrulama gönderiliyor...');
      
      await authService.sendEmailVerification();
      
      debugPrint('✅ EMAIL TEST: Doğrulama e-postası gönderildi');
      _showTestResult('✅ Test Başarılı', 'Doğrulama e-postası ${user.email} adresine gönderildi.\n\nE-posta kutunuzu kontrol edin.');
      
    } catch (e) {
      debugPrint('❌ EMAIL TEST HATASI: $e');
      _showTestResult('❌ Test Hatası', e.toString().replaceAll('Exception:', '').trim());
    } finally {
      setState(() {
        _emailTestLoading = false;
      });
    }
  }

  void _showTestResult(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // Hatırlatıcı saatini seçme
  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && mounted) {
      setState(() {
        _reminderTime = picked;
      });
      
      // Bildirim hizmetini güncelle - providers.dart'tan geliyor
      if (_enableDailyReminder) {
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.scheduleDailyNotification(
          'zikirReminder'.tr(),
          'dailyZikirReminder'.tr(),
          _reminderTime.hour,
          _reminderTime.minute,
        );
      }
    }
  }

  // Dil değiştirme
  void _changeLanguage(String languageCode) async {
    await context.setLocale(Locale(languageCode));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Mevcut tema modu
    final themeMode = ref.watch(themeModeProvider);
    
    // Mevcut dil
    final currentLocale = context.locale.languageCode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
      ),
      body: ListView(
        children: [
          // Hesap ayarları
          _buildSectionHeader(context, 'Hesap'.tr()),
          
          ListTile(
            leading: const Icon(Icons.person),
            title: Text('Profil'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          
          if (_isUserLoggedIn())
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text('signOut'.tr()),
              onTap: () async {
                await _showSignOutDialog();
              },
            ),

          // 🧪 TEST BÖLÜMÜ - GEÇİCİ
          _buildSectionHeader(context, '🧪 Developer Test'),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Geçici Test Bölümü',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu bölüm sadece email doğrulama testleri için eklendi. Test tamamlandıktan sonra kaldırılacak.',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          ListTile(
            leading: _emailTestLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.email_outlined),
            title: Text('📧 Email Doğrulama Testi'),
            subtitle: Text('Mevcut kullanıcıya doğrulama e-postası gönder'),
            trailing: _emailTestLoading 
              ? null 
              : const Icon(Icons.send),
            onTap: _emailTestLoading ? null : _testEmailVerification,
          ),
          
          // Uygulama ayarları
          _buildSectionHeader(context, 'Uygulama'.tr()),
          
          // Dil seçimi
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('language'.tr()),
            subtitle: Text(_getLanguageName(currentLocale)),
            trailing: DropdownButton<String>(
              underline: const SizedBox(),
              value: currentLocale,
              onChanged: (value) {
                if (value != null) {
                  _changeLanguage(value);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: 'tr',
                  child: Text('Türkçe'),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
              ],
            ),
          ),
          
          // Tema seçimi
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text('Tema'.tr()),
            subtitle: Text(_getThemeModeName(themeMode)),
            trailing: DropdownButton<ThemeMode>(
              underline: const SizedBox(),
              value: themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).state = value;
                }
              },
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('Sistem'.tr()),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Aydınlık'.tr()),
                ),
                DropdownMenuItem(
                 value: ThemeMode.dark,
                 child: Text('Karanlık'.tr()),
               ),
             ],
           ),
         ),
         
         // Zikir sayacı ayarları
         _buildSectionHeader(context, 'Zikir Sayacı'.tr()),
         
         // Titreşim
         SwitchListTile(
           secondary: const Icon(Icons.vibration),
           title: Text('Titreşim'.tr()),
           subtitle: Text('Zikir sayarken titreşim'.tr()),
           value: _useVibration,
           onChanged: (value) {
             setState(() {
               _useVibration = value;
             });
             // TODO: Ayarı kaydet
           },
         ),
         
         // Ses
         SwitchListTile(
           secondary: const Icon(Icons.volume_up),
           title: Text('Ses'.tr()),
           subtitle: Text('Zikir sayarken ses'.tr()),
           value: _useSound,
           onChanged: (value) {
             setState(() {
               _useSound = value;
             });
             // TODO: Ayarı kaydet
           },
         ),
         
         // Sayaç boyutu
         ListTile(
           leading: const Icon(Icons.touch_app),
           title: Text('Sayaç Boyutu'.tr()),
           subtitle: Slider(
             value: _counterSize,
             min: 50.0,
             max: 120.0,
             divisions: 7,
             label: _counterSize.round().toString(),
             onChanged: (value) {
               setState(() {
                 _counterSize = value;
               });
               // TODO: Ayarı kaydet
             },
           ),
         ),
         
         // Bildirim ayarları
         _buildSectionHeader(context, 'Bildirimler'.tr()),
         
         // Günlük hatırlatıcı
         SwitchListTile(
           secondary: const Icon(Icons.notifications),
           title: Text('Günlük Hatırlatıcı'.tr()),
           subtitle: Text('Her gün zikirlerinizi hatırlatır'.tr()),
           value: _enableDailyReminder,
           onChanged: (value) async {
             setState(() {
               _enableDailyReminder = value;
             });
             
             final notificationService = ref.read(notificationServiceProvider);
             if (value) {
               await notificationService.scheduleDailyNotification(
                 'zikirReminder'.tr(),
                 'dailyZikirReminder'.tr(),
                 _reminderTime.hour,
                 _reminderTime.minute,
               );
             } else {
               await notificationService.cancelAllNotifications();
             }
             
             // TODO: Ayarı kaydet
           },
         ),
         
         // Hatırlatıcı saati
         if (_enableDailyReminder)
           ListTile(
             leading: const Icon(Icons.access_time),
             title: Text('Hatırlatıcı Saati'.tr()),
             subtitle: Text(
               '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
             ),
             onTap: _selectReminderTime,
           ),
         
         // Gizlilik ayarları
         _buildSectionHeader(context, 'Gizlilik'.tr()),
         
         // Satın alımları gizleme
         SwitchListTile(
           secondary: const Icon(Icons.visibility_off),
           title: Text('Satın Alımları Gizle'.tr()),
           subtitle: Text('Premium içerikleri gizle'.tr()),
           value: _hideInAppPurchases,
           onChanged: (value) {
             setState(() {
               _hideInAppPurchases = value;
             });
             // TODO: Ayarı kaydet
           },
         ),
         
         // Hakkında
         _buildSectionHeader(context, 'Hakkında'.tr()),
         
         ListTile(
           leading: const Icon(Icons.info),
           title: Text('Uygulama Hakkında'.tr()),
           trailing: const Icon(Icons.chevron_right),
           onTap: () {
             _showAboutDialog();
           },
         ),
         
         ListTile(
           leading: const Icon(Icons.description),
           title: Text('Gizlilik Politikası'.tr()),
           trailing: const Icon(Icons.chevron_right),
           onTap: () {
             // TODO: Gizlilik politikası sayfasına git
           },
         ),
         
         ListTile(
           leading: const Icon(Icons.gavel),
           title: Text('Kullanım Şartları'.tr()),
           trailing: const Icon(Icons.chevron_right),
           onTap: () {
             // TODO: Kullanım şartları sayfasına git
           },
         ),
         
         // Versiyon bilgisi
         const Padding(
           padding: EdgeInsets.all(16.0),
           child: Center(
             child: Text(
               'Versiyon 1.0.0',
               style: TextStyle(color: Colors.grey),
             ),
           ),
         ),
       ],
     ),
   );
 }
 
 // Bölüm başlığı
 Widget _buildSectionHeader(BuildContext context, String title) {
   return Padding(
     padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(
           title,
           style: Theme.of(context).textTheme.titleMedium?.copyWith(
                 color: Theme.of(context).primaryColor,
                 fontWeight: FontWeight.bold,
               ),
         ),
         const SizedBox(height: 8),
         const Divider(),
       ],
     ),
   );
 }
 
 // Kullanıcının oturum açıp açmadığını kontrol et
 bool _isUserLoggedIn() {
   final authService = ref.read(authServiceProvider);
   return authService.currentUser != null;
 }
 
 // Çıkış onay dialog'u
 Future<void> _showSignOutDialog() async {
   return showDialog<void>(
     context: context,
     barrierDismissible: false,
     builder: (BuildContext context) {
       return AlertDialog(
         title: Text('Çıkış'.tr()),
         content: SingleChildScrollView(
           child: ListBody(
             children: <Widget>[
               Text('Çıkış yapmak istediğinize emin misiniz?'.tr()),
             ],
           ),
         ),
         actions: <Widget>[
           TextButton(
             child: Text('cancel'.tr()),
             onPressed: () {
               Navigator.of(context).pop();
             },
           ),
           TextButton(
             child: Text('signOut'.tr()),
             onPressed: () async {
               Navigator.of(context).pop();
               
               final authService = ref.read(authServiceProvider);
               await authService.signOut();
               
               if (context.mounted) {
                 Navigator.pushReplacementNamed(context, AppRoutes.login);
               }
             },
           ),
         ],
       );
     },
   );
 }
 
 // Hakkında dialog'u
 void _showAboutDialog() {
   showAboutDialog(
     context: context,
     applicationName: 'Zikir Matik',
     applicationVersion: '1.0.0',
     applicationIcon: const Icon(
       Icons.apps,
       size: 48,
       color: Colors.teal,
     ),
     applicationLegalese: '© 2025 Zikir Matik. Tüm hakları saklıdır.',
     children: [
       const SizedBox(height: 16),
       Text('Zikir Matik, zikir ibadetlerinizi kolayca takip etmenizi sağlayan bir uygulamadır.'.tr()),
     ],
   );
 }
 
 // Dil adını al
 String _getLanguageName(String languageCode) {
   switch (languageCode) {
     case 'tr':
       return 'Türkçe';
     case 'en':
       return 'English';
     default:
       return languageCode;
   }
 }
 
 // Tema modu adını al
 String _getThemeModeName(ThemeMode mode) {
   switch (mode) {
     case ThemeMode.system:
       return 'Sistem'.tr();
     case ThemeMode.light:
       return 'Aydınlık'.tr();
     case ThemeMode.dark:
       return 'Karanlık'.tr();
   }
 }
}