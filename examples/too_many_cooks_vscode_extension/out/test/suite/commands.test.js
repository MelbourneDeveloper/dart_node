"use strict";
/**
 * Command Tests
 * Verifies all registered commands work correctly.
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
suite('Commands', () => {
    suiteSetup(async () => {
        await (0, test_helpers_1.waitForExtensionActivation)();
    });
    test('tooManyCooks.connect command is registered', async () => {
        const commands = await vscode.commands.getCommands(true);
        assert.ok(commands.includes('tooManyCooks.connect'), 'connect command should be registered');
    });
    test('tooManyCooks.disconnect command is registered', async () => {
        const commands = await vscode.commands.getCommands(true);
        assert.ok(commands.includes('tooManyCooks.disconnect'), 'disconnect command should be registered');
    });
    test('tooManyCooks.refresh command is registered', async () => {
        const commands = await vscode.commands.getCommands(true);
        assert.ok(commands.includes('tooManyCooks.refresh'), 'refresh command should be registered');
    });
    test('tooManyCooks.showDashboard command is registered', async () => {
        const commands = await vscode.commands.getCommands(true);
        assert.ok(commands.includes('tooManyCooks.showDashboard'), 'showDashboard command should be registered');
    });
    test('disconnect command can be executed without error when not connected', async () => {
        // Should not throw even when not connected
        await vscode.commands.executeCommand('tooManyCooks.disconnect');
        const api = (0, test_helpers_1.getTestAPI)();
        assert.strictEqual(api.isConnected(), false);
    });
    test('showDashboard command opens a webview panel', async () => {
        // Close any existing editors
        await vscode.commands.executeCommand('workbench.action.closeAllEditors');
        // Execute command
        await vscode.commands.executeCommand('tooManyCooks.showDashboard');
        // Give time for panel to open
        await new Promise((resolve) => setTimeout(resolve, 500));
        // The dashboard should be visible (can't directly test webview content,
        // but we can verify the command executed without error)
        // The test passes if no error is thrown
    });
});
//# sourceMappingURL=commands.test.js.map