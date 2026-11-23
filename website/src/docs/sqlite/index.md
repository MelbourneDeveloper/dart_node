---
layout: layouts/docs.njk
title: dart_node_better_sqlite3
description: Typed Dart bindings for better-sqlite3. Synchronous SQLite3 with WAL mode for Node.js.
eleventyNavigation:
  key: dart_node_better_sqlite3
  parent: Packages
  order: 6
---

Typed Dart bindings for [better-sqlite3](https://github.com/WiseLibs/better-sqlite3). Provides synchronous SQLite3 access with WAL mode support for Node.js applications.

## Installation

```yaml
dependencies:
  dart_node_better_sqlite3: ^0.2.0
  nadz: ^0.9.0
```

Also install the npm package:

```bash
npm install better-sqlite3
```

## Quick Start

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

## Core Concepts

### Opening a Database

```dart
final db = switch (openDatabase('./my.db')) {
  Success(:final value) => value,
  Error(:final error) => throw Exception(error),
};
```

Options can be passed for read-only mode, memory databases, etc.

### Executing SQL

For statements that don't return data:

```dart
db.exec('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');
db.exec('DROP TABLE IF EXISTS temp');
```

### Prepared Statements

For parameterized queries:

```dart
final stmt = switch (db.prepare('INSERT INTO users (name, email) VALUES (?, ?)')) {
  Success(:final value) => value,
  Error(:final error) => throw Exception(error),
};

stmt.run(['Alice', 'alice@example.com']);
stmt.run(['Bob', 'bob@example.com']);
```

### Querying Data

```dart
final query = switch (db.prepare('SELECT * FROM users WHERE id = ?')) {
  Success(:final value) => value,
  Error(:final error) => throw Exception(error),
};

// Get single row
final row = query.get([1]);

// Get all rows
final allRows = query.all([]);
```

### Transactions

```dart
db.exec('BEGIN');
try {
  // Multiple operations...
  db.exec('COMMIT');
} catch (e) {
  db.exec('ROLLBACK');
  rethrow;
}
```

## Compile and Run

```bash
# Compile Dart to JavaScript
dart compile js -o app.js lib/main.dart

# Run with Node.js
node app.js
```

## Source Code

The source code is available on [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_node_better_sqlite3).
