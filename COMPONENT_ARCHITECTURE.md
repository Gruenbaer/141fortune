# Fortune 14/1 - Component Encapsulation & Reusability Strategy

## 🎯 Core Principle
**"Change it once, use it everywhere"** - Every UI element, setting control, and player interaction should be extracted into reusable widgets/components. No duplicate code, consistent behavior across the entire app.

---

## 📦 Component Categories

### 1. **Player Interactions**
**Status**: ✅ PlayerNameInputDialog created (v3.7.0)

**What we have:**
- `PlayerNameInputDialog` - unified player name input with autocomplete, create button, checkmark

**What we need:**
- `PlayerSelectorWidget` - dropdown/list for selecting players
- `PlayerStatsCard` - reusable card showing player stats
- `PlayerAvatar` - consistent player avatar/icon display
- `PlayerComparisonWidget` - side-by-side player stats

### 2. **Settings Controls**
**Status**: ❌ Needs extraction

**Current problem:** Each screen builds its own sliders, toggle buttons, number pickers

**Extract to widgets:**
- **`SettingsSlider`** 
  - Props: `label`, `value`, `min`, `max`, `divisions`, `onChanged`, `unit`
  - Handles: Theme-aware colors, label formatting, value display
  - Example: Race-to slider, max innings slider
  
- **`QuickButtonGroup`**
  - Props: `values`, `currentValue`, `onChanged`, `label`
  - Renders: Row of outlined buttons with active/inactive states
  - Example: 25/50/100 race buttons, 25/50/100 innings buttons
  
- **`SettingsToggle`**
  - Props: `title`, `subtitle`, `value`, `onChanged`, `icon`
  - Renders: Themed SwitchListTile with consistent styling
  - Example: 3-foul rule, sound toggle, league game toggle
  
- **`NumberPicker`**
  - Props: `label`, `value`, `min`, `max`, `step`, `onChanged`
  - Renders: +/- buttons with value display
  - Example: Handicap adjustments

### 3. **Game Screen Elements**
**Status**: ❌ Scattered across game_screen.dart

**Extract to widgets:**
- **`ScoreDisplay`** - Player score with theme, animations
- **`BallRackWidget`** - Reusable ball rack (current/max display)
- **`InningsCounter`** - Consistent innings display
- **`GameControlButtons`** - Foul, undo, menu buttons
- **`FoulButton`** - Standardized foul button with states

### 4. **Dialogs & Overlays**
**Status**: ⚠️ Mix of inline and extracted

**Current widgets:**
- ✅ `PlayerNameInputDialog`
- ✅ `ReRackOverlay`
- ✅ `FoulOverlays` (foul_overlays.dart)
- ✅ `PauseOverlay`

**Need extraction:**
- **`ConfirmationDialog`** - Standard yes/no dialogs
- **`InfoDialog`** - Rule explanations, help text
- **`AchievementDialog`** - Achievement unlock notifications

### 5. **Theme Components**
**Status**: ⚠️ Partially theme-aware

**Current system:**
- `FortuneColors` extension in `fortune_theme.dart`
- Individual themes: `SteampunkTheme`, `CyberpunkTheme`

**Problems:**
- Some screens hardcode `SteampunkTheme` instead of using active theme
- Inconsistent color access (`SteampunkTheme.brassPrimary` vs `FortuneColors.of(context).primary`)

**Action needed:**
- **Audit all files** - Search for `SteampunkTheme` references
- **Replace with** `FortuneColors.of(context)`
- **Create helper widgets** that auto-fetch theme:
  - `ThemedCard` - Card with correct theme colors
  - `ThemedButton` - Button with theme-aware styling
  - `ThemedIcon` - Icon with theme color

---

## 🔧 Refactoring Roadmap

### Phase 1: Settings Widgets ⏳ Next
**Goal:** Eliminate duplication in `new_game_settings_screen.dart` and `settings_screen.dart`

