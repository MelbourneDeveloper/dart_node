// Jest setup for React Testing Library
require('@testing-library/jest-dom');

// Make React available globally (as dart2js expects)
global.React = require('react');
global.ReactDOM = require('react-dom');

// Make userEvent available with default export
global.userEvent = require('@testing-library/user-event').default;
