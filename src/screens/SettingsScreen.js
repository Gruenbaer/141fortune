import React from 'react';
import { View, Text, TouchableOpacity, ScrollView } from 'react-native';
import { useGame } from '../store/GameContext';
import { t } from '../utils/i18n';

export default function SettingsScreen() {
    const {
        language, switchLanguage,
        soundEnabled, setSoundEnabled,
        theme, setTheme
    } = useGame();

    const ThemeOption = ({ label, value, color }) => (
        <TouchableOpacity
            onPress={() => setTheme(value)}
            className={`flex-row items-center p-4 mb-2 rounded-xl border ${theme === value ? 'bg-gray-800 border-green-500' : 'bg-knthlz-surface border-gray-700'}`}
        >
            <View className={`w-6 h-6 rounded-full mr-4 border border-gray-600`} style={{ backgroundColor: color }} />
            <Text className={`font-bold text-lg ${theme === value ? 'text-green-500' : 'text-gray-400'}`}>{label}</Text>
            {theme === value && <Text className="ml-auto text-green-500 font-bold">✓</Text>}
        </TouchableOpacity>
    );

    return (
        <ScrollView className="flex-1 bg-knthlz-dark p-6">
            <Text className="text-white text-3xl font-bold mb-8 mt-4">Settings</Text>

            {/* Theme Section */}
            <View className="mb-8">
                <Text className="text-knthlz-dim text-xs font-bold uppercase tracking-widest mb-4">Appearance</Text>
                <ThemeOption label="Dark (Default)" value="dark" color="#0f172a" />
                <ThemeOption label="AMOLED Black" value="black" color="#000000" />
                <ThemeOption label="Cosmic Blue" value="blue" color="#1e3a8a" />
            </View>

            {/* Language Section */}
            <View className="mb-8">
                <Text className="text-knthlz-dim text-xs font-bold uppercase tracking-widest mb-4">{t('language')}</Text>
                <View className="flex-row gap-4">
                    <TouchableOpacity onPress={() => switchLanguage('en')} className={`flex-1 p-4 rounded-lg border items-center ${language === 'en' ? 'bg-gray-800 border-green-500' : 'bg-knthlz-surface border-gray-700'}`}>
                        <Text className={language === 'en' ? 'text-green-500 font-bold' : 'text-gray-400 font-bold'}>English</Text>
                    </TouchableOpacity>
                    <TouchableOpacity onPress={() => switchLanguage('de')} className={`flex-1 p-4 rounded-lg border items-center ${language === 'de' ? 'bg-gray-800 border-green-500' : 'bg-knthlz-surface border-gray-700'}`}>
                        <Text className={language === 'de' ? 'text-green-500 font-bold' : 'text-gray-400 font-bold'}>Deutsch</Text>
                    </TouchableOpacity>
                </View>
            </View>

            {/* Sound Section */}
            <View className="mb-8">
                <Text className="text-knthlz-dim text-xs font-bold uppercase tracking-widest mb-4">{t('sound')}</Text>
                <View className="flex-row gap-4">
                    <TouchableOpacity onPress={() => setSoundEnabled(true)} className={`flex-1 p-4 rounded-lg border items-center ${soundEnabled ? 'bg-gray-800 border-green-500' : 'bg-knthlz-surface border-gray-700'}`}>
                        <Text className={soundEnabled ? 'text-green-500 font-bold' : 'text-gray-400 font-bold'}>{t('on')}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity onPress={() => setSoundEnabled(false)} className={`flex-1 p-4 rounded-lg border items-center ${!soundEnabled ? 'bg-gray-800 border-green-500' : 'bg-knthlz-surface border-gray-700'}`}>
                        <Text className={!soundEnabled ? 'text-green-500 font-bold' : 'text-gray-400 font-bold'}>{t('off')}</Text>
                    </TouchableOpacity>
                </View>
            </View>

            {/* Info */}
            <View className="mt-4 border-t border-gray-800 pt-8 pb-10">
                <Text className="text-knthlz-dim text-center text-xs uppercase tracking-widest">Fortune 14/2 • v2.0.0</Text>
                <Text className="text-knthlz-dim text-center text-[10px] mt-1 opacity-50">Build 2025.12.17</Text>
            </View>
        </ScrollView>
    );
}
