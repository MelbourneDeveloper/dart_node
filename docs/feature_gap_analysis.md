# Feature Gap Analysis: dart_node_react vs react & over_react

This document analyzes the feature gaps between `dart_node_react` and the established Dart React packages:
- [`react`](https://pub.dev/packages/react) (v7.1.1) - Workiva's Dart bindings for React
- [`over_react`](https://pub.dev/packages/over_react) - Workiva's higher-level React abstraction

## Executive Summary

`dart_node_react` provides a **modern, type-safe foundation** using `dart:js_interop` and extension types, but lacks several features present in the mature `react`/`over_react` ecosystem. This analysis identifies **critical gaps** that must be addressed for feature parity.

---

## 1. Component Definition

### Current dart_node_react

| Feature | Status | Notes |
|---------|--------|-------|
| Function components | **YES** | `registerFunctionComponent()` + `fc()` |
| Class components | **NO** | No `Component2` equivalent |
| Stateful class components | **NO** | No lifecycle methods |
| Component registration | **YES** | `registerFunctionComponent()` |

### react Package

| Feature | Status | Notes |
|---------|--------|-------|
| Function components | YES | `registerFunctionComponent()` |
| Class components | YES | `Component2` class |
| Stateful class components | YES | Full state management |
| Component registration | YES | `registerComponent2()` |

### over_react Package

| Feature | Status | Notes |
|---------|--------|-------|
| Function components | YES | `uiFunction()` wrapper |
| Class components | YES | `UiComponent2` |
| Stateful class components | YES | `UiStatefulComponent2` |
| Typed props/state | YES | `UiProps`, `UiState` classes |
| Props mixins | YES | Composable prop definitions |
| Builder pattern | YES | Fluent API with cascades |
| Code generation | YES | `build_runner` integration |

### GAPS - dart_node_react Needs

- [ ] **Class-based components** - `Component2` equivalent with lifecycle
- [ ] **Stateful class components** - State management in class components
- [ ] **UiProps/UiState pattern** - Typed props/state classes (optional, for ergonomics)
- [ ] **Props mixins** - Composable prop definitions

---

## 2. Lifecycle Methods

### Current dart_node_react

| Method | Status |
|--------|--------|
| `useEffect` | **YES** |
| `useLayoutEffect` | **YES** |
| Class lifecycle methods | **NO** |

### react Package (Component2)

| Method | Status |
|--------|--------|
| `componentWillMount()` | YES (deprecated) |
| `componentDidMount()` | YES |
| `componentWillReceiveProps()` | YES (deprecated) |
| `shouldComponentUpdate()` | YES |
| `componentWillUpdate()` | YES (deprecated) |
| `componentDidUpdate()` | YES |
| `componentWillUnmount()` | YES |
| `getDerivedStateFromProps()` | YES |
| `getSnapshotBeforeUpdate()` | YES |

### GAPS - dart_node_react Needs

- [ ] All lifecycle methods if class components are added

---

## 3. State Management Hooks

### Current dart_node_react

| Hook | Status | Notes |
|------|--------|-------|
| `useState<T>()` | **YES** | Generic typed state |
| `useStateLazy<T>()` | **YES** | Lazy initialization |
| `useStateJS()` | **YES** | For JSAny types |
| `useStateJSArray<T>()` | **YES** | For List<JSAny> |
| `useReducer()` | **YES** | Reducer pattern |
| `useReducerLazy()` | **YES** | Lazy reducer init |

### react Package

| Hook | Status | Notes |
|------|--------|-------|
| `useState` | NO | Uses class-based state |
| `useReducer` | NO | Uses class-based state |

### over_react Package

| Hook | Status | Notes |
|------|--------|-------|
| Redux hooks | YES | Via over_react_redux |

### dart_node_react Advantage

**dart_node_react has SUPERIOR hook support** with:
- Generic typed state hooks
- Lazy initialization variants
- JS-interop specific variants
- Reducer with lazy init

---

## 4. Effect & Performance Hooks

### Current dart_node_react

| Hook | Status | Notes |
|------|--------|-------|
| `useEffect()` | **YES** | With dependency array |
| `useLayoutEffect()` | **YES** | Synchronous effects |
| `useMemo<T>()` | **YES** | Memoized values |
| `useCallback()` | **YES** | Memoized callbacks |
| `useDebugValue()` | **YES** | DevTools debugging |

### react Package

| Hook | Status | Notes |
|------|--------|-------|
| Hooks | NO | Class-based architecture |

### GAPS - dart_node_react Needs

- [ ] **`useTransition()`** - Concurrent React feature
- [ ] **`useDeferredValue()`** - Concurrent React feature
- [ ] **`useId()`** - Unique ID generation
- [ ] **`useSyncExternalStore()`** - External store subscription
- [ ] **`useInsertionEffect()`** - CSS-in-JS libraries

---

## 5. Ref Hooks

### Current dart_node_react

| Feature | Status | Notes |
|---------|--------|-------|
| `useRef<T>()` | **YES** | Generic typed refs |
| `useRefInit<T>()` | **YES** | With initial value |
| `createRef<T>()` | **YES** | Static refs |
| `Ref<T>` wrapper | **YES** | Type-safe wrapper |
| `useImperativeHandle()` | **YES** | Custom ref handles |
| `forwardRef2()` | **YES** | Ref forwarding |

### react Package

| Feature | Status | Notes |
|---------|--------|-------|
| `createRef<T>()` | YES | Typed refs |
| `forwardRef2()` | YES | Ref forwarding |

### dart_node_react Advantage

**dart_node_react has EQUIVALENT or BETTER ref support** with type-safe wrappers.

---

## 6. Context API

### Current dart_node_react

| Feature | Status | Notes |
|---------|--------|-------|
| `createContext<T>()` | **YES** | Generic typed context |
| `useContext<T>()` | **YES** | Hook for consuming |
| `Context.providerType` | **YES** | Provider component |
| `Context.consumerType` | **YES** | Consumer (deprecated) |
| `Context.defaultValue` | **YES** | Default value |

### react Package

| Feature | Status | Notes |
|---------|--------|-------|
| `createContext<T>()` | YES | Context creation |
| `contextType` property | YES | Class component context |
| `Context.Provider` | YES | Provider component |
| `Context.Consumer` | YES | Consumer component |

### over_react Package

| Feature | Status | Notes |
|---------|--------|-------|
| Context support | YES | Via react package |

### dart_node_react Advantage

**dart_node_react has EQUIVALENT context support** with modern hook-based consumption.

---

## 7. Error Boundaries

### Current dart_node_react

| Feature | Status |
|---------|--------|
| `getDerivedStateFromError()` | **NO** |
| `componentDidCatch()` | **NO** |
| Error boundary component | **NO** |

### react Package (Component2)

| Feature | Status |
|---------|--------|
| `getDerivedStateFromError()` | YES |
| `componentDidCatch()` | YES |

### over_react Package

| Feature | Status |
|---------|--------|
| Error boundary support | YES |

### GAPS - dart_node_react Needs

- [ ] **Error boundary support** - Either via class components or a wrapper

---

## 8. Redux Integration

### Current dart_node_react

| Feature | Status |
|---------|--------|
| Redux bindings | **NO** |
| `useSelector()` | **NO** |
| `useDispatch()` | **NO** |
| `useStore()` | **NO** |
| `ReduxProvider` | **NO** |
| `connect()` HOC | **NO** |

### over_react Package (over_react_redux)

| Feature | Status | Notes |
|---------|--------|-------|
| `useSelector<TState, TValue>()` | YES | Typed selector hook |
| `useDispatch()` | YES | Dispatch hook |
| `useStore<TState>()` | YES | Store access hook |
| `createSelectorHook<TState>()` | YES | Custom selector factory |
| `createDispatchHook()` | YES | Custom dispatch factory |
| `createStoreHook<TState>()` | YES | Custom store factory |
| `ReduxProvider` | YES | Store provider |
| `connect()` HOC | YES | Class component connection |
| Multiple stores | YES | Via custom context |
| DevTools integration | YES | Redux DevTools middleware |
| `ConnectPropsMixin` | YES | Dispatch prop mixin |

### GAPS - dart_node_react Needs

- [ ] **`useSelector<TState, TValue>()`** - Typed selector hook
- [ ] **`useDispatch()`** - Dispatch hook
- [ ] **`useStore<TState>()`** - Store access hook
- [ ] **`createSelectorHook<TState>()`** - Custom selector factory
- [ ] **`createDispatchHook()`** - Custom dispatch factory
- [ ] **`createStoreHook<TState>()`** - Custom store factory
- [ ] **`ReduxProvider`** - Store provider component
- [ ] **`connect()` HOC** - Class component connection (if class components added)
- [ ] **Multiple store support** - Via custom context
- [ ] **DevTools middleware** - Redux DevTools integration

---

## 9. Special Components

### Current dart_node_react

| Component | Status | Notes |
|-----------|--------|-------|
| `Fragment` | **YES** | `fragment()` helper |
| `Suspense` | **YES** | `suspense()` helper |
| `StrictMode` | **YES** | `strictMode()` helper |
| `lazy()` | **YES** | Code splitting |
| `memo2()` | **YES** | Component memoization |

### react Package

| Component | Status |
|-----------|--------|
| `Fragment` | YES |
| `Suspense` | YES |
| `StrictMode` | YES |
| `lazy()` | YES |
| `memo2()` | YES |

### dart_node_react Status

**PARITY ACHIEVED** for special components.

---

## 10. Synthetic Events

### Current dart_node_react

| Event Type | Status |
|------------|--------|
| `SyntheticEvent` | **YES** |
| `SyntheticMouseEvent` | **YES** |
| `SyntheticKeyboardEvent` | **YES** |
| `SyntheticFocusEvent` | **YES** |
| `SyntheticFormEvent` | **YES** |
| `SyntheticInputEvent` | **YES** |
| `SyntheticChangeEvent` | **YES** |
| `SyntheticClipboardEvent` | **YES** |
| `SyntheticCompositionEvent` | **YES** |
| `SyntheticDragEvent` | **YES** |
| `SyntheticPointerEvent` | **YES** |
| `SyntheticTouchEvent` | **YES** |
| `SyntheticTransitionEvent` | **YES** |
| `SyntheticAnimationEvent` | **YES** |
| `SyntheticUIEvent` | **YES** |
| `SyntheticWheelEvent` | **YES** |

### react Package

| Event Type | Status |
|------------|--------|
| Same events | YES |

### dart_node_react Status

**PARITY ACHIEVED** for synthetic events.

---

## 11. DOM Elements

### Current dart_node_react

| Category | Count | Status |
|----------|-------|--------|
| Semantic elements | 10+ | **YES** |
| Form elements | 7 | **YES** |
| List elements | 6 | **YES** |
| Table elements | 8 | **YES** |
| Text elements | 5 | **YES** |
| Media elements | 3 | **YES** |
| SVG elements | 15+ | **YES** |
| Metadata elements | 6 | **YES** |

### react Package

| Category | Status | Notes |
|----------|--------|-------|
| DOM elements | YES | 300+ properties |

### over_react Package

| Category | Status | Notes |
|----------|--------|-------|
| `Dom.*` methods | YES | All DOM elements |
| `DomProps` | YES | Typed DOM props |

### dart_node_react Status

**PARITY ACHIEVED** - All major DOM elements supported.

---

## 12. JSX-like DSL

### Current dart_node_react

| Feature | Status | Notes |
|---------|--------|-------|
| `$element` factories | **YES** | `$div`, `$span`, etc. |
| `>>` operator | **YES** | Children composition |
| Fluent props | **YES** | Named parameters |
| Event handlers | **YES** | `onClick`, etc. |

### over_react Package

| Feature | Status | Notes |
|---------|--------|-------|
| Cascade operator | YES | `..prop = value` |
| Builder pattern | YES | `(Dom.div()..id='x')()` |

### dart_node_react Advantage

**dart_node_react has a MORE ERGONOMIC DSL**:
```dart
// dart_node_react - cleaner syntax
$div(className: 'container') >> [
  $h1 >> 'Title',
  $p >> 'Content'
]

// over_react - more verbose
(Dom.div()..className = 'container')([
  (Dom.h1())('Title'),
  (Dom.p())('Content'),
])
```

---

## 13. Testing Utilities

### Current dart_node_react

| Feature | Status | Notes |
|---------|--------|-------|
| `render()` | **YES** | Returns RenderResult |
| `renderIntoDocument()` | **YES** | Legacy render |
| `isElement()` | **YES** | Element check |
| `isDOMComponent()` | **YES** | DOM check |
| `isCompositeComponent()` | **YES** | Component check |
| `Simulate.*` | **YES** | Event simulation |
| `RenderResult` queries | **YES** | `findByClass`, etc. |
| `DomNode` wrapper | **YES** | DOM interaction |

### react Package

| Feature | Status | Notes |
|---------|--------|-------|
| `react_test_utils` | YES | TestUtils wrapper |
| `Simulate` | YES | Event simulation |
| `findDOMNode()` | YES | DOM access |

### over_react Package

| Feature | Status | Notes |
|---------|--------|-------|
| `over_react_test` | YES | Separate package |

### dart_node_react Status

**PARITY ACHIEVED** for basic testing utilities.

### GAPS - dart_node_react Needs (Nice-to-have)

- [ ] **`screen` queries** - Testing Library style queries
- [ ] **`waitFor()`** - Async waiting utility
- [ ] **`fireEvent`** - Alternative to Simulate
- [ ] **`userEvent`** - More realistic user interactions

---

## 14. Children Utilities

### Current dart_node_react

| Method | Status |
|--------|--------|
| `Children.map()` | **YES** |
| `Children.forEach()` | **YES** |
| `Children.count()` | **YES** |
| `Children.only()` | **YES** |
| `Children.toArray()` | **YES** |

### react Package

| Method | Status |
|--------|--------|
| React.Children | YES |

### dart_node_react Status

**PARITY ACHIEVED** for children utilities.

---

## 15. Prop Validation

### Current dart_node_react

| Feature | Status |
|---------|--------|
| PropTypes | **NO** |
| Runtime validation | **NO** |

### react Package

| Feature | Status | Notes |
|---------|--------|-------|
| `propTypes` | YES | On Component2 |
| `PropValidator` | YES | Validation function |
| `PropValidatorInfo` | YES | Validation metadata |

### over_react Package

| Feature | Status | Notes |
|---------|--------|-------|
| Required props | YES | Via `late` keyword |
| Prop validation | YES | Analyzer plugin |

### GAPS - dart_node_react Assessment

**NOT NEEDED** - dart_node_react uses Dart's type system which provides **compile-time type safety**, superior to runtime PropTypes. The analyzer catches errors before runtime.

---

## 16. Code Generation / Boilerplate

### Current dart_node_react

| Feature | Status | Notes |
|---------|--------|-------|
| Code generation | **NO** | Not required |
| Build runner | **NO** | Not required |

### over_react Package

| Feature | Status | Notes |
|---------|--------|-------|
| Code generation | YES | Required via build_runner |
| Part files | YES | `.over_react.g.dart` |
| Snippets | YES | IDE templates |

### dart_node_react Advantage

**dart_node_react requires NO CODE GENERATION** - Components work out of the box without build steps. This is a significant ergonomic advantage.

---

## 17. Flux Integration

### Current dart_node_react

| Feature | Status |
|---------|--------|
| Flux bindings | **NO** |

### over_react Package

| Feature | Status | Notes |
|---------|--------|-------|
| w_flux | YES | Deprecated |
| Migration to Redux | YES | Recommended |

### dart_node_react Assessment

**NOT NEEDED** - Flux is deprecated. Focus on Redux hooks instead.

---

## Priority Gap List

### Critical (Must Have)

1. **Redux Hooks** - `useSelector`, `useDispatch`, `useStore`
2. **Redux Provider** - Store provider component
3. **Error Boundaries** - `getDerivedStateFromError`, `componentDidCatch`

### High Priority (Should Have)

4. **Concurrent React Hooks** - `useTransition`, `useDeferredValue`, `useId`
5. **`useSyncExternalStore()`** - External store subscription
6. **DevTools Middleware** - Redux DevTools integration

### Medium Priority (Nice to Have)

7. **Class Components** - `Component2` equivalent (for migration support)
8. **Testing Library Queries** - `screen`, `waitFor`, `fireEvent`
9. **`useInsertionEffect()`** - CSS-in-JS support

### Low Priority (Consider)

10. **Multiple Redux Stores** - Via custom context
11. **Props Mixins** - over_react style composition

---

## Ergonomics Comparison

### dart_node_react Advantages

| Aspect | dart_node_react | react/over_react |
|--------|-----------------|------------------|
| Setup complexity | **Simple** - no build_runner | Complex - requires code generation |
| DSL syntax | **Cleaner** - `$div >> children` | Verbose - `(Dom.div()..prop = x)()` |
| Type safety | **Better** - extension types | Good - but requires generated code |
| Hooks | **Modern** - all hooks available | Limited - class-based focus |
| Bundle size | **Smaller** - no generated code | Larger - generated boilerplate |
| Learning curve | **Lower** - standard React patterns | Higher - custom patterns |

### react/over_react Advantages

| Aspect | dart_node_react | react/over_react |
|--------|-----------------|------------------|
| Maturity | New | **Mature** - production tested |
| Redux integration | Missing | **Full** - comprehensive |
| Error handling | Missing | **Full** - error boundaries |
| Class components | Missing | **Full** - migration support |
| Documentation | Basic | **Extensive** |
| IDE support | Basic | **Better** - analyzer plugin |

---

## Recommended Implementation Order

### Phase 1: Core Parity
1. Redux hooks (`useSelector`, `useDispatch`, `useStore`)
2. `ReduxProvider` component
3. Error boundary support (wrapper component)

### Phase 2: Modern React
4. `useTransition()`
5. `useDeferredValue()`
6. `useId()`
7. `useSyncExternalStore()`

### Phase 3: Developer Experience
8. Redux DevTools middleware
9. Enhanced testing utilities
10. `useInsertionEffect()`

### Phase 4: Migration Support (Optional)
11. Class component base (for teams migrating from over_react)
12. Props mixins pattern

---

## Conclusion

`dart_node_react` has a **strong foundation** with modern hooks, type-safe design, and ergonomic syntax. The critical gaps are:

1. **Redux integration** - Essential for real-world applications
2. **Error boundaries** - Required for production error handling
3. **Concurrent React features** - Important for modern React patterns

Once these gaps are filled, `dart_node_react` will be **more ergonomic** than `over_react` due to:
- No code generation required
- Cleaner JSX-like syntax
- Modern extension type architecture
- First-class hooks support

The package is well-positioned to be the **next-generation** Dart React solution.
