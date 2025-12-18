import 'react-native-gesture-handler';
import './global.css';
import * as React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { GameProvider } from './src/store/GameContext';


import HomeScreen from './src/screens/HomeScreen';
import GameSetScreen from './src/screens/GameSetScreen';
import Game141Screen from './src/screens/Game141Screen'; // Keep for logic ref needed
import MatchScreen from './src/screens/MatchScreen';
import MatchSetupScreen from './src/screens/MatchSetupScreen';
import SettingsScreen from './src/screens/SettingsScreen';
import HistoryScreen from './src/screens/HistoryScreen';
import PlayersScreen from './src/screens/PlayersScreen';
import StatisticsScreen from './src/screens/StatisticsScreen';

const Stack = createNativeStackNavigator();

export default function App() {
  return (
    <GameProvider>
      <SafeAreaProvider>
        <NavigationContainer>
          <StatusBar style="light" />
          <Stack.Navigator
            screenOptions={{
              headerStyle: { backgroundColor: '#0f172a' },
              headerTintColor: '#fff',
              headerTitleStyle: { fontWeight: 'bold' },
              contentStyle: { backgroundColor: '#0f172a' },
            }}
          >
            <Stack.Screen name="Home" component={HomeScreen} options={{ title: 'Fortune Pool', headerShown: false }} />
            <Stack.Screen name="GameSet" component={GameSetScreen} />
            <Stack.Screen name="Game141" component={Game141Screen} options={{ title: '14.1 Straight Pool' }} />
            <Stack.Screen name="Match" component={MatchScreen} options={{ headerShown: false }} />
            <Stack.Screen name="MatchSetup" component={MatchSetupScreen} options={{ title: 'New Game' }} />
            <Stack.Screen name="Statistics" component={StatisticsScreen} />
            <Stack.Screen name="Settings" component={SettingsScreen} />
            <Stack.Screen name="History" component={HistoryScreen} />
            <Stack.Screen name="Players" component={PlayersScreen} />
          </Stack.Navigator>
        </NavigationContainer>
      </SafeAreaProvider>
    </GameProvider>
  );
}
