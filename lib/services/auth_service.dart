import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles the app's PIN lock.
///
/// This protects the app if a phone is lost or picked up by someone else —
/// it is NOT full database encryption (the SQLite file itself isn't
/// encrypted yet). Think of it as a locked front door, not a safe. Proper
/// encryption-at-rest and individual surveyor logins are a good next step
/// once we build out cloud sync.
class AuthService {
  static const _pinHashKey = 'rashan_pin_hash';

  String _hash(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinHashKey) != null;
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinHashKey, _hash(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_pinHashKey);
    return storedHash != null && storedHash == _hash(pin);
  }
}
