
[better-sqlite3](https://github.com/WiseLibs/better-sqlite3) 的类型化 Dart 绑定。为 Node.js 应用程序提供支持 WAL 模式的同步 SQLite3 访问。

## 安装

```yaml
dependencies:
  dart_node_better_sqlite3: ^0.11.0-beta
  nadz: ^0.9.0
```

通过 npm 安装：

```bash
npm install better-sqlite3
```

## 快速开始

```dart
import 'package:dart_node_better_sqlite3/dart_node_better_sqlite3.dart';
import 'package:nadz/nadz.dart';

void main() {
  final db = switch (openDatabase('./my.db')) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  db.exec('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)');

  final stmt = switch (db.prepare('INSERT INTO users (name) VALUES (?)')) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  stmt.run(['Alice']);

  final query = switch (db.prepare('SELECT * FROM users')) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  final rows = query.all([]);
  print(rows);

  db.close();
}
```

## 核心概念

### 打开数据库

```dart
final db = switch (openDatabase('./my.db')) {
  Success(:final value) => value,
  Error(:final error) => throw Exception(error),
};
```

可以传递选项用于只读模式、内存数据库等。

### 执行 SQL

对于不返回数据的语句：

```dart
db.exec('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');
db.exec('DROP TABLE IF EXISTS temp');
```

### 预处理语句

用于参数化查询：

```dart
final stmt = switch (db.prepare('INSERT INTO users (name, email) VALUES (?, ?)')) {
  Success(:final value) => value,
  Error(:final error) => throw Exception(error),
};

stmt.run(['Alice', 'alice@example.com']);
stmt.run(['Bob', 'bob@example.com']);
```

### 查询数据

```dart
final query = switch (db.prepare('SELECT * FROM users WHERE id = ?')) {
  Success(:final value) => value,
  Error(:final error) => throw Exception(error),
};

// 获取单行
final row = query.get([1]);

// 获取所有行
final allRows = query.all([]);
```

### 事务

```dart
db.exec('BEGIN');
try {
  // 多个操作...
  db.exec('COMMIT');
} catch (e) {
  db.exec('ROLLBACK');
  rethrow;
}
```

## 编译和运行

```bash
# 将 Dart 编译为 JavaScript
dart compile js -o app.js lib/main.dart

# 使用 Node.js 运行
node app.js
```

## 源代码

源代码可在 [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_node_better_sqlite3) 上获取。
