import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static Future<void> save(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_$key', jsonEncode(data));
    await prefs.setInt('cache_${key}_ts', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<dynamic> get(String key, {int maxAgeMinutes = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cache_$key');
    final ts = prefs.getInt('cache_${key}_ts') ?? 0;

    if (cached == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > maxAgeMinutes * 60 * 1000) return null; // expired

    return jsonDecode(cached);
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cache_$key');
    await prefs.remove('cache_${key}_ts');
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
