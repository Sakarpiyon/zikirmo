// lib/features/home/home_screen_backup.dart
// ORİJİNAL HOMESCREEN YEDEĞİ - BOZULURSA BUNU KULLAN
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/providers/providers.dart';

class HomeScreenBackup extends ConsumerWidget {
  const HomeScreenBackup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('home'.tr()),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hoş geldin mesajı
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.teal,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '🎉 Giriş Başarılı! 🎉',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Firebase Authentication çalışıyor!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.teal.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Kullanıcı bilgileri
              if (user != null) ...[
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Text(
                        user.email?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user.displayName ?? 'Kullanıcı'),
                    subtitle: Text(user.email ?? ''),
                    trailing: Icon(
                      user.emailVerified ? Icons.verified : Icons.warning,
                      color: user.emailVerified ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'User ID: ${user.uid}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Çıkış butonu
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Çıkış hatası: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: Text('signOut'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}