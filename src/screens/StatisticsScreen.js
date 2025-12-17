import React, { useMemo } from 'react';
import { View, Text, FlatList, ScrollView, Dimensions } from 'react-native';
import { useGame } from '../store/GameContext';
import { LineChart } from 'react-native-chart-kit';
import { t } from '../utils/i18n';
import { styled } from 'nativewind';

const screenWidth = Dimensions.get('window').width;

const StatBox = ({ label, p1Value, p2Value }) => (
    <View className="flex-row justify-between items-center bg-knthlz-surface p-3 mb-2 rounded border border-gray-800">
        <Text className="text-white font-bold w-16 text-center">{p1Value}</Text>
        <Text className="text-knthlz-dim text-xs uppercase font-bold">{label}</Text>
        <Text className="text-white font-bold w-16 text-center">{p2Value}</Text>
    </View>
);

const InningItem = ({ item, index }) => {
    const isP1 = item.player === 1;
    return (
        <View className="flex-row justify-between items-center bg-knthlz-surface p-3 mb-1 border-b border-gray-800">
            <View className="flex-row items-center w-12">
                <Text className="text-knthlz-dim font-mono text-xs">#{index + 1}</Text>
            </View>

            <View className="flex-1 flex-row items-center justify-center">
                {/* Player Indicator & Points */}
                <Text className={`font-bold text-lg ${isP1 ? 'text-knthlz-green' : 'text-knthlz-dim'}`}>
                    {isP1 ? (item.penalty > 0 ? `-${item.penalty}` : item.points) : ''}
                </Text>
            </View>

            <View className="w-8 items-center"><Text className="text-gray-700">|</Text></View>

            <View className="flex-1 flex-row items-center justify-center">
                <Text className={`font-bold text-lg ${!isP1 ? 'text-knthlz-green' : 'text-knthlz-dim'}`}>
                    {!isP1 ? (item.penalty > 0 ? `-${item.penalty}` : item.points) : ''}
                </Text>
            </View>

            <View className="w-12 items-end">
                <Text className="text-knthlz-dim text-xs">{item.total}</Text>
            </View>
        </View>
    );
};

export default function StatisticsScreen() {
    const { inningHistory, player1, player2 } = useGame();

    // Compute Stats
    const stats = useMemo(() => {
        let p1Innings = 0, p2Innings = 0;
        let p1HighRun = 0, p2HighRun = 0;

        inningHistory.forEach(turn => {
            if (turn.player === 1) {
                p1Innings++;
                if (turn.points > p1HighRun) p1HighRun = turn.points;
            } else {
                p2Innings++;
                if (turn.points > p2HighRun) p2HighRun = turn.points;
            }
        });

        const p1Avg = p1Innings > 0 ? (player1.score / p1Innings).toFixed(1) : "0.0";
        const p2Avg = p2Innings > 0 ? (player2.score / p2Innings).toFixed(1) : "0.0";

        return {
            p1Innings, p2Innings,
            p1HighRun, p2HighRun,
            p1Avg, p2Avg
        };
    }, [inningHistory, player1, player2]);

    // Prepare Chart Data
    // We need cumulative score arrays.
    // inningHistory is reversed (newest first). Reverse it back.
    const chartData = useMemo(() => {
        const p1Scores = [0];
        const p2Scores = [0];
        let p1Total = 0;
        let p2Total = 0;

        // Process chronological order
        [...inningHistory].reverse().forEach(turn => {
            const net = turn.points - turn.penalty;
            if (turn.player === 1) {
                p1Total += net;
                p1Scores.push(p1Total);
                // Push last known for P2 to keep graph aligned? 
                // LineChart usually expects same length or uses index.
                // Let's just push current total for BOTH for every inning? 
                // Or simplified: Just push updates.
                // Better: Push a data point for every inning index.
                p2Scores.push(p2Total);
            } else {
                p2Total += net;
                p2Scores.push(p2Total);
                p1Scores.push(p1Total);
            }
        });

        // Cap data points if too many (e.g. last 20 innings) to prevent overcrowding?
        // For now, show all.
        return {
            labels: Array.from({ length: p1Scores.length }, (_, i) => i % 5 === 0 ? i.toString() : ''), // sparse labels
            datasets: [
                {
                    data: p1Scores,
                    color: (opacity = 1) => `rgba(204, 255, 0, ${opacity})`, // Neon Green
                    strokeWidth: 2
                },
                {
                    data: p2Scores,
                    color: (opacity = 1) => `rgba(0, 122, 255, ${opacity})`, // Blue (P2)
                    strokeWidth: 2
                }
            ],
            legend: [player1.name, player2.name]
        };
    }, [inningHistory]);

    return (
        <ScrollView className="flex-1 bg-knthlz-dark">
            {/* Header Score */}
            <View className="flex-row justify-between items-center p-6 bg-knthlz-surface/50">
                <View className="items-center">
                    <Text className="text-xl font-bold text-knthlz-green">{player1.name}</Text>
                    <Text className="text-4xl font-mono font-bold text-white">{player1.score}</Text>
                </View>
                <View className="items-center px-4">
                    <Text className="text-knthlz-dim font-bold text-xs uppercase">VS</Text>
                </View>
                <View className="items-center">
                    <Text className="text-xl font-bold text-blue-400">{player2.name}</Text>
                    <Text className="text-4xl font-mono font-bold text-white">{player2.score}</Text>
                </View>
            </View>

            {/* Matrix */}
            <View className="p-4">
                <Text className="text-knthlz-dim mb-2 text-xs font-bold uppercase tracking-widest">{t('statistics')}</Text>
                <StatBox label={t('highRun')} p1Value={stats.p1HighRun} p2Value={stats.p2HighRun} />
                <StatBox label={t('avg')} p1Value={stats.p1Avg} p2Value={stats.p2Avg} />
                <StatBox label={t('innings')} p1Value={stats.p1Innings} p2Value={stats.p2Innings} />
            </View>

            {/* Chart */}
            <View className="items-center my-4">
                <Text className="text-knthlz-dim mb-2 text-xs font-bold uppercase tracking-widest text-left w-full pl-4">{t('progression')}</Text>
                <LineChart
                    data={chartData}
                    width={screenWidth - 16}
                    height={220}
                    chartConfig={{
                        backgroundColor: "#1a1a1a",
                        backgroundGradientFrom: "#1a1a1a",
                        backgroundGradientTo: "#1a1a1a",
                        decimalPlaces: 0,
                        color: (opacity = 1) => `rgba(255, 255, 255, ${opacity})`,
                        labelColor: (opacity = 1) => `rgba(136, 136, 136, ${opacity})`,
                        style: {
                            borderRadius: 16
                        },
                        propsForDots: {
                            r: "3",
                            strokeWidth: "1",
                            stroke: "#2b2b2b"
                        }
                    }}
                    bezier
                    style={{
                        marginVertical: 8,
                        borderRadius: 16
                    }}
                />
            </View>

            {/* History List */}
            <View className="p-4 flex-1">
                <Text className="text-knthlz-dim mb-2 text-xs font-bold uppercase tracking-widest">{t('inningHistory')}</Text>
                {inningHistory.length === 0 ? (
                    <Text className="text-gray-600 text-center italic mt-4">No Data</Text>
                ) : (
                    inningHistory.map((item, index) => (
                        <InningItem key={index} item={item} index={inningHistory.length - 1 - index} />
                    ))
                )}
            </View>

            <View className="h-20" />
        </ScrollView>
    );
}
