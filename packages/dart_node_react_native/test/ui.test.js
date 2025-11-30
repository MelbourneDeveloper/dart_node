/**
 * UI Interaction Tests for Dart React Native Components
 * Uses React Native Testing Library for real component testing
 */

const { render, fireEvent, waitFor } = require('@testing-library/react-native');

// Make testing library available globally for Dart interop
// dart2js uses init.G which resolves to self || globalThis
global.rnTestingLibrary = { render, fireEvent, waitFor };
globalThis.rnTestingLibrary = global.rnTestingLibrary;

// Load compiled Dart code
require('./dist/ui_test.js');

// Get exported Dart components
const {
  counterComponent,
  formComponent,
  toggleComponent,
  listComponent,
  switchComponent,
  loadingComponent,
} = global.dartReactNativeTests;

// =============================================================================
// Counter Component Tests
// =============================================================================

describe('Counter Component', () => {
  test('renders with initial count of 0', () => {
    const { getByTestId } = render(counterComponent());

    const display = getByTestId('count-display');
    expect(display).toHaveTextContent('Count: 0');
  });

  test('increments count when increment button pressed', () => {
    const { getByTestId } = render(counterComponent());

    const incrementBtn = getByTestId('increment-btn');
    const display = getByTestId('count-display');

    fireEvent.press(incrementBtn);
    expect(display).toHaveTextContent('Count: 1');

    fireEvent.press(incrementBtn);
    expect(display).toHaveTextContent('Count: 2');

    fireEvent.press(incrementBtn);
    expect(display).toHaveTextContent('Count: 3');
  });

  test('decrements count when decrement button pressed', () => {
    const { getByTestId } = render(counterComponent());

    const decrementBtn = getByTestId('decrement-btn');
    const display = getByTestId('count-display');

    fireEvent.press(decrementBtn);
    expect(display).toHaveTextContent('Count: -1');

    fireEvent.press(decrementBtn);
    expect(display).toHaveTextContent('Count: -2');
  });

  test('resets count to 0 when reset button pressed', () => {
    const { getByTestId } = render(counterComponent());

    const incrementBtn = getByTestId('increment-btn');
    const resetBtn = getByTestId('reset-btn');
    const display = getByTestId('count-display');

    // Increment a few times
    fireEvent.press(incrementBtn);
    fireEvent.press(incrementBtn);
    fireEvent.press(incrementBtn);
    expect(display).toHaveTextContent('Count: 3');

    // Reset
    fireEvent.press(resetBtn);
    expect(display).toHaveTextContent('Count: 0');
  });

  test('handles rapid presses correctly', () => {
    const { getByTestId } = render(counterComponent());

    const incrementBtn = getByTestId('increment-btn');
    const display = getByTestId('count-display');

    // Rapid presses
    for (let i = 0; i < 10; i++) {
      fireEvent.press(incrementBtn);
    }

    expect(display).toHaveTextContent('Count: 10');
  });
});

// =============================================================================
// Form Component Tests
// =============================================================================

