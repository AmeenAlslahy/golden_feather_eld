/// Barrel export for ELD connectivity and diagnostics widgets.
///
/// This modular structure separates:
/// - [EldConnectivityPanel] for server-side ELD connection status.
/// - [EldReadinessPanel] for hardware readiness checks.
/// - [ManualRecordingSection] for FMCSA §395.34 paper-log fallback workflow.
/// - [ManualModeReasonDialog] for reason input dialog.
library;

export 'dialogs/manual_mode_reason_dialog.dart';
export 'eld_connectivity_panel.dart';
export 'eld_readiness_panel.dart';
export 'manual_recording_section.dart';
