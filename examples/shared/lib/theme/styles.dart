import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// Shared styles for React and React Native components
abstract final class AppStyles {
  // Auth card container
  static const Map<String, dynamic> authCard = {
    'backgroundColor': AppColors.bgCard,
    'borderWidth': 1,
    'borderColor': AppColors.borderRN,
    'borderRadius': AppSpacing.radiusXl,
    'padding': 40,
  };

  // Auth title
  static const Map<String, dynamic> authTitle = {
    'fontSize': AppTypography.sizeTitle,
    'fontWeight': AppTypography.weightBold,
    'color': AppColors.accentPrimary,
    'textAlign': 'center',
    'marginBottom': AppSpacing.xxxl,
  };

  // Form label
  static const Map<String, dynamic> label = {
    'fontSize': AppTypography.sizeSm,
    'fontWeight': AppTypography.weightMedium,
    'color': AppColors.textSecondary,
    'marginBottom': AppSpacing.sm,
  };

  // Text input
  static const Map<String, dynamic> input = {
    'paddingVertical': 14,
    'paddingHorizontal': 16,
    'fontSize': AppTypography.sizeMd,
    'backgroundColor': AppColors.bgSecondary,
    'borderWidth': 1,
    'borderColor': AppColors.borderRN,
    'borderRadius': AppSpacing.radiusMd,
    'color': AppColors.textPrimary,
  };

  // Form group spacing
  static const Map<String, dynamic> formGroup = {'marginBottom': AppSpacing.xl};

  // Primary button
  static const Map<String, dynamic> btnPrimary = {
    'alignItems': 'center',
    'justifyContent': 'center',
    'paddingVertical': 14,
    'paddingHorizontal': 24,
    'borderRadius': AppSpacing.radiusMd,
    'backgroundColor': AppColors.accentPrimary,
    'marginTop': AppSpacing.sm,
  };

  // Primary button text
  static const Map<String, dynamic> btnPrimaryText = {
    'color': AppColors.textPrimary,
    'fontSize': AppTypography.sizeMd,
    'fontWeight': AppTypography.weightSemibold,
  };

  // Link button container
  static const Map<String, dynamic> linkContainer = {
    'marginTop': AppSpacing.xxxl,
    'alignItems': 'center',
    'flexDirection': 'row',
  };

  // Link text
  static const Map<String, dynamic> linkText = {
    'color': AppColors.textMuted,
    'fontSize': AppTypography.sizeSm,
  };

  // Link highlight
  static const Map<String, dynamic> linkHighlight = {
    'color': AppColors.accentPrimary,
    'fontSize': AppTypography.sizeSm,
    'fontWeight': AppTypography.weightMedium,
  };

  // Error message
  static const Map<String, dynamic> errorMsg = {
    'backgroundColor': '#3d1414',
    'borderWidth': 1,
    'borderColor': AppColors.danger,
    'borderRadius': AppSpacing.radiusMd,
    'padding': AppSpacing.lg,
    'marginBottom': AppSpacing.xl,
  };

  static const Map<String, dynamic> errorText = {
    'color': AppColors.errorText,
    'fontSize': AppTypography.sizeSm,
  };

  // Header
  static const Map<String, dynamic> header = {
    'backgroundColor': AppColors.bgPrimary,
    'borderBottomWidth': 1,
    'borderBottomColor': AppColors.borderRN,
    'paddingHorizontal': AppSpacing.xl,
    'paddingVertical': AppSpacing.lg,
    'flexDirection': 'row',
    'justifyContent': 'space-between',
    'alignItems': 'center',
  };

  static const Map<String, dynamic> headerTitle = {
    'fontSize': AppTypography.sizeLg,
    'fontWeight': AppTypography.weightBold,
    'color': AppColors.accentPrimary,
  };

  static const Map<String, dynamic> headerUserName = {
    'color': AppColors.textSecondary,
    'fontSize': AppTypography.sizeSm,
  };

  static const Map<String, dynamic> logoutText = {
    'color': AppColors.textSecondary,
    'fontSize': AppTypography.sizeSm,
  };

  // Task item
  static const Map<String, dynamic> taskItem = {
    'flexDirection': 'row',
    'alignItems': 'flex-start',
    'backgroundColor': AppColors.bgCard,
    'borderWidth': 1,
    'borderColor': AppColors.borderRN,
    'borderRadius': AppSpacing.radiusMd,
    'padding': AppSpacing.lg,
    'marginBottom': AppSpacing.md,
  };

  // Checkbox unchecked
  static const Map<String, dynamic> checkboxUnchecked = {
    'width': 24,
    'height': 24,
    'borderRadius': 6,
    'borderWidth': 2,
    'borderColor': AppColors.borderHoverRN,
    'marginRight': AppSpacing.lg,
    'marginTop': 2,
    'alignItems': 'center',
    'justifyContent': 'center',
  };

