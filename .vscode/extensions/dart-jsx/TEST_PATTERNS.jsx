/// Comprehensive test file for Dart JSX syntax highlighting
/// This file tests ALL JSX patterns that should be highlighted correctly

library;

import 'package:dart_node_react/dart_node_react.dart';

// TEST 1: Self-closing tags
ReactElement Test1() {
  return <Component />;
}

// TEST 2: Self-closing tags with attributes
ReactElement Test2() {
  return <Component className="test" />;
}

// TEST 3: Self-closing tags with expression attributes
ReactElement Test3() {
  return <Component onClick={() => handler()} />;
}

// TEST 4: Tags with children
ReactElement Test4() {
  return <div>text content</div>;
}

// TEST 5: Nested tags
ReactElement Test5() {
  return <div><span>nested text</span></div>;
}

// TEST 6: Multiple nested levels
ReactElement Test6() {
  return <div>
    <header>
      <h1>Title</h1>
    </header>
  </div>;
}

// TEST 7: JSX expressions
ReactElement Test7() {
  final name = 'World';
  return <div>{name}</div>;
}

// TEST 8: Nested expressions (object literals)
ReactElement Test8() {
  return <div style={{color: 'red', fontSize: 16}}>
    Styled text
  </div>;
}

// TEST 9: Multiple attributes - string values
ReactElement Test9() {
  return <div className="container" id="main" aria-label="content">
    Text
  </div>;
}

// TEST 10: Multiple attributes - expression values
ReactElement Test10() {
  final value = 10;
  return <input
    value={value}
    onChange={(e) => print(e)}
    disabled={false}
  />;
}

// TEST 11: Spread attributes (if supported)
ReactElement Test11(Map<String, dynamic> props) {
  // Note: Spread syntax may not be supported yet
  return <Component />;
}

// TEST 12: Boolean attributes
ReactElement Test12() {
  return <input disabled required />;
}

// TEST 13: Conditional expressions in JSX
ReactElement Test13(bool show) {
  return <div>{show ? <span>Visible</span> : null}</div>;
}

// TEST 14: Lists/arrays in JSX
ReactElement Test14(List<String> items) {
  return <ul>
    {items.map((item) => <li key={item}>{item}</li>).toList()}
  </ul>;
}

// TEST 15: Mixed content
ReactElement Test15() {
  return <div>
    Text before
    <strong>bold text</strong>
    Text after
  </div>;
}

// TEST 16: Event handlers
ReactElement Test16() {
  return <button
    onClick={() => print('clicked')}
    onMouseEnter={() => print('hover')}
    onMouseLeave={() => print('leave')}
  >
    Click me
  </button>;
}

// TEST 17: Component composition
ReactElement Test17() {
  return <div>
    <Header />
    <Content>
      <Sidebar />
      <Main />
    </Content>
    <Footer />
  </div>;
}

// TEST 18: Complex expressions
ReactElement Test18(int count) {
  return <div>
    Count: {count}
    Double: {count * 2}
    Message: {count > 10 ? 'High' : 'Low'}
  </div>;
}

// TEST 19: String attribute escaping
ReactElement Test19() {
  return <div title="Quote: \"Hello\"" data-value='Single: \'test\''>
    Content
  </div>;
}

// TEST 20: Multiline JSX
ReactElement Test20() {
  return <div
    className="multi-line"
    style={{
      color: 'blue',
      padding: 10,
    }}
  >
    <h1>Title</h1>
    <p>Paragraph with {2 + 2} expression</p>
    <ul>
      <li>Item 1</li>
      <li>Item 2</li>
    </ul>
  </div>;
}

// TEST 21: Adjacent JSX elements (fragments would need <>...</>)
ReactElement Test21() {
  return <div>
    <span>First</span>
    <span>Second</span>
  </div>;
}

// TEST 22: Deeply nested expressions
ReactElement Test22() {
  final data = {'user': {'name': 'John', 'age': 30}};
  return <div>
    {data['user']?['name'] ?? 'Unknown'}
  </div>;
}

// TEST 23: Callback with multiple statements
ReactElement Test23() {
  return <button onClick={() {
    print('First action');
    print('Second action');
  }}>
    Multi-statement handler
  </button>;
}

// TEST 24: Custom component with PascalCase
ReactElement Test24() {
  return <MyCustomComponent
    propName="value"
    onAction={(data) => handleAction(data)}
  />;
}

// TEST 25: HTML-like elements (lowercase)
ReactElement Test25() {
  return <div>
    <input type="text" />
    <button>Submit</button>
    <span>Text</span>
  </div>;
}

void handleAction(dynamic data) {}
ReactElement Header() => <div>Header</div>;
ReactElement Content({List<ReactElement>? children}) => <div>{children}</div>;
ReactElement Sidebar() => <div>Sidebar</div>;
ReactElement Main() => <div>Main</div>;
ReactElement Footer() => <div>Footer</div>;
ReactElement MyCustomComponent({String? propName, Function? onAction}) => <div />;
void handler() {}
