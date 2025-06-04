// Dosya: lib/core/config/firebase_options.dart
// Açıklama: Firebase hizmetleri için platforma özgü yapılandırma dosyası.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'FIREBASE_ANDROID_API_KEY',
    appId: 'FIREBASE_ANDROID_APP_ID',
    messagingSenderId: 'FIREBASE_MESSAGING_SENDER_ID',
    projectId: 'FIREBASE_PROJECT_ID',
    storageBucket: 'FIREBASE_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'FIREBASE_IOS_API_KEY',
    appId: 'FIREBASE_IOS_APP_ID',
    messagingSenderId: 'FIREBASE_MESSAGING_SENDER_ID',
    projectId: 'FIREBASE_PROJECT_ID',
    storageBucket: 'FIREBASE_STORAGE_BUCKET',
    iosBundleId: 'FIREBASE_IOS_BUNDLE_ID',
  );
}