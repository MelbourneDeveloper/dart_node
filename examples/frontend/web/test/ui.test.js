/**
 * UI Tests for Frontend Web Components
 *
 * Test components are defined in Dart (ui_test.dart) and compiled to JS.
 * This file loads the compiled Dart code and runs Jest tests against it.
 */

const { render, screen, fireEvent, waitFor } = require('@testing-library/react');
const userEvent = require('@testing-library/user-event').default;

// Make testing library available globally for Dart interop
global.testingLibrary = { render, screen, fireEvent, waitFor };
global.userEvent = userEvent;

// Load compiled Dart code
require('./dist/ui_test.js');

// Get exported Dart components and scenarios
const {
  loginFormComponent,
  registerFormComponent,
  taskManagerComponent,
  headerComponent,
} = global.frontendWebTests;

// =============================================================================
// Login Form Tests
// =============================================================================

describe('Login Form', () => {
  test('renders with empty inputs', () => {
    render(loginFormComponent(null, null));

    const emailInput = screen.getByTestId('email-input');
    const passwordInput = screen.getByTestId('password-input');

    expect(emailInput).toHaveValue('');
    expect(passwordInput).toHaveValue('');
  });

  test('updates email input when typing', async () => {
    const user = userEvent.setup();
    render(loginFormComponent(null, null));

    const emailInput = screen.getByTestId('email-input');
    await user.type(emailInput, 'test@example.com');

    expect(emailInput).toHaveValue('test@example.com');
  });

  test('updates password input when typing', async () => {
    const user = userEvent.setup();
    render(loginFormComponent(null, null));

    const passwordInput = screen.getByTestId('password-input');
    await user.type(passwordInput, 'secret123');

    expect(passwordInput).toHaveValue('secret123');
  });

  test('shows error when submitting empty form', async () => {
    const user = userEvent.setup();
    render(loginFormComponent(null, null));

    const submitBtn = screen.getByTestId('submit-btn');
    await user.click(submitBtn);

    const errorMessage = screen.getByTestId('error-message');
    expect(errorMessage).toHaveTextContent('All fields required');
  });

  test('shows error when only email is filled', async () => {
    const user = userEvent.setup();
    render(loginFormComponent(null, null));

    const emailInput = screen.getByTestId('email-input');
    const submitBtn = screen.getByTestId('submit-btn');

    await user.type(emailInput, 'test@example.com');
    await user.click(submitBtn);

    const errorMessage = screen.getByTestId('error-message');
    expect(errorMessage).toHaveTextContent('All fields required');
  });

  test('calls onSubmit callback with credentials', async () => {
    const user = userEvent.setup();
    const onSubmit = jest.fn();

    render(loginFormComponent(onSubmit, null));

    const emailInput = screen.getByTestId('email-input');
    const passwordInput = screen.getByTestId('password-input');
    const submitBtn = screen.getByTestId('submit-btn');

    await user.type(emailInput, 'user@test.com');
    await user.type(passwordInput, 'password123');
    await user.click(submitBtn);

    expect(onSubmit).toHaveBeenCalledWith('user@test.com', 'password123');
  });

  test('register link is visible', () => {
    render(loginFormComponent(null, null));

    const registerLink = screen.getByTestId('register-link');
    expect(registerLink).toBeInTheDocument();
  });

  test('register link calls callback when clicked', async () => {
    const user = userEvent.setup();
    const onRegisterClick = jest.fn();

    render(loginFormComponent(null, onRegisterClick));

    const registerLink = screen.getByTestId('register-link');
    await user.click(registerLink);

    expect(onRegisterClick).toHaveBeenCalled();
  });
});

// =============================================================================
// Register Form Tests
// =============================================================================

describe('Register Form', () => {
  test('renders with empty inputs', () => {
    render(registerFormComponent(null, null));

    const nameInput = screen.getByTestId('name-input');
    const emailInput = screen.getByTestId('email-input');
    const passwordInput = screen.getByTestId('password-input');

    expect(nameInput).toHaveValue('');
    expect(emailInput).toHaveValue('');
    expect(passwordInput).toHaveValue('');
  });

  test('updates name input when typing', async () => {
    const user = userEvent.setup();
    render(registerFormComponent(null, null));

    const nameInput = screen.getByTestId('name-input');
    await user.type(nameInput, 'John Doe');

    expect(nameInput).toHaveValue('John Doe');
  });

  test('shows error when submitting empty form', async () => {
    const user = userEvent.setup();
    render(registerFormComponent(null, null));

    const submitBtn = screen.getByTestId('submit-btn');
    await user.click(submitBtn);

    const errorMessage = screen.getByTestId('error-message');
    expect(errorMessage).toHaveTextContent('All fields required');
  });

  test('shows error when missing password', async () => {
    const user = userEvent.setup();
    render(registerFormComponent(null, null));

    const nameInput = screen.getByTestId('name-input');
    const emailInput = screen.getByTestId('email-input');
    const submitBtn = screen.getByTestId('submit-btn');

    await user.type(nameInput, 'John');
    await user.type(emailInput, 'john@example.com');
    await user.click(submitBtn);

    const errorMessage = screen.getByTestId('error-message');
    expect(errorMessage).toHaveTextContent('All fields required');
  });

  test('calls onSubmit callback with form data', async () => {
    const user = userEvent.setup();
    const onSubmit = jest.fn();

    render(registerFormComponent(onSubmit, null));

    const nameInput = screen.getByTestId('name-input');
    const emailInput = screen.getByTestId('email-input');
    const passwordInput = screen.getByTestId('password-input');
    const submitBtn = screen.getByTestId('submit-btn');

    await user.type(nameInput, 'John Doe');
    await user.type(emailInput, 'john@example.com');
    await user.type(passwordInput, 'secret123');
    await user.click(submitBtn);

    expect(onSubmit).toHaveBeenCalledWith('John Doe', 'john@example.com', 'secret123');
  });

  test('login link is visible', () => {
    render(registerFormComponent(null, null));

    const loginLink = screen.getByTestId('login-link');
    expect(loginLink).toBeInTheDocument();
  });
});