  // Checkbox checked
  static const Map<String, dynamic> checkboxChecked = {
    'width': 24,
    'height': 24,
    'borderRadius': 6,
    'backgroundColor': AppColors.success,
    'borderWidth': 2,
    'borderColor': AppColors.success,
    'marginRight': AppSpacing.lg,
    'marginTop': 2,
    'alignItems': 'center',
    'justifyContent': 'center',
  };

  static const Map<String, dynamic> checkIcon = {
    'color': AppColors.textPrimary,
    'fontSize': 12,
    'fontWeight': AppTypography.weightBold,
  };

  // Task text
  static const Map<String, dynamic> taskTitle = {
    'fontSize': AppTypography.sizeMd,
    'fontWeight': AppTypography.weightMedium,
    'color': AppColors.textPrimary,
    'flex': 1,
  };

  static const Map<String, dynamic> taskTitleCompleted = {
    'fontSize': AppTypography.sizeMd,
    'fontWeight': AppTypography.weightMedium,
    'color': AppColors.textMuted,
    'flex': 1,
    'textDecorationLine': 'line-through',
  };

  // Delete button
  static const Map<String, dynamic> deleteBtn = {'padding': AppSpacing.sm};

  static const Map<String, dynamic> deleteBtnText = {
    'color': AppColors.danger,
    'fontSize': AppTypography.sizeXl,
  };

  // Empty state
  static const Map<String, dynamic> emptyState = {
    'alignItems': 'center',
    'padding': 64,
    'backgroundColor': AppColors.bgCard,
    'borderWidth': 1,
    'borderColor': AppColors.borderRN,
    'borderRadius': AppSpacing.radiusLg,
  };

  static const Map<String, dynamic> emptyIcon = {
    'fontSize': 48,
    'marginBottom': AppSpacing.lg,
  };

  static const Map<String, dynamic> emptyText = {
    'color': AppColors.textMuted,
    'fontSize': AppTypography.sizeMd,
  };

  // Main container
  static const Map<String, dynamic> container = {
    'flex': 1,
    'backgroundColor': AppColors.bgPrimary,
  };

  // Content area with padding
  static const Map<String, dynamic> content = {
    'flex': 1,
    'padding': AppSpacing.xl,
  };

  // Centered content for auth screens
  static const Map<String, dynamic> centeredContent = {
    'flex': 1,
    'justifyContent': 'center',
    'padding': AppSpacing.xl,
    'backgroundColor': AppColors.bgPrimary,
  };

  // App root container
  static const Map<String, dynamic> app = {
    'minHeight': '100vh',
    'display': 'flex',
    'flexDirection': 'column',
  };

  // Main content wrapper
  static const Map<String, dynamic> mainContent = {
    'flex': 1,
    'maxWidth': 600,
    'margin': '0 auto',
    'padding': '48px 24px',
    'width': '100%',
  };

  // Header content (inner container)
  static const Map<String, dynamic> headerContent = {
    'maxWidth': 1000,
    'margin': '0 auto',
    'padding': '16px 32px',
    'display': 'flex',
    'justifyContent': 'space-between',
    'alignItems': 'center',
  };

  // Logo style
  static const Map<String, dynamic> logo = {
    'fontSize': AppTypography.sizeXxl,
    'fontWeight': AppTypography.weightBold,
    'color': AppColors.accentPrimary,
  };

  // User info container
  static const Map<String, dynamic> userInfo = {
    'display': 'flex',
    'alignItems': 'center',
    'gap': AppSpacing.lg,
  };

  // Ghost button (for logout, etc.)
  static const Map<String, dynamic> btnGhost = {
    'backgroundColor': 'transparent',
    'color': AppColors.textSecondary,
    'padding': '8px 16px',
    'borderRadius': AppSpacing.radiusMd,
    'border': 'none',
    'cursor': 'pointer',
  };

  // Link button (inline text button)
  static const Map<String, dynamic> btnLink = {
    'backgroundColor': 'transparent',
    'border': 'none',
    'color': AppColors.accentPrimary,
    'fontSize': AppTypography.sizeMd,
    'fontWeight': AppTypography.weightMedium,
    'cursor': 'pointer',
    'padding': 0,
  };

  // Footer
  static const Map<String, dynamic> footer = {
    'textAlign': 'center',
    'padding': AppSpacing.xxxl,
    'color': AppColors.textMuted,
    'fontSize': AppTypography.sizeSm,
    'borderTopWidth': 1,
    'borderTopColor': AppColors.borderRN,
  };

  // Task container
  static const Map<String, dynamic> taskContainer = {
    'display': 'flex',
    'flexDirection': 'column',
  };

  // Task header
  static const Map<String, dynamic> taskHeader = {
    'display': 'flex',
    'justifyContent': 'space-between',
    'alignItems': 'center',
    'marginBottom': AppSpacing.xxl,
  };

  // Section title
  static const Map<String, dynamic> sectionTitle = {
    'fontSize': AppTypography.sizeXxl,
    'fontWeight': AppTypography.weightBold,
    'color': AppColors.textPrimary,
  };

  // Stats container
  static const Map<String, dynamic> stats = {
    'display': 'flex',
    'alignItems': 'center',
    'gap': AppSpacing.lg,
  };

