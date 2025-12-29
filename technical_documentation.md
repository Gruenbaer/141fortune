# Technical Documentation: 14.1 Fortune

This document provides a comprehensive technical overview of the **14.1 Fortune** application, designed to help developers understand its architecture, core logic, and implementation details.

## 1. Overview
**14.1 Fortune** is a specialized scoring application for **Straight Pool (14.1 Continuous)** billiards. It features **multiple visual themes** (Cyberpunk and Steampunk, with Cyberpunk as the default) and handles complex rule enforcement including safe shots, break fouls, the 3-foul rule, and game history tracking.

## 2. Technology Stack
*   **Framework**: [Flutter](https://flutter.dev/) (Dart SDK >=3.0.0 <4.0.0)
*   **State Management**: `provider` (ChangeNotifier pattern)
*   **Persistence**: `shared_preferences` (Local storage for settings and game history)
*   **Localization**: `flutter_localizations`, `intl`
*   **Assets**: `flutter_svg` (Vector graphics)
*   **Fonts**: `google_fonts`
*   **Effects**: `confetti` (Victory animations)

## 3. Project Architecture
The project follows a standard scalable Flutter architecture separation concerns between data, logic, and UI.

### Directory Structure (`lib/`)
*   **`main.dart`**: Application entry point. Sets up the `MultiProvider` for dependency injection and initializes the `MaterialApp` with localization and theming.
*   **`models/`**: Data classes and State Notifiers.
    *   `game_state.dart`: **Core Logic**. The primary State Object for the active game.
    *   `game_record.dart`: Data model for long-term storage of match history.
    *   `player.dart`: Model for player statistics and score.
    *   `game_settings.dart`: Configuration model (Race to score, rules).
    *   `achievement_manager.dart`: Handles unlocking achievements based on game events.
*   **`screens/`**: Full-page widgets.
    *   `game_screen.dart`: Main scoring interface.
    *   `home_screen.dart`: Landing page / Menu.
    *   `settings_screen.dart`: Configuration UI.
    *   `details_screen.dart`: Match statistics view.
*   **`services/`**: Data persistence and helper logic.
    *   `game_history_service.dart`: Handles saving/loading games via `SharedPreferences`.
    *   `settings_service.dart`: Persists user preferences.
    *   `player_service.dart`: Aggregates long-term player stats.
*   **`widgets/`**: Reusable UI components.
    *   `steampunk_widgets.dart`: Legacy themed widgets (being migrated to theme-agnostic components).
    *   `ball_button.dart`: Interactive billiard ball widget.
    *   `victory_splash.dart`: End-of-game overlay.
*   **`l10n/`**: Localization resources (ARB files).

## 4. Core Logic & State Management
The application's heart is the **`GameState`** class (extends `ChangeNotifier`), located in `lib/models/game_state.dart`.

### 4.1 Game Loop & Scoring
*   **Initialization**: `GameState` initializes with two `Player` objects and a full rack (balls 1-15).
*   **Turn Management**: Logic automatically tracks `currentPlayerIndex`.
    *   **Normal Play**: Turn switches after every ball potted (unless "Re-Rack" logic applies).
    *   **Miss/Safe**: Turn ends immediately.
    *   **Fouls**: Penalty applied, turn ends.
*   **Scoring**:
    *   Points are added to the current player.
    *   **Rack Tracking**: `activeBalls` (Set<int>) tracks valid balls remaining on table.
    *   **Re-Rack Logic**: If ball count drops to 1 (active ball + cue ball phantom), logic detects "Re-rack" potential. Tapping the last ball resets the rack to full (15).

### 4.2 Rules Implementation
*   **Foul Handling** (`FoulTracker`):
    *   **Standard Foul**: -1 point.
    *   **Severe Foul (Break Foul)**: -2 points.
    *   **3-Foul Rule**: If enabled, 3 consecutive fouls result in a -15 point penalty.
*   **Foul Modes**: Use `FoulMode` enum (none, normal, severe).
    *   The UI toggle sets the mode.
    *   The next ball tap applies the foul penalty instead of scoring points.
*   **Safe Mode**:
    *   Defensive shots are tracked separate from misses for "Saves" stats.
    *   "Defensive Pocketing": If in Safe Mode, tapping a ball reduces the rack count but only scores +1 defensive point (statistical only in some variations, or actual score depending on settings).

### 4.3 Undo/Redo System
Implemented using the **Memento Pattern**.
*   **`GameSnapshot`**: A robust DTO that serializes the entire state of `GameState` (Players, Scores, Rack, History, Fouls).
*   **Stacks**: `_undoStack` and `_redoStack` store `GameSnapshot` objects.
*   **Action**: Every state-changing action (ball tap, foul, skip) pushes a snapshot before mutating state. `undo()` pops the stack and restores the snapshot.

### 4.4 Data Persistence
The app uses a dual-layer persistence strategy:
1.  **Preferences**: `SettingsService` saves `GameSettings` (JSON) to `SharedPreferences`.
2.  **History**: `GameHistoryService` manages a list of `GameRecord` objects serialized as a large JSON string in `SharedPreferences` key `game_history`.
    *   **In-Progress Games**: Saved with a full `snapshot` to allow seamless resumption.
    *   **Completed Games**: Saved with final stats purely for historical records (snapshot is null to save space).

## 5. UI/UX Details
The app supports **multiple visual themes** managed through `FortuneTheme`:
*   **Default Theme**: **Cyberpunk** - Modern neon aesthetics with cyan (`#00D9FF`) and purple accents
*   **Alternative Theme**: **Steampunk** - Vintage brass (`#B5A642`), mahogany (`#421C02`), and parchment colors
*   **Theme System**: `FortuneTheme` and `FortuneColors` provide theme-agnostic access to colors and styles
*   **Custom Widgets**:
    *   Buttons use gradients and heavy borders to simulate metallic physical buttons.
    *   `PlayerPlaque` shows score, name, and inning in a stylized frame.
*   **Animations**:
    *   `ConfettiWidget` used on the Victory Screen.
    *   Simple opacity/scale transitions for dialogs.

## 6. Key Workflows

### Starting a New Game
1.  User enters `HomeScreen`.
2.  Clicks "New Game" -> `NewGameSettingsScreen`.
3.  Selects/Enters Player Names and Race Score.
4.  `Navigator` pushes `GameScreen`.
5.  `GameScreen` creates a **new** `GameState` via `ChangeNotifierProvider`.

### Resuming a Game
1.  `GameHistoryService` fetches active games.
2.  User selects a game card.
3.  `GameScreen` is pushed with `resumeGame: GameRecord` argument.
4.  In `initState`, `GameState.loadFromJson(record.snapshot)` is called to hydrate the state.

## 7. Future Considerations
*   **Database**: Migrating `SharedPreferences` to `sqlite` (drift/sqflite) is recommended if match history exceeds ~500 games to avoid performance bottlenecks with large JSON parsing.
*   **Stats API**: Current `PlayerService` matches players by **Name String**. A migration to UUIDs would be more robust for renaming players.
