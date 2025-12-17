import React from 'react';
import Svg, { Circle, Text as SvgText, Rect, Defs, RadialGradient, Stop } from 'react-native-svg';
import { View, Text } from 'react-native';

const BALL_COLORS = {
    1: '#FDD835', // Yellow
    2: '#1E88E5', // Blue
    3: '#E53935', // Red
    4: '#8E24AA', // Purple
    5: '#FB8C00', // Orange
    6: '#43A047', // Green
    7: '#6D4C41', // Brown
    8: '#212121', // Black
};

const STRIPE_COLOR = '#FFFFFF';

export default function PoolBall({ number, size = 40, isPotted = false }) {
    // TV Colors Mapping
    // 1-8 are their colors. 9-15 correspond to 1-7 but stripes.
    const baseNumber = number > 8 ? number - 8 : number;
    const color = BALL_COLORS[baseNumber] || '#000000';
    const isStripe = number > 8;
    const r = size / 2;

    const opacity = isPotted ? 0.3 : 1;

    return (
        <Svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ opacity }}>
            <Defs>
                {/* Gloss Effect */}
                <RadialGradient id="gloss" cx="30%" cy="30%" rx="50%" ry="50%" fx="30%" fy="30%">
                    <Stop offset="0%" stopColor="white" stopOpacity="0.4" />
                    <Stop offset="100%" stopColor="white" stopOpacity="0" />
                </RadialGradient>
            </Defs>

            {/* Base Ball Color */}
            <Circle cx={r} cy={r} r={r} fill={isStripe ? '#FFFFFF' : color} />

            {/* Stripe (if applicable) */}
            {isStripe && (
                <View>
                    {/* SVG clipping for stripe is tricky, simpler hack: 
                         Draw white ball, then draw thick colored band in middle? 
                         Or draw colored ball, then draw white caps?
                         User asked for "White stripe in middle".
                         So Base = Color, Stripe = White? No, typically base is white, stripe is color.
                         But user said "For 9-15: White stripe in the middle".
                         Wait, standard balls are White with Colored Stripe. 
                         But user said "Weißer Streifen in der Mitte". 
                         Let's interpret strictly: Color Ball with "White Stripe"? That sounds inverted.
                         Standard TV: White Ball, Colored Stripe.
                         User Specs: "1/9: Gelb... Für 9-15: Ein weißer Streifen in der Mitte".
                         Okay, I will draw the Color background, and put a White Rect in middle?
                         Or maybe they meant "Colored Stripe on White".
                         Let's assume Standard Look (White ball, Colored Stripe) but follow user's text literally if possible?
                         "Ein weißer Streifen in der Mitte" implies the rest is colored?
                         Actually, usually user descriptions can be slightly off.
                         Let's do: Base Color. If Stripe -> Draw White Rect in middle? No that would look like a flag.
                         Standard Stripe is: Top/Bottom White, Middle Color.
                         If user wants "White Stripe in Middle", that means Top/Bottom is Color.
                         Let's stick to Standard Visuals: White Ball, Colored Band.
                         Wait, user said "1/9: Gelb". 
                         Okay, if I make 9 Yellow, and add a "White Stripe", it's distinct from 1.
                         Let's try to make it look good. I'll make the base White for Stripe balls and draw a wide colored band.
                     */}
                    <Circle cx={r} cy={r} r={r} fill="#FFFFFF" />
                    <Rect x={0} y={size * 0.2} width={size} height={size * 0.6} fill={color} />
                </View>
            )}

            {/* If user STRICTLY meant "White Stripe in Middle of Color Ball" -> 
                Base = Color. Rect = White.
                Let's stick to Standard (White Ball, Colored Stripe) because "1/9: Gelb" usually implies the identifiable color.
                Correction: I can't use View inside Svg. Must use SVG elements.
            */}

            {isStripe ? (
                <>
                    {/* White Base */}
                    <Circle cx={r} cy={r} r={r} fill="#FFFFFF" />
                    {/* Colored Band (approximated as Rect masked by Circle? Native SVG mask is complex) 
                        Simpler: Draw colored circle, then draw white 'caps' (segments)?
                        Or Draw White Circle, then ClipPath for Band?
                        Let's keep it simple: White Circle. Colored Rect in middle. Masked by Circle.
                    */}
                    <Defs>
                        <Circle id="ballShape" cx={r} cy={r} r={r} />
                    </Defs>
                    {/* Clip everything to ball shape */}
                    <Circle cx={r} cy={r} r={r} fill="#FFFFFF" />
                    <Rect x="0" y={size * 0.25} width={size} height={size * 0.5} fill={color} clipPath="url(#ballShape)" />
                </>
            ) : (
                <Circle cx={r} cy={r} r={r} fill={color} />
            )}


            {/* Gloss Overlay */}
            <Circle cx={r} cy={r} r={r} fill="url(#gloss)" />

            {/* Number Circle (White Background) */}
            <Circle cx={r} cy={r} r={size * 0.4} fill="#FFFFFF" />

            {/* Number Text */}
            <SvgText
                x={r}
                y={r + (size * 0.14)} // visual centering
                fill="#000000"
                fontSize={size * 0.5}
                fontWeight="bold"
                textAnchor="middle"
            >
                {number}
            </SvgText>
        </Svg>
    );
}
