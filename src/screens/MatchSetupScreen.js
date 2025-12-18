import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, ScrollView, Switch, StyleSheet } from 'react-native';
import Svg, { Path } from 'react-native-svg';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useGame } from '../store/GameContext';
import { t } from '../utils/i18n';

// --- Components ---

const SmartPlayerSelect = ({ label, value, onChange, onSelect, onCreate, players = [] }) => {
    // Safety check for players array
    const safePlayers = Array.isArray(players) ? players : [];

    // Filter players based on value
    const suggestions = (value.length > 0)
        ? safePlayers.filter(p => p.name && p.name.toLowerCase().includes(value.toLowerCase()))
        : [];

    const exactMatch = safePlayers.find(p => p.name && p.name.toLowerCase() === value.toLowerCase());
    const isKnown = !!exactMatch;

    return (
        <View style={styles.inputContainer}>
            <Text style={styles.label}>
                {label}
            </Text>
            <View style={styles.inputRow}>
                <TextInput
                    style={styles.textInput}
                    placeholder="Name..."
                    placeholderTextColor="#666"
                    value={value}
                    onChangeText={onChange}
                    autoCapitalize="words"
                />

                <TouchableOpacity
                    onPress={() => isKnown ? onSelect(exactMatch) : onCreate(value)}
                    style={[
                        styles.actionButton,
                        {
                            backgroundColor: isKnown ? '#22c55e' : '#2563eb', // Green for Known/Selected, Blue for Create
                            opacity: value.length === 0 ? 0.5 : 1
                        }
                    ]}
                    disabled={value.length === 0}
                >
                    {isKnown ? (
                        // Checkmark Icon
                        <View style={{ width: 24, height: 24, alignItems: 'center', justifyContent: 'center' }}>
                            {/* Simple SVG Checkmark */}
                            <Svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                                <Path d="M20 6L9 17l-5-5" />
                            </Svg>
                        </View>
                    ) : (
                        <Text style={styles.actionButtonText}>
                            CREATE
                        </Text>
                    )}
                </TouchableOpacity>
            </View>

            {/* Suggestions Inline List */}
            {suggestions.length > 0 && !isKnown && (
                <View style={styles.suggestionsContainer}>
                    {suggestions.map(p => (
                        <TouchableOpacity
                            key={p.id}
                            onPress={() => {
                                console.log("Suggestion Selected:", p.name);
                                onSelect(p);
                            }}
                            style={styles.suggestionItem}
                        >
                            <Text style={styles.suggestionText}>{p.name}</Text>
                        </TouchableOpacity>
                    ))}
                </View>
            )}

            <Text style={styles.helperText}>
                {isKnown ? "Player found in database" : (value.length > 0 ? "New player will be created" : "")}
            </Text>
        </View>
    );
};

