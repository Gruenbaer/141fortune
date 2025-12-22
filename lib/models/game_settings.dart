class GameSettings {
  bool threeFoulRuleEnabled;
  int raceToScore;
  String player1Name;
  String player2Name;
  bool isLeagueGame;
  int player1Handicap;
  int player2Handicap;
  int maxInnings;
  bool soundEnabled;
  String languageCode;
  bool isDarkTheme;

  GameSettings({
    this.threeFoulRuleEnabled = true,
    this.raceToScore = 100,
    this.player1Name = 'Player 1',
    this.player2Name = 'Player 2',
    this.isLeagueGame = false,
    this.player1Handicap = 0,
    this.player2Handicap = 0,
    this.maxInnings = 25, // Standard for 14.1
    this.soundEnabled = true,
    this.languageCode = 'de', // Default: German
    this.isDarkTheme = false, // Default: Light theme
  });

  Map<String, dynamic> toJson() => {
        'threeFoulRuleEnabled': threeFoulRuleEnabled,
        'raceToScore': raceToScore,
        'player1Name': player1Name,
        'player2Name': player2Name,
        'isLeagueGame': isLeagueGame,
        'player1Handicap': player1Handicap,
        'player2Handicap': player2Handicap,
        'maxInnings': maxInnings,
        'soundEnabled': soundEnabled,
        'languageCode': languageCode,
        'isDarkTheme': isDarkTheme,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        threeFoulRuleEnabled: json['threeFoulRuleEnabled'] ?? true,
        raceToScore: json['raceToScore'] ?? 100,
        player1Name: json['player1Name'] ?? 'Player 1',
        player2Name: json['player2Name'] ?? 'Player 2',
        isLeagueGame: json['isLeagueGame'] ?? false,
        player1Handicap: json['player1Handicap'] ?? 0,
        player2Handicap: json['player2Handicap'] ?? 0,
        maxInnings: json['maxInnings'] ?? 25,
        soundEnabled: json['soundEnabled'] ?? true,
        languageCode: json['languageCode'] ?? 'de',
        isDarkTheme: json['isDarkTheme'] ?? false,
      );

  GameSettings copyWith({
    bool? threeFoulRuleEnabled,
    int? raceToScore,
    String? player1Name,
    String? player2Name,
    bool? isLeagueGame,
    int? player1Handicap,
    int? player2Handicap,
    int? maxInnings,
    bool? soundEnabled,
    String? languageCode,
    bool? isDarkTheme,
  }) {
    return GameSettings(
      threeFoulRuleEnabled: threeFoulRuleEnabled ?? this.threeFoulRuleEnabled,
      raceToScore: raceToScore ?? this.raceToScore,
      player1Name: player1Name ?? this.player1Name,
      player2Name: player2Name ?? this.player2Name,
      isLeagueGame: isLeagueGame ?? this.isLeagueGame,
      player1Handicap: player1Handicap ?? this.player1Handicap,
      player2Handicap: player2Handicap ?? this.player2Handicap,
      maxInnings: maxInnings ?? this.maxInnings,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      languageCode: languageCode ?? this.languageCode,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
    );
  }
}