describe('Form Component', () => {
  test('renders empty form inputs', () => {
    const { getByTestId } = render(formComponent(null));

    const emailInput = getByTestId('email-input');
    const passwordInput = getByTestId('password-input');

    expect(emailInput.props.value).toBe('');
    expect(passwordInput.props.value).toBe('');
  });

  test('updates email input when typing', () => {
    const { getByTestId } = render(formComponent(null));

    const emailInput = getByTestId('email-input');

    fireEvent.changeText(emailInput, 'test@example.com');
    expect(emailInput.props.value).toBe('test@example.com');
  });

  test('updates password input when typing', () => {
    const { getByTestId } = render(formComponent(null));

    const passwordInput = getByTestId('password-input');

    fireEvent.changeText(passwordInput, 'secretpass123');
    expect(passwordInput.props.value).toBe('secretpass123');
  });

  test('shows error when submitting empty form', () => {
    const { getByTestId } = render(formComponent(null));

    const submitBtn = getByTestId('submit-btn');

    fireEvent.press(submitBtn);

    const errorMessage = getByTestId('error-message');
    expect(errorMessage).toHaveTextContent('All fields required');
  });

  test('shows error when only email is filled', () => {
    const { getByTestId } = render(formComponent(null));

    const emailInput = getByTestId('email-input');
    const submitBtn = getByTestId('submit-btn');

    fireEvent.changeText(emailInput, 'test@example.com');
    fireEvent.press(submitBtn);

    const errorMessage = getByTestId('error-message');
    expect(errorMessage).toHaveTextContent('All fields required');
  });

  test('shows error when only password is filled', () => {
    const { getByTestId } = render(formComponent(null));

    const passwordInput = getByTestId('password-input');
    const submitBtn = getByTestId('submit-btn');

    fireEvent.changeText(passwordInput, 'secret123');
    fireEvent.press(submitBtn);

    const errorMessage = getByTestId('error-message');
    expect(errorMessage).toHaveTextContent('All fields required');
  });

  test('shows success message when form is valid', () => {
    const { getByTestId, queryByTestId } = render(formComponent(null));

    const emailInput = getByTestId('email-input');
    const passwordInput = getByTestId('password-input');
    const submitBtn = getByTestId('submit-btn');

    fireEvent.changeText(emailInput, 'test@example.com');
    fireEvent.changeText(passwordInput, 'secret123');
    fireEvent.press(submitBtn);

    const successMessage = getByTestId('success-message');
    expect(successMessage).toHaveTextContent('Form submitted!');

    // Error should not be visible
    expect(queryByTestId('error-message')).toBeNull();
  });

  test('calls onSubmit callback with form values', () => {
    const onSubmit = jest.fn();

    const { getByTestId } = render(formComponent(onSubmit));

    const emailInput = getByTestId('email-input');
    const passwordInput = getByTestId('password-input');
    const submitBtn = getByTestId('submit-btn');

    fireEvent.changeText(emailInput, 'user@test.com');
    fireEvent.changeText(passwordInput, 'mypassword');
    fireEvent.press(submitBtn);

    expect(onSubmit).toHaveBeenCalledTimes(1);
    expect(onSubmit).toHaveBeenCalledWith('user@test.com', 'mypassword');
  });

  test('clears error when valid form is submitted', () => {
    const { getByTestId, queryByTestId } = render(formComponent(null));

    const emailInput = getByTestId('email-input');
    const passwordInput = getByTestId('password-input');
    const submitBtn = getByTestId('submit-btn');

    // First submit empty form to show error
    fireEvent.press(submitBtn);
    expect(getByTestId('error-message')).toBeTruthy();

    // Now fill and submit
    fireEvent.changeText(emailInput, 'test@example.com');
    fireEvent.changeText(passwordInput, 'password123');
    fireEvent.press(submitBtn);

    // Error should be gone, success should show
    expect(queryByTestId('error-message')).toBeNull();
    expect(getByTestId('success-message')).toBeTruthy();
  });
});

// =============================================================================
// Toggle Component Tests
// =============================================================================

describe('Toggle Component', () => {
  test('renders with OFF state initially', () => {
    const { getByTestId } = render(toggleComponent());

    const status = getByTestId('toggle-status');
    expect(status).toHaveTextContent('OFF');
  });

  test('toggles to ON when button pressed', () => {
    const { getByTestId } = render(toggleComponent());

    const toggleBtn = getByTestId('toggle-btn');
    const status = getByTestId('toggle-status');

    fireEvent.press(toggleBtn);
    expect(status).toHaveTextContent('ON');
  });

  test('toggles back to OFF when pressed again', () => {
    const { getByTestId } = render(toggleComponent());

    const toggleBtn = getByTestId('toggle-btn');
    const status = getByTestId('toggle-status');

    fireEvent.press(toggleBtn);
    expect(status).toHaveTextContent('ON');

    fireEvent.press(toggleBtn);
    expect(status).toHaveTextContent('OFF');
  });

  test('handles multiple toggles correctly', () => {
    const { getByTestId } = render(toggleComponent());

    const toggleBtn = getByTestId('toggle-btn');
    const status = getByTestId('toggle-status');

    // Toggle 5 times
    fireEvent.press(toggleBtn); // ON
    expect(status).toHaveTextContent('ON');

    fireEvent.press(toggleBtn); // OFF
    expect(status).toHaveTextContent('OFF');

    fireEvent.press(toggleBtn); // ON
    expect(status).toHaveTextContent('ON');

    fireEvent.press(toggleBtn); // OFF
    expect(status).toHaveTextContent('OFF');

    fireEvent.press(toggleBtn); // ON
    expect(status).toHaveTextContent('ON');
  });
});

