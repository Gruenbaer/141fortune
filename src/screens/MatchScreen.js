import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, Modal, ScrollView, Dimensions, StyleSheet } from 'react-native';
import { useGame } from '../store/GameContext';
import Rack from '../components/Rack';
import { t } from '../utils/i18n';
import PoolBall from '../components/PoolBall';

const { width } = Dimensions.get('window');

// --- Helper Components ---

const MatchHistoryModal = ({ visible, onClose, history, player }) => (
    <Modal visible={visible} animationType="fade" transparent>
        <TouchableOpacity style={styles.modalOverlay} activeOpacity={1} onPress={onClose}>
            <TouchableOpacity activeOpacity={1} onPress={() => { }} style={styles.modalContent}>
                <View style={styles.modalHeader}>
                    <Text style={styles.modalTitle}>{player.name}'s History</Text>
                    <TouchableOpacity onPress={onClose} style={styles.closeButton}>
                        <Text style={styles.closeButtonText}>Close</Text>
                    </TouchableOpacity>
                </View>
                {/* Stats Header */}
                <View style={styles.statsHeader}>
                    <View style={styles.statBox}>
                        <Text style={styles.statLabel}>Game Avg</Text>
                        <Text style={styles.statValue}>{player.avg || "0.0"}</Text>
                    </View>
                    <View style={styles.statBox}>
                        <Text style={styles.statLabel}>High Run</Text>
                        <Text style={styles.statValueHighlight}>{player.highRun || 0}</Text>
                    </View>
                </View>

                {/* List */}
                <ScrollView>
                    {history
                        .filter(h => h.player === (player.id === '1' || player.id === 1 ? 1 : 2)) // Simplified check or rely on player prop context
                        .map((turn, i) => (
                            <View key={i} style={styles.historyItem}>
                                <Text style={styles.historyInning}>#{history.length - i}</Text>
                                <View style={styles.historyDetails}>
                                    {turn.isSafety && <Text style={styles.tagSafety}>SAFE</Text>}
                                    {turn.penalty > 0 && <Text style={styles.tagFoul}>FOUL -{turn.penalty}</Text>}
                                    <Text style={styles.historyPoints}>+{turn.points}</Text>
                                </View>
                                <Text style={styles.historyTotal}>{turn.total}</Text>
                            </View>
                        ))}
                </ScrollView>
            </TouchableOpacity>
        </TouchableOpacity>
    </Modal>
);

