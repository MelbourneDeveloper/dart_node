"use strict";
/**
 * Extension Activation Tests
 * Verifies the extension activates correctly and exposes the test API.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const assert = __importStar(require("assert"));
const vscode = __importStar(require("vscode"));
const test_helpers_1 = require("../test-helpers");
suite('Extension Activation', () => {
    suiteSetup(async () => {
        await (0, test_helpers_1.waitForExtensionActivation)();
    });
    test('Extension is present and can be activated', async () => {
        const extension = vscode.extensions.getExtension('Nimblesite.too-many-cooks');
        assert.ok(extension, 'Extension should be present');
        assert.ok(extension.isActive, 'Extension should be active');
    });
    test('Extension exports TestAPI', () => {
        const api = (0, test_helpers_1.getTestAPI)();
        assert.ok(api, 'TestAPI should be available');
    });
    test('TestAPI has all required methods', () => {
        const api = (0, test_helpers_1.getTestAPI)();
        // State getters
        assert.ok(typeof api.getAgents === 'function', 'getAgents should be a function');
        assert.ok(typeof api.getLocks === 'function', 'getLocks should be a function');
        assert.ok(typeof api.getMessages === 'function', 'getMessages should be a function');
        assert.ok(typeof api.getPlans === 'function', 'getPlans should be a function');
        assert.ok(typeof api.getConnectionStatus === 'function', 'getConnectionStatus should be a function');
        // Computed getters
        assert.ok(typeof api.getAgentCount === 'function', 'getAgentCount should be a function');
        assert.ok(typeof api.getLockCount === 'function', 'getLockCount should be a function');
        assert.ok(typeof api.getMessageCount === 'function', 'getMessageCount should be a function');
        assert.ok(typeof api.getUnreadMessageCount === 'function', 'getUnreadMessageCount should be a function');
        assert.ok(typeof api.getAgentDetails === 'function', 'getAgentDetails should be a function');
        // Store actions
        assert.ok(typeof api.connect === 'function', 'connect should be a function');
        assert.ok(typeof api.disconnect === 'function', 'disconnect should be a function');
        assert.ok(typeof api.refreshStatus === 'function', 'refreshStatus should be a function');
        assert.ok(typeof api.isConnected === 'function', 'isConnected should be a function');
    });
    test('Initial state is disconnected', () => {
        const api = (0, test_helpers_1.getTestAPI)();
        assert.strictEqual(api.getConnectionStatus(), 'disconnected');
        assert.strictEqual(api.isConnected(), false);
    });
    test('Initial state has empty arrays', () => {
        const api = (0, test_helpers_1.getTestAPI)();
        assert.deepStrictEqual(api.getAgents(), []);
        assert.deepStrictEqual(api.getLocks(), []);
        assert.deepStrictEqual(api.getMessages(), []);
        assert.deepStrictEqual(api.getPlans(), []);
    });
    test('Initial computed values are zero', () => {
        const api = (0, test_helpers_1.getTestAPI)();
        assert.strictEqual(api.getAgentCount(), 0);
        assert.strictEqual(api.getLockCount(), 0);
        assert.strictEqual(api.getMessageCount(), 0);
        assert.strictEqual(api.getUnreadMessageCount(), 0);
    });
    test('Extension logs activation messages', () => {
        const api = (0, test_helpers_1.getTestAPI)();
        const logs = api.getLogMessages();
        // MUST have log messages - extension MUST be logging
        assert.ok(logs.length > 0, 'Extension must produce log messages');
        // MUST contain activation message
        const hasActivatingLog = logs.some((msg) => msg.includes('Extension activating'));
        assert.ok(hasActivatingLog, 'Must log "Extension activating..."');
        // MUST contain activated message
        const hasActivatedLog = logs.some((msg) => msg.includes('Extension activated'));
        assert.ok(hasActivatedLog, 'Must log "Extension activated"');
        // MUST contain server path log
        const hasServerPathLog = logs.some((msg) => msg.includes('Server path:'));
        assert.ok(hasServerPathLog, 'Must log server path');
    });
});
//# sourceMappingURL=extension-activation.test.js.map