import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Kalıcı yerel depolama - SharedPreferences tabanlı (Windows / web uyumlu).
class StorageService {
  static const _usersKey = 'users';
  static const _companiesKey = 'companies';
  static const _transactionsKey = 'transactions';
  static const _settingsKey = 'settings';
  static const _loansKey = 'loans';
  static const _auditKey = 'audit';
  static const _notificationsKey = 'notifications';
  static const _metaKey = 'meta';
  static const _seededKey = 'seeded';

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  Future<Map<String, dynamic>> loadAll() async {
    try {
      final p = await _prefs;
      return {
        'users': _decode(p.getString(_usersKey), []),
        'companies': _decode(p.getString(_companiesKey), []),
        'transactions': _decode(p.getString(_transactionsKey), []),
        'settings': _decode(p.getString(_settingsKey), {}),
        'loans': _decode(p.getString(_loansKey), []),
        'audit': _decode(p.getString(_auditKey), []),
        'notifications': _decode(p.getString(_notificationsKey), []),
        'meta': _decode(p.getString(_metaKey), {}),
        'seeded': p.getBool(_seededKey) ?? false,
      };
    } catch (_) {
      return {
        'users': [],
        'companies': [],
        'transactions': [],
        'settings': {},
        'loans': [],
        'audit': [],
        'notifications': [],
        'meta': {},
        'seeded': false,
      };
    }
  }

  static dynamic _decode(String? raw, dynamic fallback) {
    if (raw == null || raw.isEmpty) return fallback;
    try {
      final decoded = jsonDecode(raw);
      return decoded ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> saveAll({
    required List<Map<String, dynamic>> users,
    required List<Map<String, dynamic>> companies,
    required List<Map<String, dynamic>> transactions,
    required Map<String, dynamic> settings,
    List<Map<String, dynamic>> loans = const [],
    List<Map<String, dynamic>> audit = const [],
    List<Map<String, dynamic>> notifications = const [],
    Map<String, dynamic> meta = const {},
  }) async {
    try {
      final p = await _prefs;
      await p.setString(_usersKey, jsonEncode(users));
      await p.setString(_companiesKey, jsonEncode(companies));
      await p.setString(_transactionsKey, jsonEncode(transactions));
      await p.setString(_settingsKey, jsonEncode(settings));
      await p.setString(_loansKey, jsonEncode(loans));
      await p.setString(_auditKey, jsonEncode(audit));
      await p.setString(_notificationsKey, jsonEncode(notifications));
      await p.setString(_metaKey, jsonEncode(meta));
    } catch (_) {}
  }

  Future<void> setSeeded(bool value) async {
    try {
      final p = await _prefs;
      await p.setBool(_seededKey, value);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      final p = await _prefs;
      for (final key in [
        _usersKey,
        _companiesKey,
        _transactionsKey,
        _settingsKey,
        _loansKey,
        _auditKey,
        _notificationsKey,
        _metaKey,
        _seededKey,
      ]) {
        await p.remove(key);
      }
    } catch (_) {}
  }
}
