/**
 * UI Tests for Mobile App Components
 *
 * Test components are defined in Dart (ui_test.dart) and compiled to JS.
 * This file loads the compiled Dart code and runs Jest tests against it.
 */

const { render, fireEvent, waitFor } = require('@testing-library/react-native');

// Make testing library available globally for Dart interop
global.rnTestingLibrary = { render, fireEvent, waitFor };
globalThis.rnTestingLibrary = global.rnTestingLibrary;

// Load compiled Dart code
require('./dist/ui_test.js');

// Get exported Dart components
const {
  loginScreenComponent,
  registerScreenComponent,
  taskListComponent,
  headerComponent,
} = global.mobileAppTests;

// =============================================================================
// Login Screen Tests
// =============================================================================

describe('Login Screen', () => {
  test('renders with empty inputs', () => {
    const { getByTestId } = render(loginScreenComponent(null, null));

    const emailInput = getByTestId('email-input');
    const passwordInput = getByTestId('password-input');

    expect(emailInput.props.value).toBe('');
    expect(passwordInput.props.value).toBe('');
  });

  test('updates email input when typing', () => {
    const { getByTestId } = render(loginScreenComponent(null, null));

    const emailInput = getByTestId('email-input');
    fireEvent.changeText(emailInput, 'test@example.com');

    expect(emailInput.props.value).toBe('test@example.com');
  });

  test('updates password input when typing', () => {
    const { getByTestId } = render(loginScreenComponent(null, null));

    const passwordInput = getByTestId('password-input');
    fireEvent.changeText(passwordInput, 'secret123');

    expect(passwordInput.props.value).toBe('secret123');
  });

  test('shows error when submitting empty form', () => {
    const { getByTestId, getByText } = render(loginScreenComponent(null, null));

    const submitBtn = getByTestId('submit-btn');
    fireEvent.press(submitBtn);

    const errorMessage = getByTestId('error-message');
    expect(errorMessage).toBeTruthy();
    expect(getByText('All fields required')).toBeTruthy();
  });

  test('shows error when only email is filled', () => {
    const { getByTestId, getByText } = render(loginScreenComponent(null, null));

    const emailInput = getByTestId('email-input');
    const submitBtn = getByTestId('submit-btn');

    fireEvent.changeText(emailInput, 'test@example.com');
    fireEvent.press(submitBtn);

    expect(getByText('All fields required')).toBeTruthy();
  });

  test('calls onSubmit callback with credentials', () => {
    const onSubmit = jest.fn();
    const { getByTestId } = render(loginScreenComponent(onSubmit, null));

    const emailInput = getByTestId('email-input');
    const passwordInput = getByTestId('password-input');
    const submitBtn = getByTestId('submit-btn');

    fireEvent.changeText(emailInput, 'user@test.com');
    fireEvent.changeText(passwordInput, 'password123');
    fireEvent.press(submitBtn);

    expect(onSubmit).toHaveBeenCalledWith('user@test.com', 'password123');
  });

  test('register link is visible', () => {
    const { getByTestId } = render(loginScreenComponent(null, null));

    const registerLink = getByTestId('register-link');
    expect(registerLink).toBeTruthy();
  });

  test('register link calls callback when pressed', () => {
    const onRegisterClick = jest.fn();
    const { getByTestId } = render(loginScreenComponent(null, onRegisterClick));

    const registerLink = getByTestId('register-link');
    fireEvent.press(registerLink);

    expect(onRegisterClick).toHaveBeenCalled();
  });
});

// =============================================================================
// Register Screen Tests
// =============================================================================

describe('Register Screen', () => {
  test('renders with empty inputs', () => {
    const { getByTestId } = render(registerScreenComponent(null, null));

    const nameInput = getByTestId('name-input');
    const emailInput = getByTestId('email-input');
    const passwordInput = getByTestId('password-input');

    expect(nameInput.props.value).toBe('');
    expect(emailInput.props.value).toBe('');
    expect(passwordInput.props.value).toBe('');
  });

  test('updates name input when typing', () => {
    const { getByTestId } = render(registerScreenComponent(null, null));

    const nameInput = getByTestId('name-input');
    fireEvent.changeText(nameInput, 'John Doe');

    expect(nameInput.props.value).toBe('John Doe');
  });

  test('shows error when submitting empty form', () => {
    const { getByTestId, getByText } = render(registerScreenComponent(null, null));

    const submitBtn = getByTestId('submit-btn');
    fireEvent.press(submitBtn);

    expect(getByText('All fields required')).toBeTruthy();
  });

  test('shows error when missing password', () => {
    const { getByTestId, getByText } = render(registerScreenComponent(null, null));

    const nameInput = getByTestId('name-input');
    const emailInput = getByTestId('email-input');
    const submitBtn = getByTestId('submit-btn');

    fireEvent.changeText(nameInput, 'John');
    fireEvent.changeText(emailInput, 'john@example.com');
    fireEvent.press(submitBtn);

    expect(getByText('All fields required')).toBeTruthy();
  });

  test('calls onSubmit callback with form data', () => {
    const onSubmit = jest.fn();
    const { getByTestId } = render(registerScreenComponent(onSubmit, null));

    const nameInput = getByTestId('name-input');
    const emailInput = getByTestId('email-input');
    const passwordInput = getByTestId('password-input');
    const submitBtn = getByTestId('submit-btn');

    fireEvent.changeText(nameInput, 'John Doe');
    fireEvent.changeText(emailInput, 'john@example.com');
    fireEvent.changeText(passwordInput, 'secret123');
    fireEvent.press(submitBtn);

    expect(onSubmit).toHaveBeenCalledWith('John Doe', 'john@example.com', 'secret123');
  });

  test('login link is visible', () => {
    const { getByTestId } = render(registerScreenComponent(null, null));

    const loginLink = getByTestId('login-link');
    expect(loginLink).toBeTruthy();
  });
});

