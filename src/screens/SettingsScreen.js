import React from 'react';
import { View, Text, TouchableOpacity, ScrollView } from 'react-native';
import { useGame } from '../store/GameContext';
import { t } from '../utils/i18n';
import { styled } from 'nativewind';

export default function SettingsScreen() {
    const { language, switchLanguage, soundEnabled, setSoundEnabled } = useGame();

    return (
        <ScrollView className="flex-1 bg-knthlz-dark p-4">
            <Text className="text-knthlz-text text-2xl font-bold mb-6 mt-4">{t('settings')}</Text>

            {/* Language Section */}
            <View className="mb-8">
                <Text className="text-knthlz-dim text-xs font-bold uppercase tracking-widest mb-4">{t('language')}</Text>

                <View className="flex-row gap-4">
                    <TouchableOpacity
                        onPress={() => switchLanguage('en')}
                        className={`flex-1 p-4 rounded-lg border ${language === 'en' ? 'bg-knthlz-surface border-knthlz-green' : 'bg-knthlz-dark border-gray-700'}`}
                    >
                        <Text className={`text-center font-bold ${language === 'en' ? 'text-knthlz-green' : 'text-knthlz-dim'}`}>
                            English
                        </Text>
                    </TouchableOpacity>

                    <TouchableOpacity
                        onPress={() => switchLanguage('de')}
                        className={`flex-1 p-4 rounded-lg border ${language === 'de' ? 'bg-knthlz-surface border-knthlz-green' : 'bg-knthlz-dark border-gray-700'}`}
                    >
                        <Text className={`text-center font-bold ${language === 'de' ? 'text-knthlz-green' : 'text-knthlz-dim'}`}>
                            Deutsch
                        </Text>
                    </TouchableOpacity>
                </View>
            </View>

            {/* Sound Section */}
            <View className="mb-8">
                <Text className="text-knthlz-dim text-xs font-bold uppercase tracking-widest mb-4">{t('sound')}</Text>

                <View className="flex-row gap-4">
                    <TouchableOpacity
                        onPress={() => setSoundEnabled(true)}
                        className={`flex-1 p-4 rounded-lg border ${soundEnabled ? 'bg-knthlz-surface border-knthlz-green' : 'bg-knthlz-dark border-gray-700'}`}
                    >
                        <Text className={`text-center font-bold ${soundEnabled ? 'text-knthlz-green' : 'text-knthlz-dim'}`}>
                            {t('on')}
                        </Text>
                    </TouchableOpacity>

                    <TouchableOpacity
                        onPress={() => setSoundEnabled(false)}
                        className={`flex-1 p-4 rounded-lg border ${!soundEnabled ? 'bg-knthlz-surface border-knthlz-green' : 'bg-knthlz-dark border-gray-700'}`}
                    >
                        <Text className={`text-center font-bold ${!soundEnabled ? 'text-knthlz-green' : 'text-knthlz-dim'}`}>
                            {t('off')}
                        </Text>
                    </TouchableOpacity>
                </View>
            </View>

            {/* Info */}
            <View className="mt-8 border-t border-gray-800 pt-8">
                <Text className="text-knthlz-dim text-center text-xs">Fortune 14/2 • v1.0.0</Text>
                <Text className="text-knthlz-dim text-center text-xs mt-1">KNTHLZ Edition</Text>
            </View>
        </ScrollView>
    );
}
