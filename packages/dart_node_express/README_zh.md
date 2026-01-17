# dart_node_express

类型安全的 Express.js 绑定。完全使用 Dart 构建 HTTP 服务器和 REST API。

## 安装

```yaml
dependencies:
  dart_node_express: ^0.11.0-beta
```

通过 npm 安装 Express：

```bash
npm install express
```

## 快速开始

```dart
import 'dart:js_interop';
import 'package:dart_node_express/dart_node_express.dart';

void main() {
  final app = express();

  app.get('/', handler((req, res) {
    res.send('Hello, Dart!');
  }));

  app.listen(3000, () {
    print('Server running on port 3000');
  }.toJS);
}
```

## 路由

### 基本路由

```dart
app.get('/users', handler((req, res) {
  res.jsonMap({'users': []});
}));

app.post('/users', handler((req, res) {
  final body = req.body;
  res.status(201);
  res.jsonMap({'created': true});
}));

app.put('/users/:id', handler((req, res) {
  final id = req.params['id'];
  res.jsonMap({'updated': id});
}));

app.delete('/users/:id', handler((req, res) {
  res.status(204);
  res.end();
}));
```

### 路由参数

```dart
app.get('/users/:userId/posts/:postId', handler((req, res) {
  final userId = req.params['userId'];
  final postId = req.params['postId'];

  res.jsonMap({
    'userId': userId,
    'postId': postId,
  });
}));
```

### 查询参数

```dart
app.get('/search', handler((req, res) {
  final query = req.query['q'];
  final page = int.tryParse(req.query['page'] ?? '1') ?? 1;

  res.jsonMap({
    'query': query,
    'page': page,
  });
}));
```

## 请求对象

`Request` 对象提供对传入请求数据的访问：

```dart
app.post('/api/data', handler((req, res) {
  // 请求体（需要 body-parsing 中间件）
  final body = req.body;

  // 请求头
  final contentType = req.headers['content-type'];

  // URL 路径
  final path = req.path;

  // HTTP 方法
  final method = req.method;

  // 查询字符串参数
  final params = req.query;

  res.jsonMap({'received': body});
}));
```

## 响应对象

`Response` 对象提供发送响应的方法：

```dart
// 发送文本
res.send('Hello!');

// 发送 JSON（对于 Dart Map，使用 jsonMap）
res.jsonMap({'message': 'Hello!'});

// 设置状态码（与响应分开调用）
res.status(201);
res.jsonMap({'created': true});

// 设置响应头
res.set('X-Custom-Header', 'value');

// 重定向
res.redirect('/new-location');

// 结束响应（无响应体）
res.status(204);
res.end();
```

## 中间件

### 自定义中间件

```dart
app.use(middleware((req, res, next) {
  print('${req.method} ${req.path}');
  next();
}));
```

### 链式中间件

```dart
app.use(chain([
  middleware((req, res, next) {
    print('First middleware');
    next();
  }),
  middleware((req, res, next) {
    print('Second middleware');
    next();
  }),
]));
```

### 请求上下文

在请求上下文中存储和检索值：

```dart
// 在中间件中设置上下文
app.use(middleware((req, res, next) {
  setContext(req, 'userId', '123');
  next();
}));

// 在处理程序中获取上下文
app.get('/profile', handler((req, res) {
  final userId = getContext<String>(req, 'userId');
  res.jsonMap({'userId': userId});
}));
```

## 路由器

使用路由器组织路由：

```dart
Router createUserRouter() {
  final router = Router();

  router.get('/', handler((req, res) {
    res.jsonMap({'users': []});
  }));

  router.post('/', handler((req, res) {
    res.status(201);
    res.jsonMap({'created': true});
  }));

  router.get('/:id', handler((req, res) {
    res.jsonMap({'user': req.params['id']});
  }));

  return router;
}

void main() {
  final app = express();

  // 挂载路由器
  final router = createUserRouter();
  app.use('/api/users', router);

  app.listen(3000);
}
```

## 异步处理程序

使用异步处理程序进行数据库调用和其他异步操作：

```dart
app.get('/users', asyncHandler((req, res) async {
  final users = await database.fetchUsers();
  res.jsonMap({'users': users});
}));
```

`asyncHandler` 包装器确保错误被正确捕获并传递给错误中间件。

## 验证

使用基于 Schema 的验证系统：

```dart
// 定义验证数据类型
typedef CreateUserData = ({String name, String email, int? age});

// 创建 Schema
final createUserSchema = schema<CreateUserData>(
  {
    'name': string().minLength(2).maxLength(50),
    'email': string().email(),
    'age': optional(int_().positive()),
  },
  (data) => (
    name: data['name'] as String,
    email: data['email'] as String,
    age: data['age'] as int?,
  ),
);

// 使用验证中间件
app.post('/users', validateBody(createUserSchema));
app.post('/users', handler((req, res) {
  final result = getValidatedBody<CreateUserData>(req);
  switch (result) {
    case Success(:final value):
      res.status(201);
      res.jsonMap({'name': value.name, 'email': value.email});
    case Error(:final error):
      res.status(400);
      res.jsonMap({'error': error});
  }
}));
```

### 可用验证器

```dart
// 字符串验证器
string().minLength(2).maxLength(100).notEmpty().email().alphanumeric()

// 整数验证器
int_().min(0).max(100).positive().range(1, 10)

// 布尔验证器
bool_()

// 可选包装器
optional(string())
```

## 完整示例

```dart
import 'dart:js_interop';
import 'package:dart_node_express/dart_node_express.dart';

void main() {
  final app = express();

  // 日志中间件
  app.use(middleware((req, res, next) {
    print('[${DateTime.now()}] ${req.method} ${req.path}');
    next();
  }));

  // 路由
  app.get('/', handler((req, res) {
    res.jsonMap({
      'name': 'My API',
      'version': '1.0.0',
    });
  }));

  app.get('/health', handler((req, res) {
    res.jsonMap({'status': 'ok'});
  }));

  // 挂载路由器
  app.use('/api/users', createUserRouter());

  // 启动服务器
  app.listen(3000, () {
    print('Server running on port 3000');
  }.toJS);
}
```

## 源代码

源代码可在 [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_node_express) 上获取。
