import React from 'react';
import { View, Text, FlatList, TouchableOpacity, Alert } from 'react-native';
import { useGame } from '../store/GameContext';
import { t } from '../utils/i18n';
import { styled } from 'nativewind';

const GameItem = ({ item, onDelete }) => {
    // item: { id, date, player1, player2, winner, innings }
    const dateStr = new Date(item.date).toLocaleDateString();

    return (
        <View className="bg-knthlz-surface p-4 mb-3 rounded-xl border border-gray-800">
            <View className="flex-row justify-between items-start mb-2">
                <Text className="text-knthlz-dim text-xs font-bold">{dateStr}</Text>
                <TouchableOpacity onPress={() => onDelete(item.id)}>
                    <Text className="text-red-500 text-xs font-bold uppercase">{t('deleteGame')}</Text>
                </TouchableOpacity>
            </View>

            <View className="flex-row justify-between items-center">
                <View className="flex-1">
                    <Text className={`text-lg font-bold ${item.winner === 1 ? 'text-knthlz-green' : 'text-white'}`}>
                        {item.player1.name}
                    </Text>
                    <Text className="text-2xl font-mono text-knthlz-dim">{item.player1.score}</Text>
                </View>

                <Text className="text-knthlz-dim font-bold text-xs px-4">VS</Text>

                <View className="flex-1 items-end">
                    <Text className={`text-lg font-bold ${item.winner === 2 ? 'text-blue-400' : 'text-white'}`}>
                        {item.player2.name}
                    </Text>
                    <Text className="text-2xl font-mono text-knthlz-dim">{item.player2.score}</Text>
                </View>
            </View>
        </View>
    );
};

export default function HistoryScreen() {
    const { gameHistory, deleteGame } = useGame();

    const handleDelete = (id) => {
        Alert.alert(
            t('deleteGame'),
            "Are you sure?",
            [
                { text: t('no'), style: "cancel" },
                { text: t('yes'), onPress: () => deleteGame(id), style: 'destructive' }
            ]
        );
    };

    return (
        <View className="flex-1 bg-knthlz-dark p-4">
            <Text className="text-knthlz-text text-2xl font-bold mb-6 mt-4">{t('history')}</Text>

            {gameHistory.length === 0 ? (
                <View className="flex-1 justify-center items-center">
                    <Text className="text-knthlz-dim text-lg">{t('noGames')}</Text>
                </View>
            ) : (
                <FlatList
                    data={gameHistory}
                    keyExtractor={item => item.id}
                    renderItem={({ item }) => <GameItem item={item} onDelete={handleDelete} />}
                />
            )}
        </View>
    );
}