export default function MatchSetupScreen({ navigation }) {
    const { players, addPlayer, startMatch } = useGame();

    // Local State for Setup
    const [p1Name, setP1Name] = useState('');
    const [p2Name, setP2Name] = useState('');
    const [p1Profile, setP1Profile] = useState(null); // Selected Object
    const [p2Profile, setP2Profile] = useState(null);

    const [isHandicap, setIsHandicap] = useState(false);
    const [goal, setGoal] = useState('100');
    const [p1Spot, setP1Spot] = useState('0');
    const [p2Spot, setP2Spot] = useState('0');

    // Handlers
    const handleP1Select = (profile) => {
        console.log("P1 Selected:", profile);
        setP1Profile(profile);
        setP1Name(profile.name);
    };

    const handleP1Create = async (name) => {
        try {
            console.log("Creating P1:", name);
            const newPlayer = await addPlayer(name);
            if (newPlayer) handleP1Select(newPlayer);
        } catch (e) {
            console.error("Error creating P1:", e);
        }
    };

    const handleP2Select = (profile) => {
        console.log("P2 Selected:", profile);
        setP2Profile(profile);
        setP2Name(profile.name);
    };

    const handleP2Create = async (name) => {
        try {
            console.log("Creating P2:", name);
            const newPlayer = await addPlayer(name);
            if (newPlayer) handleP2Select(newPlayer);
        } catch (e) {
            console.error("Error creating P2:", e);
        }
    };

    const handleStart = () => {
        if (!p1Profile || !p2Profile) return;

        const settings = {
            goalP1: parseInt(goal),
            goalP2: parseInt(goal),
            isHandicap,
            p1Spot: isHandicap ? parseInt(p1Spot) || 0 : 0,
            p2Spot: isHandicap ? parseInt(p2Spot) || 0 : 0
        };

        startMatch(p1Profile, p2Profile, settings);
        navigation.navigate('Match');
    };

    const isReady = p1Profile && p2Profile;

    return (
        <SafeAreaView style={styles.safeArea} edges={['bottom', 'left', 'right']}>
            <ScrollView style={styles.container} contentContainerStyle={{ paddingBottom: 40 }} keyboardShouldPersistTaps="handled">
                <Text style={styles.headerTitle}>Match Setup</Text>

                {/* Player Selection */}
                <View style={styles.section}>
                    <Text style={styles.sectionTitle}>Contenders</Text>

                    <SmartPlayerSelect
                        label="Player 1"
                        value={p1Name}
                        players={players}
                        onChange={(txt) => { setP1Name(txt); setP1Profile(null); }}
                        onSelect={handleP1Select}
                        onCreate={handleP1Create}
                    />

                    <SmartPlayerSelect
                        label="Player 2"
                        value={p2Name}
                        players={players}
                        onChange={(txt) => { setP2Name(txt); setP2Profile(null); }}
                        onSelect={handleP2Select}
                        onCreate={handleP2Create}
                    />
                </View>

                {/* Game Config */}
                <View style={styles.section}>
                    <Text style={styles.sectionTitle}>Conditions</Text>

                    <View style={styles.row}>
                        <Text style={styles.rowLabel}>Race to Points</Text>
                        <TextInput
                            style={styles.numberInput}
                            keyboardType="numeric"
                            value={goal}
                            onChangeText={setGoal}
                        />
                    </View>

                    <View style={styles.row}>
                        <Text style={styles.rowLabelSecondary}>Handicap Mode</Text>
                        <Switch
                            value={isHandicap}
                            onValueChange={setIsHandicap}
                            trackColor={{ false: "#333", true: "#059669" }}
                            thumbColor="#fff"
                        />
                    </View>
                    {/* Handicap Inputs */}
                    {isHandicap && (
                        <View style={styles.handicapContainer}>
                            <View style={styles.handicapRow}>
                                <Text style={styles.handicapLabel}>P1 Spot</Text>
                                <TextInput
                                    style={styles.handicapInput}
                                    keyboardType="numeric"
                                    placeholder="0"
                                    placeholderTextColor="#666"
                                    value={p1Spot}
                                    onChangeText={setP1Spot}
                                />
                            </View>
                            <View style={styles.handicapRow}>
                                <Text style={styles.handicapLabel}>P2 Spot</Text>
                                <TextInput
                                    style={styles.handicapInput}
                                    keyboardType="numeric"
                                    placeholder="0"
                                    placeholderTextColor="#666"
                                    value={p2Spot}
                                    onChangeText={setP2Spot}
                                />
                            </View>
                        </View>
                    )}
                </View>

                {/* Start Button */}
                <TouchableOpacity
                    style={[
                        styles.startButton,
                        isReady ? styles.startButtonActive : styles.startButtonDisabled
                    ]}
                    onPress={handleStart}
                    disabled={!isReady}
                >
                    <Text style={styles.startButtonText}>
                        {isReady ? "Start Match" : (!p1Profile ? "Select Player 1" : "Select Player 2")}
                    </Text>
                </TouchableOpacity>

            </ScrollView>
        </SafeAreaView>
    );
}

