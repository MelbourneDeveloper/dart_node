// Internal test infrastructure - scenarios are self-documenting through
// their name and description fields
// ignore_for_file: public_member_api_docs

/// Shared test scenarios that describe UI behavior
///
/// These scenarios define what should be tested, not how.
/// The actual test implementation uses these scenarios with
/// platform-specific testing libraries.
library;

import 'package:ui_testing/src/test_components.dart';

/// A test scenario with expected behavior
typedef TestScenario = ({
  String name,
  String description,
  List<TestStep> steps,
});

/// A single step in a test scenario
sealed class TestStep {}

/// Render a component
final class RenderStep extends TestStep {
  /// Creates a render step for the given component
  RenderStep(this.componentName);

  /// The name of the component to render
  final String componentName;
}

/// Assert element exists with test ID
final class AssertExistsStep extends TestStep {
  /// Creates an assertion that element with testId exists
  AssertExistsStep(this.testId, {this.expectedText});

  /// The test ID to search for
  final String testId;

  /// Optional expected text content
  final String? expectedText;
}

/// Assert element does not exist
final class AssertNotExistsStep extends TestStep {
  /// Creates an assertion that element with testId does not exist
  AssertNotExistsStep(this.testId);

  /// The test ID that should not be present
  final String testId;
}

/// Click/Press an element
final class PressStep extends TestStep {
  /// Creates a press action on element with testId
  PressStep(this.testId);

  /// The test ID of the element to press
  final String testId;
}

/// Type text into an input
final class TypeStep extends TestStep {
  /// Creates a type action on element with testId
  TypeStep(this.testId, this.text);

  /// The test ID of the input element
  final String testId;

  /// The text to type
  final String text;
}

/// Clear an input
final class ClearStep extends TestStep {
  /// Creates a clear action on element with testId
  ClearStep(this.testId);

  /// The test ID of the input to clear
  final String testId;
}

/// Assert input has value
final class AssertValueStep extends TestStep {
  /// Creates an assertion for input value
  AssertValueStep(this.testId, this.expectedValue);

  /// The test ID of the input element
  final String testId;

  /// The expected value of the input
  final String expectedValue;
}

// =============================================================================
// Counter Component Scenarios
// =============================================================================

final counterScenarios = <TestScenario>[
  (
    name: 'initial render',
    description: 'Counter should render with initial count of 0',
    steps: [
      RenderStep('counter'),
      AssertExistsStep(testIdCountDisplay, expectedText: 'Count: 0'),
    ],
  ),
  (
    name: 'increment',
    description: 'Counter should increment when increment button is pressed',
    steps: [
      RenderStep('counter'),
      PressStep(testIdIncrementBtn),
      AssertExistsStep(testIdCountDisplay, expectedText: 'Count: 1'),
      PressStep(testIdIncrementBtn),
      AssertExistsStep(testIdCountDisplay, expectedText: 'Count: 2'),
    ],
  ),
  (
    name: 'decrement',
    description: 'Counter should decrement when decrement button is pressed',
    steps: [
      RenderStep('counter'),
      PressStep(testIdDecrementBtn),
      AssertExistsStep(testIdCountDisplay, expectedText: 'Count: -1'),
    ],
  ),
  (
    name: 'reset',
    description: 'Counter should reset to 0 when reset button is pressed',
    steps: [
      RenderStep('counter'),
      PressStep(testIdIncrementBtn),
      PressStep(testIdIncrementBtn),
      PressStep(testIdIncrementBtn),
      AssertExistsStep(testIdCountDisplay, expectedText: 'Count: 3'),
      PressStep(testIdResetBtn),
      AssertExistsStep(testIdCountDisplay, expectedText: 'Count: 0'),
    ],
  ),
];

// =============================================================================
// Form Component Scenarios
// =============================================================================

