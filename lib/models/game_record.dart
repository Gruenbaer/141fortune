class GameRecord {
  final String id;
  final String player1Name;
  final String player2Name;
  final int player1Score;
  final int player2Score;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final String? winner;
  final int raceToScore;
  final int player1Innings;
  final int player2Innings;
  final int player1HighestRun;
  final int player2HighestRun;
  final int player1Fouls;
  final int player2Fouls;
  // Store minimal data for resume (will expand later)
  final List<int>? activeBalls; // Which balls are still on table
  final bool? player1IsActive; // Which player's turn
  final Map<String, dynamic>? snapshot; // Full GameState snapshot

  GameRecord({
    required this.id,
    required this.player1Name,
    required this.player2Name,
    required this.player1Score,
    required this.player2Score,
    required this.startTime,
    this.endTime,
    required this.isCompleted,
    this.winner,
    required this.raceToScore,
    this.player1Innings = 0,
    this.player2Innings = 0,
    this.player1HighestRun = 0,
    this.player2HighestRun = 0,
    this.player1Fouls = 0,
    this.player2Fouls = 0,
    this.activeBalls,
    this.player1IsActive,
    this.snapshot,
  });

  // Calculate game duration
  Duration getDuration() {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  // Format duration as human-readable string
  String getFormattedDuration() {
    final duration = getDuration();
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours h $minutes min';
    }
    return '$minutes min';
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player1Name': player1Name,
      'player2Name': player2Name,
      'player1Score': player1Score,
      'player2Score': player2Score,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isCompleted': isCompleted,
      'winner': winner,
      'raceToScore': raceToScore,
      'player1Innings': player1Innings,
      'player2Innings': player2Innings,
      'player1HighestRun': player1HighestRun,
      'player2HighestRun': player2HighestRun,
      'player1Fouls': player1Fouls,
      'player2Fouls': player2Fouls,
      'activeBalls': activeBalls,
      'player1IsActive': player1IsActive,
      'snapshot': snapshot,
    };
  }

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      id: json['id'],
      player1Name: json['player1Name'],
      player2Name: json['player2Name'],
      player1Score: json['player1Score'],
      player2Score: json['player2Score'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      isCompleted: json['isCompleted'],
      winner: json['winner'],
      raceToScore: json['raceToScore'],
      player1Innings: json['player1Innings'] ?? 0,
      player2Innings: json['player2Innings'] ?? 0,
      player1HighestRun: json['player1HighestRun'] ?? 0,
      player2HighestRun: json['player2HighestRun'] ?? 0,
      player1Fouls: json['player1Fouls'] ?? 0,
      player2Fouls: json['player2Fouls'] ?? 0,
      activeBalls: json['activeBalls'] != null 
          ? List<int>.from(json['activeBalls'])
          : null,
      player1IsActive: json['player1IsActive'],
      snapshot: json['snapshot'] != null 
          ? Map<String, dynamic>.from(json['snapshot']) 
          : null,
    );
  }

  // Create completed game record
  GameRecord copyWithCompletion(String winnerName) {
    return GameRecord(
      id: id,
      player1Name: player1Name,
      player2Name: player2Name,
      player1Score: player1Score,
      player2Score: player2Score,
      startTime: startTime,
      endTime: DateTime.now(),
      isCompleted: true,
      winner: winnerName,
      raceToScore: raceToScore,
      player1Innings: player1Innings,
      player2Innings: player2Innings,
      player1HighestRun: player1HighestRun,
      player2HighestRun: player2HighestRun,
      player1Fouls: player1Fouls,
      player2Fouls: player2Fouls,
      snapshot: null, // Don't allow resume of completed game
    );
  }
}