// =============================================================================
// Task Manager Tests
// =============================================================================

describe('Task Manager', () => {
  test('shows empty state initially', () => {
    render(taskManagerComponent(null));

    const emptyState = screen.getByTestId('empty-state');
    expect(emptyState).toHaveTextContent('No tasks yet');

    const taskStats = screen.getByTestId('task-stats');
    expect(taskStats).toHaveTextContent('0/0 completed');
  });

  test('adds task when add button pressed', async () => {
    const user = userEvent.setup();
    render(taskManagerComponent(null));

    const input = screen.getByTestId('new-task-input');
    const addBtn = screen.getByTestId('add-task-btn');

    await user.type(input, 'New task');
    await user.click(addBtn);

    const taskItem = screen.getByTestId('task-item-0');
    expect(taskItem).toHaveTextContent('New task');

    expect(screen.queryByTestId('empty-state')).not.toBeInTheDocument();
  });

  test('clears input after adding task', async () => {
    const user = userEvent.setup();
    render(taskManagerComponent(null));

    const input = screen.getByTestId('new-task-input');
    const addBtn = screen.getByTestId('add-task-btn');

    await user.type(input, 'Test task');
    await user.click(addBtn);

    expect(input).toHaveValue('');
  });

  test('does not add empty tasks', async () => {
    const user = userEvent.setup();
    render(taskManagerComponent(null));

    const addBtn = screen.getByTestId('add-task-btn');
    await user.click(addBtn);

    expect(screen.getByTestId('empty-state')).toBeInTheDocument();
  });

  test('toggles task completion', async () => {
    const user = userEvent.setup();
    render(taskManagerComponent(null));

    const input = screen.getByTestId('new-task-input');
    const addBtn = screen.getByTestId('add-task-btn');

    await user.type(input, 'Toggle me');
    await user.click(addBtn);

    const toggleBtn = screen.getByTestId('toggle-task-0');
    await user.click(toggleBtn);

    const taskStats = screen.getByTestId('task-stats');
    expect(taskStats).toHaveTextContent('1/1 completed');
  });

  test('deletes task when delete pressed', async () => {
    const user = userEvent.setup();
    render(taskManagerComponent(null));

    const input = screen.getByTestId('new-task-input');
    const addBtn = screen.getByTestId('add-task-btn');

    await user.type(input, 'Delete me');
    await user.click(addBtn);

    expect(screen.getByTestId('task-item-0')).toBeInTheDocument();

    const deleteBtn = screen.getByTestId('delete-task-0');
    await user.click(deleteBtn);

    expect(screen.queryByTestId('task-item-0')).not.toBeInTheDocument();
    expect(screen.getByTestId('empty-state')).toBeInTheDocument();
  });

  test('renders with initial tasks', () => {
    const initialTasks = [
      { id: '1', title: 'Task 1', completed: false },
      { id: '2', title: 'Task 2', completed: true },
    ];

    render(taskManagerComponent(initialTasks));

    expect(screen.getByTestId('task-item-0')).toHaveTextContent('Task 1');
    expect(screen.getByTestId('task-item-1')).toHaveTextContent('Task 2');

    const taskStats = screen.getByTestId('task-stats');
    expect(taskStats).toHaveTextContent('1/2 completed');
  });
});

// =============================================================================
// Header Tests
// =============================================================================

describe('Header', () => {
  test('does not show user info when logged out', () => {
    render(headerComponent(null, null));

    expect(screen.queryByTestId('user-name')).not.toBeInTheDocument();
    expect(screen.queryByTestId('logout-btn')).not.toBeInTheDocument();
  });

  test('shows user name when logged in', () => {
    render(headerComponent('John', null));

    const userName = screen.getByTestId('user-name');
    expect(userName).toHaveTextContent('Welcome, John');

    expect(screen.getByTestId('logout-btn')).toBeInTheDocument();
  });

  test('calls logout callback when logout clicked', async () => {
    const user = userEvent.setup();
    const onLogout = jest.fn();

    render(headerComponent('John', onLogout));

    const logoutBtn = screen.getByTestId('logout-btn');
    await user.click(logoutBtn);

    expect(onLogout).toHaveBeenCalled();
  });
});