// =============================================================================
// List Component Tests
// =============================================================================

describe('List Component', () => {
  test('renders empty list with message', () => {
    const { getByTestId } = render(listComponent());

    const emptyMessage = getByTestId('empty-message');
    expect(emptyMessage).toHaveTextContent('No items');

    const count = getByTestId('items-count');
    expect(count).toHaveTextContent('Total: 0');
  });

  test('adds item to list when add button pressed', () => {
    const { getByTestId, queryByTestId } = render(listComponent());

    const input = getByTestId('add-item-input');
    const addBtn = getByTestId('add-item-btn');

    fireEvent.changeText(input, 'First item');
    fireEvent.press(addBtn);

    const item = getByTestId('list-item-0');
    expect(item).toHaveTextContent('First item');

    const count = getByTestId('items-count');
    expect(count).toHaveTextContent('Total: 1');

    // Empty message should be gone
    expect(queryByTestId('empty-message')).toBeNull();
  });

  test('clears input after adding item', () => {
    const { getByTestId } = render(listComponent());

    const input = getByTestId('add-item-input');
    const addBtn = getByTestId('add-item-btn');

    fireEvent.changeText(input, 'Test item');
    fireEvent.press(addBtn);

    expect(input.props.value).toBe('');
  });

  test('does not add empty items', () => {
    const { getByTestId } = render(listComponent());

    const addBtn = getByTestId('add-item-btn');

    fireEvent.press(addBtn);

    // Should still show empty message
    expect(getByTestId('empty-message')).toBeTruthy();

    const count = getByTestId('items-count');
    expect(count).toHaveTextContent('Total: 0');
  });

  test('does not add whitespace-only items', () => {
    const { getByTestId } = render(listComponent());

    const input = getByTestId('add-item-input');
    const addBtn = getByTestId('add-item-btn');

    fireEvent.changeText(input, '   ');
    fireEvent.press(addBtn);

    expect(getByTestId('empty-message')).toBeTruthy();
  });

  test('adds multiple items correctly', () => {
    const { getByTestId } = render(listComponent());

    const input = getByTestId('add-item-input');
    const addBtn = getByTestId('add-item-btn');

    fireEvent.changeText(input, 'Item 1');
    fireEvent.press(addBtn);

    fireEvent.changeText(input, 'Item 2');
    fireEvent.press(addBtn);

    fireEvent.changeText(input, 'Item 3');
    fireEvent.press(addBtn);

    expect(getByTestId('list-item-0')).toHaveTextContent('Item 1');
    expect(getByTestId('list-item-1')).toHaveTextContent('Item 2');
    expect(getByTestId('list-item-2')).toHaveTextContent('Item 3');

    const count = getByTestId('items-count');
    expect(count).toHaveTextContent('Total: 3');
  });

  test('removes item when remove button pressed', () => {
    const { getByTestId, queryByTestId } = render(listComponent());

    const input = getByTestId('add-item-input');
    const addBtn = getByTestId('add-item-btn');

    fireEvent.changeText(input, 'Item to remove');
    fireEvent.press(addBtn);

    expect(getByTestId('list-item-0')).toBeTruthy();

    const removeBtn = getByTestId('remove-btn-0');
    fireEvent.press(removeBtn);

    expect(queryByTestId('list-item-0')).toBeNull();
    expect(getByTestId('empty-message')).toBeTruthy();
  });

  test('removes correct item from middle of list', () => {
    const { getByTestId, queryByTestId } = render(listComponent());

    const input = getByTestId('add-item-input');
    const addBtn = getByTestId('add-item-btn');

    fireEvent.changeText(input, 'First');
    fireEvent.press(addBtn);

    fireEvent.changeText(input, 'Second');
    fireEvent.press(addBtn);

    fireEvent.changeText(input, 'Third');
    fireEvent.press(addBtn);

    // Remove middle item
    const removeBtn = getByTestId('remove-btn-1');
    fireEvent.press(removeBtn);

    // Check remaining items
    expect(getByTestId('list-item-0')).toHaveTextContent('First');
    expect(getByTestId('list-item-1')).toHaveTextContent('Third');
    expect(queryByTestId('list-item-2')).toBeNull();

    const count = getByTestId('items-count');
    expect(count).toHaveTextContent('Total: 2');
  });

  test('handles add and remove operations in sequence', () => {
    const { getByTestId } = render(listComponent());

    const input = getByTestId('add-item-input');
    const addBtn = getByTestId('add-item-btn');

    // Add 3 items
    fireEvent.changeText(input, 'A');
    fireEvent.press(addBtn);
    fireEvent.changeText(input, 'B');
    fireEvent.press(addBtn);
    fireEvent.changeText(input, 'C');
    fireEvent.press(addBtn);

    expect(getByTestId('items-count')).toHaveTextContent('Total: 3');

    // Remove first
    fireEvent.press(getByTestId('remove-btn-0'));
    expect(getByTestId('items-count')).toHaveTextContent('Total: 2');

    // Add new item
    fireEvent.changeText(input, 'D');
    fireEvent.press(addBtn);
    expect(getByTestId('items-count')).toHaveTextContent('Total: 3');

    // Remove all
    fireEvent.press(getByTestId('remove-btn-0'));
    fireEvent.press(getByTestId('remove-btn-0'));
    fireEvent.press(getByTestId('remove-btn-0'));

    expect(getByTestId('empty-message')).toBeTruthy();
    expect(getByTestId('items-count')).toHaveTextContent('Total: 0');
  });
});

