import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Player {
  final String id;
  final String name;
  final DateTime createdAt;
  int gamesPlayed;
  int gamesWon;
  int totalPoints;
  int totalInnings;
  int totalFouls;
  int totalSaves;
  int highestRun;

  Player({
    required this.id,
    required this.name,
    DateTime? createdAt,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.totalPoints = 0,
    this.totalInnings = 0,
    this.totalFouls = 0,
    this.totalSaves = 0,
    this.highestRun = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'totalPoints': totalPoints,
        'totalInnings': totalInnings,
        'totalFouls': totalFouls,
        'totalSaves': totalSaves,
        'highestRun': highestRun,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'],
        name: json['name'],
        createdAt: DateTime.parse(json['createdAt']),
        gamesPlayed: json['gamesPlayed'] ?? 0,
        gamesWon: json['gamesWon'] ?? 0,
        totalPoints: json['totalPoints'] ?? 0,
        totalInnings: json['totalInnings'] ?? 0,
        totalFouls: json['totalFouls'] ?? 0,
        totalSaves: json['totalSaves'] ?? 0,
        highestRun: json['highestRun'] ?? 0,
      );

  Player copyWith({
    String? name,
    int? gamesPlayed,
    int? gamesWon,
    int? totalPoints,
    int? totalInnings,
    int? totalFouls,
    int? totalSaves,
    int? highestRun,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      totalPoints: totalPoints ?? this.totalPoints,
      totalInnings: totalInnings ?? this.totalInnings,
      totalFouls: totalFouls ?? this.totalFouls,
      totalSaves: totalSaves ?? this.totalSaves,
      highestRun: highestRun ?? this.highestRun,
    );
  }

  // Calculated statistics
  double get averagePointsPerGame =>
      gamesPlayed > 0 ? totalPoints / gamesPlayed : 0.0;

  double get averageInningsPerGame =>
      gamesPlayed > 0 ? totalInnings / gamesPlayed : 0.0;

  double get averageFoulsPerGame =>
      gamesPlayed > 0 ? totalFouls / gamesPlayed : 0.0;

  double get winRate =>
      gamesPlayed > 0 ? (gamesWon / gamesPlayed) * 100 : 0.0;
}

class PlayerService {
  static const String _key = 'players';

  Future<List<Player>> getAllPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? playersJson = prefs.getString(_key);
    
    if (playersJson == null) return [];
    
    final List<dynamic> decoded = json.decode(playersJson);
    return decoded.map((json) => Player.fromJson(json)).toList();
  }

  Future<void> savePlayers(List<Player> players) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(players.map((p) => p.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<Player> createPlayer(String name) async {
    final players = await getAllPlayers();
    
    // Check if player already exists
    if (players.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      throw Exception('Player with this name already exists');
    }
    
    final newPlayer = Player(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
    
    players.add(newPlayer);
    await savePlayers(players);
    
    return newPlayer;
  }

  Future<void> deletePlayer(String id) async {
    final players = await getAllPlayers();
    players.removeWhere((p) => p.id == id);
    await savePlayers(players);
  }

  Future<void> updatePlayer(Player player) async {
    final players = await getAllPlayers();
    final index = players.indexWhere((p) => p.id == player.id);
    
    if (index != -1) {
      players[index] = player;
      await savePlayers(players);
    }
  }

  Future<void> updatePlayerName(String id, String newName) async {
    final players = await getAllPlayers();
    
    // Check if another player already has this name
    if (players.any((p) => p.id != id && p.name.toLowerCase() == newName.toLowerCase())) {
      throw Exception('Player with this name already exists');
    }
    
    final index = players.indexWhere((p) => p.id == id);
    if (index != -1) {
      players[index] = players[index].copyWith(name: newName);
      await savePlayers(players);
    }
  }

  Future<Player?> getPlayerByName(String name) async {
    final players = await getAllPlayers();
    try {
      return players.firstWhere(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