// =============================================================================
// Task List Tests
// =============================================================================

describe('Task List', () => {
  test('shows empty state initially', () => {
    const { getByTestId, getByText } = render(taskListComponent(null));

    const emptyState = getByTestId('empty-state');
    expect(emptyState).toBeTruthy();
    expect(getByText('No tasks yet')).toBeTruthy();

    const taskStats = getByTestId('task-stats');
    expect(taskStats).toHaveTextContent('0/0 completed');
  });

  test('adds task when add button pressed', () => {
    const { getByTestId, getByText, queryByTestId } = render(taskListComponent(null));

    const input = getByTestId('new-task-input');
    const addBtn = getByTestId('add-task-btn');

    fireEvent.changeText(input, 'New task');
    fireEvent.press(addBtn);

    const taskItem = getByTestId('task-item-0');
    expect(taskItem).toBeTruthy();
    expect(getByText('New task')).toBeTruthy();

    expect(queryByTestId('empty-state')).toBeNull();
  });

  test('clears input after adding task', () => {
    const { getByTestId } = render(taskListComponent(null));

    const input = getByTestId('new-task-input');
    const addBtn = getByTestId('add-task-btn');

    fireEvent.changeText(input, 'Test task');
    fireEvent.press(addBtn);

    expect(input.props.value).toBe('');
  });

  test('does not add empty tasks', () => {
    const { getByTestId } = render(taskListComponent(null));

    const addBtn = getByTestId('add-task-btn');
    fireEvent.press(addBtn);

    expect(getByTestId('empty-state')).toBeTruthy();
  });

  test('toggles task completion', () => {
    const { getByTestId } = render(taskListComponent(null));

    const input = getByTestId('new-task-input');
    const addBtn = getByTestId('add-task-btn');

    fireEvent.changeText(input, 'Toggle me');
    fireEvent.press(addBtn);

    const toggleBtn = getByTestId('toggle-task-0');
    fireEvent.press(toggleBtn);

    const taskStats = getByTestId('task-stats');
    expect(taskStats).toHaveTextContent('1/1 completed');
  });

  test('deletes task when delete pressed', () => {
    const { getByTestId, queryByTestId } = render(taskListComponent(null));

    const input = getByTestId('new-task-input');
    const addBtn = getByTestId('add-task-btn');

    fireEvent.changeText(input, 'Delete me');
    fireEvent.press(addBtn);

    expect(getByTestId('task-item-0')).toBeTruthy();

    const deleteBtn = getByTestId('delete-task-0');
    fireEvent.press(deleteBtn);

    expect(queryByTestId('task-item-0')).toBeNull();
    expect(getByTestId('empty-state')).toBeTruthy();
  });

  test('renders with initial tasks', () => {
    const initialTasks = [
      { id: '1', title: 'Task 1', completed: false },
      { id: '2', title: 'Task 2', completed: true },
    ];

    const { getByTestId, getByText } = render(taskListComponent(initialTasks));

    expect(getByTestId('task-item-0')).toBeTruthy();
    expect(getByTestId('task-item-1')).toBeTruthy();
    expect(getByText('Task 1')).toBeTruthy();
    expect(getByText('Task 2')).toBeTruthy();

    const taskStats = getByTestId('task-stats');
    expect(taskStats).toHaveTextContent('1/2 completed');
  });
});

// =============================================================================
// Header Tests
// =============================================================================

describe('Header', () => {
  test('does not show user info when logged out', () => {
    const { queryByTestId } = render(headerComponent(null, null));

    expect(queryByTestId('user-name')).toBeNull();
    expect(queryByTestId('logout-btn')).toBeNull();
  });

  test('shows user name when logged in', () => {
    const { getByTestId } = render(headerComponent('John', null));

    const userName = getByTestId('user-name');
    expect(userName).toHaveTextContent('Welcome, John');

    expect(getByTestId('logout-btn')).toBeTruthy();
  });

  test('calls logout callback when logout pressed', () => {
    const onLogout = jest.fn();
    const { getByTestId } = render(headerComponent('John', onLogout));

    const logoutBtn = getByTestId('logout-btn');
    fireEvent.press(logoutBtn);

    expect(onLogout).toHaveBeenCalled();
  });
});
