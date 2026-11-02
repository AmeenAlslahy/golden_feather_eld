/// Barrel file لنظام التصميم — استيراد واحد لكل الهوية البصرية.
///
/// ملاحظة: الملفات الفعلية باقية في مواضعها (core/theme/) — هذا الجسر
/// يتيح `import 'package:golden_feather_eld/core/design_system.dart';`
/// دون نقل ملفات يكسر 25 مستورداً (قرار المالك: لا فوضى).
library;

export 'theme/app_colors.dart';
export 'theme/golden_colors.dart';
export 'theme/app_radius.dart';
export 'theme/app_shadows.dart';
export 'theme/app_decorations.dart';

export 'theme/app_spacing.dart';
export 'theme/app_sizing.dart';
export 'theme/app_density.dart';
export 'theme/app_styles.dart';
export 'theme/app_theme.dart';
export 'theme/app_typography.dart';
export 'theme/press_feedback.dart';
export 'extensions/context_extensions.dart';
export 'widgets/app_status_pill.dart';
export 'widgets/app_button.dart';
export 'widgets/app_feedback.dart';
export 'widgets/app_signature_canvas.dart';
export 'widgets/app_status_badge.dart';
export 'widgets/app_text_field.dart';
export 'widgets/critical_error_app.dart';
export 'widgets/eld_card.dart';
export 'widgets/eld_date_paginator.dart';
export 'widgets/eld_graph_grid.dart';
export 'widgets/eld_info_row.dart';
export 'widgets/eld_dropdown_row.dart';
export 'widgets/eld_retry_view.dart';
export 'widgets/directional_chevron.dart';
export 'widgets/eld_footer_notice.dart';
export 'widgets/app_dialog.dart';
export 'widgets/app_logo.dart';
export 'widgets/connection_status_indicator.dart';
export 'widgets/golden_app_bar.dart';
export 'widgets/status_color_resolver.dart';
export 'widgets/app_loading_state.dart';
export 'widgets/app_section.dart';
export 'widgets/app_selection_tile.dart';
export 'widgets/app_key_value_row.dart';