// =============================================================================
// Switch Component Tests
// =============================================================================

describe('Switch Component', () => {
  test('renders with Disabled state initially', () => {
    const { getByTestId } = render(switchComponent());

    const status = getByTestId('switch-status');
    expect(status).toHaveTextContent('Disabled');
  });

  test('switch toggles state when value changes', () => {
    const { getByTestId } = render(switchComponent());

    const switchControl = getByTestId('switch-control');
    const status = getByTestId('switch-status');

    // Simulate switch toggle
    fireEvent(switchControl, 'valueChange', true);
    expect(status).toHaveTextContent('Enabled');

    fireEvent(switchControl, 'valueChange', false);
    expect(status).toHaveTextContent('Disabled');
  });
});

// =============================================================================
// Loading Component Tests
// =============================================================================

describe('Loading Component', () => {
  test('renders loading indicator initially', () => {
    const { getByTestId, queryByTestId } = render(loadingComponent());

    const indicator = getByTestId('loading-indicator');
    expect(indicator).toBeTruthy();

    expect(queryByTestId('loaded-content')).toBeNull();
  });

  test('shows content when loading is finished', () => {
    const { getByTestId, queryByTestId } = render(loadingComponent());

    const toggleBtn = getByTestId('toggle-loading-btn');

    fireEvent.press(toggleBtn);

    expect(queryByTestId('loading-indicator')).toBeNull();
    expect(getByTestId('loaded-content')).toHaveTextContent('Content loaded');
  });

  test('toggles back to loading state', () => {
    const { getByTestId, queryByTestId } = render(loadingComponent());

    const toggleBtn = getByTestId('toggle-loading-btn');

    // Finish loading
    fireEvent.press(toggleBtn);
    expect(getByTestId('loaded-content')).toBeTruthy();

    // Start loading again
    fireEvent.press(toggleBtn);
    expect(getByTestId('loading-indicator')).toBeTruthy();
    expect(queryByTestId('loaded-content')).toBeNull();
  });
});
