class GameSettings {
  bool threeFoulRuleEnabled;
  int raceToScore;
  String player1Name;
  String player2Name;
  bool isLeagueGame;
  int player1Handicap;
  int player2Handicap;
  double player1HandicapMultiplier;
  double player2HandicapMultiplier;
  int maxInnings;
  bool soundEnabled;
  String languageCode;
  bool isDarkTheme;
  String themeId;
  bool hasSeenBreakFoulRules;
  bool hasShown2FoulWarning;
  bool hasShown3FoulWarning;

  GameSettings({
    this.threeFoulRuleEnabled = true,
    this.raceToScore = 100,
    this.player1Name = '',
    this.player2Name = '',
    this.isLeagueGame = false,
    this.player1Handicap = 0,
    this.player2Handicap = 0,
    this.player1HandicapMultiplier = 1.0,
    this.player2HandicapMultiplier = 1.0,
    this.maxInnings = 25, // Standard for 14.1
    this.soundEnabled = true,
    this.languageCode = 'de', // Default: German
    this.isDarkTheme = false, // Default: Light theme
    this.themeId = 'cyberpunk',
    this.hasSeenBreakFoulRules = false,
    this.hasShown2FoulWarning = false,
    this.hasShown3FoulWarning = false,
  });

  Map<String, dynamic> toJson() => {
        'threeFoulRuleEnabled': threeFoulRuleEnabled,
        'raceToScore': raceToScore,
        'player1Name': player1Name,
        'player2Name': player2Name,
        'isLeagueGame': isLeagueGame,
        'player1Handicap': player1Handicap,
        'player2Handicap': player2Handicap,
        'player1HandicapMultiplier': player1HandicapMultiplier,
        'player2HandicapMultiplier': player2HandicapMultiplier,
        'maxInnings': maxInnings,
        'soundEnabled': soundEnabled,
        'languageCode': languageCode,
        'isDarkTheme': isDarkTheme,
        'themeId': themeId,
        'hasSeenBreakFoulRules': hasSeenBreakFoulRules,
      'hasShown2FoulWarning': hasShown2FoulWarning,
      'hasShown3FoulWarning': hasShown3FoulWarning,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        threeFoulRuleEnabled: json['threeFoulRuleEnabled'] ?? true,
        raceToScore: json['raceToScore'] ?? 100,
        player1Name: json['player1Name'] ?? '',
        player2Name: json['player2Name'] ?? '',
        isLeagueGame: json['isLeagueGame'] ?? false,
        player1Handicap: json['player1Handicap'] ?? 0,
        player2Handicap: json['player2Handicap'] ?? 0,
        player1HandicapMultiplier: (json['player1HandicapMultiplier'] ?? 1.0).toDouble(),
        player2HandicapMultiplier: (json['player2HandicapMultiplier'] ?? 1.0).toDouble(),
        maxInnings: json['maxInnings'] ?? 25,
        soundEnabled: json['soundEnabled'] ?? true,
        languageCode: json['languageCode'] ?? 'de',
        isDarkTheme: json['isDarkTheme'] ?? false,
        themeId: json['themeId'] ?? 'steampunk',
        hasSeenBreakFoulRules: json['hasSeenBreakFoulRules'] ?? false,
      hasShown2FoulWarning: json['hasShown2FoulWarning'] ?? false,
      hasShown3FoulWarning: json['hasShown3FoulWarning'] ?? false,
      );

  GameSettings copyWith({
    bool? threeFoulRuleEnabled,
    int? raceToScore,
    String? player1Name,
    String? player2Name,
    bool? isLeagueGame,
    int? player1Handicap,
    int? player2Handicap,
    double? player1HandicapMultiplier,
    double? player2HandicapMultiplier,
    int? maxInnings,
    bool? soundEnabled,
    String? languageCode,
    bool? isDarkTheme,
    String? themeId,
    bool? hasSeenBreakFoulRules,
    bool? hasShown2FoulWarning,
    bool? hasShown3FoulWarning,
  }) {
    return GameSettings(
      threeFoulRuleEnabled: threeFoulRuleEnabled ?? this.threeFoulRuleEnabled,
      raceToScore: raceToScore ?? this.raceToScore,
      player1Name: player1Name ?? this.player1Name,
      player2Name: player2Name ?? this.player2Name,
      isLeagueGame: isLeagueGame ?? this.isLeagueGame,
      player1Handicap: player1Handicap ?? this.player1Handicap,
      player2Handicap: player2Handicap ?? this.player2Handicap,
      player1HandicapMultiplier: player1HandicapMultiplier ?? this.player1HandicapMultiplier,
      player2HandicapMultiplier: player2HandicapMultiplier ?? this.player2HandicapMultiplier,
      maxInnings: maxInnings ?? this.maxInnings,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      languageCode: languageCode ?? this.languageCode,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      themeId: themeId ?? this.themeId,
      hasSeenBreakFoulRules: hasSeenBreakFoulRules ?? this.hasSeenBreakFoulRules,
      hasShown2FoulWarning: hasShown2FoulWarning ?? this.hasShown2FoulWarning,
      hasShown3FoulWarning: hasShown3FoulWarning ?? this.hasShown3FoulWarning,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is GameSettings &&
      other.threeFoulRuleEnabled == threeFoulRuleEnabled &&
      other.raceToScore == raceToScore &&
      other.player1Name == player1Name &&
      other.player2Name == player2Name &&
      other.isLeagueGame == isLeagueGame &&
      other.player1Handicap == player1Handicap &&
      other.player2Handicap == player2Handicap &&
      other.player1HandicapMultiplier == player1HandicapMultiplier &&
      other.player2HandicapMultiplier == player2HandicapMultiplier &&
      other.maxInnings == maxInnings &&
      other.soundEnabled == soundEnabled &&
      other.languageCode == languageCode &&
      other.isDarkTheme == isDarkTheme &&
      other.themeId == themeId &&
      other.hasSeenBreakFoulRules == hasSeenBreakFoulRules;
  }

  @override
  int get hashCode {
    return threeFoulRuleEnabled.hashCode ^
      raceToScore.hashCode ^
      player1Name.hashCode ^
      player2Name.hashCode ^
      isLeagueGame.hashCode ^
      player1Handicap.hashCode ^
      player2Handicap.hashCode ^
      player1HandicapMultiplier.hashCode ^
      player2HandicapMultiplier.hashCode ^
      maxInnings.hashCode ^
      soundEnabled.hashCode ^
      languageCode.hashCode ^
      isDarkTheme.hashCode ^
      themeId.hashCode ^
      hasSeenBreakFoulRules.hashCode;
  }
}
