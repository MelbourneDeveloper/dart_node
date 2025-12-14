// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from: tabs_example.jsx

/// Tabs component using JSX syntax.
///
/// Demonstrates:
/// - Conditional rendering
/// - Dynamic class names
/// - State management for active tab
library;

import 'package:dart_node_react/dart_node_react.dart';

/// A tabbed interface component.
ReactElement TabsExample() {
  final activeTab = useState('home');

  final homeContent = 'Welcome to the home tab. This is the main content area.';
  final profileContent = 'View and edit your profile settings here.';
  final settingsContent = 'Configure your application preferences.';

  final currentContent = switch (activeTab.value) {
    'home' => homeContent,
    'profile' => profileContent,
    'settings' => settingsContent,
    _ => homeContent,
  };

  final currentLabel = switch (activeTab.value) {
    'home' => 'Home',
    'profile' => 'Profile',
    'settings' => 'Settings',
    _ => 'Home',
  };

  return $div(className: 'tabs-container') >>
      [
        $h1 >> 'Tabbed Interface',
        $div(className: 'tab-buttons') >>
            [
              $button(
                    className: activeTab.value == 'home'
                        ? 'tab-btn active'
                        : 'tab-btn',
                    onClick: () => activeTab.set('home'),
                  ) >>
                  'Home',
              $button(
                    className: activeTab.value == 'profile'
                        ? 'tab-btn active'
                        : 'tab-btn',
                    onClick: () => activeTab.set('profile'),
                  ) >>
                  'Profile',
              $button(
                    className: activeTab.value == 'settings'
                        ? 'tab-btn active'
                        : 'tab-btn',
                    onClick: () => activeTab.set('settings'),
                  ) >>
                  'Settings',
            ],
        $div(className: 'tab-content') >>
            [$h2 >> currentLabel, $p() >> currentContent],
      ];
}
