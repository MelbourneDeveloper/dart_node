/// Integration tests for the JSX Demo app.
///
/// Tests the full component tree: App with Counter AND TabsExample together.
/// Run with: dart test -p chrome
@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

import '../web/app.dart' show App;

void main() {
  late JSAny appComponent;

  setUp(() {
    appComponent = registerFunctionComponent((props) => App());
  });

  test('renders full App with Counter and TabsExample', () {
    final result = render(fc(appComponent));

    // Counter component renders
    expect(result.container.textContent, contains('Dart + JSX'));
    expect(result.container.textContent, contains('-'));
    expect(result.container.textContent, contains('+'));
    expect(result.container.textContent, contains('Reset'));

    // TabsExample component renders
    expect(result.container.textContent, contains('Tabbed Interface'));
    expect(result.container.textContent, contains('Home'));
    expect(result.container.textContent, contains('Profile'));
    expect(result.container.textContent, contains('Settings'));

    result.unmount();
  });

  test('Counter increment and decrement work', () {
    final result = render(fc(appComponent));

    // Find counter value display
    final valueDiv = result.container.querySelector('.value');
    expect(valueDiv, isNotNull);
    expect(valueDiv!.textContent, '0');

    // Click increment button
    final incButton = result.container.querySelector('.btn-inc');
    expect(incButton, isNotNull);
    fireClick(incButton!);

    // Value should be 1
    expect(result.container.querySelector('.value')!.textContent, '1');

    // Click increment again
    fireClick(incButton);
    expect(result.container.querySelector('.value')!.textContent, '2');

    // Click decrement
    final decButton = result.container.querySelector('.btn-dec');
    fireClick(decButton!);
    expect(result.container.querySelector('.value')!.textContent, '1');

    // Click reset
    final resetButton = result.container.querySelector('.btn-reset');
    fireClick(resetButton!);
    expect(result.container.querySelector('.value')!.textContent, '0');

    result.unmount();
  });

  test('TabsExample tab switching works', () {
    final result = render(fc(appComponent));

    // Initial state - Home tab content should show
    expect(result.container.textContent, contains('Welcome to the home tab'));

    // Find tab buttons by their text content
    final tabButtons = result.container.querySelectorAll('.tab-btn');
    expect(tabButtons.length, greaterThanOrEqualTo(3));

    // Click Profile tab (second button)
    final profileButton = tabButtons[1];
    fireClick(profileButton);

    // Profile content should now show
    expect(
      result.container.textContent,
      contains('View and edit your profile settings'),
    );

    // Click Settings tab (third button)
    final settingsButton = tabButtons[2];
    fireClick(settingsButton);

    // Settings content should now show
    expect(
      result.container.textContent,
      contains('Configure your application preferences'),
    );

    // Click back to Home tab
    final homeButton = tabButtons[0];
    fireClick(homeButton);

    // Home content should show again
    expect(result.container.textContent, contains('Welcome to the home tab'));

    result.unmount();
  });

  test('Counter and Tabs work independently without interference', () {
    final result = render(fc(appComponent));

    // Increment counter a few times
    final incButton = result.container.querySelector('.btn-inc')!;
    fireClick(incButton);
    fireClick(incButton);
    fireClick(incButton);

    expect(result.container.querySelector('.value')!.textContent, '3');

    // Switch tabs - counter should stay at 3
    final tabButtons = result.container.querySelectorAll('.tab-btn');
    fireClick(tabButtons[1]); // Profile

    // Counter still at 3
    expect(result.container.querySelector('.value')!.textContent, '3');

    // Tab content changed
    expect(
      result.container.textContent,
      contains('View and edit your profile settings'),
    );

    // Switch tabs again and decrement counter
    fireClick(tabButtons[2]); // Settings
    final decButton = result.container.querySelector('.btn-dec')!;
    fireClick(decButton);

    // Counter now at 2, tab is Settings
    expect(result.container.querySelector('.value')!.textContent, '2');
    expect(
      result.container.textContent,
      contains('Configure your application preferences'),
    );

    result.unmount();
  });

  test('active tab button has active class', () {
    final result = render(fc(appComponent));

    final tabButtons = result.container.querySelectorAll('.tab-btn');

    // First button (Home) should be active initially
    expect(tabButtons[0].className, contains('active'));
    expect(tabButtons[1].className, isNot(contains('active')));
    expect(tabButtons[2].className, isNot(contains('active')));

    // Click Profile
    fireClick(tabButtons[1]);

    // Now Profile should be active
    final updatedButtons = result.container.querySelectorAll('.tab-btn');
    expect(updatedButtons[0].className, isNot(contains('active')));
    expect(updatedButtons[1].className, contains('active'));
    expect(updatedButtons[2].className, isNot(contains('active')));

    result.unmount();
  });

  test('Counter buttons have correct class names', () {
    final result = render(fc(appComponent));

    final decButton = result.container.querySelector('.btn-dec');
    final incButton = result.container.querySelector('.btn-inc');
    final resetButton = result.container.querySelector('.btn-reset');

    expect(decButton, isNotNull);
    expect(incButton, isNotNull);
    expect(resetButton, isNotNull);

    expect(decButton!.textContent, '-');
    expect(incButton!.textContent, '+');
    expect(resetButton!.textContent, 'Reset');

    result.unmount();
  });

  test('App has correct structure with app class', () {
    final result = render(fc(appComponent));

    final appDiv = result.container.querySelector('.app');
    expect(appDiv, isNotNull);

    // App contains both Counter and TabsExample
    expect(appDiv!.textContent, contains('Dart + JSX'));
    expect(appDiv.textContent, contains('Tabbed Interface'));

    result.unmount();
  });

  test('rapid Counter clicks work correctly', () {
    final result = render(fc(appComponent));

    final incButton = result.container.querySelector('.btn-inc')!;

    // Rapid clicks
    for (var i = 0; i < 10; i++) {
      fireClick(incButton);
    }

    expect(result.container.querySelector('.value')!.textContent, '10');

    final decButton = result.container.querySelector('.btn-dec')!;
    for (var i = 0; i < 5; i++) {
      fireClick(decButton);
    }

    expect(result.container.querySelector('.value')!.textContent, '5');

    result.unmount();
  });

  test('Counter can go negative', () {
    final result = render(fc(appComponent));

    final decButton = result.container.querySelector('.btn-dec')!;
    fireClick(decButton);
    fireClick(decButton);
    fireClick(decButton);

    expect(result.container.querySelector('.value')!.textContent, '-3');

    result.unmount();
  });
}
