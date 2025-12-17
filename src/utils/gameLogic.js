const calculate141Turn = (player, currentPoints, type) => {
    // Returns { scoreChange, newConsecutiveFouls, penaltyApplied }
    let points = currentPoints;
    let penalty = 0;
    let consecutiveFouls = player.consecutiveFouls || 0;

    if (type === 'foul' || type === 'breaking_foul') {
        penalty = (type === 'breaking_foul') ? 2 : 1;
        consecutiveFouls += 1;
        // Check 3-foul penalty
        if (consecutiveFouls >= 3) {
            penalty += 15;
            consecutiveFouls = 0; // Reset after penalty
        }
    } else {
        // Safety or Miss
        // Any legal shot (pocketing a ball) resets consecutive fouls.
        if (points > 0) {
            consecutiveFouls = 0;
        }
        // If safety with 0 points, fouls remain (do not increment, do not reset).
    }

    return {
        scoreChange: points - penalty,
        newConsecutiveFouls: consecutiveFouls,
        penaltyApplied: penalty
    };
};

module.exports = { calculate141Turn };
