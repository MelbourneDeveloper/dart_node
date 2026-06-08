[sql.js](https://github.com/sql-js/sql.js) 的类型化 Dart 绑定 —— 编译为
WebAssembly 的 SQLite。为 Node.js 应用提供同步的纯内存 SQLite，并可显式持久化到磁盘。

与原生绑定不同，sql.js 无需编译，在任何支持 WebAssembly 的环境中运行方式都一致。
数据库存在于内存中；你可以通过 `save` 或 `close` 将其持久化到文件。

## 安装

```yaml
dependencies:
  dart_node_sql_js: ^0.13.0-beta
  nadz: ^0.0.7-beta
```

同时安装 npm 包：

```bash
npm install sql.js
```

## 快速开始

```dart
import 'package:dart_node_sql_js/dart_node_sql_js.dart';
import 'package:nadz/nadz.dart';

Future<void> main() async {
  // 启动时初始化一次 WebAssembly 运行时。
  final runtime = switch (await initializeSqlJs()) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  // 如果 ./my.db 存在则打开它，否则创建一个新数据库。
  final db = switch (openDatabase('./my.db', sqlJs: runtime)) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  db.exec('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)');

  final insert = switch (db.prepare('INSERT INTO users (name) VALUES (?)')) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };
  insert.run(['Alice']);

  final query = switch (db.prepare('SELECT * FROM users')) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };
  final rows = switch (query.all()) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };
  print(rows); // [{id: 1, name: Alice}]

  // 将内存中的数据库持久化到 ./my.db。
  db.close();
}
```

## 持久化

sql.js 完全在内存中运行。序列化它（`export()`）的唯一方式会释放所有存活的预编译语句，
因此该绑定**不会**在每条语句之后写入磁盘。而是：

- `db.save()` 按需将当前状态刷新到后端文件。
- `db.close()` 先保存，再释放数据库。

重新打开同一路径会加载已持久化的字节。

## API

`initializeSqlJs()` 返回 `Future<Result<SqlJsRuntime, String>>`。将该运行时传给
每一次 `openDatabase` 调用。

`openDatabase(path, sqlJs: runtime)` 返回 `Result<Database, String>`，包含：

| 成员 | 说明 |
|--------|-------------|
| `prepare(sql)` | 准备一条可复用的语句。 |
| `exec(sql)` | 执行一条或多条语句，忽略结果。 |
| `pragma(value)` | 执行 `PRAGMA`。 |
| `save()` | 将内存中的数据库持久化到其文件。 |
| `close()` | 先持久化，再关闭。 |
| `isOpen()` | 数据库是否仍处于打开状态。 |

预编译的 `Statement` 提供：

| 成员 | 说明 |
|--------|-------------|
| `all([params])` | 以列名为键的映射列表返回所有行。 |
| `get([params])` | 第一行，或 null。 |
| `run([params])` | 执行，返回 `changes` 和 `lastInsertRowid`。 |

每个操作都返回 `Result`（来自 [nadz](https://pub.dev/packages/nadz)），而不是抛出异常。

## 许可证

BSD 3-Clause。参见 [LICENSE](LICENSE)。
