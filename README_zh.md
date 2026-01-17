# dart_node

使用 Dart 编写完整技术栈：React Web 应用、基于 Expo 的 React Native 移动应用，以及 Node.js Express 后端。

[文档](https://melbournedeveloper.github.io/dart_node/)

![React 和 React Native](images/dart_node.gif)

## 包

| 包 | 描述 |
|---------|-------------|
| [dart_node_core](packages/dart_node_core) | 核心 JS 互操作工具 |
| [dart_node_express](packages/dart_node_express) | Express.js 绑定 |
| [dart_node_ws](packages/dart_node_ws) | WebSocket 绑定 |
| [dart_node_react](packages/dart_node_react) | React 绑定 |
| [dart_node_react_native](packages/dart_node_react_native) | React Native 绑定 |
| [dart_node_mcp](packages/dart_node_mcp) | MCP 服务器绑定 |
| [dart_node_better_sqlite3](packages/dart_node_better_sqlite3) | SQLite3 绑定 |
| [dart_jsx](packages/dart_jsx) | Dart JSX 转译器 |
| [reflux](packages/reflux) | Redux 风格状态管理 |
| [dart_logging](packages/dart_logging) | 结构化日志 |
| [dart_node_coverage](packages/dart_node_coverage) | dart2js 代码覆盖率 |

## 工具

| 工具 | 描述 |
|------|-------------|
| [too-many-cooks](examples/too_many_cooks) | 多智能体协调 MCP 服务器 ([npm](https://www.npmjs.com/package/too-many-cooks)) |
| [Too Many Cooks VSCode](examples/too_many_cooks_vscode_extension) | 智能体可视化 VSCode 扩展 |

## 快速开始

```bash
# 切换到本地依赖
dart tools/switch_deps.dart local

# 运行全部
sh run_dev.sh
```

打开 http://localhost:8080/web/

**移动端：** 使用 VSCode 启动配置 `Mobile: Build & Run (Expo)`

## 许可证

BSD 3-Clause 许可证。版权所有 (c) 2025，Christian Findlay。
