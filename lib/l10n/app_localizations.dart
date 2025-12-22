import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('de'), // German (default)
    Locale('en'), // English
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'de': {
      // App
      'appTitle': 'Fortune 14/2',
      
      // Home Screen
      'newGame': 'Neues Spiel',
      'new141Game': 'Neues 14.1 Spiel',
      'resume': 'Spiel fortsetzen',
      'players': 'Spieler',
      'statistics': 'Statistiken',
      'achievements': 'Erfolge',
      'settings': 'Einstellungen',
      'version': 'Version',
      
      // Game Setup
      'newGameSetup': 'Neues Spiel einrichten',
      'gameType': 'Spieltyp',
      'leagueGame': 'Ligaspiel',
      'leagueGameSubtitle': 'Für Statistiken und Ranglisten erfassen',
      'raceTo': 'Rennen bis',
      'custom': 'Benutzerdefiniert',
      'maxInnings': 'Max. Aufnahmen',
      'unlimited': 'Unbegrenzt',
      'playersTitle': 'Spieler',
      'player1': 'Spieler 1',
      'player2': 'Spieler 2',
      'enterOrSelectPlayer': 'Name eingeben oder auswählen',
      'createPlayer': 'Spieler erstellen',
      'handicap': 'Handicap',
      'additionalRules': 'Zusätzliche Regeln',
      'threeFoulRule': '3-Foul-Regel',
      'threeFoulRuleSubtitle': '3 aufeinanderfolgende Fouls = -15 Punkte',
      'startGame': 'Spiel starten',
      
      // Settings
      'soundEffects': 'Soundeffekte',
      'enableGameSounds': 'Spielsounds aktivieren',
      'language': 'Sprache',
      'german': 'Deutsch',
      'english': 'Englisch',
      'theme': 'Design',
      'lightTheme': 'Hell',
      'darkTheme': 'Dunkel',
      'raceToScore': 'Rennen bis',
      'points': 'Punkte',
      'save': 'Speichern',
      'settingsSaved': 'Einstellungen gespeichert!',
      
      // Player Management
      'playerCreated': 'Spieler erstellt ✓',
      'noPlayersYet': 'Noch keine Spieler',
      'tapToCreate': 'Tippen Sie auf +, um einen Spieler zu erstellen',
      'deletePlayer': 'Spieler löschen',
      'confirmDelete': 'Möchten Sie wirklich löschen',
      'playerName': 'Spielername',
      'gamesPlayed': 'Gespielte Spiele',
      'gamesWon': 'Gewonnene Spiele',
      'gamesLost': 'Verlorene Spiele',
      'editPlayer': 'Spieler bearbeiten',
      'playerUpdated': 'Spieler aktualisiert',
      'noAchievementsYet': 'Noch keine Erfolge freigeschaltet',
      
      // Statistics
      'overallStatistics': 'Gesamtstatistik',
      'games': 'Spiele',
      'fouls': 'Fouls',
      'bestRun': 'Beste Serie',
      'playerRankings': 'Spieler-Rangliste',
      'noStatistics': 'Noch keine Statistiken',
      'playGamesToSee': 'Spielen Sie Spiele, um Statistiken zu sehen',
      'sortBy': 'Sortieren nach',
      'rank': 'Rang',
      'winRate': 'Siegrate',
      'avgPoints': 'Ø Punkte',
      'highestRun': 'Höchste Serie',
      'totalPoints': 'Gesamt Punkte',
      'totalFouls': 'Gesamt Fouls',
      'totalInnings': 'Gesamt Aufnahmen',
      'totalSaves': 'Gesamt Safety-Shots',
      'avgInnings': 'Ø Aufnahmen',
      'avgFouls': 'Ø Fouls',
      
      // Achievements  
      'achievementsUnlocked': 'Erfolge freigeschaltet',
      'unlocked': 'Freigeschaltet',
      'howToUnlock': 'Wie man es freischaltet',
      'unlockedBy': 'Freigeschaltet von',
      'unlockedOn': 'Freigeschaltet am',
      'secretAchievement': 'Dies ist ein geheimes Easter Egg! Finde heraus, wie man es freischaltet! 🤫',
      
      // Game Screen
      'exitGame': 'Spiel beenden?',
      'exitGameMessage': 'Spielfortschritt geht verloren. Sind Sie sicher?',
      'restartGame': 'Spiel neustarten?',
      'restartGameMessage': 'Dies setzt alle Punkte und Verlauf zurück. Sind Sie sicher?',
      'gameRules': 'Spielregeln',
      'details': 'Details',
      'undo': 'Rückgängig',
      'redo': 'Wiederholen',
      
      // Common
      'cancel': 'Abbrechen',
      'close': 'Schließen',
      'delete': 'Löschen',
      'create': 'Erstellen',
      'edit': 'Bearbeiten',
      'back': 'Zurück',
      'yes': 'Ja',
      'no': 'Nein',
      'ok': 'OK',
      
      // Game Dialogs
      'exit': 'Beenden',
      'exitGameTitle': 'Spiel beenden?',
      'gameRulesContent': 'Fortune 14/2 (Modifiziert)\\n\\n1. Spielziel\\nDas Ziel ist es, die festgelegte Punktzahl zu erreichen (Rennen bis X).\\n\\n2. Punktevergabe\\nEine versenkte Kugel bringt Punkte gleich (15 - Kugelnummer).\\nBeispiel: Kugel 14 = 1 Punkt. Kugel 1 = 14 Punkte.\\n\\n3. Spezielle Kugeln\\n- Kugel 1: Bringt 14 Punkte und führt zu einem Neuaufbau. Spieler macht weiter.\\n- Doppel-Sack (Spielball): Bringt 15 Punkte und führt zu einem Neuaufbau. Spieler macht weiter.\\n\\n4. Fouls\\n- Normales Foul: -1 Punkt. 3 aufeinanderfolgende Fouls = -15 Punkte.\\n- Schweres Foul: -2 Punkte.',
      'threeFoulPenalty': '3-Foul-Strafe!',
      'threeFoulMessage': 'Spieler hat 3 aufeinanderfolgende Fouls begangen.\\n\\nStrafe: -15 Punkte\\n\\nDer Foulzähler wurde zurückgesetzt.',
      'resetGame': 'Spiel zurücksetzen',
      'resetGameMessage': 'Möchten Sie das Spiel wirklich zurücksetzen?',
      'reset': 'Zurücksetzen',
      
      // Game History
      'gameHistory': 'Spielverlauf',
      'allGames': 'Alle Spiele',
      'inProgress': 'Laufend',
      'completed': 'Abgeschlossen',
      'noGamesYet': 'Noch keine Spiele',
      'playGameToSeeHistory': 'Spielen Sie ein Spiel, um den Verlauf zu sehen',
      'resumeGame': 'Spiel fortsetzen',
      'viewStats': 'Statistiken ansehen',
      'deleteGame': 'Spiel löschen',
      'deleteAllGames': 'Alle Spiele löschen',
      'confirmDeleteGame': 'Möchten Sie dieses Spiel wirklich löschen?',
      'confirmDeleteAll': 'Möchten Sie wirklich alle Spiele löschen?',
      'gameDetails': 'Spieldetails',
      'duration': 'Dauer',
      'vs': 'vs',
      'score': 'Punkte',
    },
    'en': {
      // App
      'appTitle': 'Fortune 14/2',
      
      // Home Screen
      'newGame': 'New Game',
      'new141Game': 'New 14.1 Game',
      'resume': 'Resume Game',
      'players': 'Players',
      'statistics': 'Statistics',
      'achievements': 'Achievements',
      'settings': 'Settings',
      'version': 'Version',
      
      // Game Setup
      'newGameSetup': 'New Game Setup',
      'gameType': 'Game Type',
      'leagueGame': 'League Game',
      'leagueGameSubtitle': 'Track for statistics and rankings',
      'raceTo': 'Race to',
      'custom': 'Custom',
      'maxInnings': 'Max Innings',
      'unlimited': 'Unlimited',
      'playersTitle': 'Players',
      'player1': 'Player 1',
      'player2': 'Player 2',
      'enterOrSelectPlayer': 'Enter or select player',
      'createPlayer': 'Create Player',
      'handicap': 'Handicap',
      'additionalRules': 'Additional Rules',
      'threeFoulRule': '3-Foul Rule',
      'threeFoulRuleSubtitle': '3 consecutive fouls = -15 points',
      'startGame': 'Start Game',
      
      // Settings
      'soundEffects': 'Sound Effects',
      'enableGameSounds': 'Enable game sounds',
      'language': 'Language',
      'german': 'German',
      'english': 'English',
      'theme': 'Theme',
      'lightTheme': 'Light',
      'darkTheme': 'Dark',
      'raceToScore': 'Race to Score',
      'points': 'Points',
      'save': 'Save',
      'settingsSaved': 'Settings saved!',
      
      // Player Management
      'playerCreated': 'Player created ✓',
      'noPlayersYet': 'No players yet',
      'tapToCreate': 'Tap + to create your first player',
      'deletePlayer': 'Delete Player',
      'confirmDelete': 'Are you sure you want to delete',
      'playerName': 'Player Name',
      'gamesPlayed': 'Games Played',
      'gamesWon': 'Games Won',
      'gamesLost': 'Games Lost',
      'editPlayer': 'Edit Player',
      'playerUpdated': 'Player updated',
      'noAchievementsYet': 'No achievements unlocked yet',
      
      // Statistics
      'overallStatistics': 'Overall Statistics',
      'games': 'Games',
      'fouls': 'Fouls',
      'bestRun': 'Best Run',
      'playerRankings': 'Player Rankings',
      'noStatistics': 'No statistics yet',
      'playGamesToSee': 'Play some games to see statistics',
      'sortBy': 'Sort by',
      'rank': 'Rank',
      'winRate': 'Win Rate',
      'avgPoints': 'Avg Points',
      'highestRun': 'Highest Run',
      'totalPoints': 'Total Points',
      'totalFouls': 'Total Fouls',
      'totalInnings': 'Total Innings',
      'totalSaves': 'Total Saves',
      'avgInnings': 'Avg Innings',
      'avgFouls': 'Avg Fouls',
      
      // Achievements
      'achievementsUnlocked': 'Achievements Unlocked',
      'unlocked': 'Unlocked',
      'howToUnlock': 'How to unlock',
      'unlockedBy': 'Unlocked by',
      'unlockedOn': 'Unlocked on',
      'secretAchievement': 'This is a secret Easter Egg! Find out how to unlock it! 🤫',
      
      // Game Screen
      'exitGame': 'Exit Game?',
      'exitGameMessage': 'Game progress will be lost. Are you sure?',
      'restartGame': 'Restart Game?',
      'restartGameMessage': 'This will reset all scores and history. Are you sure?',
      'gameRules': 'Game Rules',
      'details': 'Details',
      'undo': 'Undo',
      'redo': 'Redo',
      
      // Common
      'cancel': 'Cancel',
      'close': 'Close',
      'delete': 'Delete',
      'create': 'Create',
      'edit': 'Edit',
      'back': 'Back',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      
      // Game Dialogs
      'exit': 'Exit',
      'exitGameTitle': 'Exit Game?',
      'gameRulesContent': 'Fortune 14/2 (Modified)\\n\\n1. Object of the Game\\nThe goal is to reach the set score (Race to X).\\n\\n2. Scoring\\nPocketing a ball scores points equal to (15 - Ball Number).\\nExample: Ball 14 = 1 point. Ball 1 = 14 points.\\n\\n3. Special Balls\\n- Ball 1: Scores 14 points and causes a Re-Rack. Player continues.\\n- Double Sack (Cue Ball): Scores 15 points and causes a Re-Rack. Player continues.\\n\\n4. Fouls\\n- Normal Foul: -1 point. 3 consecutive fouls = -15 points.\\n- Severe Foul: -2 points.',
      'threeFoulPenalty': '3-Foul Penalty!',
      'threeFoulMessage': 'Player committed 3 consecutive fouls.\\n\\nPenalty: -15 points\\n\\nThe foul counter has been reset.',
      'resetGame': 'Reset Game',
      'resetGameMessage': 'Are you sure you want to reset the game?',
      'reset': 'Reset',
      
      // Game History
      'gameHistory': 'Game History',
      'allGames': 'All Games',
      'inProgress': 'In Progress',
      'completed': 'Completed',
      'noGamesYet': 'No games yet',
      'playGameToSeeHistory': 'Play a game to see history',
      'resumeGame': 'Resume Game',
      'viewStats': 'View Stats',
      'deleteGame': 'Delete Game',
      'deleteAllGames': 'Delete All Games',
      'confirmDeleteGame': 'Are you sure you want to delete this game?',
      'confirmDeleteAll': 'Are you sure you want to delete all games?',
      'gameDetails': 'Game Details',
      'duration': 'Duration',
      'vs': 'vs',
      'score': 'Score',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Convenience getters for all translations
  String get appTitle => translate('appTitle');
  String get newGame => translate('newGame');
  String get new141Game => translate('new141Game');
  String get resume => translate('resume');
  String get players => translate('players');
  String get statistics => translate('statistics');
  String get achievements => translate('achievements');
  String get settings => translate('settings');
  String get version => translate('version');
  
  String get newGameSetup => translate('newGameSetup');
  String get gameType => translate('gameType');
  String get leagueGame => translate('leagueGame');
  String get leagueGameSubtitle => translate('leagueGameSubtitle');
  String get raceTo => translate('raceTo');
  String get custom => translate('custom');
  String get maxInnings => translate('maxInnings');
  String get unlimited => translate('unlimited');
  String get playersTitle => translate('playersTitle');
  String get player1 => translate('player1');
  String get player2 => translate('player2');
  String get enterOrSelectPlayer => translate('enterOrSelectPlayer');
  String get createPlayer => translate('createPlayer');
  String get handicap => translate('handicap');
  String get additionalRules => translate('additionalRules');
  String get threeFoulRule => translate('threeFoulRule');
  String get threeFoulRuleSubtitle => translate('threeFoulRuleSubtitle');
  String get startGame => translate('startGame');
  
  String get soundEffects => translate('soundEffects');
  String get enableGameSounds => translate('enableGameSounds');
  String get language => translate('language');
  String get german => translate('german');
  String get english => translate('english');
  String get theme => translate('theme');
  String get lightTheme => translate('lightTheme');
  String get darkTheme => translate('darkTheme');
  String get raceToScore => translate('raceToScore');
  String get points => translate('points');
  String get save => translate('save');
  String get settingsSaved => translate('settingsSaved');
  
  String get playerCreated => translate('playerCreated');
  String get noPlayersYet => translate('noPlayersYet');
  String get tapToCreate => translate('tapToCreate');
  String get deletePlayer => translate('deletePlayer');
  String get confirmDelete => translate('confirmDelete');
  String get playerName => translate('playerName');
  String get gamesPlayed => translate('gamesPlayed');
  String get gamesWon => translate('gamesWon');
  String get gamesLost => translate('gamesLost');
  String get editPlayer => translate('editPlayer');
  String get playerUpdated => translate('playerUpdated');
  String get noAchievementsYet => translate('noAchievementsYet');
  
  String get overallStatistics => translate('overallStatistics');
  String get games => translate('games');
  String get fouls => translate('fouls');
  String get bestRun => translate('bestRun');
  String get playerRankings => translate('playerRankings');
  String get noStatistics => translate('noStatistics');
  String get playGamesToSee => translate('playGamesToSee');
  String get sortBy => translate('sortBy');
  String get rank => translate('rank');
  String get winRate => translate('winRate');
  String get avgPoints => translate('avgPoints');
  String get highestRun => translate('highestRun');
  String get totalPoints => translate('totalPoints');
  String get totalFouls => translate('totalFouls');
  String get totalInnings => translate('totalInnings');
  String get totalSaves => translate('totalSaves');
  String get avgInnings => translate('avgInnings');
  String get avgFouls => translate('avgFouls');
  
  String get achievementsUnlocked => translate('achievementsUnlocked');
  String get unlocked => translate('unlocked');
  String get howToUnlock => translate('howToUnlock');
  String get unlockedBy => translate('unlockedBy');
  String get unlockedOn => translate('unlockedOn');
  String get secretAchievement => translate('secretAchievement');
  
  String get exitGame => translate('exitGame');
  String get exitGameMessage => translate('exitGameMessage');
  String get restartGame => translate('restartGame');
  String get restartGameMessage => translate('restartGameMessage');
  String get gameRules => translate('gameRules');
  String get details => translate('details');
  String get undo => translate('undo');
  String get redo => translate('redo');
  
  String get cancel => translate('cancel');
  String get close => translate('close');
  String get delete => translate('delete');
  String get create => translate('create');
  String get edit => translate('edit');
  String get back => translate('back');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  
  String get exit => translate('exit');
  String get exitGameTitle => translate('exitGameTitle');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['de', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
