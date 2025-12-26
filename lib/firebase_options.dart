import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Default Firebase options for each supported platform.
///
/// These values are required when running on platforms that don't have
/// native configuration files (e.g. web). If you create new Firebase apps
/// (iOS, macOS, Windows, etc.), update the corresponding [FirebaseOptions]
/// below with the values shown in the Firebase console.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Firebase options have not been configured for '
          '${defaultTargetPlatform.name}. '
          'Add the platform in Firebase and update firebase_options.dart.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCowo4dL23QYIRvr-3bab786V0fRUyNutc',
    appId: '1:126365997554:web:443b677c4a8c23de8af36b',
    messagingSenderId: '126365997554',
    projectId: 'unimartapp-cb00c',
    authDomain: 'unimartapp-cb00c.firebaseapp.com',
    storageBucket: 'unimartapp-cb00c.firebasestorage.app',
    measurementId: 'G-X4R9R4NZ4Q',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDi5kLaN0iV-qdJ0ZAKNLbYvMvTThn61yU',
    appId: '1:126365997554:android:9a31027105acde5b8af36b',
    messagingSenderId: '126365997554',
    projectId: 'unimartapp-cb00c',
    storageBucket: 'unimartapp-cb00c.firebasestorage.app',
  );
}
