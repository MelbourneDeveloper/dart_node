
Reflux 是一个用于 **React with Dart** 和 **Flutter** 的状态管理库。它使用 Dart 的密封类提供完全类型安全的可预测状态容器，支持穷尽模式匹配。

## 安装

```yaml
dependencies:
  reflux: ^0.11.0-beta
```

## 核心概念

### Store

Store 保存应用程序的完整状态树。整个应用应该只有一个 store。

```dart
import 'package:reflux/reflux.dart';

final store = createStore(counterReducer, (count: 0));
```

### Actions

Actions 是描述发生了什么的密封类。使用 Dart 的模式匹配来匹配实际的类型，而不是字符串。

```dart
sealed class CounterAction extends Action {}

final class Increment extends CounterAction {}
final class Decrement extends CounterAction {}
final class SetValue extends CounterAction {
  const SetValue(this.value);
  final int value;
}
```

### Reducers

Reducers 是纯函数，指定状态如何响应 actions 而改变。

```dart
typedef CounterState = ({int count});

CounterState counterReducer(CounterState state, Action action) =>
    switch (action) {
      Increment() => (count: state.count + 1),
      Decrement() => (count: state.count - 1),
      SetValue(:final value) => (count: value),
      _ => state,
    };
```

## 快速开始

```dart
import 'package:reflux/reflux.dart';

// 使用记录类型定义状态
typedef CounterState = ({int count});

// 使用密封类定义 Actions
sealed class CounterAction extends Action {}
final class Increment extends CounterAction {}
final class Decrement extends CounterAction {}

// 使用模式匹配的 Reducer
CounterState counterReducer(CounterState state, Action action) =>
    switch (action) {
      Increment() => (count: state.count + 1),
      Decrement() => (count: state.count - 1),
      _ => state,
    };

void main() {
  final store = createStore(counterReducer, (count: 0));

  store.subscribe(() => print('Count: ${store.getState().count}'));

  store.dispatch(Increment()); // Count: 1
  store.dispatch(Increment()); // Count: 2
  store.dispatch(Decrement()); // Count: 1
}
```

## 中间件

中间件提供了在分发 action 和 reducer 之间的第三方扩展点。

```dart
Middleware<CounterState> loggerMiddleware() =>
    (api) => (next) => (action) {
          print('Dispatching: ${action.runtimeType}');
          next(action);
          print('State: ${api.getState()}');
        };

final store = createStore(
  counterReducer,
  (count: 0),
  enhancer: applyMiddleware([loggerMiddleware()]),
);
```

## 选择器

选择器从状态中提取和记忆化派生数据。

```dart
final getCount = createSelector1(
  (CounterState s) => s.count,
  (count) => count * 2,
);

final doubledCount = getCount(store.getState());
```

## 时间旅行

TimeTravelEnhancer 允许您撤销/重做状态更改。

```dart
final timeTravel = TimeTravelEnhancer<CounterState>();

final store = createStore(
  counterReducer,
  (count: 0),
  enhancer: timeTravel.enhancer,
);

store.dispatch(Increment());
store.dispatch(Increment());

timeTravel.undo(); // 后退一步
timeTravel.redo(); // 前进一步
```

## API 参考

请参阅[完整 API 文档](/api/reflux/)了解所有可用函数和类型。

## 源代码

源代码可在 [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/reflux) 上获取。
