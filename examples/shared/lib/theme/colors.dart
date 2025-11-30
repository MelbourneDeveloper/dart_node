/// App color palette - matches web CSS variables
abstract final class AppColors {
  // Backgrounds
  static const bgPrimary = '#0a0a0f';
  static const bgSecondary = '#12121a';
  static const bgCard = '#1a1a24';
  static const bgHover = '#242430';

  // Accent colors
  static const accentPrimary = '#6366f1';
  static const accentSecondary = '#8b5cf6';
  static const accentTertiary = '#a855f7';

  // Status colors
  static const success = '#10b981';
  static const danger = '#ef4444';

  // Text colors
  static const textPrimary = '#f8fafc';
  static const textSecondary = '#94a3b8';
  static const textMuted = '#64748b';

  // Borders
  static const border = 'rgba(255, 255, 255, 0.08)';
  static const borderHover = 'rgba(255, 255, 255, 0.15)';

  // For React Native (doesn't support rgba strings)
  static const borderRN = '#1f1f2e';
  static const borderHoverRN = '#2a2a3a';

  // Shorthand borders for web
  static const borderInput = '1px solid #1f1f2e';
  static const borderCard = '1px solid #1f1f2e';

  // Error text
  static const errorText = '#fca5a5';
}
