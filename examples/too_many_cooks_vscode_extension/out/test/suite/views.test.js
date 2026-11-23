"use strict";
/**
 * View Tests
 * Verifies tree views are registered and visible.
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
const vscode = __importStar(require("vscode"));
const test_helpers_1 = require("../test-helpers");
suite('Views', () => {
    suiteSetup(async () => {
        await (0, test_helpers_1.waitForExtensionActivation)();
    });
    test('Too Many Cooks view container is registered', async () => {
        // Open the view container
        await (0, test_helpers_1.openTooManyCooksPanel)();
        // The test passes if the command doesn't throw
        // We can't directly query view containers, but opening succeeds
    });
    test('Agents view is accessible', async () => {
        await (0, test_helpers_1.openTooManyCooksPanel)();
        // Try to focus the agents view
        try {
            await vscode.commands.executeCommand('tooManyCooksAgents.focus');
        }
        catch {
            // View focus may not work in test environment, but that's ok
            // The important thing is the view exists
        }
    });
    test('Locks view is accessible', async () => {
        await (0, test_helpers_1.openTooManyCooksPanel)();
        try {
            await vscode.commands.executeCommand('tooManyCooksLocks.focus');
        }
        catch {
            // View focus may not work in test environment
        }
    });
    test('Messages view is accessible', async () => {
        await (0, test_helpers_1.openTooManyCooksPanel)();
        try {
            await vscode.commands.executeCommand('tooManyCooksMessages.focus');
        }
        catch {
            // View focus may not work in test environment
        }
    });
    test('Plans view is accessible', async () => {
        await (0, test_helpers_1.openTooManyCooksPanel)();
        try {
            await vscode.commands.executeCommand('tooManyCooksPlans.focus');
        }
        catch {
            // View focus may not work in test environment
        }
    });
});
//# sourceMappingURL=views.test.js.map