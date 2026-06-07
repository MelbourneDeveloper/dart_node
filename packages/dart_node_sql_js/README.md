Typed Dart bindings for [sql.js](https://github.com/sql-js/sql.js) — SQLite
compiled to WebAssembly. Provides synchronous, in-memory SQLite for Node.js
applications, with explicit persistence to disk.

Unlike native bindings, sql.js needs no compilation and runs the same
everywhere WebAssembly does. The database lives in memory; you persist it to a
file with `save` or `close`.

## Installation

```yaml
dependencies:
  dart_node_sql_js: ^0.13.0-beta
  nadz: ^0.0.7-beta
```

Also install the npm package:

```bash
npm install sql.js
```

## Quick Start

```dart
import 'package:dart_node_sql_js/dart_node_sql_js.dart';
import 'package:nadz/nadz.dart';

Future<void> main() async {
  // Initialize the WebAssembly runtime once at startup.
  final runtime = switch (await initializeSqlJs()) {
    Success(:final value) => value,
    Error(:final error) => throw Exception(error),
  };

  // Opens ./my.db if it exists, otherwise creates a new database.
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

  // Persist the in-memory database to ./my.db.
  db.close();
}
```

## Persistence

sql.js is entirely in-memory. The only way to serialize it (`export()`) frees
every live prepared statement, so this binding does **not** write to disk after
each statement. Instead:

- `db.save()` flushes the current state to the backing file on demand.
- `db.close()` saves and then releases the database.

Reopening the same path loads the persisted bytes.

## API

`initializeSqlJs()` returns a `Future<Result<SqlJsRuntime, String>>`. Pass the
runtime to every `openDatabase` call.

`openDatabase(path, sqlJs: runtime)` returns a `Result<Database, String>` with:

| Member | Description |
|--------|-------------|
| `prepare(sql)` | Prepare a reusable statement. |
| `exec(sql)` | Run one or more statements, ignoring results. |
| `pragma(value)` | Run a `PRAGMA`. |
| `save()` | Persist the in-memory database to its file. |
| `close()` | Persist, then close. |
| `isOpen()` | Whether the database is still open. |

A prepared `Statement` exposes:

| Member | Description |
|--------|-------------|
| `all([params])` | All rows as a list of column-keyed maps. |
| `get([params])` | The first row, or null. |
| `run([params])` | Execute, returning `changes` and `lastInsertRowid`. |

Every operation returns a `Result` (from [nadz](https://pub.dev/packages/nadz))
instead of throwing.

## License

BSD 3-Clause. See [LICENSE](LICENSE).
