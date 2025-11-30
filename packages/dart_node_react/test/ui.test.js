/**
 * UI Interaction Tests for Dart React Components
 * Uses React Testing Library for real DOM testing
 */

const { render, screen, fireEvent, waitFor } = require('@testing-library/react');
const userEvent = require('@testing-library/user-event').default;

// Make testing library available globally for Dart interop
global.testingLibrary = { render, screen, fireEvent, waitFor };
global.userEvent = userEvent;

// Load compiled Dart code
require('./dist/ui_test.js');

// Get exported Dart components
const {
  counterComponent,
  formComponent,
  toggleComponent,
  listComponent,
} = global.dartReactTests;

// =============================================================================
// Counter Component Tests
// =============================================================================

describe('Counter Component', () => {
  test('renders with initial count of 0', () => {
    render(counterComponent());

    const display = screen.getByTestId('count-display');
    expect(display).toHaveTextContent('Count: 0');
  });

  test('increments count when increment button clicked', async () => {
    const user = userEvent.setup();
    render(counterComponent());

    const incrementBtn = screen.getByTestId('increment-btn');
    const display = screen.getByTestId('count-display');

    await user.click(incrementBtn);
    expect(display).toHaveTextContent('Count: 1');

    await user.click(incrementBtn);
    expect(display).toHaveTextContent('Count: 2');

    await user.click(incrementBtn);
    expect(display).toHaveTextContent('Count: 3');
  });

  test('decrements count when decrement button clicked', async () => {
    const user = userEvent.setup();
    render(counterComponent());

    const decrementBtn = screen.getByTestId('decrement-btn');
    const display = screen.getByTestId('count-display');

    await user.click(decrementBtn);
    expect(display).toHaveTextContent('Count: -1');

    await user.click(decrementBtn);
    expect(display).toHaveTextContent('Count: -2');
  });

  test('resets count to 0 when reset button clicked', async () => {
    const user = userEvent.setup();
    render(counterComponent());

    const incrementBtn = screen.getByTestId('increment-btn');
    const resetBtn = screen.getByTestId('reset-btn');
    const display = screen.getByTestId('count-display');

    // Increment a few times
    await user.click(incrementBtn);
    await user.click(incrementBtn);
    await user.click(incrementBtn);
    expect(display).toHaveTextContent('Count: 3');

    // Reset
    await user.click(resetBtn);
    expect(display).toHaveTextContent('Count: 0');
  });

  test('handles rapid clicks correctly', async () => {
    const user = userEvent.setup();
    render(counterComponent());

    const incrementBtn = screen.getByTestId('increment-btn');
    const display = screen.getByTestId('count-display');

    // Rapid clicks
    for (let i = 0; i < 10; i++) {
      await user.click(incrementBtn);
    }

    expect(display).toHaveTextContent('Count: 10');
  });
});

// =============================================================================
// Form Component Tests
// =============================================================================

