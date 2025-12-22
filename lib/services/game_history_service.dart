import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game_record.dart';

class GameHistoryService {
  static const String _key = 'game_history';
  static const int _maxGames = 100; // Keep only 100 most recent games

  // Get all game records
  Future<List<GameRecord>> getAllGames() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_key);
    
    if (historyJson == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(historyJson);
      final games = decoded.map((json) => GameRecord.fromJson(json)).toList();
      
      // Sort by start time (newest first)
      games.sort((a, b) => b.startTime.compareTo(a.startTime));
      return games;
    } catch (e) {
      print('Error loading game history: $e');
      return [];
    }
  }

  // Get only active (in-progress) games
  Future<List<GameRecord>> getActiveGames() async {
    final allGames = await getAllGames();
    return allGames.where((game) => !game.isCompleted).toList();
  }

  // Get only completed games
  Future<List<GameRecord>> getCompletedGames() async {
    final allGames = await getAllGames();
    return allGames.where((game) => game.isCompleted).toList();
  }

  // Save a game record
  Future<void> saveGame(GameRecord game) async {
    final games = await getAllGames();
    
    // Check if game already exists (update it)
    final existingIndex = games.indexWhere((g) => g.id == game.id);
    if (existingIndex != -1) {
      games[existingIndex] = game;
    } else {
      games.insert(0, game); // Add to beginning (newest first)
    }
    
    // Cleanup old games if exceeded max
    await _cleanup(games);
    
    // Save to SharedPreferences
    await _saveGames(games);
  }

  // Delete a specific game
  Future<void> deleteGame(String id) async {
    final games = await getAllGames();
    games.removeWhere((g) => g.id == id);
    await _saveGames(games);
  }

  // Clear all game history
  Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // Get game by ID
  Future<GameRecord?> getGameById(String id) async {
    final games = await getAllGames();
    try {
      return games.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  // Private: Save games to storage
  Future<void> _saveGames(List<GameRecord> games) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(games.map((g) => g.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  // Private: Auto-cleanup old games (keep only max number)
  Future<void> _cleanup(List<GameRecord> games) async {
    if (games.length > _maxGames) {
      // Remove oldest games beyond the limit
      games.removeRange(_maxGames, games.length);
    }
  }

  // Get statistics summary
  Future<Map<String, dynamic>> getStatsSummary() async {
    final games = await getCompletedGames();
    
    if (games.isEmpty) {
      return {
        'totalGames': 0,
        'totalDuration': Duration.zero,
        'averageDuration': Duration.zero,
      };
    }

    final totalDuration = games.fold<Duration>(
      Duration.zero,
      (sum, game) => sum + game.getDuration(),
    );

    return {
      'totalGames': games.length,
      'totalDuration': totalDuration,
      'averageDuration': Duration(
        milliseconds: totalDuration.inMilliseconds ~/ games.length,
      ),
    };
  }
}
