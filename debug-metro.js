console.log('Attempting to require metro.config.js...');
try {
    const config = require('./metro.config.js');
    console.log('SUCCESS: config loaded');
} catch (e) {
    console.error('ERROR: Failed to load config');
    console.error(e);
    // Also try to require the dependencies individually to see which one fails
    try {
        require('expo/metro-config');
        console.log('SUCCESS: expo/metro-config loaded');
    } catch (e2) {
        console.error('ERROR: Failed to load expo/metro-config', e2.message);
    }

    try {
        require('nativewind/metro');
        console.log('SUCCESS: nativewind/metro loaded');
    } catch (e3) {
        console.error('ERROR: Failed to load nativewind/metro', e3.message);
    }
}
