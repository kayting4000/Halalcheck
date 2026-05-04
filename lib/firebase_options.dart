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
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBvw2tRSact7mVVK9dz91WZJgLS6Mfle-o',
    appId: '1:67067428466:android:cc70642e12d771dfa8cceb',
    messagingSenderId: '67067428466',
    projectId: 'halalscanner-c7667',
    authDomain: 'halalscanner-c7667.firebaseapp.com',
    storageBucket: 'halalscanner-c7667.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDElzPgU2AxDHOooQPOZ4lEZf7bB-jGsYg',
    appId: '1:287840830584:ios:88d4c7928cfd76053d998d',
    messagingSenderId: '287840830584',
    projectId: 'gen-lang-client-0790556538',
    authDomain: 'gen-lang-client-0790556538.firebaseapp.com',
    storageBucket: 'gen-lang-client-0790556538.firebasestorage.app',
  );
}
