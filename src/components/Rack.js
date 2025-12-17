import React from 'react';
import { View, TouchableOpacity, StyleSheet } from 'react-native';
import PoolBall from './PoolBall';

export default function Rack({ ballsOnTable = 15, activeBalls, onToggle }) {
    // Rack Layout: Triangle
    // Controlled Component: receives 'activeBalls' (Set of indices) from parent.
    // Renders all 15 positions, ghosts those not in 'activeBalls'.

    const ballSize = 38;
    const gap = 2; // tight rack
    const rowHeight = ballSize * 0.85; // hexagonal packing height (sqrt(3)/2)

    // Coordinates generator
    const getPos = (row, col) => {
        // Center the triangle.
        // Row 0: 1 ball (Offset 0)
        // Row 1: 2 balls (Offset -0.5)
        // Row i: i+1 balls. x-offset = - (i * ballSize/2)
        const xOffset = -(row * (ballSize + gap) / 2);
        const x = xOffset + col * (ballSize + gap);
        const y = row * rowHeight;
        return { x, y };
    };

    // Rows structure: [start_index, count]
    const rows = [
        [0, 1],
        [1, 2],
        [3, 3],
        [6, 4],
        [10, 5]
    ];

    // Helper to map linear index (0..14) to ball number (1..15)
    // 8-ball pattern just for fun?
    // 1 (Apex), 8 (Center of 3rd row -> index 4).
    const mapIndexToNumber = (i) => {
        // User requested sorted ascending order (1-15)
        return i + 1;
    };

    return (
        <View className="items-center justify-center p-4 bg-knthlz-dark/50 rounded-xl border border-gray-800"
            style={{ width: 300, height: 260 }}>

            <View style={{ position: 'relative', width: 250, height: 200, alignItems: 'center' }}>
                {/* Render 15 balls, check if they are in activeBalls or should be hidden entirely?
                     Logic: We render all 15 positions.
                     State: 
                     - activeBalls.has(i) -> Visible
                     - !activeBalls.has(i) -> Potted (Ghost)
                     
                     However, if ballsOnTable < 15, some balls conceptually don't exist.
                     (e.g. 14.1 end of rack, only 1 ball left).
                     Parent manages `activeBalls`. If parent wants only 1 ball, set has only 1 index.
                     The other 14 are "Potted" (Ghost).
                     Does user want to see "Empty Ghost Spaces"? Yes, "Muster erkennbar bleibt".
                  */}
                {Array.from({ length: 15 }, (_, i) => {
                    // Find row/col
                    let r = 0, c = 0, idx = i;
                    if (idx >= 10) { r = 4; c = idx - 10; }
                    else if (idx >= 6) { r = 3; c = idx - 6; }
                    else if (idx >= 3) { r = 2; c = idx - 3; }
                    else if (idx >= 1) { r = 1; c = idx - 1; }
                    else { r = 0; c = 0; }

                    const { x, y } = getPos(r, c);

                    const isPotted = !activeBalls.has(i);

                    return (
                        <TouchableOpacity
                            key={i}
                            activeOpacity={0.8}
                            onPress={() => onToggle(i)}
                            style={{
                                position: 'absolute',
                                left: 125 + x - ballSize / 2, // 125 is half of container width 250
                                top: y + 20
                            }}
                        >
                            <PoolBall
                                number={mapIndexToNumber(i)}
                                size={ballSize}
                                isPotted={isPotted}
                            />
                        </TouchableOpacity>
                    );
                })}
            </View>
        </View>
    );
}
