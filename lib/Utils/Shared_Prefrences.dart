import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SharedPreferencesHelper {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // ───── Username ─────
  static Future<void> saveUsername(String value) async {
    await _storage.write(key: 'username', value: value);
  }

  static Future<String> getUsername() async {
    return await _storage.read(key: 'username') ?? '';
  }

  // ───── Zone ─────
  static Future<void> saveZoneCode(String value) async {
    await _storage.write(key: 'zone', value: value);
  }

  static Future<String> getZoneCode() async {
    return await _storage.read(key: 'zone') ?? '';
  }

  // ───── Phone ─────
  static Future<void> savePhone(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String> getPhone(String key) async {
    return await _storage.read(key: key) ?? '';
  }

  // ───── Password ─────
  static Future<void> savePassword(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String> getPassword(String key) async {
    return await _storage.read(key: key) ?? '';
  }

  // ───── CNIC ─────
  static Future<void> saveCNIC(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String> getCNIC(String key) async {
    return await _storage.read(key: key) ?? '';
  }

  // ───── Token ─────
  static Future<void> saveToken(String value) async {
    await _storage.write(key: 'token', value: value);
  }

  static Future<String> getToken() async {
    return await _storage.read(key: 'token') ?? '';
  }

  // ───── Date ─────
  static Future<void> saveDate(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String> getDate(String key) async {
    return await _storage.read(key: key) ?? '';
  }

  // ───── Name ─────
  static Future<void> saveName(String value) async {
    await _storage.write(key: 'name', value: value);
  }

  static Future<String> getName() async {
    return await _storage.read(key: 'name') ?? '';
  }

  // ───── Onboarding ─────
  static Future<bool> getOnboardingStatus() async {
    final value = await _storage.read(key: 'onboardingStatus');
    return value == 'true';
  }

  static Future<void> setOnboardingStatus(bool newValue) async {
    await _storage.write(
        key: 'onboardingStatus', value: newValue.toString());
  }

  // ───── Login ─────
  static Future<bool> getIsLogin() async {
    final value = await _storage.read(key: 'isLogin');
    return value == 'true';
  }

  static Future<void> setIsLogin(bool newValue) async {
    await _storage.write(key: 'isLogin', value: newValue.toString());
  }

  // ───── Clear All (optional) ─────
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}