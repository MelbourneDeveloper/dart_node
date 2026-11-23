---
layout: layouts/docs.njk
title: dart_node_better_sqlite3
description: SQLite bindings using better-sqlite3 for Node.js.
eleventyNavigation:
  key: dart_node_better_sqlite3
  parent: Packages
  order: 6
---

`dart_node_better_sqlite3` provides type-safe SQLite bindings for Node.js using the better-sqlite3 npm package. It offers synchronous database access with WAL mode for better concurrency.

## Installation

```yaml
dependencies:
  dart_node_better_sqlite3: ^0.1.0-beta
```

Also install the better-sqlite3 package via npm:

```bash
npm install better-sqlite3
```

## Quick Start

```dart
import 'package:dart_node_better_sqlite3/dart_node_better_sqlite3.dart';
import 'package:nadz/nadz.dart';

void main() {
  // Open a database (creates if not exists)
  final dbResult = openDatabase('myapp.db');

  final db = switch (dbResult) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  // Create a table
  db.exec('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT UNIQUE
    )
  ''');

  // Insert data
  final insertResult = db.prepare(
    'INSERT INTO users (name, email) VALUES (?, ?)',
  );

  switch (insertResult) {
    case Success(:final value):
      value.run(['Alice', 'alice@example.com']);
      value.run(['Bob', 'bob@example.com']);
    case Error(:final error):
      print('Error: $error');
  }

  // Query data
  final selectResult = db.prepare('SELECT * FROM users');

  switch (selectResult) {
    case Success(:final value):
      final rows = value.all([]);
      for (final row in rows) {
        print('User: ${row['name']} - ${row['email']}');
      }
    case Error(:final error):
      print('Error: $error');
  }

  // Close the database
  db.close();
}
```

## Database API

### Opening a Database

```dart
// Open or create a database file
final dbResult = openDatabase('path/to/database.db');

// In-memory database
final memDbResult = openDatabase(':memory:');
```

The `openDatabase` function automatically:
- Enables WAL (Write-Ahead Logging) mode for better concurrency
- Sets a 5-second busy timeout

### Executing Raw SQL

```dart
// Execute SQL without results (DDL, multiple statements)
db.exec('''
  CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT);
  CREATE INDEX idx_name ON products(name);
''');
```

### Prepared Statements

```dart
// Prepare a parameterized statement
final stmtResult = db.prepare('SELECT * FROM users WHERE id = ?');

switch (stmtResult) {
  case Success(:final value):
    // Use the statement
    final row = value.get([1]); // Get single row
    final rows = value.all([]); // Get all rows
    value.run([1]); // Run without returning data
  case Error(:final error):
    print('Failed to prepare: $error');
}
```

### Statement Methods

```dart
// Get a single row (or null if not found)
final row = stmt.get([param1, param2]);

// Get all matching rows
final rows = stmt.all([param1]);

// Run statement (INSERT, UPDATE, DELETE)
// Returns info about affected rows
final info = stmt.run([param1, param2]);
print('Changes: ${info.changes}');
print('Last insert ID: ${info.lastInsertRowid}');
```

### Checking Database State

```dart
if (db.isOpen()) {
  // Database is ready
}
```

### Setting Pragmas

```dart
// Set additional pragmas
db.pragma('foreign_keys = ON');
db.pragma('synchronous = NORMAL');
```

## Error Handling

All operations return `Result<T, String>` for safe error handling:

```dart
final result = db.prepare('SELECT * FROM nonexistent');

switch (result) {
  case Success(:final value):
    // Use the statement
    break;
  case Error(:final error):
    print('SQL error: $error');
}
```

## Example: Todo App

```dart
import 'package:dart_node_better_sqlite3/dart_node_better_sqlite3.dart';
import 'package:nadz/nadz.dart';

typedef Todo = ({int id, String title, bool completed});

class TodoRepository {
  final Database _db;

  TodoRepository(this._db) {
    _db.exec('''
      CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        completed INTEGER DEFAULT 0
      )
    ''');
  }

  Result<int, String> add(String title) {
    final result = _db.prepare(
      'INSERT INTO todos (title) VALUES (?)',
    );
    return switch (result) {
      Success(:final value) => Success(value.run([title]).lastInsertRowid),
      Error(:final error) => Error(error),
    };
  }

  Result<List<Todo>, String> getAll() {
    final result = _db.prepare('SELECT * FROM todos ORDER BY id');
    return switch (result) {
      Success(:final value) => Success(
        value.all([]).map((row) => (
          id: row['id'] as int,
          title: row['title'] as String,
          completed: row['completed'] == 1,
        )).toList(),
      ),
      Error(:final error) => Error(error),
    };
  }

  Result<void, String> complete(int id) {
    final result = _db.prepare(
      'UPDATE todos SET completed = 1 WHERE id = ?',
    );
    return switch (result) {
      Success(:final value) => Success(value.run([id])),
      Error(:final error) => Error(error),
    };
  }

  Result<void, String> delete(int id) {
    final result = _db.prepare('DELETE FROM todos WHERE id = ?');
    return switch (result) {
      Success(:final value) => Success(value.run([id])),
      Error(:final error) => Error(error),
    };
  }
}
```

## API Reference

See the [full API documentation](/api/dart_node_better_sqlite3/) for all available functions and types.
