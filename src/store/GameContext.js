import React, { createContext, useContext, useState, useEffect } from 'react';
import { calculate141Turn } from '../utils/gameLogic';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { setLanguage, t } from '../utils/i18n';

const GameContext = createContext();

export const useGame = () => useContext(GameContext);

export const GameProvider = ({ children }) => {
    // Global State
    const [gameMode, setGameMode] = useState(null);
    const [language, setLanguageState] = useState('en');
    const [soundEnabled, setSoundEnabled] = useState(true);

    const switchLanguage = (lang) => {
        setLanguageState(lang);
        setLanguage(lang); // Update utility
    };

    // Players
    const [player1, setPlayer1] = useState({ name: 'Player 1', score: 0, racks: 0, fouls: 0, consecutiveFouls: 0 });
    const [player2, setPlayer2] = useState({ name: 'Player 2', score: 0, racks: 0, fouls: 0, consecutiveFouls: 0 });

    // 14.1 Specific
    const [currentInningPoints, setCurrentInningPoints] = useState(0);
    const [currentRackCount, setCurrentRackCount] = useState(0);
    const [ballsOnTable, setBallsOnTable] = useState(15); // Local state moved to Context
    const [turn, setTurn] = useState(1);
    const [inningHistory, setInningHistory] = useState([]); // Display log
    const [turnHistory, setTurnHistory] = useState([]); // State snapshots for Undo
    const [gameHistory, setGameHistory] = useState([]); // Persisted Games

    // Actions
    // Actions
    const resetGame = (mode) => {
        setGameMode(mode);
        setPlayer1({ name: 'Player 1', score: 0, racks: 0, fouls: 0, consecutiveFouls: 0 });
        setPlayer2({ name: 'Player 2', score: 0, racks: 0, fouls: 0, consecutiveFouls: 0 });
        setCurrentInningPoints(0);
        setCurrentRackCount(0);
        setBallsOnTable(15);
        setTurn(1);
        setInningHistory([]);
    };

    // Load History on Mount
    useEffect(() => {
        loadHistory();
    }, []);

    const loadHistory = async () => {
        try {
            const jsonValue = await AsyncStorage.getItem('@fortune142_history');
            if (jsonValue != null) {
                setGameHistory(JSON.parse(jsonValue));
            }
        } catch (e) {
            console.error("Failed to load history", e);
        }
    };

    // Persistence Actions
    const saveGame = async () => {
        // Create Game Record
        const gameRecord = {
            id: Date.now().toString(),
            date: new Date().toISOString(),
            mode: gameMode,
            player1: player1,
            player2: player2,
            winner: player1.score > player2.score ? 1 : (player2.score > player1.score ? 2 : 0),
            innings: inningHistory
        };

        const newHistory = [gameRecord, ...gameHistory];
        setGameHistory(newHistory);

        try {
            const jsonValue = JSON.stringify(newHistory);
            await AsyncStorage.setItem('@fortune142_history', jsonValue);
        } catch (e) {
            console.error("Failed to save history", e);
        }
    };

    const deleteGame = async (id) => {
        const newHistory = gameHistory.filter(g => g.id !== id);
        setGameHistory(newHistory);
        try {
            await AsyncStorage.setItem('@fortune142_history', JSON.stringify(newHistory));
        } catch (e) {
            console.error("Failed to delete game", e);
        }
    };

    const updateSetScore = (playerNum, change) => {
        if (playerNum === 1) {
            setPlayer1(prev => ({ ...prev, racks: Math.max(0, prev.racks + change) }));
        } else {
            setPlayer2(prev => ({ ...prev, racks: Math.max(0, prev.racks + change) }));
        }
    };

    const add141Point = () => {
        setCurrentInningPoints(p => p + 1);
        setCurrentRackCount(r => {
            if (r >= 14) return 1;
            return r + 1;
        });
    };

    const undo141Point = () => {
        if (currentInningPoints > 0) {
            setCurrentInningPoints(p => p - 1);
            setCurrentRackCount(r => Math.max(0, r - 1));
        }
    };

    const undoLastTurn = () => {
        if (turnHistory.length === 0) return;

        const lastState = turnHistory[turnHistory.length - 1]; // Peek

        // Restore State
        setPlayer1(lastState.player1);
        setPlayer2(lastState.player2);
        setTurn(lastState.turn);
        setBallsOnTable(lastState.ballsOnTable);
        setInningHistory(lastState.inningHistory);

        // Pop History
        setTurnHistory(prev => prev.slice(0, -1));
    };

    const processTurn141 = ({ points, foulPoints, isSafety, shouldSwitchTurn, newBallsOnTable }) => {
        // 1. Snapshot Current State
        const snapshot = {
            player1,
            player2,
            turn,
            ballsOnTable,
            inningHistory
        };
        setTurnHistory(prev => [...prev, snapshot]);

        // 2. Calculate New State
        const activePlayerSetter = turn === 1 ? setPlayer1 : setPlayer2;
        const activePlayer = turn === 1 ? player1 : player2;

        let scoreChange = points;
        let penalty = foulPoints;
        let consecutiveFouls = activePlayer.consecutiveFouls;

        // Failing to hit a ball or scratching is a foul
        if (foulPoints > 0) {
            consecutiveFouls += 1;
            // Check 3-foul penalty
            if (consecutiveFouls >= 3) {
                penalty += 15;
                consecutiveFouls = 0; // Reset after penalty
            }
        } else {
            // Legal shot or Safety resets consecutive fouls (usually)
            if (points > 0) {
                consecutiveFouls = 0;
            }
        }

        // Apply Score Update
        activePlayerSetter(prev => ({
            ...prev,
            score: prev.score + scoreChange - penalty,
            fouls: foulPoints > 0 ? prev.fouls + 1 : prev.fouls,
            consecutiveFouls: consecutiveFouls
        }));

        // Update Table
        if (newBallsOnTable !== undefined) {
            setBallsOnTable(newBallsOnTable);
        }

        // History Log
        setInningHistory(prev => [{
            player: turn,
            points,
            penalty,
            isSafety,
            total: activePlayer.score + scoreChange - penalty,
            timestamp: Date.now()
        }, ...prev]);

        // Explicit Turn Switch logic passed from UI
        if (shouldSwitchTurn) {
            setTurn(turn === 1 ? 2 : 1);
        }
    };

    return (
        <GameContext.Provider value={{
            gameMode, player1, player2, turn, currentInningPoints, currentRackCount, inningHistory, ballsOnTable,
            gameHistory, language, soundEnabled, switchLanguage, setSoundEnabled,
            resetGame, updateSetScore, setPlayer1, setPlayer2, setTurn, setCurrentInningPoints, setBallsOnTable,
            add141Point, undo141Point, processTurn141, undoLastTurn,
            saveGame, deleteGame
        }}>
            {children}
        </GameContext.Provider>
    );
};
