import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Kalıcı yerel depolama - SharedPreferences tabanlı
class StorageService {
  static const _usersKey = 'users';
  static const _companiesKey = 'companies';
  static const _transactionsKey = 'transactions';
  static const _settingsKey = 'settings';

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  Future<Map<String, dynamic>> loadAll() async {
    try {
      final p = await _prefs;
      final usersRaw = p.getString(_usersKey);
      final compRaw = p.getString(_companiesKey);
      final txnsRaw = p.getString(_transactionsKey);
      final setRaw = p.getString(_settingsKey);

      return {
        'users': usersRaw != null ? jsonDecode(usersRaw) : [],
        'companies': compRaw != null ? jsonDecode(compRaw) : [],
        'transactions': txnsRaw != null ? jsonDecode(txnsRaw) : [],
        'settings': setRaw != null ? jsonDecode(setRaw) : {},
      };
    } catch (_) {
      return {
        'users': [],
        'companies': [],
        'transactions': [],
        'settings': {},
      };
    }
  }

  Future<void> saveAll({
    required List<Map<String, dynamic>> users,
    required List<Map<String, dynamic>> companies,
    required List<Map<String, dynamic>> transactions,
    required Map<String, dynamic> settings,
  }) async {
    try {
      final p = await _prefs;
      await p.setString(_usersKey, jsonEncode(users));
      await p.setString(_companiesKey, jsonEncode(companies));
      await p.setString(_transactionsKey, jsonEncode(transactions));
      await p.setString(_settingsKey, jsonEncode(settings));
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      final p = await _prefs;
      await p.remove(_usersKey);
      await p.remove(_companiesKey);
      await p.remove(_transactionsKey);
      await p.remove(_settingsKey);
    } catch (_) {}
  }
}