export default function MatchScreen({ navigation }) {
    const {
        player1, player2, turn, ballsOnTable,
        processTurn141, undoLastTurn, saveGame,
        inningHistory, gameSettings
    } = useGame();

    // --- Local State ---
    const [activeRackBalls, setActiveRackBalls] = useState(new Set(Array.from({ length: 15 }, (_, i) => i)));

    const [foulCount, setFoulCount] = useState(0);
    const [isSafety, setIsSafety] = useState(false);

    // Re-Rack Logic: 14.1 Continuous triggers when 1 ball is left.
    const reRackNeeded = activeRackBalls.size === 1;

    // History Modals
    const [showP1History, setShowP1History] = useState(false);
    const [showP2History, setShowP2History] = useState(false);

    // Derived Stats
    const activePlayer = turn === 1 ? player1 : player2;

    const [rackStartCount, setRackStartCount] = useState(15);

    // Sync Local State with Context on Mount/Undo/TurnSwitch
    useEffect(() => {
        // Recover state from ballsOnTable count
        let count = ballsOnTable;
        if (count > 15) count = 15; // safety

        const rackSet = new Set();
        for (let i = 0; i < count; i++) {
            rackSet.add(i);
        }

        setActiveRackBalls(rackSet);
        setRackStartCount(count); // Initialize baseline for this rack

    }, [ballsOnTable, turn]);

    // Interactions
    const toggleRackBall = (idx) => {
        const newSet = new Set(activeRackBalls);
        if (newSet.has(idx)) {
            // Trying to POT a ball
            // PREVENT putting the last ball (Constraint: "do not let the ball pot")
            if (newSet.size <= 1) return;
            newSet.delete(idx);
        } else {
            // Un-potting (restoring)
            newSet.add(idx);
        }
        setActiveRackBalls(newSet);
    };

    // Live Point Calculation
    // We use a local baseline (rackStartCount) that updates when we Re-Rack.
    // This allows exact math even if we start with 14 balls and re-rack to 15.

    const [pendingPoints, setPendingPoints] = useState(0);
    const currentBalls = activeRackBalls.size;
    const diff = rackStartCount - currentBalls;
    const currentRun = pendingPoints + diff;

    const onReRackPress = () => {
        // User clicked RE-RACK. 
        // Condition: 1 ball left.
        // Action: 
        // 1. Add points based on what was potted THIS rack (diff).
        // 2. Reset visual rack to 15.
        // 3. Update baseline (rackStartCount) to 15.

        const pointsToAdd = rackStartCount - activeRackBalls.size;
        setPendingPoints(p => p + pointsToAdd);
        setRackStartCount(15); // New baseline for the fresh rack

        // Reset Rack to full 15 balls
        const newSet = new Set();
        for (let i = 0; i < 15; i++) newSet.add(i);
        setActiveRackBalls(newSet);
    };

    const onPotAllRack = () => {
        // "Pot All" now means: Pot down to 1 ball.
        // Rule: The 1-Ball (Index 0) should be the one remaining if possible.
        // Because that is the Break Ball position.

        const newSet = new Set();

        // If 1-ball (index 0) is currently on the table, KEEP IT.
        // If not, keep the lowest index available? Or just any.
        // User specifically asked for "The 1 ball".

        if (activeRackBalls.has(0)) {
            newSet.add(0); // Keep 1-ball
        } else if (activeRackBalls.size > 0) {
            // If 1-ball was already potted, keep the first available one to be safe
            const firstAvailable = Array.from(activeRackBalls)[0];
            newSet.add(firstAvailable);
        }

        setActiveRackBalls(newSet);
    };

    const onAcceptPress = () => {
        const totalPoints = currentRun;

        const turnData = {
            points: Math.max(0, totalPoints),
            foulPoints: foulCount,
            isSafety,
            shouldSwitchTurn: true,
            newBallsOnTable: activeRackBalls.size // Persist remaining balls
        };

        processTurn141(turnData);

        // Reset Local
        setPendingPoints(0);
        setFoulCount(0);
        setIsSafety(false);
    };

    return (
        <ScrollView contentContainerStyle={{ flexGrow: 1 }} style={styles.container}>
            {/* --- Header --- */}
            <View style={styles.header}>
                {/* Player 1 */}
                <View style={[styles.playerCard, turn === 1 ? styles.activePlayerP1 : styles.inactivePlayer]}>
                    <Text style={[styles.playerName, turn === 1 ? styles.textWhite : styles.textGray]}>{player1.name}</Text>
                    <Text style={styles.scoreText}>{player1.score}</Text>
                    <Text style={styles.goalText}>Goal: {gameSettings.goalP1 || 100}</Text>
                </View>

                {/* Center Stats */}
                <View style={styles.centerStats}>
                    {/* Rack Count */}
                    <View style={styles.rackInfo}>
                        <Text style={styles.rackLabel}>Rack</Text>
                        <Text style={styles.rackValue}>{Math.floor((player1.score + player2.score + currentRun) / 14) + 1}</Text>
                    </View>

                    {/* Current Run */}
                    {currentRun > 0 && (
                        <View style={styles.runIndicator}>
                            <Text style={styles.runLabel}>Run</Text>
                            <Text style={styles.runValue}>+{currentRun}</Text>
                        </View>
                    )}
                </View>

                {/* Player 2 */}
                <View style={[styles.playerCard, turn === 2 ? styles.activePlayerP2 : styles.inactivePlayer]}>
                    <Text style={[styles.playerName, turn === 2 ? styles.textWhite : styles.textGray]}>{player2.name}</Text>
                    <Text style={styles.scoreText}>{player2.score}</Text>
                    <Text style={styles.goalText}>Goal: {gameSettings.goalP2 || 100}</Text>
                </View>
            </View>

            {/* --- Table Area (Green Felt) --- */}
            <View style={styles.tableArea}>
                {/* Felt Texture simulated by color */}
                <View style={styles.feltOverlay} />

                {/* Details Buttons (Now "On the Felt") */}
                <TouchableOpacity onPress={() => setShowP1History(true)} style={[styles.detailsButtonOnFelt, { left: 16 }]}>
                    <Text style={styles.detailsButtonText}>DETAILS</Text>
                </TouchableOpacity>

                <TouchableOpacity onPress={() => setShowP2History(true)} style={[styles.detailsButtonOnFelt, { right: 16 }]}>
                    <Text style={styles.detailsButtonText}>DETAILS</Text>
                </TouchableOpacity>

                {/* Break Ball Spot (Restored) */}
                <View style={styles.breakBallContainer}>
                    <Text style={styles.breakBallLabel}>Break Ball</Text>
                    <TouchableOpacity onPress={() => toggleRackBall(0)} activeOpacity={0.8}>
                        <PoolBall
                            number={1}
                            size={50}
                            isPotted={!activeRackBalls.has(0)}
                        />
                    </TouchableOpacity>
                </View>

                {/* Rack */}
                <View style={styles.rackContainer}>
                    <Rack
                        ballsOnTable={15}
                        activeBalls={activeRackBalls}
                        onToggle={toggleRackBall}
                        is141Mode={true}
                    />

                    {/* Centered POT RACK Button */}
                    {activeRackBalls.size > 1 && (
                        <TouchableOpacity
                            style={styles.potRackCentered}
                            onPress={onPotAllRack}
                        >
                            <Text style={styles.potAllText}>POT RACK</Text>
                        </TouchableOpacity>
                    )}
                </View>
            </View>

            {/* --- Action Bar --- */}
            <View style={styles.actionBar}>
                {/* Status Toggles */}
                <View style={styles.togglesRow}>
                    {/* Foul Toggle */}
                    <TouchableOpacity
                        onPress={() => setFoulCount((f + 1) % 3)}
                        style={[styles.toggleButton, foulCount > 0 ? styles.toggleFoulActive : styles.toggleInactive]}
                    >
                        <Text style={styles.toggleLabel}>Fouls</Text>
                        <Text style={[styles.toggleValue, foulCount > 0 ? styles.textRed : styles.textGray]}>{foulCount}</Text>
                    </TouchableOpacity>

                    {/* Safety Toggle */}
                    <TouchableOpacity
                        onPress={() => setIsSafety(!isSafety)}
                        style={[styles.toggleButton, isSafety ? styles.toggleSafetyActive : styles.toggleInactive]}
                    >
                        <Text style={styles.toggleLabel}>Safety</Text>
                        <View style={[styles.safetyIndicator, isSafety ? styles.bgBlue : styles.bgGray]} />
                    </TouchableOpacity>
                </View>

                {/* Commit Actions */}
                <View style={styles.actionsRow}>
                    <TouchableOpacity
                        onPress={undoLastTurn}
                        style={styles.undoButton}
                    >
                        <Text style={styles.undoText}>Undo</Text>
                    </TouchableOpacity>

                    <TouchableOpacity
                        onPress={reRackNeeded ? onReRackPress : onAcceptPress}
                        style={[styles.acceptButton, reRackNeeded && styles.reRackActionBtn]}
                    >
                        <Text style={styles.acceptText}>{reRackNeeded ? "RE-RACK" : "ACCEPT"}</Text>
                        <Text style={styles.acceptSubText}>
                            {reRackNeeded
                                ? `Continue Run (+${diff})`
                                : `Ends Turn (Commit +${currentRun})`
                            }
                        </Text>
                    </TouchableOpacity>
                </View>
            </View>

            {/* Modals */}
            <MatchHistoryModal visible={showP1History} onClose={() => setShowP1History(false)} history={inningHistory} player={{ ...player1, id: 1 }} />
            <MatchHistoryModal visible={showP2History} onClose={() => setShowP2History(false)} history={inningHistory} player={{ ...player2, id: 2 }} />
        </ScrollView>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#0f172a',
    },
    header: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'flex-end',
        paddingHorizontal: 24,
        paddingTop: 48,
        paddingBottom: 16,
        backgroundColor: '#1e293b',
        borderBottomWidth: 1,
        borderBottomColor: '#1f2937',
    },
    playerCard: {
        alignItems: 'center',
        padding: 8,
        borderRadius: 12,
        minWidth: 80,
    },
    activePlayerP1: {
        backgroundColor: '#1f2937',
        borderWidth: 2,
        borderColor: '#22c55e',
        elevation: 4,
    },
    activePlayerP2: {
        backgroundColor: '#1f2937',
        borderWidth: 2,
        borderColor: '#3b82f6',
        elevation: 4,
    },
    inactivePlayer: {
        opacity: 0.6,
    },
    playerName: {
        fontSize: 18,
        fontWeight: '900',
        textTransform: 'uppercase',
    },
    textWhite: { color: 'white' },
    textGray: { color: '#9ca3af' },
    scoreText: {
        fontSize: 48,
        fontFamily: 'monospace',
        fontWeight: 'bold',
        color: 'white',
        lineHeight: 56,
    },
    goalText: {
        fontSize: 16, // Was 12
        color: '#9ca3af', // Lighter for contrast
        marginTop: 4,
    },
    // Center Stats
    centerStats: {
        alignItems: 'center',
        justifyContent: 'flex-end',
        paddingBottom: 4,
        gap: 12,
    },
    rackInfo: {
        alignItems: 'center',
    },
    rackLabel: {
        color: '#9ca3af',
        fontWeight: 'bold',
        fontSize: 14, // Was 10
        textTransform: 'uppercase',
        letterSpacing: 1,
    },
    rackValue: {
        color: 'white',
        fontSize: 32, // Was 24
        fontWeight: 'bold',
    },
    runIndicator: {
        backgroundColor: '#22c55e',
        paddingHorizontal: 16,
        paddingVertical: 6,
        borderRadius: 12,
        alignItems: 'center',
        elevation: 4,
    },
    runLabel: {
        color: '#064e3b',
        fontSize: 12, // Was 8
        fontWeight: 'bold',
        textTransform: 'uppercase',
    },
    runValue: {
        color: '#ffffff',
        fontSize: 24, // Was 20
        fontWeight: 'black',
    },
    // Details Button (On Felt)
    detailsButtonOnFelt: {
        position: 'absolute',
        top: 12,
        backgroundColor: 'rgba(5, 150, 105, 0.9)',
        paddingVertical: 8, // More padding
        paddingHorizontal: 16,
        borderRadius: 24,
        zIndex: 10,
        elevation: 4,
        borderWidth: 1,
        borderColor: 'rgba(255,255,255,0.2)'
    },
    detailsButtonText: {
        color: 'white',
        fontSize: 13, // Was 11
        fontWeight: 'bold',
        letterSpacing: 1,
    },
    // Pot All Button (Centered)
    potRackCentered: {
        marginTop: 32,
        backgroundColor: 'rgba(255, 255, 255, 0.1)',
        paddingVertical: 16, // Bigger button
        paddingHorizontal: 32,
        borderRadius: 32,
        borderWidth: 2, // Thicker border
        borderColor: 'rgba(255, 255, 255, 0.3)',
        alignSelf: 'center',
    },
    potAllText: {
        color: 'white',
        fontWeight: 'bold',
        fontSize: 16, // Was 12
        textTransform: 'uppercase',
        letterSpacing: 2,
    },

    header: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'flex-end',
        paddingHorizontal: 16,
        paddingTop: 48,
        paddingBottom: 24, // More space
        backgroundColor: '#1e293b',
        borderBottomWidth: 1,
        borderBottomColor: '#1f2937',
        zIndex: 20,
    },
    playerCard: {
        alignItems: 'center',
        padding: 12,
        borderRadius: 16,
        minWidth: 100, // Bigger card
    },
    playerName: {
        fontSize: 20, // Bigger name
        fontWeight: '900',
        textTransform: 'uppercase',
        marginBottom: 4,
    },
    scoreText: {
        fontSize: 56, // Bigger score
        fontFamily: 'monospace',
        fontWeight: 'bold',
        color: 'white',
        lineHeight: 64,
    },
    // Details Button (On Felt)
    detailsButtonOnFelt: {
        position: 'absolute',
        top: 12, // Hanging from top of felt
        backgroundColor: 'rgba(5, 150, 105, 0.9)', // Emerald 600
        paddingVertical: 6,
        paddingHorizontal: 12,
        borderRadius: 20,
        zIndex: 10,
        elevation: 4,
        borderWidth: 1,
        borderColor: 'rgba(255,255,255,0.2)'
    },
    detailsButtonText: {
        color: 'white',
        fontSize: 11,
        fontWeight: 'bold',
        letterSpacing: 1,
    },
    // Pot All Button (Centered)
    potRackCentered: {
        marginTop: 24, // Space below rack
        backgroundColor: 'rgba(255, 255, 255, 0.1)',
        paddingVertical: 12,
        paddingHorizontal: 24,
        borderRadius: 24,
        borderWidth: 1,
        borderColor: 'rgba(255, 255, 255, 0.3)',
        alignSelf: 'center',
    },
    potAllText: {
        color: 'white',
        fontWeight: 'bold',
        fontSize: 12,
        textTransform: 'uppercase',
        letterSpacing: 1,
    },
    // Table
    tableArea: {
        alignItems: 'center',
        justifyContent: 'center',
        paddingVertical: 32,
        backgroundColor: '#14532d',
        borderTopWidth: 8,
        borderBottomWidth: 8,
        borderColor: '#713f12',
        minHeight: 450,
        position: 'relative',
        overflow: 'hidden',
    },
    feltOverlay: {
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: 'rgba(21, 128, 61, 0.3)', // bg-green-800/30
    },
    breakBallContainer: {
        position: 'absolute',
        top: 40,
        alignItems: 'center',
    },
    breakBallLabel: {
        color: 'rgba(187, 247, 208, 0.5)',
        fontSize: 10,
        fontWeight: 'bold',
        marginBottom: 4,
        textTransform: 'uppercase',
        letterSpacing: 2,
    },

    breakBallContainer: {
        position: 'absolute',
        top: 100, // Aligned with the rack roughly
        left: 20, // To the left side
        zIndex: 10,
    },
    breakBallLabel: {
        color: 'rgba(187, 247, 208, 0.5)',
        fontSize: 10,
        fontWeight: 'bold',
        marginBottom: 4,
        textTransform: 'uppercase',
        letterSpacing: 2,
        textAlign: 'center',
    },
    rackContainer: {
        marginTop: 40, // Reduced from 100 to save space
        alignSelf: 'center', // Keep rack centered
        // potentially add paddingLeft if we want to shift it right, but let's try just overlay first
    },

    // Actions
    actionBar: {
        padding: 16,
        gap: 16,
        paddingBottom: 40,
    },
    togglesRow: {
        flexDirection: 'row',
        gap: 16,
    },
    toggleButton: {
        flex: 1,
        paddingVertical: 16,
        borderRadius: 12,
        borderWidth: 2,
        alignItems: 'center',
        justifyContent: 'center',
    },
    toggleInactive: {
        backgroundColor: '#1f2937',
        borderColor: '#374151',
    },
    toggleFoulActive: {
        backgroundColor: 'rgba(127, 29, 29, 0.4)',
        borderColor: '#ef4444',
    },
    toggleSafetyActive: {
        backgroundColor: 'rgba(30, 58, 138, 0.4)',
        borderColor: '#3b82f6',
    },
    toggleLabel: {
        color: '#9ca3af',
        fontSize: 10,
        fontWeight: 'bold',
        textTransform: 'uppercase',
    },
    toggleValue: {
        fontSize: 24,
        fontWeight: '900',
    },
    textRed: { color: '#ef4444' },
    safetyIndicator: {
        width: 32,
        height: 32,
        borderRadius: 16,
        marginTop: 4,
    },
    bgBlue: { backgroundColor: '#3b82f6' },
    bgGray: { backgroundColor: '#374151' },
    actionsRow: {
        flexDirection: 'row',
        gap: 16,
    },
    undoButton: {
        width: 80,
        backgroundColor: '#374151',
        borderRadius: 12,
        alignItems: 'center',
        justifyContent: 'center',
    },
    undoText: {
        color: 'white',
        fontWeight: 'bold',
        fontSize: 10,
        textTransform: 'uppercase',
    },
    acceptButton: {
        flex: 1,
        backgroundColor: 'white',
        borderRadius: 12,
        paddingVertical: 20,
        alignItems: 'center',
        justifyContent: 'center',
        elevation: 4,
    },
    reRackActionBtn: {
        backgroundColor: '#fbbf24', // Amber 400 for Re-Rack/Continue
    },
    acceptText: {
        color: 'black',
        fontWeight: '900',
        fontSize: 30,
        letterSpacing: 2,
        textTransform: 'uppercase',
    },
    acceptSubText: {
        color: '#6b7280',
        fontSize: 10,
        fontWeight: 'bold',
        textTransform: 'uppercase',
        marginTop: 4,
    },
    // Modal
    modalOverlay: {
        flex: 1,
        backgroundColor: 'rgba(0,0,0,0.8)',
        justifyContent: 'flex-end',
    },
    modalContent: {
        backgroundColor: '#1e293b',
        height: '75%',
        borderTopLeftRadius: 24,
        borderTopRightRadius: 24,
        padding: 24,
    },
    modalHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 24,
    },
    modalTitle: {
        color: 'white',
        fontSize: 24,
        fontWeight: 'bold',
    },
    closeButton: {
        backgroundColor: '#1f2937',
        paddingHorizontal: 16,
        paddingVertical: 8,
        borderRadius: 8,
    },
    closeButtonText: {
        color: 'white',
        fontWeight: 'bold',
    },
    statsHeader: {
        flexDirection: 'row',
        backgroundColor: '#0f172a',
        padding: 16,
        borderRadius: 12,
        marginBottom: 16,
        justifyContent: 'space-around',
    },
    statBox: {
        alignItems: 'center',
    },
    statLabel: {
        color: '#9ca3af',
        fontSize: 12, // Was 10
        fontWeight: 'bold',
        textTransform: 'uppercase',
    },
    statValue: {
        color: 'white',
        fontSize: 24, // Was 20
        fontFamily: 'monospace',
    },
    statValueHighlight: {
        color: '#22c55e',
        fontSize: 24, // Was 20
        fontFamily: 'monospace',
    },
    historyItem: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingVertical: 16, // More padding
        borderBottomWidth: 1,
        borderBottomColor: '#1f2937',
    },
    historyInning: {
        color: '#9ca3af',
        fontSize: 16, // Bigger
    },
    historyDetails: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
    },
    tagSafety: {
        color: '#60a5fa',
        fontSize: 12, // Was 10
        fontWeight: 'bold',
    },
    tagFoul: {
        color: '#ef4444',
        fontSize: 12, // Was 10
        fontWeight: 'bold',
    },
    historyPoints: {
        color: 'white',
        fontWeight: 'bold',
        fontSize: 22, // Was 18
    },
    historyTotal: {
        color: '#9ca3af',
        fontSize: 14, // Was 10
        fontFamily: 'monospace',
    },
});
