# dart_node_express

Express.js bindings for Dart. Build Node.js HTTP servers entirely in Dart.

## Getting Started

```dart
import 'package:dart_node_express/dart_node_express.dart';

void main() {
  final app = express();

  app.get('/', (req, res) {
    res.send('Hello from Dart!');
  });

  app.listen(3000, () {
    print('Server running on http://localhost:3000');
  });
}
```

## Run

```bash
dart compile js -o server.js lib/main.dart
node server.js
```

## Part of dart_node

[GitHub](https://github.com/MelbourneDeveloper/dart_node)
