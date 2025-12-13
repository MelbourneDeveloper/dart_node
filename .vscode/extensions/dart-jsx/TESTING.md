# Testing the Dart JSX Syntax Extension

## How to Test

1. **Reload VS Code Window**
   - Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
   - Type "Developer: Reload Window" and select it
   - This will reload the window and activate the local extension

2. **Open a JSX File**
   - Open `examples/jsx_demo/lib/counter.jsx`
   - Open `examples/jsx_demo/lib/tabs_example.jsx`

3. **Verify Syntax Highlighting**

   You should see:
   - **JSX Tags** (like `<div>`, `<button>`, `<h1>`) highlighted in cyan/teal color
   - **JSX Attributes** (like `className`, `onClick`) highlighted in light blue
   - **JSX Tag Brackets** (`<`, `>`, `</`, `/>`) in gray
   - **JSX Expressions** (braces `{` and `}`) in gold/yellow
   - **Dart Code** inside braces with normal Dart syntax highlighting
   - **Strings** in JSX with proper string colors

4. **Test Scope Inspector**
   - Place cursor on a JSX tag (e.g., `<div>`)
   - Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
   - Type "Developer: Inspect Editor Tokens and Scopes"
   - Verify the scope shows `entity.name.tag.jsx`

## Expected Highlighting Examples

From `counter.jsx`:
```dart
return <div className="counter">     // <div> = teal, className = light blue
  <h1>Dart + JSX</h1>               // <h1> = teal, text = white
  <div className="value">{count.value}</div>  // {} = gold, count.value = Dart syntax
  <button onClick={() => count.set(count.value + 1)}>  // onClick = light blue
    +
  </button>
</div>;
```

## Troubleshooting

If syntax highlighting doesn't work:

1. **Check File Association**
   - Open a `.jsx` file
   - Look at the bottom-right corner of VS Code
   - It should say "Dart JSX" not "Dart"
   - If it says "Dart", click it and select "Configure File Association for '.jsx'"
   - Select "Dart JSX"

2. **Reload Window Again**
   - Sometimes VS Code needs to be reloaded twice for local extensions

3. **Check Extension is Loaded**
   - Press `Cmd+Shift+X` to open Extensions
   - Search for "dart-jsx"
   - You should see "Dart JSX Syntax" listed (may show as disabled but that's OK for local extensions)

4. **Check Grammar File**
   - Verify `.vscode/extensions/dart-jsx/syntaxes/dart-jsx.tmLanguage.json` exists
   - Verify it's valid JSON

5. **Clear Extension Cache**
   - Close VS Code completely
   - Delete `~/Library/Application Support/Code/CachedExtensions/` (Mac)
   - Reopen VS Code
