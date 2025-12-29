# 14.1 Fortune - Professional Straight Pool Scoring App

A professional Flutter-based scoring application for 14.1 Straight Pool (14.1 Continuous).

## 🎱 About

14.1 Fortune is a professional scoring app for 14.1 Straight Pool, featuring accurate rule enforcement, player statistics, achievements, and comprehensive game history.

## 🛠️ Development Setup

### Prerequisites

This project uses **Puro** (Flutter version manager) instead of standard Flutter installation.

- **Flutter SDK**: Managed via Puro
- **Required Flutter Version**: 3.38.5 (stable)
- **Dart SDK**: 3.10.4

### Quick Start

1. **Install Puro** (if not already installed):
   ```bash
   # Windows (via WinGet)
   winget install puro
   ```

2. **Clone the repository**:
   ```bash
   git clone https://github.com/Gruenbaer/141fortune
   cd 141fortune
   ```

3. **Set up Flutter environment**:
   ```bash
   puro use stable
   puro flutter pub get
   ```

4. **Run the app**:
   ```bash
   puro flutter run
   ```

### Important: Using Puro

Since this project uses Puro, **always prefix Flutter commands with `puro`**:

| Standard Flutter | With Puro |
|-----------------|-----------|
| `flutter run` | `puro flutter run` |
| `flutter analyze` | `puro flutter analyze` |
| `flutter doctor` | `puro flutter doctor` |
| `flutter pub get` | `puro flutter pub get` |
| `flutter build apk` | `puro flutter build apk` |

### Build Commands

```bash
# Android APK
puro flutter build apk --release

# Check for issues
puro flutter analyze
puro flutter doctor
```

## 📦 Dependencies

Key dependencies are managed in `pubspec.yaml`:
- `provider` - State management
- `shared_preferences` - Local storage
- `google_fonts` - Custom typography
- `confetti` - Achievement animations
- `audioplayers` - Sound effects

## 🤖 AI Development Note

**For Antigravity AI**: This project uses **Puro** for Flutter version management. When running Flutter commands, use `puro flutter` instead of `flutter`. The Puro environment is configured with `puro use stable` in the project directory.

## 📱 Platforms

- Android
- iOS  
- Windows
- macOS
- Linux
- Web

## 📄 License

This project is private and not published.
