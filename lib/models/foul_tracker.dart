class FoulTracker {
  int consecutiveNormalFouls = 0;
  bool threeFoulRuleEnabled;

  FoulTracker({this.threeFoulRuleEnabled = true});

  /// Returns penalty points. -15 if 3-foul triggered, -1 otherwise
  int applyNormalFoul() {
    if (threeFoulRuleEnabled) {
      consecutiveNormalFouls++;
      if (consecutiveNormalFouls >= 3) {
        consecutiveNormalFouls = 0;
        return -15; // 3-foul penalty
      }
    }
    return -1;
  }

  /// Severe (Break) Foul: -2 points, does NOT count toward 3-foul rule
  int applySevereFoul() {
    return -2;
  }

  void resetOnSuccessfulShot() {
    consecutiveNormalFouls = 0;
  }

  void reset() {
    consecutiveNormalFouls = 0;
  }
  Map<String, dynamic> toJson() => {
    'consecutiveNormalFouls': consecutiveNormalFouls,
    'threeFoulRuleEnabled': threeFoulRuleEnabled,
  };

  factory FoulTracker.fromJson(Map<String, dynamic> json) {
    return FoulTracker(
      threeFoulRuleEnabled: json['threeFoulRuleEnabled'] as bool? ?? true,
    )..consecutiveNormalFouls = json['consecutiveNormalFouls'] as int? ?? 0;
  }
}
