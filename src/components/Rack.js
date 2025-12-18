import React from 'react';
import { View, TouchableOpacity } from 'react-native';
import PoolBall from './PoolBall';

export default function Rack({ ballsOnTable, activeBalls, onToggle, is141Mode = false }) {
    // Rack Layout: Triangle
    // 14.1 Mode: Apex ball (Position 0) is EMPTY.
    // We strictly render positions. The BALL NUMBER rendered is derived from index + 1 (or special logic).

    const ballSize = 48;
    const gap = 2;
    const rowHeight = ballSize * 0.86;

    // Coordinates generator
    const getPos = (row, col) => {
        // Center the triangle.
        const xOffset = -(row * (ballSize + gap) / 2);
        const x = xOffset + col * (ballSize + gap);
        const y = row * rowHeight;
        return { x, y };
    };

    // Calculate positions for 5 rows standard triangle
    // 14.1: If is141Mode is true, we SKIP index 0 (Apex).
    // But we still want 14 clickable zones.
    // Actually, "activeBalls" set tracks INDICES. 
    // If we map 0..14 to the triangle positions.
    // 15 positions total in a 5-row triangle.
    // Index 0 is Apex.
    // If is141Mode, index 0 is irrelevant/hidden.

    // Let's render 15 positions.
    // If is141Mode && i === 0 -> Don't render.

    return (
        <View className="items-center justify-center p-4"
            style={{ width: 300, height: 260 }}>

            <View style={{ position: 'relative', width: 250, height: 200, alignItems: 'center' }}>
                {Array.from({ length: 15 }, (_, i) => {
                    // 14.1 Logic: Apex (i=0) is empty/break ball spot.
                    if (is141Mode && i === 0) return null;

                    // Find row/col
                    let r = 0, c = 0, idx = i;
                    if (idx >= 10) { r = 4; c = idx - 10; }
                    else if (idx >= 6) { r = 3; c = idx - 6; }
                    else if (idx >= 3) { r = 2; c = idx - 3; }
                    else if (idx >= 1) { r = 1; c = idx - 1; }
                    else { r = 0; c = 0; }

                    const { x, y } = getPos(r, c);

                    // State: Is this ball active (on table)?
                    // If activeBalls.has(i), it IS on table.
                    // If not, it is potted (ghost).
                    const isPotted = !activeBalls.has(i);

                    // Ball Number mapping
                    // i=0 is 1-ball. i=14 is 15-ball.
                    // In 14.1, the balls in rack are random usually, but for UI we just show numbers.
                    // We can just use i+1.

                    return (
                        <TouchableOpacity
                            key={i}
                            activeOpacity={0.8}
                            onPress={() => onToggle(i)}
                            style={{
                                position: 'absolute',
                                left: 125 + x - ballSize / 2,
                                top: y + 20
                            }}
                        >
                            <PoolBall
                                number={i + 1}
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
