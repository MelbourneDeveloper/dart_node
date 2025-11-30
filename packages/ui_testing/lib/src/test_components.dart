/// Shared test component definitions for React and React Native
///
/// These define the component structure and behavior that is tested
/// across both platforms. The actual rendering differs by platform.
library;

import 'dart:js_interop';

/// State management types for test components
typedef StateValue<T> = (JSAny?, JSFunction);

/// Function to update state with a new value
typedef SetState<T> = void Function(T);

/// Helper to extract string from JSAny state
String stringFromState(JSAny? state) => (state as JSString?)?.toDart ?? '';

/// Helper to extract int from JSAny state
int intFromState(JSAny? state) => (state as JSNumber?)?.toDartInt ?? 0;

/// Helper to extract bool from JSAny state
bool boolFromState(JSAny? state) => (state as JSBoolean?)?.toDart ?? false;

/// Helper to extract list from JSAny state
List<JSAny?> listFromState(JSAny? state) => (state as JSArray?)?.toDart ?? [];

/// Wrap setState for type-safe updates
SetState<T> wrapSetState<T>(JSFunction setState) => (value) {
  final jsValue = switch (value) {
    final String s => s.toJS,
    final int i => i.toJS,
    final double d => d.toJS,
    final bool b => b.toJS,
    null => null,
    _ => (value as Object).jsify(),
  };
  setState.callAsFunction(null, jsValue);
};

/// Form submission callback type
typedef OnFormSubmit = void Function(String email, String password);

// =============================================================================
// Test IDs used across platforms
// =============================================================================

/// Counter component container test ID
const testIdCounterContainer = 'counter-container';

/// Count display element test ID
const testIdCountDisplay = 'count-display';

/// Increment button test ID
const testIdIncrementBtn = 'increment-btn';

/// Decrement button test ID
const testIdDecrementBtn = 'decrement-btn';

/// Reset button test ID
const testIdResetBtn = 'reset-btn';

/// Form component container test ID
const testIdFormContainer = 'form-container';

/// Email input field test ID
const testIdEmailInput = 'email-input';

/// Password input field test ID
const testIdPasswordInput = 'password-input';

/// Submit button test ID
const testIdSubmitBtn = 'submit-btn';

/// Error message display test ID
const testIdErrorMessage = 'error-message';

/// Success message display test ID
const testIdSuccessMessage = 'success-message';

/// Toggle component container test ID
const testIdToggleContainer = 'toggle-container';

/// Toggle status display test ID
const testIdToggleStatus = 'toggle-status';

/// Toggle button test ID
const testIdToggleBtn = 'toggle-btn';

/// List component container test ID
const testIdListContainer = 'list-container';

/// Add item input field test ID
const testIdAddItemInput = 'add-item-input';

/// Add item button test ID
const testIdAddItemBtn = 'add-item-btn';

/// Items list container test ID
const testIdItemsList = 'items-list';

/// Empty message display test ID
const testIdEmptyMessage = 'empty-message';

/// Items count display test ID
const testIdItemsCount = 'items-count';

/// Generate list item test ID
String testIdListItem(int index) => 'list-item-$index';

/// Generate remove button test ID
String testIdRemoveBtn(int index) => 'remove-btn-$index';

/// Switch component container test ID
const testIdSwitchContainer = 'switch-container';

/// Switch status display test ID
const testIdSwitchStatus = 'switch-status';

/// Switch control element test ID
const testIdSwitchControl = 'switch-control';

/// Loading component container test ID
const testIdLoadingContainer = 'loading-container';

/// Loading indicator test ID
const testIdLoadingIndicator = 'loading-indicator';

/// Loaded content display test ID
const testIdLoadedContent = 'loaded-content';

/// Toggle loading button test ID
const testIdToggleLoadingBtn = 'toggle-loading-btn';

// =============================================================================
// Error messages used in validation
// =============================================================================

/// All fields required error message
const errorMessageAllFieldsRequired = 'All fields required';

/// Form submitted success message
const errorMessageFormSubmitted = 'Form submitted!';

// =============================================================================
// Text content patterns
// =============================================================================

/// Generate count text pattern
String textPatternCount(int value) => 'Count: $value';

/// Generate total text pattern
String textPatternTotal(int value) => 'Total: $value';

/// ON text pattern
const textPatternOn = 'ON';

/// OFF text pattern
const textPatternOff = 'OFF';

/// Enabled text pattern
const textPatternEnabled = 'Enabled';

/// Disabled text pattern
const textPatternDisabled = 'Disabled';

/// No items text pattern
const textPatternNoItems = 'No items';

/// Content loaded text pattern
const textPatternContentLoaded = 'Content loaded';

/// No tasks text pattern
const textPatternNoTasks = 'No tasks yet';

// =============================================================================
// Login Form Test IDs
// =============================================================================

/// Login form container test ID
const testIdLoginForm = 'login-form';

/// Register link button test ID
const testIdRegisterLink = 'register-link';

// =============================================================================
// Register Form Test IDs
// =============================================================================

/// Register form container test ID
const testIdRegisterForm = 'register-form';

/// Name input field test ID
const testIdNameInput = 'name-input';

/// Login link button test ID
const testIdLoginLink = 'login-link';

// =============================================================================
// Task Manager Test IDs
// =============================================================================

/// Task manager container test ID
const testIdTaskManager = 'task-manager';

/// Task stats display test ID
const testIdTaskStats = 'task-stats';

/// New task input field test ID
const testIdNewTaskInput = 'new-task-input';

/// Add task button test ID
const testIdAddTaskBtn = 'add-task-btn';

/// Task list container test ID
const testIdTaskList = 'task-list';

/// Empty state display test ID
const testIdEmptyState = 'empty-state';

/// Generate task item test ID
String testIdTaskItem(int index) => 'task-item-$index';

/// Generate toggle task test ID
String testIdToggleTask(int index) => 'toggle-task-$index';

/// Generate task title test ID
String testIdTaskTitle(int index) => 'task-title-$index';

/// Generate delete task button test ID
String testIdDeleteTask(int index) => 'delete-task-$index';

// =============================================================================
// Header Test IDs
// =============================================================================

/// App header container test ID
const testIdAppHeader = 'app-header';

/// User name display test ID
const testIdUserName = 'user-name';

/// Logout button test ID
const testIdLogoutBtn = 'logout-btn';