const styles = StyleSheet.create({
    safeArea: {
        flex: 1,
        backgroundColor: '#0f172a',
    },
    container: {
        flex: 1,
        padding: 24,
    },
    headerTitle: {
        color: 'white',
        fontSize: 30,
        fontWeight: 'bold',
        marginBottom: 32,
        marginTop: 16,
        textAlign: 'center',
    },
    section: {
        backgroundColor: '#1e293b',
        padding: 16,
        borderRadius: 16,
        borderWidth: 1,
        borderColor: '#1f2937',
        marginBottom: 24,
    },
    sectionTitle: {
        color: '#9ca3af',
        fontSize: 14,
        fontWeight: 'bold',
        textTransform: 'uppercase',
        marginBottom: 16,
        letterSpacing: 2,
        borderBottomWidth: 1,
        borderBottomColor: '#1f2937',
        paddingBottom: 8,
    },
    // SmartPlayerSelect Styles
    inputContainer: {
        marginBottom: 24,
    },
    label: {
        color: '#9ca3af',
        fontSize: 12,
        fontWeight: 'bold',
        textTransform: 'uppercase',
        marginBottom: 8,
        marginLeft: 4,
    },
    inputRow: {
        flexDirection: 'row',
        marginBottom: 8,
    },
    textInput: {
        flex: 1,
        backgroundColor: '#1e293b',
        color: 'white',
        padding: 16,
        borderTopLeftRadius: 12,
        borderBottomLeftRadius: 12,
        borderColor: '#374151',
        borderWidth: 1,
        fontSize: 18,
    },
    actionButton: {
        paddingHorizontal: 24,
        justifyContent: 'center',
        borderTopRightRadius: 12,
        borderBottomRightRadius: 12,
        borderLeftWidth: 1,
        borderLeftColor: '#111827',
    },
    actionButtonText: {
        color: 'white',
        fontWeight: 'bold',
        textTransform: 'uppercase',
        letterSpacing: 1,
    },
    suggestionsContainer: {
        backgroundColor: '#1f2937',
        borderRadius: 12,
        borderWidth: 1,
        borderColor: '#374151',
        marginBottom: 8,
        overflow: 'hidden',
    },
    suggestionItem: {
        padding: 12,
        borderBottomWidth: 1,
        borderBottomColor: 'rgba(55, 65, 81, 0.5)',
    },
    suggestionText: {
        color: '#d1d5db',
        fontWeight: 'bold',
    },
    helperText: {
        fontSize: 12,
        textAlign: 'right',
        marginTop: 4,
        color: '#6b7280',
        minHeight: 16,
    },
    // Config Styles
    row: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 24,
    },
    rowLabel: {
        color: 'white',
        fontWeight: 'bold',
        fontSize: 18,
    },
    rowLabelSecondary: {
        color: '#9ca3af',
    },
    numberInput: {
        backgroundColor: '#0f172a',
        color: 'white',
        fontWeight: 'bold',
        fontSize: 20,
        paddingHorizontal: 16,
        paddingVertical: 8,
        borderRadius: 8,
        borderWidth: 1,
        borderColor: '#374151',
        textAlign: 'center',
        width: 100,
    },
    // Handicap Styles
    handicapContainer: {
        marginTop: 16,
        borderTopWidth: 1,
        borderTopColor: '#374151',
        paddingTop: 16,
        flexDirection: 'row',
        justifyContent: 'space-between',
    },
    handicapRow: {
        alignItems: 'center',
        width: '45%',
    },
    handicapLabel: {
        color: '#9ca3af',
        fontSize: 12,
        fontWeight: 'bold',
        marginBottom: 8,
        textTransform: 'uppercase',
    },
    handicapInput: {
        backgroundColor: '#0f172a',
        color: 'white',
        fontWeight: 'bold',
        fontSize: 18,
        padding: 12,
        borderRadius: 8,
        borderWidth: 1,
        borderColor: '#374151',
        textAlign: 'center',
        width: '100%',
    },
    startButton: {
        padding: 24,
        borderRadius: 16,
        alignItems: 'center',
        marginBottom: 40,
    },
    startButtonActive: {
        backgroundColor: '#22c55e',
        elevation: 4,
        shadowColor: '#14532d',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.5,
        shadowRadius: 8,
    },
    startButtonDisabled: {
        backgroundColor: '#1f2937',
        opacity: 0.5,
    },
    startButtonText: {
        color: '#0f172a',
        fontSize: 20,
        fontWeight: '900',
        textTransform: 'uppercase',
        letterSpacing: 2,
    },
});
