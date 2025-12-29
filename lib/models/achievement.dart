class Achievement {
  final String id;
  final String title;
  final String description;
  final String howToUnlock;
  final String emoji;
  final bool isEasterEgg;
  final DateTime? unlockedAt;
  final List<String> unlockedBy;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.howToUnlock,
    required this.emoji,
    this.isEasterEgg = false,
    this.unlockedAt,
    List<String>? unlockedBy,
  }) : unlockedBy = unlockedBy ?? [];

  bool get isUnlocked => unlockedAt != null;

  Achievement copyWith({
    DateTime? unlockedAt,
    List<String>? unlockedBy,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      howToUnlock: howToUnlock,
      emoji: emoji,
      isEasterEgg: isEasterEgg,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      unlockedBy: unlockedBy ?? this.unlockedBy,
    );
  }

  Achievement addUnlocker(String playerName) {
    final updatedList = List<String>.from(unlockedBy);
    if (!updatedList.contains(playerName)) {
      updatedList.add(playerName);
    }
    return copyWith(
      unlockedAt: unlockedAt ?? DateTime.now(),
      unlockedBy: updatedList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'unlockedAt': unlockedAt?.toIso8601String(),
        'unlockedBy': unlockedBy,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) {
    // Find the template from definitions
    final template = AchievementDefinitions.all.firstWhere(
      (a) => a.id == json['id'],
      orElse: () => Achievement(
        id: json['id'],
        title: 'Unknown',
        description: '',
        howToUnlock: '',
        emoji: '❓',
      ),
    );

    return Achievement(
      id: template.id,
      title: template.title,
      description: template.description,
      howToUnlock: template.howToUnlock,
      emoji: template.emoji,
      isEasterEgg: template.isEasterEgg,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
      unlockedBy: List<String>.from(json['unlockedBy'] ?? []),
    );
  }
}

class AchievementDefinitions {
  // ===== STARTER ACHIEVEMENTS =====
  static final firstGame = Achievement(
    id: 'first_game',
    title: 'Erstes Spiel',
    description: 'Herzlichen Glückwunsch! Du hast dein erstes 14.1 Spiel abgeschlossen.',
    howToUnlock: 'Beende dein erstes Spiel',
    emoji: '🎱',
  );

  static final firstWin = Achievement(
    id: 'first_win',
    title: 'Erster Sieg',
    description: 'Dein erster Sieg! Der Anfang einer großartigen Karriere.',
    howToUnlock: 'Gewinne ein Spiel',
    emoji: '🏆',
  );

  // ===== CATEGORY 1: RUN STREAKS (Single Inning Scoring) =====
  static final streak10 = Achievement(
    id: 'streak_10',
    title: 'Aufwärmphase',
    description: '10 Bälle in einer Aufnahme versenkt. Ein solider Start!',
    howToUnlock: 'Erziele eine 10er-Serie',
    emoji: '🎯',
  );

  static final streak20 = Achievement(
    id: 'streak_20',
    title: 'Im Flow',
    description: '20 Bälle ohne Unterbrechung! Du kommst in Fahrt.',
    howToUnlock: 'Erziele eine 20er-Serie',
    emoji: '🔥',
  );

  static final streak30 = Achievement(
    id: 'streak_30',
    title: 'Meisterschaft',
    description: '30 Bälle am Stück! Das ist wahre Meisterschaft.',
    howToUnlock: 'Erziele eine 30er-Serie',
    emoji: '⭐',
  );

  static final streak40 = Achievement(
    id: 'streak_40',
    title: 'Virtuose',
    description: '40 Bälle in Folge! Du beherrschst den Tisch.',
    howToUnlock: 'Erziele eine 40er-Serie',
    emoji: '💎',
  );

  static final streak50 = Achievement(
    id: 'streak_50',
    title: 'Legende',
    description: '50 Bälle ohne Fehler! Ein legendärer Lauf!',
    howToUnlock: 'Erziele eine 50er-Serie',
    emoji: '👑',
  );

  // ===== CATEGORY 2: TOTAL BALLS POCKETED (Career Total) =====
  static final balls100 = Achievement(
    id: 'balls_100',
    title: 'Jahrhundert',
    description: '100 Bälle versenkt! Deine Reise beginnt.',
    howToUnlock: 'Versenke insgesamt 100 Bälle',
    emoji: '💯',
  );

  static final balls500 = Achievement(
    id: 'balls_500',
    title: 'Fleißig',
    description: '500 Bälle! Du baust dir eine beeindruckende Statistik auf.',
    howToUnlock: 'Versenke insgesamt 500 Bälle',
    emoji: '📈',
  );

  static final balls1000 = Achievement(
    id: 'balls_1000',
    title: 'Tausender-Marke',
    description: '1.000 Bälle versenkt! Ein bedeutender Meilenstein.',
    howToUnlock: 'Versenke insgesamt 1.000 Bälle',
    emoji: '🎖️',
  );