final formScenarios = <TestScenario>[
  (
    name: 'empty form',
    description: 'Form should render with empty inputs',
    steps: [
      RenderStep('form'),
      AssertValueStep(testIdEmailInput, ''),
      AssertValueStep(testIdPasswordInput, ''),
    ],
  ),
  (
    name: 'email input',
    description: 'Email input should update when typing',
    steps: [
      RenderStep('form'),
      TypeStep(testIdEmailInput, 'test@example.com'),
      AssertValueStep(testIdEmailInput, 'test@example.com'),
    ],
  ),
  (
    name: 'password input',
    description: 'Password input should update when typing',
    steps: [
      RenderStep('form'),
      TypeStep(testIdPasswordInput, 'secret123'),
      AssertValueStep(testIdPasswordInput, 'secret123'),
    ],
  ),
  (
    name: 'empty submit error',
    description: 'Form should show error when submitted empty',
    steps: [
      RenderStep('form'),
      PressStep(testIdSubmitBtn),
      AssertExistsStep(
        testIdErrorMessage,
        expectedText: errorMessageAllFieldsRequired,
      ),
    ],
  ),
  (
    name: 'partial submit error - email only',
    description: 'Form should show error when only email is filled',
    steps: [
      RenderStep('form'),
      TypeStep(testIdEmailInput, 'test@example.com'),
      PressStep(testIdSubmitBtn),
      AssertExistsStep(
        testIdErrorMessage,
        expectedText: errorMessageAllFieldsRequired,
      ),
    ],
  ),
  (
    name: 'partial submit error - password only',
    description: 'Form should show error when only password is filled',
    steps: [
      RenderStep('form'),
      TypeStep(testIdPasswordInput, 'secret123'),
      PressStep(testIdSubmitBtn),
      AssertExistsStep(
        testIdErrorMessage,
        expectedText: errorMessageAllFieldsRequired,
      ),
    ],
  ),
  (
    name: 'successful submit',
    description: 'Form should show success when valid',
    steps: [
      RenderStep('form'),
      TypeStep(testIdEmailInput, 'test@example.com'),
      TypeStep(testIdPasswordInput, 'secret123'),
      PressStep(testIdSubmitBtn),
      AssertExistsStep(
        testIdSuccessMessage,
        expectedText: errorMessageFormSubmitted,
      ),
      AssertNotExistsStep(testIdErrorMessage),
    ],
  ),
];

// =============================================================================
// Toggle Component Scenarios
// =============================================================================

final toggleScenarios = <TestScenario>[
  (
    name: 'initial state',
    description: 'Toggle should render in OFF state',
    steps: [
      RenderStep('toggle'),
      AssertExistsStep(testIdToggleStatus, expectedText: textPatternOff),
    ],
  ),
  (
    name: 'toggle on',
    description: 'Toggle should switch to ON when pressed',
    steps: [
      RenderStep('toggle'),
      PressStep(testIdToggleBtn),
      AssertExistsStep(testIdToggleStatus, expectedText: textPatternOn),
    ],
  ),
  (
    name: 'toggle off',
    description: 'Toggle should switch back to OFF when pressed again',
    steps: [
      RenderStep('toggle'),
      PressStep(testIdToggleBtn),
      AssertExistsStep(testIdToggleStatus, expectedText: textPatternOn),
      PressStep(testIdToggleBtn),
      AssertExistsStep(testIdToggleStatus, expectedText: textPatternOff),
    ],
  ),
];

// =============================================================================
// List Component Scenarios
// =============================================================================

