"use strict";
/**
 * Status bar item showing agent/lock/message counts.
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
exports.StatusBarManager = void 0;
const vscode = __importStar(require("vscode"));
const signals_core_1 = require("@preact/signals-core");
const signals_1 = require("../../state/signals");
class StatusBarManager {
    statusBarItem;
    disposeEffect = null;
    constructor() {
        this.statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
        this.statusBarItem.command = 'tooManyCooks.showDashboard';
        this.disposeEffect = (0, signals_core_1.effect)(() => {
            this.update();
        });
        this.statusBarItem.show();
    }
    update() {
        const status = signals_1.connectionStatus.value;
        const agents = signals_1.agentCount.value;
        const locks = signals_1.lockCount.value;
        const unread = signals_1.unreadMessageCount.value;
        if (status === 'disconnected') {
            this.statusBarItem.text = '$(debug-disconnect) Too Many Cooks';
            this.statusBarItem.tooltip = 'Click to connect';
            this.statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.errorBackground');
            return;
        }
        if (status === 'connecting') {
            this.statusBarItem.text = '$(sync~spin) Connecting...';
            this.statusBarItem.tooltip = 'Connecting to Too Many Cooks server';
            this.statusBarItem.backgroundColor = undefined;
            return;
        }
        // Connected
        const parts = [
            `$(person) ${agents}`,
            `$(lock) ${locks}`,
            `$(mail) ${unread}`,
        ];
        this.statusBarItem.text = parts.join('  ');
        this.statusBarItem.tooltip = [
            `${agents} agent${agents !== 1 ? 's' : ''}`,
            `${locks} lock${locks !== 1 ? 's' : ''}`,
            `${unread} unread message${unread !== 1 ? 's' : ''}`,
            '',
            'Click to open dashboard',
        ].join('\n');
        this.statusBarItem.backgroundColor = undefined;
    }
    dispose() {
        this.disposeEffect?.();
        this.statusBarItem.dispose();
    }
}
exports.StatusBarManager = StatusBarManager;
//# sourceMappingURL=statusBarItem.js.map