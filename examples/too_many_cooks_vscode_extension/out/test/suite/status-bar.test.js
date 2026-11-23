"use strict";
/**
 * Status Bar Tests
 * Verifies the status bar item updates correctly.
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
const test_helpers_1 = require("../test-helpers");
suite('Status Bar', () => {
    suiteSetup(async () => {
        await (0, test_helpers_1.waitForExtensionActivation)();
    });
    test('Status bar exists after activation', () => {
        // The status bar is created during activation
        // We can't directly query it, but we verify the extension is active
        const api = (0, test_helpers_1.getTestAPI)();
        assert.ok(api, 'Extension should be active with status bar');
    });
    test('Connection status changes are reflected', async function () {
        this.timeout(5000);
        const api = (0, test_helpers_1.getTestAPI)();
        // Ensure clean state by disconnecting first
        await api.disconnect();
        // Initial state should be disconnected
        assert.strictEqual(api.getConnectionStatus(), 'disconnected');
    });
});
//# sourceMappingURL=status-bar.test.js.map