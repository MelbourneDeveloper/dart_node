---
layout: layouts/docs.njk
title: Why Dart?
description: A respectful comparison of Dart and TypeScript. Learn why Dart's runtime type safety and sound null safety make it an excellent choice for full-stack development.
keywords: Dart vs TypeScript, type safety, null safety, runtime types, JavaScript alternative, full-stack Dart
eleventyNavigation:
  key: Why Dart
  order: 2
faq:
  - question: What is the main difference between Dart and TypeScript?
    answer: TypeScript erases types at compile time (they don't exist at runtime), while Dart preserves types at runtime. This means Dart can validate types when deserializing JSON or checking generics, something TypeScript cannot do.
  - question: Does Dart have null safety?
    answer: Yes, Dart has sound null safety. Unlike TypeScript's strictNullChecks which can be bypassed, Dart's null safety is enforced at both compile time and runtime, preventing null reference errors.
  - question: Can I use React with Dart?
    answer: Yes! dart_node_react provides full React bindings for Dart, including hooks (useState, useEffect, etc.), component creation, and JSX-like syntax. You get all React's power with Dart's type safety.
  - question: Why choose Dart over TypeScript for a new project?
    answer: Choose Dart when runtime type safety matters (API boundaries, serialization), when you want one language for frontend, backend, and mobile, or when you're already familiar with Dart from Flutter.
  - question: Can Dart use npm packages?
    answer: Yes, dart_node compiles to JavaScript and runs on Node.js, giving you access to the entire npm ecosystem while writing pure Dart code.
---

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "What is the main difference between Dart and TypeScript?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "TypeScript erases types at compile time (they don't exist at runtime), while Dart preserves types at runtime. This means Dart can validate types when deserializing JSON or checking generics, something TypeScript cannot do."
      }
    },
    {
      "@type": "Question",
      "name": "Does Dart have null safety?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes, Dart has sound null safety. Unlike TypeScript's strictNullChecks which can be bypassed, Dart's null safety is enforced at both compile time and runtime, preventing null reference errors."
      }
    },
    {
      "@type": "Question",
      "name": "Can I use React with Dart?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes! dart_node_react provides full React bindings for Dart, including hooks (useState, useEffect, etc.), component creation, and JSX-like syntax. You get all React's power with Dart's type safety."
      }
    },
    {
      "@type": "Question",
      "name": "Why choose Dart over TypeScript for a new project?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Choose Dart when runtime type safety matters (API boundaries, serialization), when you want one language for frontend, backend, and mobile, or when you're already familiar with Dart from Flutter."
      }
    },
    {
      "@type": "Question",
      "name": "Can Dart use npm packages?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes, dart_node compiles to JavaScript and runs on Node.js, giving you access to the entire npm ecosystem while writing pure Dart code."
      }
    }
  ]
}
</script>

If you're a TypeScript developer, you already appreciate the value of types. Dart takes that appreciation further with features that TypeScript, due to its design constraints, cannot provide.

If you're a Flutter developer, you already know Dart. Now you can use it across the entire JavaScript ecosystem.

## TypeScript: A Brilliant Compromise

TypeScript is an engineering marvel. It adds static typing to JavaScript without breaking compatibility with the massive JS ecosystem. This was a deliberate choice - and it was the right one for TypeScript's goals.

However, this choice comes with trade-offs that become apparent in larger applications.

## The Type Erasure Problem

TypeScript types exist only at compile time. When your code runs, they're gone.

```typescript
interface User {
  id: number;
  name: string;
  email: string;
}

// This compiles fine
const user: User = JSON.parse(apiResponse);

// But at runtime, there's no guarantee `user` matches the interface.
// If the API returns { id: "123", name: null }, TypeScript can't help you.
console.log(user.name.toUpperCase()); // Runtime error if name is null!
```

**Dart preserves types at runtime:**

