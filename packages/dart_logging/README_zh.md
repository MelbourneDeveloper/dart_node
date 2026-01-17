
Pino 风格的结构化日志，支持子日志器。提供具有自动上下文继承的分层日志记录。

## 安装

```yaml
dependencies:
  dart_logging: ^0.11.0-beta
```

## 快速开始

```dart
import 'package:dart_logging/dart_logging.dart';

void main() {
  final context = createLoggingContext(
    transports: [logTransport(logToConsole)],
  );
  final logger = createLoggerWithContext(context);

  logger.info('Hello world');
  logger.warn('Something might be wrong');
  logger.error('Something went wrong');

  // 具有继承上下文的子日志器
  final childLogger = logger.child({'requestId': 'abc-123'});
  childLogger.info('Processing request'); // requestId 自动包含
}
```

## 核心概念

### 日志上下文

使用一个或多个传输创建日志上下文：

```dart
final context = createLoggingContext(
  transports: [logTransport(logToConsole)],
);
```

### 日志级别

提供标准日志级别（从最低到最高严重性）：

```dart
logger.trace('Very detailed trace info');
logger.debug('Debugging info');
logger.info('Information');
logger.warn('Warning');
logger.error('Error occurred');
logger.fatal('Fatal error');
```

### 结构化数据

在日志消息中传递结构化数据：

```dart
logger.info('User logged in', structuredData: {'userId': 123, 'email': 'user@example.com'});
```

### 子日志器

创建继承并扩展上下文的子日志器：

```dart
final requestLogger = logger.child({'requestId': 'abc-123'});
requestLogger.info('Start'); // 包含 requestId

final userLogger = requestLogger.child({'userId': 456});
userLogger.info('Action'); // 同时包含 requestId 和 userId
```

这对于添加适用于某个作用域（如请求处理程序）的上下文非常有用。

### 自定义传输

创建自定义传输以将日志发送到不同目的地：

```dart
void myTransport(LogEntry entry) {
  // 发送到外部服务、文件等
  print('${entry.level}: ${entry.message}');
}

final context = createLoggingContext(
  transports: [logTransport(myTransport)],
);
```

## 示例：Express 服务器日志

```dart
import 'dart:js_interop';
import 'package:dart_node_express/dart_node_express.dart';
import 'package:dart_logging/dart_logging.dart';

void main() {
  final logger = createLoggerWithContext(
    createLoggingContext(transports: [logTransport(logToConsole)]),
  );

  final app = express();

  app.use(middleware((req, res, next) {
    final reqLogger = logger.child({'path': req.path, 'method': req.method});
    reqLogger.info('Request received');
    next();
  }));

  app.listen(3000, () {
    logger.info('Server started', structuredData: {'port': 3000});
  }.toJS);
}
```

## 源代码

源代码可在 [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_logging) 上获取。
