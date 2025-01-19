// lib/core/config/firebase_config.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:task_management/firebase_options.dart';

class FirebaseConfig {
  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Firestore offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Enable network status monitoring
    FirebaseFirestore.instance.enableNetwork();
  }

  static Future<void> enableNetwork() async {
    try {
      await FirebaseFirestore.instance.enableNetwork();
    } catch (e) {
      // Handle network enable error
    }
  }

  static Future<void> disableNetwork() async {
    try {
      await FirebaseFirestore.instance.disableNetwork();
    } catch (e) {
      // Handle network disable error
    }
  }
}
