import React, { useEffect } from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { useGame } from '../store/GameContext';
import { styled } from 'nativewind';

const PlayerCard = ({ name, racks, onIncrement, onDecrement, isActive }) => (
    <View className={`flex-1 p-4 m-2 rounded-xl justify-between items-center ${isActive ? 'bg-slate-700 border-2 border-emerald-500' : 'bg-slate-800'}`}>
        <Text className="text-white text-2xl font-bold mb-4">{name}</Text>
        <Text className="text-6xl text-emerald-400 font-bold mb-8">{racks}</Text>

        <View className="flex-row w-full justify-between">
            <TouchableOpacity onPress={onDecrement} className="bg-red-900/50 p-4 rounded-full w-16 h-16 items-center justify-center">
                <Text className="text-red-400 text-2xl font-bold">-</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={onIncrement} className="bg-emerald-600 p-4 rounded-full w-16 h-16 items-center justify-center">
                <Text className="text-white text-2xl font-bold">+</Text>
            </TouchableOpacity>
        </View>
    </View>
);

export default function GameSetScreen({ route, navigation }) {
    const { mode } = route.params;
    const { resetGame, player1, player2, updateSetScore, turn, setTurn } = useGame();

    useEffect(() => {
        resetGame(mode);
        navigation.setOptions({ title: mode });
    }, [mode]);

    return (
        <View className="flex-1 bg-slate-900 p-2">
            <View className="flex-1 flex-row">
                <PlayerCard
                    name={player1.name}
                    racks={player1.racks}
                    onIncrement={() => updateSetScore(1, 1)}
                    onDecrement={() => updateSetScore(1, -1)}
                    isActive={turn === 1}
                />
                <PlayerCard
                    name={player2.name}
                    racks={player2.racks}
                    onIncrement={() => updateSetScore(2, 1)}
                    onDecrement={() => updateSetScore(2, -1)}
                    isActive={turn === 2}
                />
            </View>

            {/* Control Bar */}
            <View className="h-20 bg-slate-800 flex-row items-center justify-center px-4 rounded-t-3xl">
                <TouchableOpacity
                    className="bg-sky-600 px-8 py-3 rounded-full"
                    onPress={() => setTurn(turn === 1 ? 2 : 1)}
                >
                    <Text className="text-white font-bold text-lg">Switch Turn</Text>
                </TouchableOpacity>
            </View>
        </View>
    );
}
