// Build-time release history, derived from the canonical package CHANGELOGs —
// the same release notes the publish pipeline validates per `Release/<version>`
// tag. Single source of truth: packages/<pkg>/CHANGELOG.md. Versions and per-
// package notes are parsed here; publish dates come from pub.dev (baked below,
// since the Pages build checks out shallow with no git tags). Chinese notes use
// a translation overlay and fall back to English for any unmapped line.

import { readFileSync } from "fs";
import { dirname, resolve, join } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PACKAGES_DIR = resolve(__dirname, "..", "..", "..", "packages");

// Publishable packages, in tier/display order.
const PACKAGES = [
  "dart_logging",
  "dart_node_core",
  "reflux",
  "dart_node_express",
  "dart_node_ws",
  "dart_node_better_sqlite3",
  "dart_node_sql_js",
  "dart_node_mcp",
  "dart_node_react",
  "dart_node_react_native",
];

// Release dates (ISO) sourced from pub.dev — earliest publish across packages
// for each version. Versions absent here render without a date.
const RELEASE_DATES = {
  "0.13.0-beta": "2026-06-07",
  "0.12.0-beta": "2026-01-29",
  "0.11.0-beta": "2025-12-13",
  "0.9.0-beta": "2025-12-11",
  "0.8.0-beta": "2025-12-04",
  "0.2.0-beta": "2025-12-02",
  "0.1.0-beta": "2025-11-30",
};

// Chinese overlay for changelog lines. Unmapped lines fall back to English.
const ZH_NOTES = {
  "Maintenance release; no functional changes": "维护版本；无功能性更改",
  "Maintenance release": "维护版本",
  "Maintenance release; internal test improvements": "维护版本；内部测试改进",
  "Enhanced test coverage": "增强测试覆盖率",
  "Early release": "早期版本",
  "Initial beta release": "首个 Beta 版本",
  "Version bump for upcoming release": "为即将发布的版本提升版本号",
  "Updated docs": "更新文档",
  "Improved documentation for core extensions": "改进核心扩展的文档",
  "Pino-style structured logging framework": "Pino 风格的结构化日志框架",
  "Child loggers with inherited context": "支持继承上下文的子日志记录器",
  "Add filesystem (`fs`) bindings": "新增文件系统（`fs`）绑定",
  "Add child process interop": "新增子进程互操作",
  "Core JS interop utilities for Dart-to-JavaScript compilation":
    "用于 Dart 到 JavaScript 编译的核心 JS 互操作工具",
  "Foundation for dart_node package family": "dart_node 包系列的基础",
  "Add WebSocket support via dart_node_ws package":
    "通过 dart_node_ws 包新增 WebSocket 支持",
  "Redux-style predictable state container for Dart":
    "面向 Dart 的 Redux 风格可预测状态容器",
  "Sealed classes for exhaustive action pattern matching":
    "使用密封类实现详尽的 action 模式匹配",
  "Express.js bindings for Dart": "面向 Dart 的 Express.js 绑定",
  "Build Node.js HTTP servers entirely in Dart":
    "完全使用 Dart 构建 Node.js HTTP 服务器",
  "Add WebSocket support integration with dart_node_ws":
    "新增与 dart_node_ws 的 WebSocket 集成支持",
  "WebSocket bindings for Dart on Node.js":
    "面向 Node.js 上 Dart 的 WebSocket 绑定",
  "Build real-time WebSocket servers entirely in Dart":
    "完全使用 Dart 构建实时 WebSocket 服务器",
  "Typed Dart bindings for better-sqlite3 npm package":
    "为 better-sqlite3 npm 包提供类型化的 Dart 绑定",
  "Synchronous SQLite3 access with WAL mode":
    "支持 WAL 模式的同步 SQLite3 访问",
  "Typed Dart bindings for sql.js (SQLite compiled to WebAssembly)":
    "为 sql.js（编译为 WebAssembly 的 SQLite）提供类型化的 Dart 绑定",
  "Synchronous in-memory SQLite with file persistence on Node.js":
    "在 Node.js 上支持文件持久化的同步内存 SQLite",
  "`Result`-based API: open, prepare, exec, run, get, all, pragma":
    "基于 `Result` 的 API：open、prepare、exec、run、get、all、pragma",
  "Add streamable HTTP transport": "新增可流式传输的 HTTP 传输层",
  "Additional MCP server capabilities": "新增 MCP 服务器能力",
  "Typed Dart bindings for @modelcontextprotocol/sdk":
    "为 @modelcontextprotocol/sdk 提供类型化的 Dart 绑定",
  "Build MCP servers in Dart that run on Node.js":
    "使用 Dart 构建运行于 Node.js 的 MCP 服务器",
  "React bindings for Dart": "面向 Dart 的 React 绑定",
  "Build React web applications entirely in Dart":
    "完全使用 Dart 构建 React Web 应用",
  "React Native bindings for Dart": "面向 Dart 的 React Native 绑定",
  "Build mobile apps with Expo entirely in Dart":
    "完全使用 Dart 与 Expo 构建移动应用",
};

