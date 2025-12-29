# 14.1 Fortune - Projektnotizen

## Spielregeln (Vereinfacht)

### Zählsystem
- Ball-Nummer = Anzahl Kugeln auf dem Tisch
- Punkte = 15 - Ball-Nummer

### Spezialregeln
- **Ball 1:** 14 Punkte + Re-Rack + Spieler bleibt
- **Weiße Kugel (W):** 15 Punkte + Re-Rack + Spieler bleibt (Double-Sack)
- **Automatischer Spielerwechsel:** Nach jedem Ball (außer Ball 1 und Weiße)

### Foulsystem
| Typ | Punkte | 3-Foul-Zähler |
|-----|--------|---------------|
| Normal | -1 | ✅ Zählt |
| Severe | -2 | ❌ Zählt nicht |

**3-Foul-Regel:**
- 3 normale Fouls hintereinander → -15 Punkte
- Popup erklärt Strafe
- Zähler ist global (alle Fouls)

## UI-Design

### Bälle
- **Solide (1-8):** Komplett einfarbig mit weißem Zahlenkreis
- **Gestreift (9-15):** Weißer Ball mit farbigem Band in der Mitte, schwarze Nummer
- **Anordnung:** Dreieck-Rack (15 Bälle + Weiße unten)
- **Rendering:** CustomPainter mit RadialGradient für Glanz

### Layout
- **Oben:** Spieler-Plaketten (Gradient) mit Score/Inning
- **Mitte:** Auto-skalierendes Rack (FittedBox)
- **Unten:** Foul-Toggle (3 Zustände)

### Buttons
- **Details:** Analytics-Icon
- **Settings:** Zahnrad
- **Reset:** Refresh
- **Foul:** Toggle (No Foul → Foul -1 → Severe -2)

## Technische Details

### State Management
- **Provider** für GameState
- **SharedPreferences** für Settings-Persistenz

### Features
- 3-Foul-Toggle in Settings
- Race-to-Score konfigurierbar
- Spielernamen editierbar
- Details-Screen mit Statistiken

## Entwicklung

**Flutter Version:** 3.22.1  
**Min SDK:** API 21 (Android 5.0)  
**Dependencies:**
- provider: ^6.1.1
- shared_preferences: ^2.2.2

**Build:**
```bash
flutter build apk --debug
```

**Run:**
```bash
flutter run -d <device>
```

## Status
- ✅ Phase 1-4: Core Features + Advanced Features
- ✅ Phase 5: UI Improvements (Bälle, Rack, Toggle)
- ⏸️ Phase 6: Testing & Polish
- ⏸️ Phase 7: Deployment
