// Heavy diagnostics for debugging
console.log('=== INDEX.JS STARTING ===');
console.log('=== Checking globals ===');
console.log('typeof global:', typeof global);
console.log('typeof require:', typeof require);

// Import React and React Native FIRST
console.log('=== Importing React ===');
const React = require('react');
console.log('React loaded:', !!React);
console.log('React.createElement:', typeof React.createElement);

console.log('=== Importing React Native ===');
const ReactNative = require('react-native');
console.log('ReactNative loaded:', !!ReactNative);
console.log('AppRegistry:', typeof ReactNative.AppRegistry);
console.log('View:', typeof ReactNative.View);
console.log('Text:', typeof ReactNative.Text);

// Make React and ReactNative available globally for Dart
// Dart's @JS() looks at 'self' which the node preamble sets up
console.log('=== Setting up globals for Dart ===');
global.React = React;
global.ReactNative = ReactNative;
global.reactNative = ReactNative;

// Also set on self/this for Dart JS interop
if (typeof self !== 'undefined') {
  console.log('Setting on self...');
  self.React = React;
  self.ReactNative = ReactNative;
  self.reactNative = ReactNative;
}
// For React Native, also set on globalThis
if (typeof globalThis !== 'undefined') {
  console.log('Setting on globalThis...');
  globalThis.React = React;
  globalThis.ReactNative = ReactNative;
  globalThis.reactNative = ReactNative;
}

console.log('global.React set:', !!global.React);
console.log('global.reactNative set:', !!global.reactNative);
console.log('Checking self.React:', typeof self !== 'undefined' ? !!self.React : 'self undefined');
console.log('Checking globalThis.React:', typeof globalThis !== 'undefined' ? !!globalThis.React : 'globalThis undefined');

// Load compiled Dart app
console.log('=== Loading Dart app.js ===');
try {
  require('../build/app.js');
  console.log('=== APP.JS LOADED SUCCESSFULLY ===');
} catch (e) {
  console.error('=== ERROR LOADING APP.JS ===');
  console.error('Error:', e.message);
  console.error('Stack:', e.stack);

  // Register a fallback error component
  console.log('=== Registering fallback error component ===');
  const { AppRegistry, View, Text } = ReactNative;

  const ErrorApp = () => {
    return React.createElement(
      View,
      { style: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: 'red' } },
      React.createElement(
        Text,
        { style: { color: 'white', fontSize: 18, textAlign: 'center', padding: 20 } },
        'Error loading Dart app: ' + e.message
      )
    );
  };

  AppRegistry.registerComponent('DartMobile', () => ErrorApp);
}

console.log('=== INDEX.JS COMPLETE ===');
