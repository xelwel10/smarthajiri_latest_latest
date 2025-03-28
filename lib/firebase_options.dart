// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
    apiKey: 'AIzaSyCzH8xJWQD_-nzA9Q4vmeEJG0xxmwUCz98',
    appId: '1:383136500392:web:1a875a60ae6e0283c5109d',
    messagingSenderId: '383136500392',
    projectId: 'waterlevelindicator-18ad7',
    authDomain: 'waterlevelindicator-18ad7.firebaseapp.com',
    databaseURL: 'https://waterlevelindicator-18ad7-default-rtdb.firebaseio.com',
    storageBucket: 'waterlevelindicator-18ad7.appspot.com',
    measurementId: 'G-42BKNZRT22',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2Zq4fQ-RzU_-dOVw1B2Nz-kaQnd6xc00',
    appId: '1:383136500392:android:19d9c79570bc1f95c5109d',
    messagingSenderId: '383136500392',
    projectId: 'waterlevelindicator-18ad7',
    databaseURL: 'https://waterlevelindicator-18ad7-default-rtdb.firebaseio.com',
    storageBucket: 'waterlevelindicator-18ad7.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC8ib5k21FzffFggvdrIVxjUGbmfknn0ao',
    appId: '1:383136500392:ios:debec3603dba79d6c5109d',
    messagingSenderId: '383136500392',
    projectId: 'waterlevelindicator-18ad7',
    databaseURL: 'https://waterlevelindicator-18ad7-default-rtdb.firebaseio.com',
    storageBucket: 'waterlevelindicator-18ad7.appspot.com',
    iosBundleId: 'com.xelwel.smarthajiri',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC8ib5k21FzffFggvdrIVxjUGbmfknn0ao',
    appId: '1:383136500392:ios:debec3603dba79d6c5109d',
    messagingSenderId: '383136500392',
    projectId: 'waterlevelindicator-18ad7',
    databaseURL: 'https://waterlevelindicator-18ad7-default-rtdb.firebaseio.com',
    storageBucket: 'waterlevelindicator-18ad7.appspot.com',
    iosBundleId: 'com.xelwel.smarthajiri',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCzH8xJWQD_-nzA9Q4vmeEJG0xxmwUCz98',
    appId: '1:383136500392:web:4aec8c3d7a3a7051c5109d',
    messagingSenderId: '383136500392',
    projectId: 'waterlevelindicator-18ad7',
    authDomain: 'waterlevelindicator-18ad7.firebaseapp.com',
    databaseURL: 'https://waterlevelindicator-18ad7-default-rtdb.firebaseio.com',
    storageBucket: 'waterlevelindicator-18ad7.appspot.com',
    measurementId: 'G-W48QQ4ZWL8',
  );

}