```dart
class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,       // Fails immediately if wrong type
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

// Validation happens at the boundary
final user = User.fromJson(jsonDecode(apiResponse));

// If we get here, we KNOW user.name is a non-null String
print(user.name.toUpperCase()); // Safe!
```

## Sound Null Safety

TypeScript has `strictNullChecks`, which is excellent. But "strict" still allows escape hatches.

```typescript
// TypeScript: The ! operator trusts you (sometimes wrongly)
function processUser(user: User | null) {
  console.log(user!.name); // You're asserting user isn't null
  // TypeScript trusts you. The runtime might not.
}
```

**Dart's null safety is sound:**

```dart
// Dart: The compiler ensures this
void processUser(User? user) {
  print(user.name); // Compile error! user might be null

  // You must handle the null case
  if (user != null) {
    print(user.name); // Now it's safe
  }

  // Or use null-aware operators
  print(user?.name ?? 'Anonymous');
}
```

The `!` operator exists in Dart too, but using it on a null value throws immediately - you can't silently proceed with undefined behavior.

## Real-World Implications

### Serialization

In TypeScript, you often need runtime validation libraries like Zod or io-ts:

```typescript
import { z } from 'zod';

const UserSchema = z.object({
  id: z.number(),
  name: z.string(),
  email: z.string().email(),
});

type User = z.infer<typeof UserSchema>;

// You define the shape twice: once for Zod, once for TypeScript
const user = UserSchema.parse(apiData);
```

In Dart, the class definition IS the runtime validation:

```dart
class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
  );
}

// One definition, used for both types and validation
final user = User.fromJson(apiData);
```

### Generics

TypeScript generics are erased:

```typescript
class Box<T> {
  constructor(public value: T) {}

  isString(): boolean {
    // Can't check if T is string at runtime!
    // typeof this.value === 'string' checks the value, not T
    return typeof this.value === 'string';
  }
}
```

Dart generics exist at runtime:

```dart
class Box<T> {
  final T value;
  Box(this.value);

  bool isString() {
    // We can check the actual type parameter!
    return T == String;
  }

  // Even better: type-safe operations
  R map<R>(R Function(T) fn) => fn(value);
}
```

## Single Language, Multiple Platforms

With dart_node, you write Dart everywhere:

| Platform | TypeScript | Dart (dart_node) |
|----------|-----------|------------------|
| Backend | Node.js + TypeScript | dart_node_express |
| Web Frontend | React + TypeScript | dart_node_react |
| Mobile | React Native + TypeScript | dart_node_react_native |
| Desktop | Electron + TypeScript | Flutter Desktop |

Share models, validation logic, and business rules across all platforms - with runtime type safety.

## Simpler Build Pipeline

A typical TypeScript project:

```
Source → TypeScript Compiler → Babel → Webpack/Rollup → Bundle
         (tsconfig.json)     (.babelrc)  (webpack.config.js)
```

A dart_node project:

```
Source → dart compile js → Bundle
         (just works)
```

No configuration maze. No compatibility issues between tools. One command.

## For Flutter Developers

If you already know Dart from Flutter, dart_node opens up the JavaScript ecosystem:

- Use the massive React component ecosystem
- Access npm packages (millions of them)
- Deploy to Node.js hosting (cheaper than server-side Dart)
- Build with familiar tools (same language, same patterns)

## When TypeScript Makes Sense

TypeScript remains an excellent choice when:

- You're working with an existing JavaScript codebase
- Your team is deeply invested in the TypeScript ecosystem
- You need maximum compatibility with JS libraries
- You prefer TypeScript's structural typing over Dart's nominal typing

## Conclusion

Dart and TypeScript both add type safety to dynamic languages. TypeScript chose maximum JavaScript compatibility. Dart chose maximum type safety.

For new projects where runtime safety matters, Dart offers guarantees that TypeScript cannot provide - not because TypeScript is flawed, but because it was designed with different constraints.

With dart_node, you get the best of both worlds: Dart's type safety with access to the JavaScript ecosystem.

---

Ready to try it? [Get started with dart_node](/docs/getting-started/)