**Tasks:**
1. Create `lib/widgets/settings/`:
   - `settings_slider.dart`
   - `quick_button_group.dart`
   - `settings_toggle.dart`
   - `number_picker_widget.dart`

2. Refactor screens to use new widgets
3. Ensure all use `FortuneColors` for theming

**Benefit:** Change slider appearance once, affects both screens

### Phase 2: Game Screen Components
**Goal:** Break down the 1000+ line `game_screen.dart`

**Tasks:**
1. Create `lib/widgets/game/`:
   - `score_display.dart`
   - `ball_rack_widget.dart`
   - `innings_counter.dart`
   - `game_controls.dart`

2. Extract score/rack/innings logic into widgets
3. Game screen becomes composition of smaller widgets

**Benefit:** Easier to test, modify, and maintain game UI

### Phase 3: Theme Consistency
**Goal:** 100% theme-aware, no hardcoded colors

**Tasks:**
1. Search & replace all `SteampunkTheme.*` with `FortuneColors.of(context).*`
2. Map property names:
   - `brassPrimary` → `primary`
   - `brassDark` → `secondary`
   - `amberGlow` → `accent`
3. Test theme switching in every screen

**Benefit:** Smooth theme transitions, easy to add new themes

### Phase 4: Player Widgets Suite
**Goal:** Complete player interaction toolkit

**Tasks:**
1. Create `lib/widgets/player/`:
   - `player_selector.dart`
   - `player_stats_card.dart`
   - `player_avatar.dart`
   - `player_comparison.dart`

2. Use in players screen, game screen, history

**Benefit:** Consistent player presentation everywhere

### Phase 5: Dialog Standardization
**Goal:** All dialogs use theme-aware base components

**Tasks:**
1. Create `ThemedDialog` base class
2. Migrate all `showDialog` calls to use themed versions
3. Create dialog builder functions

**Benefit:** Dialogs automatically adapt to theme changes

---

## 📋 Component Design Principles

### 1. **Self-Contained**
Each widget should:
- Manage its own state (if stateful)
- Handle its own theme access
- Provide clear, typed props

### 2. **Theme-Aware by Default**
Always use:
```dart
final theme = FortuneColors.of(context);
// NOT: SteampunkTheme.brassPrimary
```

### 3. **Composition Over Inheritance**
Build complex screens by composing simple widgets:
```dart
// Good
Column(
  children: [
    SettingsSlider(label: 'Race To', ...),
    QuickButtonGroup(values: [25, 50, 100], ...),
  ],
)

// Bad - inline everything
Column(
  children: [
    Text('Race To'),
    Slider(...), // lots of custom code
    Row(
      children: [
        OutlinedButton(...), // duplicate styling
        OutlinedButton(...),
      ],
    ),
  ],
)
```

### 4. **Single Responsibility**
Each widget does ONE thing well:
- `SettingsSlider` - displays a themed slider with label
- `QuickButtonGroup` - displays preset value buttons
- NOT: `SettingsSliderWithButtons` (combine via composition instead)

### 5. **Prop Naming Convention**
- `value` - current value
- `onChanged` - callback when value changes
- `label` - display text
- `enabled` - can interact?
- `theme` - optional theme override (rare)

---

## 🎨 Example: Slider Refactoring

### Before (Duplicated in 2+ places):
```dart
Column(
  children: [
    Text(l10n.raceTo, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    Row(
      children: [
        OutlinedButton(
          onPressed: () => setState(() { _settings = _settings.copyWith(raceToScore: 25); }),
          style: OutlinedButton.styleFrom(
            backgroundColor: _settings.raceToScore == 25 ? Colors.green : Colors.transparent,
            // ... more styling
          ),
          child: Text('25'),
        ),
        // Repeat for 50, 100...
      ],
    ),
    Slider(
      value: _raceSliderValue,
      min: 25,
      max: 200,
      onChanged: (value) => setState(() { _raceSliderValue = value; }),
      // ... more config
    ),
  ],
)
```

