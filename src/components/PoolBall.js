import React from 'react';
import Svg, { Circle, Text as SvgText, Rect, Defs, RadialGradient, Stop, Ellipse } from 'react-native-svg';
import { View } from 'react-native';

// High-Fidelity TV Colors (Base + Shadow)
const BALL_PALETTE = {
    1: { base: '#FFD700', shadow: '#DAA520' }, // Yellow
    2: { base: '#0288D1', shadow: '#01579B' }, // Blue
    3: { base: '#FF3333', shadow: '#CC0000' }, // Red (Requested)
    4: { base: '#AB47BC', shadow: '#7B1FA2' }, // Purple
    5: { base: '#FF9800', shadow: '#E65100' }, // Orange
    6: { base: '#4CAF50', shadow: '#1B5E20' }, // Green
    7: { base: '#8D6E63', shadow: '#4E342E' }, // Brown
    8: { base: '#222222', shadow: '#000000' }, // Black (Requested)
    0: { base: '#FFFFFF', shadow: '#CFD8DC' }, // Cue Ball (White)
};

export default function PoolBall({ number, size = 40, isPotted = false }) {
    const r = size / 2;
    // Determine Base/Shadow Colors
    // Stripes (9-15) map to 1-7. Solids (1-8). 
    const isStripe = number > 8 && number < 16;
    const isCue = number === 0;
    const baseNum = number > 8 ? number - 8 : number;

    // Default fallback
    const palette = BALL_PALETTE[baseNum] || BALL_PALETTE[8];

    // For Stripes: The "Body" is White-ish, and the "Stripe" is colored.
    // For Solids: The "Body" is colored.

    // 3D Logic:
    // We define a unique gradient ID for this ball instance to prevent clashes if multiple balls render? 
    // Actually, in RN SVG, IDs are global. We should unique-ify if possible or just stick to a few shared defs if colors match.
    // To allow unique colors per ball, we can inject colors directly or use unique IDs. 
    // Given the small set (15), unique IDs like `grad-${number}` work best.

    const gradId = `ball-grad-${number}`;
    const highlightId = `specular-${number}`;

    const mainBase = isStripe ? '#FFFFFF' : palette.base;
    const mainShadow = isStripe ? '#CFD8DC' : palette.shadow;

    return (
        <View style={{ position: 'relative' }}>
            <Svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
                <Defs>
                    {/* 1. Body Gradient: Off-center radial for dimensionality */}
                    <RadialGradient id={gradId} cx="35%" cy="35%" rx="60%" ry="60%" fx="25%" fy="25%">
                        <Stop offset="0%" stopColor={mainBase} stopOpacity="1" />
                        <Stop offset="100%" stopColor={mainShadow} stopOpacity="1" />
                    </RadialGradient>

                    {/* 2. Specular Highlight: Soft white at top-left */}
                    <RadialGradient id={highlightId} cx="50%" cy="50%" rx="50%" ry="50%" fx="50%" fy="50%">
                        <Stop offset="0%" stopColor="white" stopOpacity="0.7" />
                        <Stop offset="100%" stopColor="white" stopOpacity="0" />
                    </RadialGradient>

                    {/* 3. Stripe Gradient (Vertical depth for the band) */}
                    <RadialGradient id={`stripe-${number}`} cx="50%" cy="50%" rx="60%" ry="60%" fx="50%" fy="50%">
                        <Stop offset="0%" stopColor={palette.base} stopOpacity="1" />
                        <Stop offset="90%" stopColor={palette.shadow} stopOpacity="1" />
                    </RadialGradient>
                </Defs>

                {/* --- Base Sphere --- */}
                <Circle cx={r} cy={r} r={r} fill={`url(#${gradId})`} />

                {/* --- Stripe Band (if applicable) --- */}
                {isStripe && (
                    <Rect
                        x="0"
                        y={size * 0.2}
                        width={size}
                        height={size * 0.6}
                        fill={`url(#stripe-${number})`}
                        // Mask it to the circle shape simply by using clipPath in complex apps, 
                        // but here we can just draw another circle with clipPath or use local clipping.
                        // Simple 2D approach: The ball is a circle. We can wrap the whole Group in a ClipPath of the ball.
                        clipPath={`url(#clip-${number})`}
                    />
                )}

                {/* Stripe Clip Definition */}
                {isStripe && (
                    <Defs>
                        <Circle id={`clip-${number}`} cx={r} cy={r} r={r} />
                    </Defs>
                )}

                {/* --- Badge (Number Circle) --- */}
                {/* Slightly off-white #F0F0F0, maybe small drop shadow or border */}
                <Circle cx={r} cy={r} r={size * 0.4} fill="#F0F0F0" />

                {/* --- Number --- */}
                <SvgText
                    x={r}
                    y={r + (size * 0.14)}
                    fill="#000000"
                    fontSize={size * 0.5}
                    fontWeight="900"
                    textAnchor="middle"
                    fontFamily="sans-serif" // Cleaner look
                >
                    {number}
                </SvgText>

                {/* --- Specular Highlight (The "Plastic" Gloss) --- */}
                {/* Ellipse at 10-11 o'clock position (Top Left) */}
                {/* This simulates the light source reflecting off the sphere */}
                <Ellipse
                    cx={size * 0.3}
                    cy={size * 0.3}
                    rx={size * 0.25}
                    ry={size * 0.18}
                    fill={`url(#${highlightId})`}
                    transform={`rotate(-45, ${size * 0.3}, ${size * 0.3})`}
                />
            </Svg>

            {/* Interaction: Dark overlay when potted (Active Inactive state) */}
            {isPotted && (
                <View style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    width: size,
                    height: size,
                    borderRadius: size / 2,
                    backgroundColor: 'rgba(0,0,0,0.6)', // "Dunkel/Inaktiv" overlay
                }} />
            )}
        </View>
    );
}