final listScenarios = <TestScenario>[
  (
    name: 'empty list',
    description: 'List should show empty message initially',
    steps: [
      RenderStep('list'),
      AssertExistsStep(
        testIdEmptyMessage,
        expectedText: textPatternNoItems,
      ),
      AssertExistsStep(testIdItemsCount, expectedText: 'Total: 0'),
    ],
  ),
  (
    name: 'add item',
    description: 'List should add item when add button is pressed',
    steps: [
      RenderStep('list'),
      TypeStep(testIdAddItemInput, 'First item'),
      PressStep(testIdAddItemBtn),
      AssertExistsStep(testIdListItem(0), expectedText: 'First item'),
      AssertExistsStep(testIdItemsCount, expectedText: 'Total: 1'),
      AssertNotExistsStep(testIdEmptyMessage),
    ],
  ),
  (
    name: 'clear input after add',
    description: 'Input should be cleared after adding item',
    steps: [
      RenderStep('list'),
      TypeStep(testIdAddItemInput, 'Test item'),
      PressStep(testIdAddItemBtn),
      AssertValueStep(testIdAddItemInput, ''),
    ],
  ),
  (
    name: 'no empty items',
    description: 'List should not add empty items',
    steps: [
      RenderStep('list'),
      PressStep(testIdAddItemBtn),
      AssertExistsStep(testIdEmptyMessage),
      AssertExistsStep(testIdItemsCount, expectedText: 'Total: 0'),
    ],
  ),
  (
    name: 'remove item',
    description: 'List should remove item when remove button is pressed',
    steps: [
      RenderStep('list'),
      TypeStep(testIdAddItemInput, 'Item to remove'),
      PressStep(testIdAddItemBtn),
      AssertExistsStep(testIdListItem(0)),
      PressStep(testIdRemoveBtn(0)),
      AssertNotExistsStep(testIdListItem(0)),
      AssertExistsStep(testIdEmptyMessage),
    ],
  ),
];

// =============================================================================
// Login Form Scenarios
// =============================================================================

final loginFormScenarios = <TestScenario>[
  (
    name: 'empty form',
    description: 'Login form should render with empty inputs',
    steps: [
      RenderStep('loginForm'),
      AssertValueStep(testIdEmailInput, ''),
      AssertValueStep(testIdPasswordInput, ''),
    ],
  ),
  (
    name: 'email input',
    description: 'Email input should update when typing',
    steps: [
      RenderStep('loginForm'),
      TypeStep(testIdEmailInput, 'test@example.com'),
      AssertValueStep(testIdEmailInput, 'test@example.com'),
    ],
  ),
  (
    name: 'password input',
    description: 'Password input should update when typing',
    steps: [
      RenderStep('loginForm'),
      TypeStep(testIdPasswordInput, 'secret123'),
      AssertValueStep(testIdPasswordInput, 'secret123'),
    ],
  ),
  (
    name: 'empty submit error',
    description: 'Login should show error when submitted empty',
    steps: [
      RenderStep('loginForm'),
      PressStep(testIdSubmitBtn),
      AssertExistsStep(
        testIdErrorMessage,
        expectedText: errorMessageAllFieldsRequired,
      ),
    ],
  ),
  (
    name: 'partial submit - email only',
    description: 'Login should show error when only email is filled',
    steps: [
      RenderStep('loginForm'),
      TypeStep(testIdEmailInput, 'test@example.com'),
      PressStep(testIdSubmitBtn),
      AssertExistsStep(
        testIdErrorMessage,
        expectedText: errorMessageAllFieldsRequired,
      ),
    ],
  ),
  (
    name: 'register link',
    description: 'Register link should be visible',
    steps: [
      RenderStep('loginForm'),
      AssertExistsStep(testIdRegisterLink),
    ],
  ),
];

// =============================================================================
// Register Form Scenarios
// =============================================================================

