import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, ScrollView, Alert } from 'react-native';
import { useGame } from '../store/GameContext';
import Rack from '../components/Rack';
import { t } from '../utils/i18n';

export default function MatchScreen({ navigation }) {
    const {
        player1, player2, turn, ballsOnTable,
        processTurn141, undoLastTurn, language // trigger re-render on lang change
    } = useGame();

    // Local state for the current uncommitted turn
    const [activeBalls, setActiveBalls] = useState(new Set(Array.from({ length: 15 }, (_, i) => i))); // Default 15
    // ballsOnTable is now in Context!
    const [foulCount, setFoulCount] = useState(0);
    const [isSafety, setIsSafety] = useState(false);

    // Derived state
    const pointsScored = ballsOnTable - activeBalls.size;
    const activePlayer = turn === 1 ? player1 : player2;

    // Effect to init active balls when turn starts or ballsOnTable changes (Undo/Next Turn)
    useEffect(() => {
        const newSet = new Set();
        for (let i = 0; i < ballsOnTable; i++) newSet.add(i);
        setActiveBalls(newSet);
    }, [ballsOnTable]);

    // Handlers
    const toggleBall = (index) => {
        const newSet = new Set(activeBalls);
        if (newSet.has(index)) newSet.delete(index);
        else newSet.add(index);
        setActiveBalls(newSet);
    };

    const potAll = () => {
        setActiveBalls(new Set()); // Empty (All potted)
    };

    const restoreAll = () => {
        // Restore to ballsOnTable limit
        const newSet = new Set();
        for (let i = 0; i < ballsOnTable; i++) newSet.add(i);
        setActiveBalls(newSet);
    };

    const toggleFoul = () => {
        // Toggle: 0 -> 1 (-1 pt) -> 2 (-2 pts, Break Foul) -> 0
        setFoulCount(prev => (prev + 1) % 3);
    };

    const handleAccept = () => {
        const remaining = activeBalls.size;

        // Check for 3 Consecutive Fouls Logic
        // We need to know if THIS commit will be the 3rd foul.
        // Current: activePlayer.consecutiveFouls
        // Input: foulCount > 0 ? (consecutiveFouls + 1)
        // Note: Safety or Legal Shot resets fouls.

        const willBeThreeFouls = foulCount > 0 && (activePlayer.consecutiveFouls + 1) >= 3;

        // Helper to commit
        const commit = (shouldReRack = false) => {
            let nextBallsOnTable = remaining;
            let shouldSwitchTurn = true;

            // Simplified Logic based on User Feedback:
            // "Either you pot it, or not."

            // Rack Transition Logic
            if (activeBalls.size === 0) {
                // All Potted -> Continue (14)
                shouldSwitchTurn = false;
                nextBallsOnTable = 14;
            }
            else {
                // Miss/Safe -> End Turn (Remaining)
                shouldSwitchTurn = true;
                nextBallsOnTable = remaining;
            }

            // Override for 3-Foul Re-Rack
            if (shouldReRack) {
                nextBallsOnTable = 15;
                shouldSwitchTurn = true; // Always switch after foul
            }

            const turnData = {
                points: pointsScored,
                foulPoints: foulCount === 1 ? 1 : (foulCount === 2 ? 2 : 0),
                isSafety,
                shouldSwitchTurn,
                newBallsOnTable: nextBallsOnTable
            };

            processTurn141(turnData);

            // UI Reset
            setFoulCount(0);
            setIsSafety(false);

            // Update Visuals
            const newSet = new Set();
            for (let i = 0; i < nextBallsOnTable; i++) newSet.add(i);
            setActiveBalls(newSet);
        };

        // Trigger Logic
        if (willBeThreeFouls) {
            Alert.alert(
                t('threeFouls'),
                t('reRackQuestion'),
                [
                    { text: t('no'), onPress: () => commit(false) },
                    { text: t('yes'), onPress: () => commit(true) } // Re-Rack
                ]
            );
        } else {
            commit(false);
        }
    };

    return (
        <View className="flex-1 bg-knthlz-dark">
            {/* Header: Score */}
            <View className="flex-row justify-between items-center p-6 pt-12 bg-knthlz-surface border-b border-gray-800">
                <View className="items-center">
                    <Text className={`text-xl font-bold ${turn === 1 ? 'text-knthlz-green' : 'text-knthlz-dim'}`}>{player1.name}</Text>
                    <Text className="text-5xl font-mono font-bold text-knthlz-text mt-2">{player1.score}</Text>
                    <View className="flex-row mt-1">
                        {Array.from({ length: player1.consecutiveFouls }).map((_, i) => <View key={i} className="w-2 h-2 rounded-full bg-red-500 mr-1" />)}
                    </View>
                </View>
                <View className="items-center">
                    <Text className="text-knthlz-dim font-bold text-xs uppercase tracking-widest">{t('rack')}</Text>
                    <Text className="text-knthlz-text text-xl font-bold">{Math.floor((player1.score + player2.score) / 14) + 1}</Text>
                </View>
                <View className="items-center">
                    <Text className={`text-xl font-bold ${turn === 2 ? 'text-knthlz-green' : 'text-knthlz-dim'}`}>{player2.name}</Text>
                    <Text className="text-5xl font-mono font-bold text-knthlz-text mt-2">{player2.score}</Text>
                    <View className="flex-row mt-1">
                        {Array.from({ length: player2.consecutiveFouls }).map((_, i) => <View key={i} className="w-2 h-2 rounded-full bg-red-500 mr-1" />)}
                    </View>
                </View>
            </View>

            {/* Main Input Area: Interact with Rack */}
            <View className="flex-1 p-4 justify-center items-center">
                <Text className="text-knthlz-dim text-center mb-6 text-xl tracking-widest uppercase font-bold">
                    {ballsOnTable < 15 ? `${ballsOnTable} ${t('ballsRemaining')}` : t('fullRack')}
                </Text>

                <Rack
                    ballsOnTable={ballsOnTable}
                    activeBalls={activeBalls}
                    onToggle={toggleBall}
                />

                {/* Rack Control Buttons */}
                <View className="flex-row gap-4 mt-6">
                    <TouchableOpacity onPress={potAll} className="px-4 py-2 bg-knthlz-surface border border-gray-700 rounded-full">
                        <Text className="text-knthlz-text text-xs font-bold uppercase">{t('potAll')}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity onPress={restoreAll} className="px-4 py-2 bg-knthlz-surface border border-gray-700 rounded-full">
                        <Text className="text-knthlz-text text-xs font-bold uppercase">{t('restoreAll')}</Text>
                    </TouchableOpacity>
                </View>

                <Text className="text-knthlz-dim/50 text-xs mt-4 text-center">
                    Tap to pot • {t('score')}: {pointsScored}
                </Text>
            </View>

            {/* Action Bar (Footer) */}
            <View className="p-4 bg-knthlz-surface border-t border-gray-800">
                <View className="flex-row justify-between items-center gap-3">
                    {/* Fouls Toggle */}
                    <TouchableOpacity
                        onPress={toggleFoul}
                        className={`flex-1 py-4 rounded-lg border-2 items-center ${foulCount > 0 ? 'bg-red-900/50 border-red-500' : 'bg-knthlz-dark border-gray-700'}`}
                    >
                        <Text className={`font-bold ${foulCount > 0 ? 'text-red-500' : 'text-knthlz-dim'}`}>
                            {foulCount === 0 ? t('noFoul') : (foulCount === 1 ? t('foulPenalty') : t('breakFoulPenalty'))}
                        </Text>
                    </TouchableOpacity>

                    {/* Safety Toggle */}
                    <TouchableOpacity
                        onPress={() => setIsSafety(!isSafety)}
                        className={`flex-1 py-4 rounded-lg border-2 items-center ${isSafety ? 'bg-blue-900/50 border-blue-500' : 'bg-knthlz-dark border-gray-700'}`}
                    >
                        <Text className={`font-bold ${isSafety ? 'text-blue-500' : 'text-knthlz-dim'}`}>
                            {isSafety ? t('safetyOn') : t('safety')}
                        </Text>
                    </TouchableOpacity>
                </View>

                <View className="flex-row justify-between items-center mt-3 gap-3">
                    {/* Undo */}
                    <TouchableOpacity
                        onPress={undoLastTurn}
                        className="w-20 py-4 rounded-lg bg-gray-700 items-center"
                    >
                        <Text className="text-white font-bold">{t('undo')}</Text>
                    </TouchableOpacity>

                    {/* Accept (Commit) */}
                    <TouchableOpacity
                        onPress={handleAccept}
                        // If user hasn't touched rack, ballsRemaining is null. 
                        // But maybe they want to accept 0 points (Safety)? 
                        // Actually, if they want safety, they toggle Safety.
                        // If they score, they touch balls.
                        // Can they accept "0 score" without touching balls?
                        // If they accept with null, it assumes 0 change?
                        // Let's enable it always, but if null treated as "ballsOnTable" (0 points).
                        // Wait, if no interaction, pointsScored = 0 (ballsOnTable - ballsOnTable).
                        // So enabled is fine.
                        className={`flex-1 py-4 rounded-lg items-center ${true ? 'bg-knthlz-green' : 'bg-gray-800'}`}
                    >
                        <Text className={`text-xl font-bold text-knthlz-dark`}>
                            {t('accept')}
                        </Text>
                    </TouchableOpacity>
                </View>
            </View>
        </View>
    );
}
