// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAFbvLbab_QF91tHSp_ZOQNRq_-Uxq8qgA',
    appId: '1:1002512677601:web:24a4ca7fc5edcaafc815a0',
    messagingSenderId: '1002512677601',
    projectId: 'healthweb-a4064',
    authDomain: 'healthweb-a4064.firebaseapp.com',
    storageBucket: 'healthweb-a4064.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC-swKUf2knlK1pwaNG-zOapua1RVIq1vo',
    appId: '1:1002512677601:android:296117315da80b7bc815a0',
    messagingSenderId: '1002512677601',
    projectId: 'healthweb-a4064',
    storageBucket: 'healthweb-a4064.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB0QUPGlVdL1SDotqXiRG4UeLsNZ3Wh5aA',
    appId: '1:1002512677601:ios:c0abc25fa58a70adc815a0',
    messagingSenderId: '1002512677601',
    projectId: 'healthweb-a4064',
    storageBucket: 'healthweb-a4064.firebasestorage.app',
    iosBundleId: 'com.example.doctorApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB0QUPGlVdL1SDotqXiRG4UeLsNZ3Wh5aA',
    appId: '1:1002512677601:ios:c0abc25fa58a70adc815a0',
    messagingSenderId: '1002512677601',
    projectId: 'healthweb-a4064',
    storageBucket: 'healthweb-a4064.firebasestorage.app',
    iosBundleId: 'com.example.doctorApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAFbvLbab_QF91tHSp_ZOQNRq_-Uxq8qgA',
    appId: '1:1002512677601:web:ec8ecc181bf5d37cc815a0',
    messagingSenderId: '1002512677601',
    projectId: 'healthweb-a4064',
    authDomain: 'healthweb-a4064.firebaseapp.com',
    storageBucket: 'healthweb-a4064.firebasestorage.app',
  );
}