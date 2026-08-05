import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Box names used across the app. Keep centralized to avoid typos.
class HiveBoxes {
  HiveBoxes._();
  static const String settings = 'settings_box';
  static const String syncQueue = 'sync_queue_box';
  static const String customersCache = 'customers_cache_box';
  static const String ledgerCache = 'ledger_cache_box';
  static const String businessCache = 'business_cache_box';
}

/// Handles local persistence: Hive (offline cache + sync queue) and
/// FlutterSecureStorage (tokens, PIN, sensitive settings).
class LocalStorageService {
  LocalStorageService._();

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(HiveBoxes.settings),
      Hive.openBox(HiveBoxes.syncQueue),
      Hive.openBox(HiveBoxes.customersCache),
      Hive.openBox(HiveBoxes.ledgerCache),
      Hive.openBox(HiveBoxes.businessCache),
    ]);
  }

  static Box box(String name) => Hive.box(name);

  // Secure storage helpers (PIN, biometric flag, refresh tokens if needed).
  static Future<void> writeSecure(String key, String value) =>
      _secureStorage.write(key: key, value: value);

  static Future<String?> readSecure(String key) =>
      _secureStorage.read(key: key);

  static Future<void> deleteSecure(String key) =>
      _secureStorage.delete(key: key);
}
