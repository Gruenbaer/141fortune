class Player {
  final String name;
  int score;
  int currentInning;
  bool isActive;
  int saves; // Statistics: number of safe plays
  int consecutiveFouls; // Track consecutive fouls for 3-foul rule
  double handicapMultiplier; // Points multiplier (1.0, 2.0, 3.0)

  Player({
    required this.name,
    this.score = 0,
    this.currentInning = 1,
    this.isActive = false,
    this.saves = 0,
    this.consecutiveFouls = 0,
    double handicapMultiplier = 1.0,
  }) : handicapMultiplier = handicapMultiplier.clamp(0.1, 10.0); // Defensive: prevent 0x or extreme values

  void addScore(int points) {
    score += points;
  }

  void incrementInning() {
    currentInning++;
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
  }) {
    return Player(
      name: name ?? this.name,
      score: score ?? this.score,
      currentInning: currentInning ?? this.currentInning,
      isActive: isActive ?? this.isActive,
      saves: saves ?? this.saves,
      consecutiveFouls: consecutiveFouls ?? this.consecutiveFouls,
      handicapMultiplier: (handicapMultiplier ?? this.handicapMultiplier).clamp(0.1, 10.0),
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
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    name: json['name'] as String,
    score: json['score'] as int,
    currentInning: json['currentInning'] as int,
    isActive: json['isActive'] as bool? ?? false,
    saves: json['saves'] as int? ?? 0,
    consecutiveFouls: json['consecutiveFouls'] as int? ?? 0,
    handicapMultiplier: (json['handicapMultiplier'] ?? 1.0).toDouble(),
  );
}