  static final balls2500 = Achievement(
    id: 'balls_2500',
    title: 'Billard-Veteran',
    description: '2.500 Bälle! Du bist ein erfahrener Spieler.',
    howToUnlock: 'Versenke insgesamt 2.500 Bälle',
    emoji: '🏅',
  );

  static final balls5000 = Achievement(
    id: 'balls_5000',
    title: 'Billard-Gott',
    description: '5.000 Bälle versenkt! Du bist eine lebende Legende!',
    howToUnlock: 'Versenke insgesamt 5.000 Bälle',
    emoji: '🌟',
  );

  // ===== CATEGORY 3: WIN STREAKS (Consecutive Victories) =====
  static final wins3 = Achievement(
    id: 'wins_3',
    title: 'Hattrick',
    description: '3 Siege in Folge! Du bist auf dem richtigen Weg.',
    howToUnlock: 'Gewinne 3 Spiele hintereinander',
    emoji: '🎲',
  );

  static final wins5 = Achievement(
    id: 'wins_5',
    title: 'Siegesserie',
    description: '5 Siege nacheinander! Du bist in Topform.',
    howToUnlock: 'Gewinne 5 Spiele hintereinander',
    emoji: '🏅',
  );

  static final wins10 = Achievement(
    id: 'wins_10',
    title: 'Unaufhaltsam',
    description: '10 Siege ohne Niederlage! Niemand kann dich stoppen.',
    howToUnlock: 'Gewinne 10 Spiele hintereinander',
    emoji: '💪',
  );

  static final wins15 = Achievement(
    id: 'wins_15',
    title: 'Dominator',
    description: '15 Siege am Stück! Du dominierst jeden Gegner.',
    howToUnlock: 'Gewinne 15 Spiele hintereinander',
    emoji: '⚡',
  );

  static final wins20 = Achievement(
    id: 'wins_20',
    title: 'Unbesiegbar',
    description: '20 Siege in Folge! Du bist praktisch unbesiegbar!',
    howToUnlock: 'Gewinne 20 Spiele hintereinander',
    emoji: '🔱',
  );

  // ===== SPECIAL ACHIEVEMENTS =====
  static final perfectGame = Achievement(
    id: 'perfect_game',
    title: 'Perfektes Spiel',
    description: 'Ein Spiel ohne ein einziges Foul gewonnen! Makellos!',
    howToUnlock: 'Gewinne ein Spiel ohne Fouls',
    emoji: '💎',
  );

  static final speedDemon = Achievement(
    id: 'speed_demon',
    title: 'Geschwindigkeitsdämon',
    description: 'Spiel in unter 10 Aufnahmen gewonnen. Blitzschnell!',
    howToUnlock: 'Gewinne in weniger als 10 Aufnahmen',
    emoji: '⚡',
  );

  static final comeback = Achievement(
    id: 'comeback',
    title: 'Comeback-König',
    description: 'Aus einem 50-Punkte-Rückstand gewonnen! Niemals aufgeben!',
    howToUnlock: 'Gewinne mit 50+ Punkten Rückstand',
    emoji: '👊',
  );

  static final safetyMaster = Achievement(
    id: 'safety_master',
    title: 'Safety-Meister',
    description: '10 erfolgreiche Safety-Shots in einem Spiel. Taktisch brillant!',
    howToUnlock: 'Spiele 10 Safety-Shots in einem Spiel',
    emoji: '🛡️',
  );

  static final marathon = Achievement(
    id: 'marathon',
    title: 'Marathon-Spieler',
    description: 'Wow! 50 Spiele gespielt. Deine Ausdauer ist beeindruckend.',
    howToUnlock: 'Spiele 50 Spiele',
    emoji: '🏃',
  );

  // ===== EASTER EGGS =====
  static final luckyNumber = Achievement(
    id: 'lucky_7',
    title: 'Glückszahl 7',
    description: 'Die 7 ist deine Lieblingskugel! Du hast sie in 7 aufeinanderfolgenden Aufnahmen versenkt.',
    howToUnlock: '🤐 Geheimnis!',
    emoji: '🍀',
    isEasterEgg: true,
  );

  static List<Achievement> get all => [
        // Starter
        firstGame,
        firstWin,
        
        // Run Streaks Category
        streak10,
        streak20,
        streak30,
        streak40,
        streak50,
        
        // Total Balls Category
        balls100,
        balls500,
        balls1000,
        balls2500,
        balls5000,
        
        // Win Streaks Category
        wins3,
        wins5,
        wins10,
        wins15,
        wins20,
        
        // Special
        perfectGame,
        speedDemon,
        comeback,
        safetyMaster,
        marathon,
        
        // Easter Eggs
        luckyNumber,
      ];
}
