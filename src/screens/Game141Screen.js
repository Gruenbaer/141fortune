import React, { useEffect } from 'react';
import { View, Text, TouchableOpacity, ScrollView } from 'react-native';
import { useGame } from '../store/GameContext';
import { styled } from 'nativewind';

// Components
const PlayerSummary = ({ name, score, racks, fouls, isActive }) => (
    <View className={`flex-1 p-3 m-1 rounded-xl items-center ${isActive ? 'bg-slate-700 border-2 border-emerald-500' : 'bg-slate-800 opacity-60'}`}>
        <Text className="text-slate-300 text-sm font-bold uppercase mb-1">{name}</Text>
        <Text className="text-white text-3xl font-bold">{score}</Text>
        <View className="flex-row mt-2">
            <Text className="text-xs text-slate-400 mr-2">Fouls: {fouls}</Text>
            <Text className="text-xs text-slate-400">Streak: {racks}</Text>
        </View>
    </View>
);

const ActionButton = ({ title, onPress, color, size = "md" }) => (
    <TouchableOpacity
        onPress={onPress}
        className={`${color} rounded-xl items-center justify-center m-1 shadow-lg active:opacity-80 
        ${size === 'lg' ? 'h-32 w-32' : (size === 'wide' ? 'h-20 flex-1' : 'h-24 w-24')}`}
    >
        <Text className="text-white font-bold text-center uppercase tracking-wide
        ${size === 'lg' ? 'text-2xl' : 'text-sm'}">
            {title}
        </Text>
    </TouchableOpacity>
);

export default function Game141Screen({ navigation }) {
    const {
        resetGame, player1, player2, turn,
        currentInningPoints, currentRackCount,
        add141Point, undo141Point, commit141Turn
    } = useGame();

    useEffect(() => {
        // Only reset if we just navigated here? 
        // Usually we might want to resume if we went to stats and back.
        // For now, let's assume we reset only if explicitly requested or on mount if empty.
        // Actually, App flow suggests 'Home' -> Start Game -> New Game. 
        // Simple verification check: if player scores are 0, maybe it's fresh?
        // Better: let user press "New Game" in menu.
        // But implementation plan says "Initialize". I'll reset on mount for now to be safe for verification.
        resetGame('14.1');
    }, []);

    return (
        <View className="flex-1 bg-slate-900">
            {/* Top Bar: Players */}
            <View className="flex-row pt-2 px-2 h-28">
                <PlayerSummary
                    name={player1.name}
                    score={player1.score}
                    fouls={player1.fouls}
                    racks={player1.consecutiveFouls} // Using 'racks' prop to show consec fouls for now or create new prop
                    isActive={turn === 1}
                />
                <PlayerSummary
                    name={player2.name}
                    score={player2.score}
                    fouls={player2.fouls}
                    racks={player2.consecutiveFouls}
                    isActive={turn === 2}
                />
            </View>

            {/* Info Bar */}
            <View className="flex-row justify-between px-6 py-2 bg-slate-800/50">
                <Text className="text-slate-400 font-bold">Rack Count: <Text className="text-emerald-400">{currentRackCount}/14</Text></Text>
                <Text className="text-slate-400 font-bold">Current Run: <Text className="text-white">{currentInningPoints}</Text></Text>
            </View>

            {/* Main Interaction Area */}
            <View className="flex-1 items-center justify-center">

                {/* Big Points Controls */}
                <View className="flex-row items-center mb-6">
                    <ActionButton
                        title="Undo"
                        onPress={undo141Point}
                        color="bg-red-900/40 border border-red-500/50"
                        size="md"
                    />
                    <View className="items-center mx-4">
                        <TouchableOpacity
                            onPress={add141Point}
                            className="bg-emerald-600 w-48 h-48 rounded-full items-center justify-center border-4 border-emerald-400 shadow-xl active:bg-emerald-700"
                        >
                            <Text className="text-white text-6xl font-bold">+{currentInningPoints > 0 ? 1 : 1}</Text>
                            <Text className="text-emerald-200 text-sm mt-2">POCKET</Text>
                        </TouchableOpacity>
                    </View>
                    {/* Spacer or Settings */}
                    <View className="w-24" />
                </View>

                {/* End Turn Actions */}
                <View className="w-full px-4">
                    <Text className="text-slate-500 font-bold mb-2 uppercase text-xs ml-1">End Inning</Text>
                    <View className="flex-row mb-2">
                        <ActionButton title="Safety" onPress={() => commit141Turn('safety')} color="bg-yellow-600" size="wide" />
                        <ActionButton title="Miss" onPress={() => commit141Turn('miss')} color="bg-slate-600" size="wide" />
                    </View>
                    <View className="flex-row">
                        <ActionButton title="Foul (-1)" onPress={() => commit141Turn('foul')} color="bg-red-600" size="wide" />
                        <ActionButton title="Break Foul (-2)" onPress={() => commit141Turn('breaking_foul')} color="bg-red-800" size="wide" />
                    </View>
                </View>

            </View>
        </View>
    );
}
