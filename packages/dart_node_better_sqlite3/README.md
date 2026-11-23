# dart_node_better_sqlite3

Typed Dart bindings for better-sqlite3. Synchronous SQLite3 with WAL mode.

## Getting Started

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

## Run

```bash
npm install better-sqlite3
dart compile js -o app.js lib/main.dart
node app.js
```

## Part of dart_node

[GitHub](https://github.com/MelbourneDeveloper/dart_node)
