import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models/achievement_manager.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'models/game_settings.dart';
import 'l10n/app_localizations.dart';
import 'theme/steampunk_theme.dart';

import 'widgets/feedback_wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _settingsService = SettingsService();
  late final ValueNotifier<GameSettings> _settingsNotifier;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _settingsNotifier = ValueNotifier(GameSettings());
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    _settingsNotifier.value = settings;
    setState(() {
      _isLoading = false;
    });
  }

  void _updateSettings(GameSettings newSettings) {
    _settingsNotifier.value = newSettings;
    _settingsService.saveSettings(newSettings);
  }

  @override
  void dispose() {
    _settingsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Colors.green[700],
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<GameSettings>(
      valueListenable: _settingsNotifier,
      builder: (context, settings, _) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AchievementManager()),
            Provider<GameSettings>.value(value: settings),
            Provider<Function(GameSettings)>.value(value: _updateSettings),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey, // CRITIAL: Key for overlays
            title: '14.1 Fortune',
            debugShowCheckedModeBanner: false,
            
            // Localization
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale(settings.languageCode),
            
            // Global Overlay Wrapper (Feedback Chat)
            builder: (context, child) => FeedbackWrapper(
              navigatorKey: navigatorKey, 
              child: child
            ),
            
            // Theme
            theme: SteampunkTheme.themeData,
            darkTheme: SteampunkTheme.themeData,
            themeMode: ThemeMode.dark,
            
            home: const HomeScreen(),
          ),
        );
      },
    );
  }
}
