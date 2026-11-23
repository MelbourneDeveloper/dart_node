"use strict";
/**
 * Test helpers for integration tests.
 * NO MOCKING - real VSCode instance with real extension.
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
exports.waitForCondition = void 0;
exports.getTestAPI = getTestAPI;
exports.waitForExtensionActivation = waitForExtensionActivation;
exports.waitForConnection = waitForConnection;
exports.openTooManyCooksPanel = openTooManyCooksPanel;
const vscode = __importStar(require("vscode"));
let cachedTestAPI = null;
/**
 * Gets the test API from the extension's exports.
 */
function getTestAPI() {
    if (!cachedTestAPI) {
        throw new Error('Test API not initialized - call waitForExtensionActivation first');
    }
    return cachedTestAPI;
}
/**
 * Waits for a condition to be true, polling at regular intervals.
 */
const waitForCondition = async (condition, timeoutMessage = 'Condition not met within timeout', timeout = 10000) => {
    const interval = 100;
    const startTime = Date.now();
    while (Date.now() - startTime < timeout) {
        const result = await Promise.resolve(condition());
        if (result) {
            return;
        }
        await new Promise((resolve) => setTimeout(resolve, interval));
    }
    throw new Error(timeoutMessage);
};
exports.waitForCondition = waitForCondition;
/**
 * Waits for the extension to fully activate.
 */
async function waitForExtensionActivation() {
    console.log('[TEST HELPER] Starting extension activation wait...');
    const extension = vscode.extensions.getExtension('Nimblesite.too-many-cooks');
    if (!extension) {
        throw new Error('Extension not found - check publisher name in package.json');
    }
    console.log('[TEST HELPER] Extension found, checking activation status...');
    if (!extension.isActive) {
        console.log('[TEST HELPER] Extension not active, activating now...');
        await extension.activate();
        console.log('[TEST HELPER] Extension activate() completed');
    }
    else {
        console.log('[TEST HELPER] Extension already active');
    }
    await (0, exports.waitForCondition)(() => {
        const exportsValue = extension.exports;
        console.log(`[TEST HELPER] Checking exports - type: ${typeof exportsValue}`);
        if (exportsValue !== undefined && exportsValue !== null) {
            if (typeof exportsValue === 'object') {
                cachedTestAPI = exportsValue;
                console.log('[TEST HELPER] Test API verified');
                return true;
            }
        }
        return false;
    }, 'Extension exports not available within timeout', 30000);
    console.log('[TEST HELPER] Extension activation complete');
}
/**
 * Waits for connection to the MCP server.
 */
async function waitForConnection(timeout = 30000) {
    console.log('[TEST HELPER] Waiting for MCP connection...');
    const api = getTestAPI();
    await (0, exports.waitForCondition)(() => api.isConnected(), 'MCP connection timed out', timeout);
    console.log('[TEST HELPER] MCP connection established');
}
/**
 * Opens the Too Many Cooks panel.
 */
async function openTooManyCooksPanel() {
    console.log('[TEST HELPER] Opening Too Many Cooks panel...');
    await vscode.commands.executeCommand('workbench.view.extension.tooManyCooks');
    // Wait for panel to be visible
    await new Promise((resolve) => setTimeout(resolve, 500));
    console.log('[TEST HELPER] Panel opened');
}
//# sourceMappingURL=test-helpers.js.map