const EN_MONTHS = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
];

const escapeHtml = (s) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

// Escape, then render inline `code` spans. Content is our own changelogs.
const toHtml = (s) =>
  escapeHtml(s).replace(/`([^`]+)`/g, "<code>$1</code>");

const formatDateEn = (iso) => {
  const [y, m, d] = iso.split("-").map((n) => parseInt(n, 10));
  return `${EN_MONTHS[m - 1]} ${d}, ${y}`;
};

const formatDateZh = (iso) => {
  const [y, m, d] = iso.split("-").map((n) => parseInt(n, 10));
  return `${y}年${m}月${d}日`;
};

const PRERELEASE_RANK = { alpha: 1, beta: 2 };

const parseVersion = (v) => {
  const [core, pre] = v.split("-");
  const [major, minor, patch] = core.split(".").map((n) => parseInt(n, 10) || 0);
  const rank = pre ? (PRERELEASE_RANK[pre.split(".")[0]] ?? 3) : 4;
  return [major, minor, patch, rank];
};

const compareDesc = (a, b) => {
  const pa = parseVersion(a);
  const pb = parseVersion(b);
  for (let i = 0; i < pa.length; i += 1) {
    if (pa[i] !== pb[i]) return pb[i] - pa[i];
  }
  return 0;
};

const parseChangelog = (markdown) => {
  const byVersion = {};
  let current = null;
  for (const line of markdown.split("\n")) {
    const header = line.match(/^##\s+(.+?)\s*$/);
    if (header) {
      current = header[1].trim();
      byVersion[current] = [];
      continue;
    }
    if (!current) continue;
    const bullet = line.match(/^[-*]\s+(.+?)\s*$/);
    if (bullet) byVersion[current].push(bullet[1].trim());
  }
  return byVersion;
};

const versions = {};
for (const pkg of PACKAGES) {
  const file = join(PACKAGES_DIR, pkg, "CHANGELOG.md");
  const parsed = parseChangelog(readFileSync(file, "utf-8"));
  for (const [version, changes] of Object.entries(parsed)) {
    if (changes.length === 0) continue;
    versions[version] ??= [];
    versions[version].push({
      name: pkg,
      changes: changes.map((c) => ({ en: toHtml(c), zh: toHtml(ZH_NOTES[c] ?? c) })),
    });
  }
}

export default Object.keys(versions)
  .sort(compareDesc)
  .map((version) => {
    const iso = RELEASE_DATES[version] ?? null;
    return {
      version,
      dateISO: iso,
      dateEn: iso ? formatDateEn(iso) : null,
      dateZh: iso ? formatDateZh(iso) : null,
      packages: versions[version],
    };
  });
