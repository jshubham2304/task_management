import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// lib/core/services/session_service.dart

class SessionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SharedPreferences _prefs;

  static const String _lastLoginKey = 'last_login';
  static const String _userIdKey = 'user_id';

  SessionService(this._prefs);

  Future<void> saveSession(User user) async {
    await Future.wait([
      _prefs.setString(_lastLoginKey, DateTime.now().toIso8601String()),
      _prefs.setString(_userIdKey, user.uid),
    ]);
  }

  Future<void> clearSession() async {
    await Future.wait([
      _prefs.remove(_lastLoginKey),
      _prefs.remove(_userIdKey),
    ]);
  }

  bool get hasValidSession {
    final lastLogin = _prefs.getString(_lastLoginKey);
    final userId = _prefs.getString(_userIdKey);

    if (lastLogin == null || userId == null) return false;

    final lastLoginDate = DateTime.parse(lastLogin);
    final currentUser = _auth.currentUser;

    // Session is valid if:
    // 1. Last login was within 30 days
    // 2. Current user matches stored user ID
    // 3. Firebase auth token is still valid
    return DateTime.now().difference(lastLoginDate).inDays < 30 && currentUser?.uid == userId && currentUser != null;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
