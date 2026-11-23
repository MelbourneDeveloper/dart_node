# Quick Start: JSX Syntax Highlighting

## 1. Reload VS Code

Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux), type "reload window", and hit Enter.

## 2. Open a JSX File

Open any of these:
- `examples/jsx_demo/lib/counter.jsx`
- `examples/jsx_demo/lib/tabs_example.jsx`

## 3. Check Language Mode

Look at the bottom-right corner of VS Code. It should say **"Dart JSX"**.

If it says "Dart":
1. Click on "Dart" in the bottom-right
2. Select "Configure File Association for '.jsx'"
3. Choose "Dart JSX"

## 4. Verify Highlighting

You should now see:
- JSX tags like `<div>` in **cyan/teal**
- Attributes like `className` in **light blue**
- Curly braces `{}` in **gold**
- Dart code with normal Dart colors

## That's It!

If it's not working, see `TESTING.md` for troubleshooting.

## Example

In `counter.jsx`, this line:
```dart
<button className="btn-inc" onClick={() => count.set(count.value + 1)}>
```

Should show:
- `<button>` - teal
- `className` - light blue
- `onClick` - light blue
- `{}` - gold
- `() => count.set(count.value + 1)` - Dart syntax colors
