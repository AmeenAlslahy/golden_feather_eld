/// شدة العيب — SRS 7.5: حقل داخلي لتحديد أولوية المعالجة،
/// ليس قراراً تلقائياً لإعلان OUT_OF_SERVICE.
enum DefectSeverity {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH');

  const DefectSeverity(this.wire);
  final String wire;

  static DefectSeverity? fromWire(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DefectSeverity.values
        .where((s) => s.wire == value.trim().toUpperCase())
        .firstOrNull;
  }
}

/// مرحلة دورة حياة العيب — SRS 7.6 Stepper.
enum DefectLifecycleStage {
  open('OPEN'),
  underRepair('UNDER_REPAIR'),
  repaired('REPAIRED'),
  certified('CERTIFIED'),
  closed('CLOSED');

  const DefectLifecycleStage(this.wire);
  final String wire;

  static DefectLifecycleStage fromWire(String? value) {
    if (value == null || value.trim().isEmpty) return DefectLifecycleStage.open;
    return DefectLifecycleStage.values
        .where((s) => s.wire == value.trim().toUpperCase())
        .firstOrNull ??
        DefectLifecycleStage.open;
  }
}
