class Player {
  final String name;
  int score;
  int currentInning;
  bool isActive;
  int saves; // Statistics: number of safe plays

  Player({
    required this.name,
    this.score = 0,
    this.currentInning = 1,
    this.isActive = false,
    this.saves = 0,
  });

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
  }) {
    return Player(
      name: name ?? this.name,
      score: score ?? this.score,
      currentInning: currentInning ?? this.currentInning,
      isActive: isActive ?? this.isActive,
      saves: saves ?? this.saves,
    );
  }
  Map<String, dynamic> toJson() => {
    'name': name,
    'score': score,
    'currentInning': currentInning,
    'isActive': isActive,
    'saves': saves,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    name: json['name'] as String,
    score: json['score'] as int,
    currentInning: json['currentInning'] as int,
    isActive: json['isActive'] as bool? ?? false,
    saves: json['saves'] as int? ?? 0,
  );
}
