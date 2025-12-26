import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fortune141/main.dart'; // Adjust if package name differs
import 'package:fortune141/screens/home_screen.dart';

void main() {
  testWidgets('Diagnostic App Launch Test', (WidgetTester tester) async {
    // 1. Mock SharedPreferences
    // This prevents "MethodChannel not found" errors in test environment
    SharedPreferences.setMockInitialValues({
      'game_history': '[]', // Empty history
      'game_settings': '{}', // Default settings
      'achievements': '{}', // Empty achievements
    });

    // 2. Pump the App
    await tester.pumpWidget(const MyApp());
    
    // 3. Wait for Async Loading (SettingsService, etc.)
    // MyApp has a loading state (CircularProgressIndicator)
    await tester.pump(); // Start Init
    await tester.pump(const Duration(seconds: 1)); // Wait for Future
    
    // 4. Verification
    // Check if we passed the loading screen
    expect(find.byType(CircularProgressIndicator), findsNothing, 
        reason: "App is stuck on loading screen");
        
    // Check if Home Screen is present
    expect(find.byType(HomeScreen), findsOneWidget, 
        reason: "Home Screen did not load");
        
    // Check for critical widgets
    // Removed text check as it varies by locale
        
    // Note: Since we use localization, text might vary. 
    // Checking for Icons is safer.
    expect(find.byIcon(Icons.play_arrow), findsOneWidget, 
        reason: "Play Arrow icon not found");
  });
}
