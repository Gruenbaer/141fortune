import React, { createContext, useContext, useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { setLanguage, t } from '../utils/i18n';

const GameContext = createContext();

export const useGame = () => useContext(GameContext);

export const GameProvider = ({ children }) => {
    // Global State
    const [gameMode, setGameMode] = useState(null);
    const [language, setLanguageState] = useState('en');
    const [soundEnabled, setSoundEnabled] = useState(true);
    const [theme, setTheme] = useState('dark');

    const switchLanguage = (lang) => {
        setLanguageState(lang);
        setLanguage(lang); // Update utility
    };

    // --- Player Management (New v2.0) ---
    const [players, setPlayers] = useState([]);

    useEffect(() => {
        loadPlayers();
        loadHistory();
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

    const addPlayer = async (name) => {
        console.log("Adding player:", name);
        if (!name.trim()) return null;
        const newPlayer = {
            id: Date.now().toString(),
            name: name.trim(),
            gamesPlayed: 0,
            wins: 0,
            highRun: 0,
            avg: 0.0
        };
        const updated = [...players, newPlayer];
        console.log("Updated players list:", updated);
        setPlayers(updated);
        await AsyncStorage.setItem('@fortune142_players', JSON.stringify(updated));
        return newPlayer;
    };

    const deletePlayer = async (id) => {
        const updated = players.filter(p => p.id !== id);
        setPlayers(updated);
        await AsyncStorage.setItem('@fortune142_players', JSON.stringify(updated));
    };

    // --- Active Game State ---
    const [player1, setPlayer1] = useState({ name: 'Player 1', score: 0, racks: 0, fouls: 0, consecutiveFouls: 0 });
    const [player2, setPlayer2] = useState({ name: 'Player 2', score: 0, racks: 0, fouls: 0, consecutiveFouls: 0 });
    const [gameSettings, setGameSettings] = useState({}); // Goals, Handicap

    // 14.1 Specific
    const [ballsOnTable, setBallsOnTable] = useState(15);
    const [turn, setTurn] = useState(1);
    const [inningHistory, setInningHistory] = useState([]);
    const [turnHistory, setTurnHistory] = useState([]);
    const [gameHistory, setGameHistory] = useState([]);

    // --- Actions ---

    // Initialize Match (New v2.0)
    const startMatch = (p1Profile, p2Profile, settings) => {
        setGameMode('14.1');
        setGameSettings(settings);

        // Reset Game State
        // Reset Game State
        setPlayer1({
            ...p1Profile, // Carry over ID/Name
            score: settings.p1Spot || 0,
            racks: 0,
            fouls: 0,
            consecutiveFouls: 0,
            isProfile: true // Flag to know it's a real user
        });
        setPlayer2({
            ...p2Profile,
            score: settings.p2Spot || 0,
            racks: 0,
            fouls: 0,
            consecutiveFouls: 0,
            isProfile: true
        });

        setCurrentInningPoints(0);
        setCurrentRackCount(0);
        setBallsOnTable(15);
        setTurn(1);
        setInningHistory([]);
        setTurnHistory([]);
    };

    // Legacy Reset (Keep for compat or simple modes)
    const resetGame = (mode) => {
        setGameMode(mode);
        setPlayer1({ name: 'Player 1', score: 0, racks: 0, fouls: 0, consecutiveFouls: 0 });
        setPlayer2({ name: 'Player 2', score: 0, racks: 0, fouls: 0, consecutiveFouls: 0 });
        setBallsOnTable(15);
        setTurn(1);
        setInningHistory([]);
    };

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

    // Persistence Actions (Updated v2.0)
    const saveGame = async () => {
        // 1. Save to History
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
        await AsyncStorage.setItem('@fortune142_history', JSON.stringify(newHistory));

        // 2. Update Player Statistics (if linked to profiles)
        if (player1.id && player2.id) {
            updatePlayerStats(player1, player2);
        }
    };

    const updatePlayerStats = async (p1GameData, p2GameData) => {
        const updatedPlayers = players.map(p => {
            if (p.id === p1GameData.id) return calculateNewStats(p, p1GameData, p1GameData.score > p2GameData.score);
            if (p.id === p2GameData.id) return calculateNewStats(p, p2GameData, p2GameData.score > p1GameData.score);
            return p;
        });

        setPlayers(updatedPlayers);
        await AsyncStorage.setItem('@fortune142_players', JSON.stringify(updatedPlayers));
    };

    const calculateNewStats = (currentProfile, gameData, isWinner) => {
        const newGamesPlayed = (currentProfile.gamesPlayed || 0) + 1;
        const newWins = (currentProfile.wins || 0) + (isWinner ? 1 : 0);

        // Calculate High Run from this game's history?
        // We'd need to scan inningHistory again or have MatchScreen track it.
        // Simplified: assume gameData tracks high run or we implement it later.
        // For now, let's just do Wins/Played.
        // To do High Run properly, we need to pass it or calc it.
        // Let's postpone complex High Run calc to the Stats update task.

        return {
            ...currentProfile,
            gamesPlayed: newGamesPlayed,
            wins: newWins,
        };
    };

    const deleteGame = async (id) => {
        const newHistory = gameHistory.filter(g => g.id !== id);
        setGameHistory(newHistory);
        await AsyncStorage.setItem('@fortune142_history', JSON.stringify(newHistory));
    };

    const updateSetScore = (playerNum, change) => {
        const setter = playerNum === 1 ? setPlayer1 : setPlayer2;
        setter(prev => ({ ...prev, racks: Math.max(0, prev.racks + change) }));
    };

    // 14.1 State (Legacy/Ref code)
    const [currentInningPoints, setCurrentInningPoints] = useState(0); // Not heavily used in new MatchScreen logic but kept for ref
    const [currentRackCount, setCurrentRackCount] = useState(0);

    const add141Point = () => { }; // Deprecated by processTurn141
    const undo141Point = () => { }; // Deprecated

    const undoLastTurn = () => {
        if (turnHistory.length === 0) return;
        const lastState = turnHistory[turnHistory.length - 1];
        setPlayer1(lastState.player1);
        setPlayer2(lastState.player2);
        setTurn(lastState.turn);
        setBallsOnTable(lastState.ballsOnTable);
        setInningHistory(lastState.inningHistory);
        setTurnHistory(prev => prev.slice(0, -1));
    };

    const processTurn141 = ({ points, foulPoints, isSafety, shouldSwitchTurn, newBallsOnTable }) => {
        // Snapshot
        setTurnHistory(prev => [...prev, { player1, player2, turn, ballsOnTable, inningHistory }]);

        const activePlayerSetter = turn === 1 ? setPlayer1 : setPlayer2;
        const activePlayer = turn === 1 ? player1 : player2;

        let scoreChange = points;
        let penalty = foulPoints;
        let consecutiveFouls = activePlayer.consecutiveFouls;

        if (foulPoints > 0) {
            consecutiveFouls += 1;
            if (consecutiveFouls >= 3) {
                penalty += 15;
                consecutiveFouls = 0; // Reset after penalty
            }
        } else {
            // Legal shot resets fouls. Safety does NOT reset foul count in strictly WPA, 
            // BUT usually "Safety" implies I touched a ball. 
            // If I foul on a safety, it's a foul.
            // If I play safe legally, I hit a ball + rail. 
            // A legal shot (including legal safety) resets consecutive fouls.
            // So yes, points > 0 OR isSafety (assuming legal safety) -> reset.
            if (points > 0 || isSafety) {
                consecutiveFouls = 0;
            }
        }

        activePlayerSetter(prev => ({
            ...prev,
            score: prev.score + scoreChange - penalty,
            fouls: foulPoints > 0 ? prev.fouls + 1 : prev.fouls,
            consecutiveFouls: consecutiveFouls
        }));

        if (newBallsOnTable !== undefined) {
            setBallsOnTable(newBallsOnTable);
        }

        setInningHistory(prev => [{
            player: turn,
            points,
            penalty,
            isSafety,
            total: activePlayer.score + scoreChange - penalty,
            timestamp: Date.now()
        }, ...prev]);

        if (shouldSwitchTurn) {
            setTurn(turn === 1 ? 2 : 1);
        }
    };

    const contextValue = React.useMemo(() => ({
        gameMode, language, soundEnabled, switchLanguage, setSoundEnabled,
        theme, setTheme,
        players, addPlayer, deletePlayer,
        player1, setPlayer1, player2, setPlayer2,
        turn, setTurn, gameSettings, ballsOnTable, setBallsOnTable,
        inningHistory, gameHistory,
        startMatch, saveGame, deleteGame, resetGame,
        processTurn141, undoLastTurn, updateSetScore
    }), [
        gameMode, language, soundEnabled, theme, players,
        player1, player2, turn, gameSettings, ballsOnTable,
        inningHistory, gameHistory
    ]);

    return (
        <GameContext.Provider value={contextValue}>
            {children}
        </GameContext.Provider>
    );
};