describe('Form Component', () => {
  test('renders empty form inputs', () => {
    render(formComponent(null));

    const emailInput = screen.getByTestId('email-input');
    const passwordInput = screen.getByTestId('password-input');

    expect(emailInput).toHaveValue('');
    expect(passwordInput).toHaveValue('');
  });

  test('updates email input when typing', async () => {
    const user = userEvent.setup();
    render(formComponent(null));

    const emailInput = screen.getByTestId('email-input');

    await user.type(emailInput, 'test@example.com');
    expect(emailInput).toHaveValue('test@example.com');
  });

  test('updates password input when typing', async () => {
    const user = userEvent.setup();
    render(formComponent(null));

    const passwordInput = screen.getByTestId('password-input');

    await user.type(passwordInput, 'secretpass123');
    expect(passwordInput).toHaveValue('secretpass123');
  });

  test('shows error when submitting empty form', async () => {
    const user = userEvent.setup();
    render(formComponent(null));

    const submitBtn = screen.getByTestId('submit-btn');

    await user.click(submitBtn);

    const errorMessage = screen.getByTestId('error-message');
    expect(errorMessage).toHaveTextContent('All fields required');
  });

  test('shows error when only email is filled', async () => {
    const user = userEvent.setup();
    render(formComponent(null));

    const emailInput = screen.getByTestId('email-input');
    const submitBtn = screen.getByTestId('submit-btn');

    await user.type(emailInput, 'test@example.com');
    await user.click(submitBtn);

    const errorMessage = screen.getByTestId('error-message');
    expect(errorMessage).toHaveTextContent('All fields required');
  });

  test('shows error when only password is filled', async () => {
    const user = userEvent.setup();
    render(formComponent(null));

    const passwordInput = screen.getByTestId('password-input');
    const submitBtn = screen.getByTestId('submit-btn');

    await user.type(passwordInput, 'secret123');
    await user.click(submitBtn);

    const errorMessage = screen.getByTestId('error-message');
    expect(errorMessage).toHaveTextContent('All fields required');
  });

  test('shows success message when form is valid', async () => {
    const user = userEvent.setup();
    render(formComponent(null));

    const emailInput = screen.getByTestId('email-input');
    const passwordInput = screen.getByTestId('password-input');
    const submitBtn = screen.getByTestId('submit-btn');

    await user.type(emailInput, 'test@example.com');
    await user.type(passwordInput, 'secret123');
    await user.click(submitBtn);

    const successMessage = screen.getByTestId('success-message');
    expect(successMessage).toHaveTextContent('Form submitted!');

    // Error should not be visible
    expect(screen.queryByTestId('error-message')).not.toBeInTheDocument();
  });

  test('calls onSubmit callback with form values', async () => {
    const user = userEvent.setup();
    const onSubmit = jest.fn();

    render(formComponent(onSubmit));

    const emailInput = screen.getByTestId('email-input');
    const passwordInput = screen.getByTestId('password-input');
    const submitBtn = screen.getByTestId('submit-btn');

    await user.type(emailInput, 'user@test.com');
    await user.type(passwordInput, 'mypassword');
    await user.click(submitBtn);

    expect(onSubmit).toHaveBeenCalledTimes(1);
    expect(onSubmit).toHaveBeenCalledWith('user@test.com', 'mypassword');
  });

  test('clears error when valid form is submitted', async () => {
    const user = userEvent.setup();
    render(formComponent(null));

    const emailInput = screen.getByTestId('email-input');
    const passwordInput = screen.getByTestId('password-input');
    const submitBtn = screen.getByTestId('submit-btn');

    // First submit empty form to show error
    await user.click(submitBtn);
    expect(screen.getByTestId('error-message')).toBeInTheDocument();

    // Now fill and submit
    await user.type(emailInput, 'test@example.com');
    await user.type(passwordInput, 'password123');
    await user.click(submitBtn);

    // Error should be gone, success should show
    expect(screen.queryByTestId('error-message')).not.toBeInTheDocument();
    expect(screen.getByTestId('success-message')).toBeInTheDocument();
  });
});

// =============================================================================
// Toggle Component Tests
// =============================================================================

describe('Toggle Component', () => {
  test('renders with OFF state initially', () => {
    render(toggleComponent());

    const status = screen.getByTestId('toggle-status');
    expect(status).toHaveTextContent('OFF');
  });

  test('toggles to ON when button clicked', async () => {
    const user = userEvent.setup();
    render(toggleComponent());

    const toggleBtn = screen.getByTestId('toggle-btn');
    const status = screen.getByTestId('toggle-status');

    await user.click(toggleBtn);
    expect(status).toHaveTextContent('ON');
  });

  test('toggles back to OFF when clicked again', async () => {
    const user = userEvent.setup();
    render(toggleComponent());

    const toggleBtn = screen.getByTestId('toggle-btn');
    const status = screen.getByTestId('toggle-status');

    await user.click(toggleBtn);
    expect(status).toHaveTextContent('ON');

    await user.click(toggleBtn);
    expect(status).toHaveTextContent('OFF');
  });

  test('handles multiple toggles correctly', async () => {
    const user = userEvent.setup();
    render(toggleComponent());

    const toggleBtn = screen.getByTestId('toggle-btn');
    const status = screen.getByTestId('toggle-status');

    // Toggle 5 times
    await user.click(toggleBtn); // ON
    expect(status).toHaveTextContent('ON');

    await user.click(toggleBtn); // OFF
    expect(status).toHaveTextContent('OFF');

    await user.click(toggleBtn); // ON
    expect(status).toHaveTextContent('ON');

    await user.click(toggleBtn); // OFF
    expect(status).toHaveTextContent('OFF');

    await user.click(toggleBtn); // ON
    expect(status).toHaveTextContent('ON');
  });
});

// =============================================================================
// List Component Tests
// =============================================================================

