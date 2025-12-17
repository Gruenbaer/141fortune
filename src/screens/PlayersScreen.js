import React, { useState, useEffect } from 'react';
import { View, Text, TextInput, TouchableOpacity, FlatList, Alert } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useGame } from '../store/GameContext';
import { t } from '../utils/i18n';
import { styled } from 'nativewind';

export default function PlayersScreen({ navigation }) {
    const { setPlayer1, setPlayer2, player1, player2 } = useGame();
    const [players, setPlayers] = useState([]);
    const [newName, setNewName] = useState('');

    useEffect(() => {
        loadPlayers();
    }, []);

    const loadPlayers = async () => {
        try {
            const jsonValue = await AsyncStorage.getItem('@fortune142_players');
            if (jsonValue != null) {
                setPlayers(JSON.parse(jsonValue));
            }
        } catch (e) {
            console.error("Failed to load players", e);
        }
    };

    const addPlayer = async () => {
        if (!newName.trim()) return;
        const newPlayer = { id: Date.now().toString(), name: newName.trim() };
        const updated = [...players, newPlayer];
        setPlayers(updated);
        setNewName('');
        await AsyncStorage.setItem('@fortune142_players', JSON.stringify(updated));
    };

    const deletePlayer = async (id) => {
        const updated = players.filter(p => p.id !== id);
        setPlayers(updated);
        await AsyncStorage.setItem('@fortune142_players', JSON.stringify(updated));
    };

    const assignPlayer = (player, slot) => {
        if (slot === 1) {
            setPlayer1(prev => ({ ...prev, name: player.name }));
        } else {
            setPlayer2(prev => ({ ...prev, name: player.name }));
        }
        Alert.alert("Assigned", `${player.name} is now Player ${slot}`);
    };

    return (
        <View className="flex-1 bg-knthlz-dark p-4">
            <Text className="text-knthlz-text text-2xl font-bold mb-6 mt-4">{t('players')}</Text>

            {/* Add Player */}
            <View className="flex-row gap-2 mb-6">
                <TextInput
                    className="flex-1 bg-knthlz-surface text-white p-4 rounded-lg border border-gray-700"
                    placeholder="New Player Name"
                    placeholderTextColor="#888"
                    value={newName}
                    onChangeText={setNewName}
                />
                <TouchableOpacity
                    onPress={addPlayer}
                    className="bg-knthlz-green justify-center px-6 rounded-lg"
                >
                    <Text className="text-knthlz-dark font-bold text-xl">+</Text>
                </TouchableOpacity>
            </View>

            {/* Player List */}
            <FlatList
                data={players}
                keyExtractor={item => item.id}
                renderItem={({ item }) => (
                    <View className="flex-row justify-between items-center bg-knthlz-surface p-4 mb-2 rounded-lg border border-gray-800">
                        <Text className="text-white font-bold text-lg">{item.name}</Text>

                        <View className="flex-row gap-2">
                            <TouchableOpacity onPress={() => assignPlayer(item, 1)} className="bg-gray-700 px-3 py-1 rounded">
                                <Text className="text-xs text-white">P1</Text>
                            </TouchableOpacity>
                            <TouchableOpacity onPress={() => assignPlayer(item, 2)} className="bg-gray-700 px-3 py-1 rounded">
                                <Text className="text-xs text-white">P2</Text>
                            </TouchableOpacity>
                            <TouchableOpacity onPress={() => deletePlayer(item.id)} className="bg-red-900/50 px-3 py-1 rounded border border-red-500 ml-2">
                                <Text className="text-xs text-red-500">X</Text>
                            </TouchableOpacity>
                        </View>
                    </View>
                )}
            />

            <View className="mt-4 p-4 bg-knthlz-surface rounded-xl border border-knthlz-green/30">
                <Text className="text-knthlz-dim text-xs font-bold uppercase mb-2">Current Activity</Text>
                <Text className="text-white">P1: <Text className="text-knthlz-green font-bold">{player1.name}</Text></Text>
                <Text className="text-white">P2: <Text className="text-blue-400 font-bold">{player2.name}</Text></Text>
            </View>
        </View>
    );
}
