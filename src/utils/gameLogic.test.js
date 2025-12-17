import { calculate141Turn } from './gameLogic';

describe('14.1 Score Calculation', () => {
    test('Standard run calculation', () => {
        const player = { consecutiveFouls: 0 };
        const result = calculate141Turn(player, 5, 'miss'); // Run of 5 then miss
        expect(result.scoreChange).toBe(5);
        expect(result.penaltyApplied).toBe(0);
        expect(result.newConsecutiveFouls).toBe(0);
    });

    test('Standard foul (-1)', () => {
        const player = { consecutiveFouls: 0 };
        const result = calculate141Turn(player, 0, 'foul');
        expect(result.scoreChange).toBe(-1);
        expect(result.penaltyApplied).toBe(1);
        expect(result.newConsecutiveFouls).toBe(1);
    });

    test('Breaking foul (-2)', () => {
        const player = { consecutiveFouls: 0 };
        const result = calculate141Turn(player, 0, 'breaking_foul');
        expect(result.scoreChange).toBe(-2);
        expect(result.penaltyApplied).toBe(2);
        expect(result.newConsecutiveFouls).toBe(1);
    });

    test('3 Consecutive Fouls Penalty (-15)', () => {
        const player = { consecutiveFouls: 2 };
        // 3rd foul
        const result = calculate141Turn(player, 0, 'foul');
        // Penalty: 1 (standard) + 15 (serious) = 16
        expect(result.penaltyApplied).toBe(16);
        expect(result.scoreChange).toBe(-16);
        expect(result.newConsecutiveFouls).toBe(0);
    });

    test('Safety with no points (fouls remain)', () => {
        const player = { consecutiveFouls: 1 };
        const result = calculate141Turn(player, 0, 'safety');
        expect(result.scoreChange).toBe(0);
        expect(result.newConsecutiveFouls).toBe(1); // Should not reset
    });

    test('Safety with points (fouls reset)', () => {
        const player = { consecutiveFouls: 1 };
        const result = calculate141Turn(player, 2, 'safety');
        expect(result.scoreChange).toBe(2);
        expect(result.newConsecutiveFouls).toBe(0); // Should reset
    });
});
