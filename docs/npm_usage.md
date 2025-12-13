# Using npm React/React Native Packages Directly in Dart

## The Core Idea

**You can use ANY npm React/React Native package DIRECTLY without writing Dart wrappers.**

The `npmComponent()` function lets you drop in npm packages and use them exactly like you would in TypeScript - no recreating libraries, no wrapper functions, just direct usage.

## Basic Usage

```dart
import 'package:dart_node_react_native/dart_node_react_native.dart';

// Use react-native-paper Button DIRECTLY
final button = npmComponent(
  'react-native-paper',  // npm package name
  'Button',              // component name
  props: {'mode': 'contained', 'onPress': handlePress},
  child: 'Click Me'.toJS,
);

// Use react-native-paper FAB
final fab = npmComponent(
  'react-native-paper',
  'FAB',
  props: {'icon': 'plus', 'onPress': handleAdd},
);

// Use react-native-paper Card
final card = npmComponent(
  'react-native-paper',
  'Card',
  children: [cardContent, cardActions],
);
```

## Navigation Example

```dart
// NavigationContainer from @react-navigation/native
final navContainer = npmComponent(
  '@react-navigation/native',
  'NavigationContainer',
  children: [stackNavigator],
);

// Stack.Screen from @react-navigation/stack
final homeScreen = npmComponent(
  '@react-navigation/stack',
  'Screen',
  props: {
    'name': 'Home',
    'component': homeComponent,
    'options': {'title': 'Home Screen'},
  },
);
```

## Factory Functions

For packages that export factory functions (like createStackNavigator):

```dart
// Get the factory function
final createStack = npmFactory<JSFunction>(
  '@react-navigation/stack',
  'createStackNavigator',
);

// Call the factory
final Stack = createStack.value!.callAsFunction();
```

## What NOT To Do

❌ **DON'T create wrapper functions for every component:**
```dart
// WRONG - Don't do this!
PaperButtonElement paperButton({PaperButtonProps? props, ...}) {
  // ... wrapper code
}
```

❌ **DON'T recreate entire libraries in Dart:**
```dart
// WRONG - Don't recreate npm packages!
typedef PaperButtonProps = ({
  PaperButtonMode? mode,
  bool? dark,
  // ... 20 more fields
});
```

✅ **DO use npmComponent() directly:**
```dart
// CORRECT - Direct usage!
final button = npmComponent('react-native-paper', 'Button', props: {...});
```

## Why This Approach?

1. **Works with ANY npm package immediately** - no wrapper code needed
2. **Native modules work** - camera, storage, maps, etc.
3. **TypeScript props map directly** - just use a Map<String, dynamic>
4. **Zero maintenance** - npm packages update, your code still works

## Props Mapping (TypeScript → Dart)

| TypeScript | Dart |
|------------|------|
| `string` | `String` |
| `number` | `num` / `int` / `double` |
| `boolean` | `bool` |
| `() => void` | `void Function()` |
| `{key: value}` | `Map<String, dynamic>` |
| `T \| undefined` | nullable in the Map |

## Example: Full Screen with Paper + Navigation

```dart
import 'package:dart_node_react_native/dart_node_react_native.dart';

ReactElement homeScreen(JSObject props) {
  final (count, setCount) = useState(0);

  return npmComponent(
    'react-native',
    'View',
    props: {'style': {'flex': 1, 'padding': 16}},
    children: [
      // Paper Button
      npmComponent(
        'react-native-paper',
        'Button',
        props: {
          'mode': 'contained',
          'onPress': () => setCount(count + 1),
        },
        child: 'Count: $count'.toJS,
      ),

      // Paper TextInput
      npmComponent(
        'react-native-paper',
        'TextInput',
        props: {
          'label': 'Enter text',
          'mode': 'outlined',
        },
      ),

      // Paper Card
      npmComponent(
        'react-native-paper',
        'Card',
        children: [
          npmComponent('react-native-paper', 'Card.Title',
            props: {'title': 'My Card'}),
          npmComponent('react-native-paper', 'Card.Content',
            children: [
              npmComponent('react-native-paper', 'Text',
                child: 'Card content here'.toJS),
            ]),
        ],
      ),
    ],
  );
}
```

## Adding Your Own Types (Easy!)

Start loose with `npmComponent()`, then add types WHERE YOU NEED THEM.

