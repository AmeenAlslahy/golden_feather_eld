enum RoleSwitchRefusal {
  sessionMissing,
  stillDriving,
  motionUnknown,
  thresholdMissing,
  vehicleMoving,
  coDriverMissing,
  sameDriver,
}

/// Device guard only. It does not change duty status or copy hours.
RoleSwitchRefusal? refuseRoleSwitch({
  required int? currentDriverId,
  required String? coDriverId,
  required double? speedMps,
  required double thresholdKmh,
  required bool? currentStatusIsDriving,
  required bool trackingLive,
}) {
  if (currentDriverId == null || currentDriverId <= 0) {
    return RoleSwitchRefusal.sessionMissing;
  }
  if (currentStatusIsDriving == true) return RoleSwitchRefusal.stillDriving;
  if (!thresholdKmh.isFinite || thresholdKmh <= 0) {
    return RoleSwitchRefusal.thresholdMissing;
  }
  // نفس قاعدة اختيار المركبة: الحارس يعمل فقط حين يكون تيار الموقع حياً —
  // تتبع مغلق يعني لا دليل قيادة أصلاً؛ التحقق القانوني عند connectSession.
  if (trackingLive) {
    if (speedMps == null || !speedMps.isFinite) {
      return RoleSwitchRefusal.motionUnknown;
    }
    if (speedMps * 3.6 >= thresholdKmh) return RoleSwitchRefusal.vehicleMoving;
  }

  final other = int.tryParse(coDriverId?.trim() ?? '');
  if (other == null || other <= 0) return RoleSwitchRefusal.coDriverMissing;
  if (other == currentDriverId) return RoleSwitchRefusal.sameDriver;
  return null;
}