describe('List Component', () => {
  test('renders empty list with message', () => {
    render(listComponent());

    const emptyMessage = screen.getByTestId('empty-message');
    expect(emptyMessage).toHaveTextContent('No items');

    const count = screen.getByTestId('items-count');
    expect(count).toHaveTextContent('Total: 0');
  });

  test('adds item to list when add button clicked', async () => {
    const user = userEvent.setup();
    render(listComponent());

    const input = screen.getByTestId('add-item-input');
    const addBtn = screen.getByTestId('add-item-btn');

    await user.type(input, 'First item');
    await user.click(addBtn);

    const item = screen.getByTestId('list-item-0');
    expect(item).toHaveTextContent('First item');

    const count = screen.getByTestId('items-count');
    expect(count).toHaveTextContent('Total: 1');

    // Empty message should be gone
    expect(screen.queryByTestId('empty-message')).not.toBeInTheDocument();
  });

  test('clears input after adding item', async () => {
    const user = userEvent.setup();
    render(listComponent());

    const input = screen.getByTestId('add-item-input');
    const addBtn = screen.getByTestId('add-item-btn');

    await user.type(input, 'Test item');
    await user.click(addBtn);

    expect(input).toHaveValue('');
  });

  test('does not add empty items', async () => {
    const user = userEvent.setup();
    render(listComponent());

    const addBtn = screen.getByTestId('add-item-btn');

    await user.click(addBtn);

    // Should still show empty message
    expect(screen.getByTestId('empty-message')).toBeInTheDocument();

    const count = screen.getByTestId('items-count');
    expect(count).toHaveTextContent('Total: 0');
  });

  test('does not add whitespace-only items', async () => {
    const user = userEvent.setup();
    render(listComponent());

    const input = screen.getByTestId('add-item-input');
    const addBtn = screen.getByTestId('add-item-btn');

    await user.type(input, '   ');
    await user.click(addBtn);

    expect(screen.getByTestId('empty-message')).toBeInTheDocument();
  });

  test('adds multiple items correctly', async () => {
    const user = userEvent.setup();
    render(listComponent());

    const input = screen.getByTestId('add-item-input');
    const addBtn = screen.getByTestId('add-item-btn');

    await user.type(input, 'Item 1');
    await user.click(addBtn);

    await user.type(input, 'Item 2');
    await user.click(addBtn);

    await user.type(input, 'Item 3');
    await user.click(addBtn);

    expect(screen.getByTestId('list-item-0')).toHaveTextContent('Item 1');
    expect(screen.getByTestId('list-item-1')).toHaveTextContent('Item 2');
    expect(screen.getByTestId('list-item-2')).toHaveTextContent('Item 3');

    const count = screen.getByTestId('items-count');
    expect(count).toHaveTextContent('Total: 3');
  });

  test('removes item when remove button clicked', async () => {
    const user = userEvent.setup();
    render(listComponent());

    const input = screen.getByTestId('add-item-input');
    const addBtn = screen.getByTestId('add-item-btn');

    await user.type(input, 'Item to remove');
    await user.click(addBtn);

    expect(screen.getByTestId('list-item-0')).toBeInTheDocument();

    const removeBtn = screen.getByTestId('remove-btn-0');
    await user.click(removeBtn);

    expect(screen.queryByTestId('list-item-0')).not.toBeInTheDocument();
    expect(screen.getByTestId('empty-message')).toBeInTheDocument();
  });

  test('removes correct item from middle of list', async () => {
    const user = userEvent.setup();
    render(listComponent());

    const input = screen.getByTestId('add-item-input');
    const addBtn = screen.getByTestId('add-item-btn');

    await user.type(input, 'First');
    await user.click(addBtn);

    await user.type(input, 'Second');
    await user.click(addBtn);

    await user.type(input, 'Third');
    await user.click(addBtn);

    // Remove middle item
    const removeBtn = screen.getByTestId('remove-btn-1');
    await user.click(removeBtn);

    // Check remaining items
    expect(screen.getByTestId('list-item-0')).toHaveTextContent('First');
    expect(screen.getByTestId('list-item-1')).toHaveTextContent('Third');
    expect(screen.queryByTestId('list-item-2')).not.toBeInTheDocument();

    const count = screen.getByTestId('items-count');
    expect(count).toHaveTextContent('Total: 2');
  });

  test('handles add and remove operations in sequence', async () => {
    const user = userEvent.setup();
    render(listComponent());

    const input = screen.getByTestId('add-item-input');
    const addBtn = screen.getByTestId('add-item-btn');

    // Add 3 items
    await user.type(input, 'A');
    await user.click(addBtn);
    await user.type(input, 'B');
    await user.click(addBtn);
    await user.type(input, 'C');
    await user.click(addBtn);

    expect(screen.getByTestId('items-count')).toHaveTextContent('Total: 3');

    // Remove first
    await user.click(screen.getByTestId('remove-btn-0'));
    expect(screen.getByTestId('items-count')).toHaveTextContent('Total: 2');

    // Add new item
    await user.type(input, 'D');
    await user.click(addBtn);
    expect(screen.getByTestId('items-count')).toHaveTextContent('Total: 3');

    // Remove all
    await user.click(screen.getByTestId('remove-btn-0'));
    await user.click(screen.getByTestId('remove-btn-0'));
    await user.click(screen.getByTestId('remove-btn-0'));

    expect(screen.getByTestId('empty-message')).toBeInTheDocument();
    expect(screen.getByTestId('items-count')).toHaveTextContent('Total: 0');
  });
});
