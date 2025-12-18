import React, { useMemo } from 'react';
import { View, Text, ScrollView, Dimensions } from 'react-native';
import { useGame } from '../store/GameContext';
import { LineChart } from 'react-native-chart-kit';
import { Svg, Rect } from 'react-native-svg';

const screenWidth = Dimensions.get('window').width;

const StatRow = ({ label, p1, p2, highlight = false }) => (
    <View className={`flex-row justify-between items-center py-3 px-4 border-b border-gray-800 ${highlight ? 'bg-gray-800/50' : ''}`}>
        <Text className={`font-mono font-bold text-lg ${highlight ? 'text-knthlz-green' : 'text-white'}`}>{p1}</Text>
        <Text className="text-knthlz-dim text-xs font-bold uppercase tracking-widest">{label}</Text>
        <Text className={`font-mono font-bold text-lg ${highlight ? 'text-blue-400' : 'text-white'}`}>{p2}</Text>
    </View>
);

export default function StatisticsScreen() {
    const { inningHistory, player1, player2 } = useGame();

    // Compute Match Stats
    const stats = useMemo(() => {
        let p1Innings = 0, p2Innings = 0;
        let p1HighRun = 0, p2HighRun = 0;

        inningHistory.forEach(turn => {
            const points = turn.points; // Raw points scored (ignoring penalties for High Run?) 
            // Usually High Run = Points scored in one visit.
            // turn.points includes potted balls.
            // turn.penalty is separate.
            // High Run should be just 'points'.

            if (turn.player === 1) {
                p1Innings++;
                if (points > p1HighRun) p1HighRun = points;
            } else {
                p2Innings++;
                if (points > p2HighRun) p2HighRun = points;
            }
        });

        const p1Avg = p1Innings > 0 ? (player1.score / p1Innings).toFixed(2) : "0.00";
        const p2Avg = p2Innings > 0 ? (player2.score / p2Innings).toFixed(2) : "0.00";

        return {
            p1Innings, p2Innings,
            p1HighRun, p2HighRun,
            p1Avg, p2Avg
        };
    }, [inningHistory, player1, player2]);

    // Graph Data
    const chartData = useMemo(() => {
        const p1Scores = [0];
        const p2Scores = [0];
        let p1Total = 0;
        let p2Total = 0;

        // Reconstruct timeline
        [...inningHistory].reverse().forEach(turn => {
            const net = turn.points - turn.penalty;
            if (turn.player === 1) {
                p1Total += net;
                p1Scores.push(p1Total);
                p2Scores.push(p2Total); // Keep sync
            } else {
                p2Total += net;
                p2Scores.push(p2Total);
                p1Scores.push(p1Total);
            }
        });

        // Cap data points for performance if game is long?
        return {
            labels: Array.from({ length: p1Scores.length }, (_, i) => i % 5 === 0 ? i.toString() : ''),
            datasets: [
                {
                    data: p1Scores,
                    color: (opacity = 1) => `rgba(16, 185, 129, ${opacity})`, // Emerald-500
                    strokeWidth: 3
                },
                {
                    data: p2Scores,
                    color: (opacity = 1) => `rgba(59, 130, 246, ${opacity})`, // Blue-500
                    strokeWidth: 3
                }
            ],
            legend: [player1.name, player2.name]
        };
    }, [inningHistory]);

    return (
        <ScrollView className="flex-1 bg-knthlz-dark">
            <View className="p-6 pb-2 border-b border-gray-800 bg-knthlz-surface">
                <Text className="text-white text-2xl font-bold mb-4 text-center">Match Statistics</Text>

                {/* Stats Table */}
                <View className="bg-knthlz-dark rounded-xl border border-gray-800 overflow-hidden">
                    {/* Header Row */}
                    <View className="flex-row justify-between p-3 bg-gray-900">
                        <Text className="text-knthlz-green font-bold text-center w-1/3">{player1.name}</Text>
                        <Text className="text-gray-500 font-bold text-center w-1/3">VS</Text>
                        <Text className="text-blue-400 font-bold text-center w-1/3">{player2.name}</Text>
                    </View>

                    <StatRow label="Score" p1={player1.score} p2={player2.score} highlight />
                    <StatRow label="Innings" p1={stats.p1Innings} p2={stats.p2Innings} />
                    <StatRow label="High Run" p1={stats.p1HighRun} p2={stats.p2HighRun} />
                    <StatRow label="GD (Avg)" p1={stats.p1Avg} p2={stats.p2Avg} />
                </View>
            </View>

            {/* Graph */}
            <View className="p-4 pt-6">
                <Text className="text-knthlz-dim text-xs font-bold uppercase tracking-widest mb-4 ml-2">Score Progression</Text>
                <LineChart
                    data={chartData}
                    width={screenWidth - 32}
                    height={220}
                    chartConfig={{
                        backgroundColor: "#0f172a", // kntlz-dark
                        backgroundGradientFrom: "#0f172a",
                        backgroundGradientTo: "#0f172a",
                        decimalPlaces: 0,
                        color: (opacity = 1) => `rgba(255, 255, 255, ${opacity})`,
                        labelColor: (opacity = 1) => `rgba(148, 163, 184, ${opacity})`, // slate-400
                        propsForDots: { r: "0" }, // Hide dots for cleaner look
                        propsForBackgroundLines: { strokeDasharray: "" } // Solid grid
                    }}
                    bezier
                    style={{ borderRadius: 16 }}
                />
            </View>
        </ScrollView>
    );
}