### After (Reusable):
```dart
SettingsSlider(
  label: l10n.raceTo,
  value: _settings.raceToScore.toDouble(),
  min: 25,
  max: 200,
  quickValues: [25, 50, 100],
  onChanged: (value) => _updateSetting((s) => s.copyWith(raceToScore: value.round())),
)
```

**Widget implementation** (in `lib/widgets/settings/settings_slider.dart`):
```dart
class SettingsSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final List<int>? quickValues;
  final Function(double) onChanged;
  
  @override
  Widget build(BuildContext context) {
    final theme = FortuneColors.of(context);
    
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (quickValues != null)
          QuickButtonGroup(
            values: quickValues!,
            currentValue: value.round(),
            onChanged: (val) => onChanged(val.toDouble()),
          ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: theme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
```

---

## 🐛 Known Issues to Fix During Refactoring

1. **Background video sound** - Plays even when sound disabled
   - Fix: Mute video player, respect settings.soundEnabled
   
2. **Settings screen theme** - Hardcoded Steampunk colors
   - Fix: Use FortuneColors throughout
   
3. **Re-rack animation** - Balls instantly reappear
   - Enhancement: Animate balls flying in from edges
   
4. **Hamburger menu** - Still appears in some TextFields
   - Fix: Add `contextMenuBuilder: (_,__) => SizedBox.shrink()` everywhere

---

## ✅ Success Criteria

When refactoring is complete:
- [ ] No duplicate slider/button code between screens
- [ ] All widgets use `FortuneColors.of(context)` (no hardcoded themes)
- [ ] Can change slider appearance in ONE place
- [ ] Can add new theme in `fortune_theme.dart` and it works everywhere
- [ ] Game screen < 500 lines (currently 1000+)
- [ ] Settings screens use identical components
- [ ] All player inputs use `PlayerNameInputDialog`
- [ ] Every reusable element is in `lib/widgets/`

---

## 📁 Recommended File Structure

```
lib/
├── widgets/
│   ├── player/
│   │   ├── player_name_input_dialog.dart ✅
│   │   ├── player_selector.dart
│   │   ├── player_stats_card.dart
│   │   └── player_avatar.dart
│   ├── settings/
│   │   ├── settings_slider.dart
│   │   ├── quick_button_group.dart
│   │   ├── settings_toggle.dart
│   │   └── number_picker_widget.dart
│   ├── game/
│   │   ├── score_display.dart
│   │   ├── ball_rack_widget.dart
│   │   ├── innings_counter.dart
│   │   └── game_controls.dart
│   ├── dialogs/
│   │   ├── themed_dialog.dart
│   │   ├── confirmation_dialog.dart
│   │   └── info_dialog.dart
│   └── steampunk_widgets.dart ✅
├── theme/
│   ├── fortune_theme.dart ✅
│   └── steampunk_theme.dart ✅
└── screens/
    └── (screens only compose widgets)
```

---

## 🔄 Migration Strategy

**For each duplicated pattern:**
1. **Identify** - Find all places pattern is used
2. **Extract** - Create widget in appropriate `widgets/` subfolder
3. **Replace** - Update all usages to new widget
4. **Test** - Verify behavior unchanged
5. **Commit** - "refactor: Extract [WidgetName] component"

**Example workflow:**
```bash
# 1. Find all slider implementations
rg "Slider\(" lib/screens/

# 2. Create widget
# (code SettingsSlider)

# 3. Replace in new_game_settings_screen.dart
# 4. Replace in settings_screen.dart  
# 5. Test both screens

# 6. Commit
git add lib/widgets/settings/settings_slider.dart
git commit -m "refactor: Extract SettingsSlider widget"
```

---

## 📝 Notes

- **Start small**: Don't try to refactor everything at once
- **Test frequently**: After each widget extraction, test affected screens
- **Document props**: Add clear dartdoc comments to all widgets
- **Theme first**: Always use FortuneColors, never hardcode colors
- **Composition**: Complex widgets = many simple widgets combined

**Remember:** The goal is maintainability. Better to have 10 small, simple widgets than 1 giant, complex screen.
