// Bu scripti terminal'de çalıştırın: dart simple_admin.dart
import 'dart:io';

void main() async {
  print('🚀 Basit Firebase Test Script');
  print('Bu script sadece bağlantı testi yapar\n');

  // Firebase projesi bilgileri
  const projectId = 'zikirmatik-be5c0';
  
  print('📊 Firebase Proje Bilgileri:');
  print('Project ID: $projectId');
  print('Auth Domain: $projectId.firebaseapp.com');
  print('Storage Bucket: $projectId.firebasestorage.app\n');

  print('🔑 Test Kullanıcıları (Manuel oluşturun):');
  print('Admin: admin@zikirmatik.com / Admin123!');
  print('Test: test@zikirmatik.com / Test123!\n');

  print('📝 Firebase Console\'da yapılacaklar:');
  print('1. Authentication → Sign-in method → Email/Password: ENABLE');
  print('2. Authentication → Sign-in method → Google: ENABLE');  
  print('3. Authentication → Users → Add user (manuel)');
  print('4. Firestore Database → Create database');
  print('5. Firestore → Rules → Test moduna alın:\n');
  
  print('📋 Firestore Rules (geçici):');
  print('''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true; // TESTİNG İÇİN - ÜRETIMDE DEĞİŞTİRİN
    }
  }
}
  ''');

  print('\n🌐 Firebase Console Linki:');
  print('https://console.firebase.google.com/project/$projectId\n');

  print('⚡ Sonraki adımlar:');
  print('1. Firebase Console\'a gidin');
  print('2. Authentication ayarlarını yapın'); 
  print('3. Test kullanıcılarını manuel ekleyin');
  print('4. Flutter uygulamasını test edin\n');

  print('✅ Script tamamlandı!');
}