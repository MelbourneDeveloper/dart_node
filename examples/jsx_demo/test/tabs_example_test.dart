/// UI tests for TabsExample component.
@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:jsx_demo/tabs_example.g.dart';
import 'package:test/test.dart';

void main() {
  late JSAny tabsComponent;

  setUp(() {
    tabsComponent = registerFunctionComponent((props) => TabsExample());
  });

  test('TabsExample renders with title', () {
    final result = render(fc(tabsComponent));
    expect(result.container.textContent, contains('Tabbed Interface'));
    result.unmount();
  });

  test('TabsExample shows home tab content by default', () {
    final result = render(fc(tabsComponent));
    final content = result.container.querySelector('.tab-content');
    expect(content, isNotNull);
    expect(content!.textContent, contains('Home'));
    expect(content.textContent, contains('Welcome to the home tab'));
    result.unmount();
  });

  test('TabsExample switches to profile tab when clicked', () {
    final result = render(fc(tabsComponent));

    final buttons = result.container.querySelectorAll('.tab-btn');
    final profileButton = buttons[1];

    fireClick(profileButton);

    final content = result.container.querySelector('.tab-content');
    expect(content!.textContent, contains('Profile'));
    expect(
      content.textContent,
      contains('View and edit your profile settings'),
    );

    result.unmount();
  });

  test('TabsExample switches to settings tab when clicked', () {
    final result = render(fc(tabsComponent));

    final buttons = result.container.querySelectorAll('.tab-btn');
    final settingsButton = buttons[2];

    fireClick(settingsButton);

    final content = result.container.querySelector('.tab-content');
    expect(content!.textContent, contains('Settings'));
    expect(
      content.textContent,
      contains('Configure your application preferences'),
    );

    result.unmount();
  });

  test('TabsExample can switch between all tabs', () {
    final result = render(fc(tabsComponent));

    final buttons = result.container.querySelectorAll('.tab-btn');
    final homeButton = buttons[0];
    final profileButton = buttons[1];
    final settingsButton = buttons[2];

    final content = result.container.querySelector('.tab-content')!;

    expect(content.textContent, contains('Welcome to the home tab'));

    fireClick(profileButton);
    expect(content.textContent, contains('View and edit your profile'));

    fireClick(settingsButton);
    expect(content.textContent, contains('Configure your application'));

    fireClick(homeButton);
    expect(content.textContent, contains('Welcome to the home tab'));

    result.unmount();
  });

  test('TabsExample renders all three tab buttons', () {
    final result = render(fc(tabsComponent));

    final buttons = result.container.querySelectorAll('.tab-btn');
    expect(buttons.length, equals(3));

    expect(buttons[0].textContent, contains('Home'));
    expect(buttons[1].textContent, contains('Profile'));
    expect(buttons[2].textContent, contains('Settings'));

    result.unmount();
  });

  test('active tab has active class', () {
    final result = render(fc(tabsComponent));

    final buttons = result.container.querySelectorAll('.tab-btn');
    expect(buttons[0].className, contains('active'));
    expect(buttons[1].className, isNot(contains('active')));
    expect(buttons[2].className, isNot(contains('active')));

    result.unmount();
  });

  test('active class changes when tab is clicked', () {
    final result = render(fc(tabsComponent));

    var buttons = result.container.querySelectorAll('.tab-btn');
    final profileButton = buttons[1];

    fireClick(profileButton);

    buttons = result.container.querySelectorAll('.tab-btn');
    expect(buttons[0].className, isNot(contains('active')));
    expect(buttons[1].className, contains('active'));
    expect(buttons[2].className, isNot(contains('active')));

    result.unmount();
  });
}
