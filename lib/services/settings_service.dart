import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_settings.dart';

class SettingsService {
  static const String _settingsKey = 'game_settings';

  Future<GameSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);
    
    if (jsonString == null) {
      return GameSettings();
    }
    
    try {
      final json = jsonDecode(jsonString);
      return GameSettings.fromJson(json);
    } catch (e) {
      return GameSettings();
    }
  }

  Future<void> saveSettings(GameSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, jsonString);
  }
}