  // Stats text
  static const Map<String, dynamic> statText = {
    'fontSize': AppTypography.sizeSm,
    'color': AppColors.textMuted,
  };

  // Progress bar container
  static const Map<String, dynamic> progressBar = {
    'width': 120,
    'height': 6,
    'backgroundColor': AppColors.bgSecondary,
    'borderRadius': 100,
    'overflow': 'hidden',
  };

  // Progress bar fill
  static const Map<String, dynamic> progressFill = {
    'height': '100%',
    'backgroundColor': AppColors.accentPrimary,
    'borderRadius': 100,
  };

  // Add task card
  static const Map<String, dynamic> addTaskCard = {
    'backgroundColor': AppColors.bgCard,
    'borderWidth': 1,
    'borderColor': AppColors.borderRN,
    'borderRadius': AppSpacing.radiusLg,
    'padding': AppSpacing.xxl,
    'marginBottom': AppSpacing.xxl,
  };

  // Add task form
  static const Map<String, dynamic> addTaskForm = {
    'display': 'flex',
    'flexDirection': 'column',
    'gap': AppSpacing.md,
  };

  // Task list container
  static const Map<String, dynamic> taskList = {
    'display': 'flex',
    'flexDirection': 'column',
    'gap': AppSpacing.md,
  };

  // Task content (text container)
  static const Map<String, dynamic> taskContent = {
    'flex': 1,
    'minWidth': 0,
    'display': 'flex',
    'flexDirection': 'column',
    'gap': 4,
  };

  // Task description
  static const Map<String, dynamic> taskDesc = {
    'fontSize': AppTypography.sizeSm,
    'color': AppColors.textMuted,
  };

  // Loading state
  static const Map<String, dynamic> loading = {
    'textAlign': 'center',
    'padding': 48,
    'color': AppColors.textMuted,
  };

  // Auth footer (for sign up/sign in links)
  static const Map<String, dynamic> authFooter = {
    'marginTop': AppSpacing.xxxl,
    'textAlign': 'center',
    'color': AppColors.textMuted,
    'fontSize': AppTypography.sizeSm,
  };

  // Spacer (empty element)
  static const Map<String, dynamic> spacer = {'display': 'block'};

  // Large input (for main task input)
  static const Map<String, dynamic> inputLg = {
    'paddingVertical': 16,
    'paddingHorizontal': 20,
    'fontSize': AppTypography.sizeLg,
    'backgroundColor': AppColors.bgSecondary,
    'borderWidth': 1,
    'borderColor': AppColors.borderRN,
    'borderRadius': AppSpacing.radiusMd,
    'color': AppColors.textPrimary,
  };

  // FAB (Floating Action Button)
  static const Map<String, dynamic> fab = {
    'position': 'absolute',
    'bottom': 24,
    'right': 24,
    'width': 56,
    'height': 56,
    'borderRadius': 28,
    'backgroundColor': AppColors.accentPrimary,
    'alignItems': 'center',
    'justifyContent': 'center',
    'elevation': 4,
    'shadowColor': '#000',
    'shadowOffset': {'width': 0, 'height': 2},
    'shadowOpacity': 0.25,
    'shadowRadius': 4,
  };

  static const Map<String, dynamic> fabText = {
    'color': AppColors.textPrimary,
    'fontSize': 28,
    'fontWeight': AppTypography.weightBold,
  };

  // Add task inline form
  static const Map<String, dynamic> addTaskInline = {
    'flexDirection': 'row',
    'alignItems': 'center',
    'backgroundColor': AppColors.bgCard,
    'borderWidth': 1,
    'borderColor': AppColors.borderRN,
    'borderRadius': AppSpacing.radiusMd,
    'padding': AppSpacing.md,
    'marginBottom': AppSpacing.md,
    'gap': AppSpacing.md,
  };

  static const Map<String, dynamic> addTaskInput = {
    'flex': 1,
    'paddingVertical': 10,
    'paddingHorizontal': 14,
    'fontSize': AppTypography.sizeMd,
    'backgroundColor': AppColors.bgSecondary,
    'borderWidth': 1,
    'borderColor': AppColors.borderRN,
    'borderRadius': AppSpacing.radiusSm,
    'color': AppColors.textPrimary,
  };

  static const Map<String, dynamic> addTaskBtn = {
    'paddingVertical': 10,
    'paddingHorizontal': 16,
    'backgroundColor': AppColors.accentPrimary,
    'borderRadius': AppSpacing.radiusSm,
  };

  static const Map<String, dynamic> addTaskBtnText = {
    'color': AppColors.textPrimary,
    'fontSize': AppTypography.sizeMd,
    'fontWeight': AppTypography.weightSemibold,
  };

  static const Map<String, dynamic> cancelBtn = {
    'paddingVertical': 10,
    'paddingHorizontal': 12,
  };

  static const Map<String, dynamic> cancelBtnText = {
    'color': AppColors.textSecondary,
    'fontSize': AppTypography.sizeMd,
  };
}