final registerFormScenarios = <TestScenario>[
  (
    name: 'empty form',
    description: 'Register form should render with empty inputs',
    steps: [
      RenderStep('registerForm'),
      AssertValueStep(testIdNameInput, ''),
      AssertValueStep(testIdEmailInput, ''),
      AssertValueStep(testIdPasswordInput, ''),
    ],
  ),
  (
    name: 'name input',
    description: 'Name input should update when typing',
    steps: [
      RenderStep('registerForm'),
      TypeStep(testIdNameInput, 'John Doe'),
      AssertValueStep(testIdNameInput, 'John Doe'),
    ],
  ),
  (
    name: 'empty submit error',
    description: 'Register should show error when submitted empty',
    steps: [
      RenderStep('registerForm'),
      PressStep(testIdSubmitBtn),
      AssertExistsStep(
        testIdErrorMessage,
        expectedText: errorMessageAllFieldsRequired,
      ),
    ],
  ),
  (
    name: 'partial submit - missing password',
    description: 'Register should show error when password missing',
    steps: [
      RenderStep('registerForm'),
      TypeStep(testIdNameInput, 'John'),
      TypeStep(testIdEmailInput, 'john@example.com'),
      PressStep(testIdSubmitBtn),
      AssertExistsStep(
        testIdErrorMessage,
        expectedText: errorMessageAllFieldsRequired,
      ),
    ],
  ),
  (
    name: 'login link',
    description: 'Login link should be visible',
    steps: [
      RenderStep('registerForm'),
      AssertExistsStep(testIdLoginLink),
    ],
  ),
];

// =============================================================================
// Task Manager Scenarios
// =============================================================================

final taskManagerScenarios = <TestScenario>[
  (
    name: 'empty state',
    description: 'Task manager should show empty state initially',
    steps: [
      RenderStep('taskManager'),
      AssertExistsStep(testIdEmptyState, expectedText: textPatternNoTasks),
      AssertExistsStep(testIdTaskStats, expectedText: '0/0 completed'),
    ],
  ),
  (
    name: 'add task',
    description: 'Task manager should add task when add button pressed',
    steps: [
      RenderStep('taskManager'),
      TypeStep(testIdNewTaskInput, 'New task'),
      PressStep(testIdAddTaskBtn),
      AssertExistsStep(testIdTaskItem(0), expectedText: 'New task'),
      AssertNotExistsStep(testIdEmptyState),
    ],
  ),
  (
    name: 'clear input after add',
    description: 'Input should be cleared after adding task',
    steps: [
      RenderStep('taskManager'),
      TypeStep(testIdNewTaskInput, 'Test task'),
      PressStep(testIdAddTaskBtn),
      AssertValueStep(testIdNewTaskInput, ''),
    ],
  ),
  (
    name: 'no empty tasks',
    description: 'Task manager should not add empty tasks',
    steps: [
      RenderStep('taskManager'),
      PressStep(testIdAddTaskBtn),
      AssertExistsStep(testIdEmptyState),
    ],
  ),
  (
    name: 'toggle task',
    description: 'Task should toggle completed state',
    steps: [
      RenderStep('taskManager'),
      TypeStep(testIdNewTaskInput, 'Toggle me'),
      PressStep(testIdAddTaskBtn),
      PressStep(testIdToggleTask(0)),
      AssertExistsStep(testIdTaskStats, expectedText: '1/1 completed'),
    ],
  ),
  (
    name: 'delete task',
    description: 'Task should be removed when delete pressed',
    steps: [
      RenderStep('taskManager'),
      TypeStep(testIdNewTaskInput, 'Delete me'),
      PressStep(testIdAddTaskBtn),
      AssertExistsStep(testIdTaskItem(0)),
      PressStep(testIdDeleteTask(0)),
      AssertNotExistsStep(testIdTaskItem(0)),
      AssertExistsStep(testIdEmptyState),
    ],
  ),
];

// =============================================================================
// Header Scenarios
// =============================================================================

final headerScenarios = <TestScenario>[
  (
    name: 'logged out',
    description: 'Header should not show user info when logged out',
    steps: [
      RenderStep('header'),
      AssertNotExistsStep(testIdUserName),
      AssertNotExistsStep(testIdLogoutBtn),
    ],
  ),
  (
    name: 'logged in',
    description: 'Header should show user name when logged in',
    steps: [
      RenderStep('headerWithUser'),
      AssertExistsStep(testIdUserName, expectedText: 'Welcome, John'),
      AssertExistsStep(testIdLogoutBtn),
    ],
  ),
];
