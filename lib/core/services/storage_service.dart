import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Regular preferences
  static Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  static List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  static Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  // Secure storage for sensitive data
  static Future<void> setSecureString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  static Future<String?> getSecureString(String key) async {
    return await _secureStorage.read(key: key);
  }

  static Future<void> removeSecureString(String key) async {
    await _secureStorage.delete(key: key);
  }

  static Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
  }

  // Storage keys
  static const String apiKeyKey = 'api_key';
  static const String lastCodeKey = 'last_code';
  static const String codeHistoryKey = 'code_history';
  static const String settingsKey = 'app_settings';
  static const String darkModeKey = 'dark_mode';
  static const String autoSaveKey = 'auto_save';
  static const String fontSizeKey = 'font_size';
}