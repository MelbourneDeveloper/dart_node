"use strict";
/**
 * FileDecorationProvider for lock badges on files.
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
exports.LockDecorationProvider = void 0;
const vscode = __importStar(require("vscode"));
const signals_core_1 = require("@preact/signals-core");
const signals_1 = require("../../state/signals");
class LockDecorationProvider {
    _onDidChangeFileDecorations = new vscode.EventEmitter();
    onDidChangeFileDecorations = this._onDidChangeFileDecorations.event;
    disposeEffect = null;
    constructor() {
        this.disposeEffect = (0, signals_core_1.effect)(() => {
            signals_1.locksByFile.value; // Subscribe
            this._onDidChangeFileDecorations.fire(undefined);
        });
    }
    dispose() {
        this.disposeEffect?.();
        this._onDidChangeFileDecorations.dispose();
    }
    provideFileDecoration(uri) {
        const locksMap = signals_1.locksByFile.value;
        const filePath = uri.fsPath;
        // Check if this file has a lock
        const lock = locksMap.get(filePath);
        if (!lock) {
            return undefined;
        }
        const now = Date.now();
        const isExpired = lock.expiresAt < now;
        if (isExpired) {
            return {
                badge: '!',
                color: new vscode.ThemeColor('charts.red'),
                tooltip: `Expired lock (was held by ${lock.agentName})`,
            };
        }
        return {
            badge: 'L',
            color: new vscode.ThemeColor('charts.yellow'),
            tooltip: `Locked by ${lock.agentName}${lock.reason ? `: ${lock.reason}` : ''}`,
        };
    }
}
exports.LockDecorationProvider = LockDecorationProvider;
//# sourceMappingURL=lockDecorations.js.map