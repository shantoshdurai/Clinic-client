import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static bool isFirebaseConfigured = false;

  static const String projectId = 'asclinic-6cd9b';

  /// Point the app at the local Firebase emulators instead of the live clinic
  /// project, so a full sign-in / admin / OP-desk run can be rehearsed without
  /// creating real accounts or real patient records:
  ///
  ///   firebase emulators:start --only firestore,auth
  ///   flutter run --dart-define=USE_FIREBASE_EMULATOR=true
  ///
  /// Off unless explicitly set, so release builds always hit production.
  static const bool useEmulator =
      bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);

  static const String emulatorHost =
      String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: 'localhost');

  static const FirebaseOptions androidOptions = FirebaseOptions(
    apiKey: 'AIzaSyAN6vOSPgdB57GRsqJF33Rr_8naXL_qnsQ',
    appId: '1:301979891962:android:81904c1dd476fbc8503143',
    messagingSenderId: '301979891962',
    projectId: 'asclinic-6cd9b',
    storageBucket: 'asclinic-6cd9b.firebasestorage.app',
  );

  /// Safe initialization that works seamlessly with production Firebase project
  static Future<void> initialize() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android || useEmulator) {
        await Firebase.initializeApp(options: androidOptions);
      } else {
        await Firebase.initializeApp();
      }
      isFirebaseConfigured = true;
      debugPrint('[FirebaseConfig] Connected to Firebase ($projectId) successfully.');
    } catch (e) {
      debugPrint('[FirebaseConfig] Fallback initialization: $e');
      try {
        await Firebase.initializeApp();
        isFirebaseConfigured = true;
      } catch (e2) {
        isFirebaseConfigured = false;
        debugPrint('[FirebaseConfig] Offline mode fallback: $e2');
      }
    }

    if (isFirebaseConfigured && useEmulator) {
      await _connectEmulators();
    }
  }

  static Future<void> _connectEmulators() async {
    try {
      FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
      await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
      debugPrint('[FirebaseConfig] Using local emulators at $emulatorHost '
          '(Firestore 8080, Auth 9099). No production data is touched.');
    } catch (e) {
      debugPrint('[FirebaseConfig] Emulator wiring failed: $e');
    }
  }
}