### Step 1: Create a Typed Element (Extension Type)

```dart
/// Typed element for Paper Button - zero-cost wrapper
extension type PaperButton._(NpmComponentElement _) implements ReactElement {
  factory PaperButton._create(NpmComponentElement e) = PaperButton._;
}
```

### Step 2: Create a Typed Props Record

```dart
/// Props for Paper Button - full autocomplete!
typedef PaperButtonProps = ({
  String? mode,           // 'text' | 'outlined' | 'contained' | 'elevated'
  bool? disabled,
  bool? loading,
  String? buttonColor,
  String? textColor,
});
```

### Step 3: Create a Typed Factory Function

```dart
/// Create a Paper Button with full type safety
PaperButton paperButton({
  PaperButtonProps? props,
  void Function()? onPress,
  String? label,
}) {
  final p = <String, dynamic>{};
  if (props != null) {
    if (props.mode != null) p['mode'] = props.mode;
    if (props.disabled != null) p['disabled'] = props.disabled;
    if (props.loading != null) p['loading'] = props.loading;
    if (props.buttonColor != null) p['buttonColor'] = props.buttonColor;
    if (props.textColor != null) p['textColor'] = props.textColor;
  }
  if (onPress != null) p['onPress'] = onPress;

  return PaperButton._create(npmComponent(
    'react-native-paper',
    'Button',
    props: p,
    child: label?.toJS,
  ));
}
```

### Usage - Now With Types!

```dart
// Full autocomplete and type checking!
final btn = paperButton(
  props: (
    mode: 'contained',
    disabled: false,
    loading: isSubmitting,
    buttonColor: '#6200EE',
    textColor: null,
  ),
  onPress: handleSubmit,
  label: 'Submit',
);
```

### The Pattern

1. **Extension type** - Zero-cost typed wrapper over `NpmComponentElement`
2. **Props typedef** - Named record with all the TypeScript props you care about
3. **Factory function** - Builds the props Map and calls `npmComponent()`

### When to Add Types

- Components you use **frequently** (Button, Text, View)
- Components with **complex props** (Navigation, Forms)
- Components where **autocomplete helps** (many optional props)

### When NOT to Add Types

- One-off usage of a component
- Simple components with 1-2 props
- Prototyping / exploring a new npm package

### Full Example: Typed Paper Components

```dart
// ===== Extension Types =====
extension type PaperButton._(NpmComponentElement _) implements ReactElement {}
extension type PaperFAB._(NpmComponentElement _) implements ReactElement {}
extension type PaperCard._(NpmComponentElement _) implements ReactElement {}

// ===== Props Typedefs =====
typedef PaperButtonProps = ({
  String? mode,
  bool? disabled,
  bool? loading,
  String? buttonColor,
});

typedef PaperFABProps = ({
  String? icon,
  String? label,
  bool? small,
  bool? visible,
});

// ===== Factory Functions =====
PaperButton paperButton({
  PaperButtonProps? props,
  void Function()? onPress,
  String? label,
}) => PaperButton._(npmComponent(
  'react-native-paper', 'Button',
  props: {
    if (props?.mode != null) 'mode': props!.mode,
    if (props?.disabled != null) 'disabled': props!.disabled,
    if (onPress != null) 'onPress': onPress,
  },
  child: label?.toJS,
));

PaperFAB paperFAB({
  PaperFABProps? props,
  void Function()? onPress,
}) => PaperFAB._(npmComponent(
  'react-native-paper', 'FAB',
  props: {
    if (props?.icon != null) 'icon': props!.icon,
    if (props?.label != null) 'label': props!.label,
    if (onPress != null) 'onPress': onPress,
  },
));

// ===== Usage =====
final myButton = paperButton(
  props: (mode: 'contained', disabled: false, loading: false, buttonColor: null),
  onPress: () => print('Pressed!'),
  label: 'Click Me',
);

final myFAB = paperFAB(
  props: (icon: 'plus', label: 'Add', small: false, visible: true),
  onPress: handleAdd,
);
```

## Key Insight

**Start loose, add types as needed.**

- `npmComponent()` works with ANY package IMMEDIATELY
- Add typed wrappers only for components YOU use frequently
- Extension types are zero-cost - no runtime overhead
- Props records give full autocomplete in your IDE
