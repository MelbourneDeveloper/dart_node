"use strict";
/**
 * Configuration Tests
 * Verifies configuration settings work correctly.
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
suite('Configuration', () => {
    suiteSetup(async () => {
        await (0, test_helpers_1.waitForExtensionActivation)();
    });
    test('serverPath configuration exists', () => {
        const config = vscode.workspace.getConfiguration('tooManyCooks');
        const serverPath = config.get('serverPath');
        assert.ok(serverPath !== undefined, 'serverPath config should exist');
    });
    test('autoConnect configuration exists', () => {
        const config = vscode.workspace.getConfiguration('tooManyCooks');
        const autoConnect = config.get('autoConnect');
        assert.ok(autoConnect !== undefined, 'autoConnect config should exist');
    });
    test('autoConnect defaults to true', () => {
        const config = vscode.workspace.getConfiguration('tooManyCooks');
        const autoConnect = config.get('autoConnect');
        // Default is true according to package.json
        assert.strictEqual(autoConnect, true);
    });
    test('serverPath can be updated', async () => {
        const config = vscode.workspace.getConfiguration('tooManyCooks');
        const testPath = '/test/path/to/server.js';
        await config.update('serverPath', testPath, vscode.ConfigurationTarget.Global);
        const updatedConfig = vscode.workspace.getConfiguration('tooManyCooks');
        const serverPath = updatedConfig.get('serverPath');
        assert.strictEqual(serverPath, testPath);
        // Reset
        await config.update('serverPath', '', vscode.ConfigurationTarget.Global);
    });
});
//# sourceMappingURL=configuration.test.js.map