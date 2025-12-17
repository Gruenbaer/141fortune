import React from 'react';
import { View, Text, TouchableOpacity, ScrollView } from 'react-native';

import { t } from '../utils/i18n';
import { useGame } from '../store/GameContext';

const GameButton = ({ title, onPress, color = "bg-emerald-700" }) => (
    <TouchableOpacity
        className={`${color} p-6 rounded-xl w-full mb-4 items-center shadow-lg active:opacity-80`}
        onPress={onPress}
    >
        <Text className="text-white text-xl font-bold tracking-wider">{title}</Text>
    </TouchableOpacity>
);

export default function HomeScreen({ navigation }) {
    const { language } = useGame(); // Trigger re-render

    return (
        <View className="flex-1 bg-knthlz-dark">
            <ScrollView contentContainerStyle={{ padding: 24, paddingBottom: 50 }}>
                {/* Logo Area */}
                <View className="items-center mb-10 mt-10">
                    <View className="bg-knthlz-surface p-4 rounded-full mb-4 border-2 border-knthlz-green shadow-lg shadow-knthlz-green/50">
                        <View className="w-16 h-16 bg-knthlz-green rounded-full items-center justify-center">
                            <Text className="text-knthlz-dark font-bold text-2xl">14</Text>
                        </View>
                    </View>
                    <Text className="text-white text-3xl font-extrabold text-center tracking-tight">FORTUNE 14/2</Text>
                    <Text className="text-knthlz-dim text-sm mt-2 font-bold uppercase tracking-widest">KNTHLZ Edition</Text>
                </View>

                {/* Main Action: New Game (Straight Pool) */}
                <Text className="text-knthlz-dim text-xs font-bold mb-4 ml-1 uppercase tracking-widest">{t('newGame')}</Text>

                <GameButton
                    title={t('newGame')}
                    onPress={() => navigation.navigate('Match')}
                    color="bg-knthlz-green"
                />

                {/* Secondary Modes */}
                <View className="flex-row gap-2 mb-8">
                    <TouchableOpacity className="flex-1 bg-blue-900/40 p-4 rounded-lg border border-blue-500/30 items-center" onPress={() => navigation.navigate('GameSet', { mode: '8-Ball' })}>
                        <Text className="text-blue-400 font-bold">8-Ball</Text>
                    </TouchableOpacity>
                    <TouchableOpacity className="flex-1 bg-yellow-900/40 p-4 rounded-lg border border-yellow-500/30 items-center" onPress={() => navigation.navigate('GameSet', { mode: '9-Ball' })}>
                        <Text className="text-yellow-400 font-bold">9-Ball</Text>
                    </TouchableOpacity>
                    <TouchableOpacity className="flex-1 bg-indigo-900/40 p-4 rounded-lg border border-indigo-500/30 items-center" onPress={() => navigation.navigate('GameSet', { mode: '10-Ball' })}>
                        <Text className="text-indigo-400 font-bold">10-Ball</Text>
                    </TouchableOpacity>
                </View>

                {/* Management Section */}
                <Text className="text-knthlz-dim text-xs font-bold mb-4 ml-1 uppercase tracking-widest">{t('settings')}</Text>

                <View className="flex-row flex-wrap gap-2">
                    <TouchableOpacity
                        className="w-[48%] bg-knthlz-surface p-4 rounded-xl border border-gray-800 items-center"
                        onPress={() => navigation.navigate('Players')}
                    >
                        <Text className="text-white font-bold">{t('players')}</Text>
                    </TouchableOpacity>

                    <TouchableOpacity
                        className="w-[48%] bg-knthlz-surface p-4 rounded-xl border border-gray-800 items-center"
                        onPress={() => navigation.navigate('History')}
                    >
                        <Text className="text-white font-bold">{t('history')}</Text>
                    </TouchableOpacity>

                    <TouchableOpacity
                        className="w-[48%] bg-knthlz-surface p-4 rounded-xl border border-gray-800 items-center"
                        onPress={() => navigation.navigate('Statistics')}
                    >
                        <Text className="text-white font-bold">{t('statistics')}</Text>
                    </TouchableOpacity>

                    <TouchableOpacity
                        className="w-[48%] bg-knthlz-surface p-4 rounded-xl border border-gray-800 items-center"
                        onPress={() => navigation.navigate('Settings')}
                    >
                        <Text className="text-white font-bold">{t('settings')}</Text>
                    </TouchableOpacity>
                </View>

            </ScrollView>
        </View>
    );
}
