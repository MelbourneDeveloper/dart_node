// Jest setup for React Native Testing Library
require('@testing-library/jest-native/extend-expect');

// Make React and React Native available globally (as dart2js expects)
// dart2js uses init.G which resolves to self || globalThis
const React = require('react');
global.React = React;
globalThis.React = React;

// Mock react-native module structure that Dart code expects
const RN = require('react-native');
global.reactNative = RN;
globalThis.reactNative = RN;

// Mock AppRegistry for tests
global.reactNative.AppRegistry = {
  registerComponent: jest.fn(),
};
