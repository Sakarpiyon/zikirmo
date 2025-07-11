// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBNc1yEX0mXMB0L8ZJTgb0_RJTg6FF-pB4',
    appId: '1:510473874379:web:ace2eec82312a4cf3c644e',
    messagingSenderId: '510473874379',
    projectId: 'zikirmatik-be5c0',
    authDomain: 'zikirmatik-be5c0.firebaseapp.com',
    storageBucket: 'zikirmatik-be5c0.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC7lKo8mBQSNW_9Tfj5MuFKRRht0Wo8dqc',
    appId: '1:510473874379:ios:f649491ce49dc0c13c644e',
    messagingSenderId: '510473874379',
    projectId: 'zikirmatik-be5c0',
    storageBucket: 'zikirmatik-be5c0.firebasestorage.app',
    iosBundleId: 'com.zikirmo.zikirmoNew',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC7lKo8mBQSNW_9Tfj5MuFKRRht0Wo8dqc',
    appId: '1:510473874379:ios:f649491ce49dc0c13c644e',
    messagingSenderId: '510473874379',
    projectId: 'zikirmatik-be5c0',
    storageBucket: 'zikirmatik-be5c0.firebasestorage.app',
    iosBundleId: 'com.zikirmo.zikirmoNew',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBNc1yEX0mXMB0L8ZJTgb0_RJTg6FF-pB4',
    appId: '1:510473874379:web:ace2eec82312a4cf3c644e',
    messagingSenderId: '510473874379',
    projectId: 'zikirmatik-be5c0',
    authDomain: 'zikirmatik-be5c0.firebaseapp.com',
    storageBucket: 'zikirmatik-be5c0.firebasestorage.app',
    measurementId: 'G-MDP7VPX7D5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAFy9XnebVQFc8Itt_jnCwaZYm67k8zpR8',
    appId: '1:510473874379:android:b73bda7d7e84d6943c644e',
    messagingSenderId: '510473874379',
    projectId: 'zikirmatik-be5c0',
    storageBucket: 'zikirmatik-be5c0.firebasestorage.app',
  );
}