const { calculate141Turn } = require('./gameLogic');

const assert = (condition, msg) => {
    if (!condition) {
        console.error('FAIL:', msg);
        process.exit(1);
    } else {
        console.log('PASS:', msg);
    }
};

try {
    console.log('Running Manual Verification Tests...');

    // Test 1: Run
    let player = { consecutiveFouls: 0 };
    let r = calculate141Turn(player, 5, 'miss');
    assert(r.scoreChange === 5, 'Standard Run of 5');
    assert(r.newConsecutiveFouls === 0, 'Fouls Reset on points');

    // Test 2: Standard Foul
    player = { consecutiveFouls: 0 };
    r = calculate141Turn(player, 0, 'foul');
    assert(r.scoreChange === -1, 'Standard Foul (-1)');
    assert(r.newConsecutiveFouls === 1, 'Foul Count 1');

    // Test 3: Break Foul
    player = { consecutiveFouls: 0 };
    r = calculate141Turn(player, 0, 'breaking_foul');
    assert(r.scoreChange === -2, 'Breaking Foul (-2)');
    assert(r.newConsecutiveFouls === 1, 'Foul Count 1');

    // Test 4: 3-Foul Penalty
    player = { consecutiveFouls: 2 };
    r = calculate141Turn(player, 0, 'foul');
    // -1 (foul) - 15 (penalty) = -16
    assert(r.scoreChange === -16, '3-Foul Penalty Total (-16)');
    assert(r.penaltyApplied === 16, 'Penalty Value logs correctly');
    assert(r.newConsecutiveFouls === 0, 'Fouls Reset after penalty');

    // Test 5: Safety (no points)
    player = { consecutiveFouls: 1 };
    r = calculate141Turn(player, 0, 'safety');
    assert(r.scoreChange === 0, 'Safety 0 points');
    assert(r.newConsecutiveFouls === 1, 'Fouls persist on Safety');

    console.log('All tests passed successfully.');
} catch (e) {
    console.error('Exception during test:', e);
    process.exit(1);
}
