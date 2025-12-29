class Player {
  final String name;
  int score;
  int currentInning;
  bool isActive;
  int saves; // Statistics: number of safe plays
  int consecutiveFouls; // Track consecutive fouls for 3-foul rule
  double handicapMultiplier; // Points multiplier (1.0, 2.0, 3.0)
  int? lastPoints; // Points from the very last action
  int highestRun; // Highest run in the current match
  int currentRun; // Run in current inning

  Player({
    required this.name,
    this.score = 0,
    this.currentInning = 1,
    this.isActive = false,
    this.saves = 0,
    this.consecutiveFouls = 0,
    double handicapMultiplier = 1.0,
    this.lastPoints,
    this.highestRun = 0,
    this.currentRun = 0,
  }) : handicapMultiplier = handicapMultiplier.clamp(0.1, 10.0);

  void addScore(int points) {
    score += points;
    lastPoints = points;
    
    if (points > 0) {
      currentRun += points;
      if (currentRun > highestRun) {
         highestRun = currentRun;
      }
    }
    // Negative points don't affect current run (e.g. foul), 
    // but the run ends when inning increments.
  }

  void incrementInning() {
    currentInning++;
    currentRun = 0; // Reset run for new inning
    lastPoints = null; // Reset last points visual
  }

  void incrementSaves() {
    saves++;
  }

  Player copyWith({
    String? name,
    int? score,
    int? currentInning,
    bool? isActive,
    int? saves,
    int? consecutiveFouls,
    double? handicapMultiplier,
    int? lastPoints,
    int? highestRun,
    int? currentRun,
  }) {
    return Player(
      name: name ?? this.name,
      score: score ?? this.score,
      currentInning: currentInning ?? this.currentInning,
      isActive: isActive ?? this.isActive,
      saves: saves ?? this.saves,
      consecutiveFouls: consecutiveFouls ?? this.consecutiveFouls,
      handicapMultiplier: (handicapMultiplier ?? this.handicapMultiplier).clamp(0.1, 10.0),
      lastPoints: lastPoints ?? this.lastPoints,
      highestRun: highestRun ?? this.highestRun,
      currentRun: currentRun ?? this.currentRun,
    );
  }
  Map<String, dynamic> toJson() => {
    'name': name,
    'score': score,
    'currentInning': currentInning,
    'isActive': isActive,
    'saves': saves,
    'consecutiveFouls': consecutiveFouls,
    'handicapMultiplier': handicapMultiplier,
    'lastPoints': lastPoints,
    'highestRun': highestRun,
    'currentRun': currentRun,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    name: json['name'] as String,
    score: json['score'] as int,
    currentInning: json['currentInning'] as int,
    isActive: json['isActive'] as bool? ?? false,
    saves: json['saves'] as int? ?? 0,
    consecutiveFouls: json['consecutiveFouls'] as int? ?? 0,
    handicapMultiplier: (json['handicapMultiplier'] ?? 1.0).toDouble(),
    lastPoints: json['lastPoints'] as int?,
    highestRun: json['highestRun'] as int? ?? 0,
    currentRun: json['currentRun'] as int? ?? 0,
  );
}
