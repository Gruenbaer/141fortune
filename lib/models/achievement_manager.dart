import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'achievement.dart';

class AchievementManager extends ChangeNotifier {
  final Map<String, Achievement> _achievements = {};
  Function(Achievement)? onAchievementUnlocked;

  AchievementManager() {
    // Initialize with all definitions
    for (var achievement in AchievementDefinitions.all) {
      _achievements[achievement.id] = achievement;
    }
    _loadFromPrefs();
  }

  List<Achievement> get allAchievements => _achievements.values.toList();
  List<Achievement> get unlockedAchievements => 
      _achievements.values.where((a) => a.isUnlocked).toList();

  bool isUnlocked(String id) => _achievements[id]?.isUnlocked ?? false;

  Future<void> unlock(String id, {String playerName = ''}) async {
    final achievement = _achievements[id];
    if (achievement == null || achievement.isUnlocked) return;

    final unlockedAchievement = achievement.copyWith(
      unlockedAt: DateTime.now(),
      unlockedBy: playerName.isNotEmpty 
          ? [...achievement.unlockedBy, playerName]
          : achievement.unlockedBy,
    );
    
    _achievements[id] = unlockedAchievement;
    notifyListeners();
    await _saveToPrefs();

    // Trigger callback for splash screen
    onAchievementUnlocked?.call(unlockedAchievement);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('achievements');
    if (jsonString == null) return;

    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      data.forEach((id, achievementJson) {
        if (_achievements.containsKey(id)) {
          _achievements[id] = Achievement.fromJson(achievementJson);
        }
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = {};
    _achievements.forEach((id, achievement) {
      data[id] = achievement.toJson();
    });
    await prefs.setString('achievements', json.encode(data));
  }

  Future<void> reset() async {
    for (var id in _achievements.keys) {
      final def = AchievementDefinitions.all.firstWhere((a) => a.id == id);
      _achievements[id] = def;
    }
    notifyListeners();
    await _saveToPrefs();
  }
}
