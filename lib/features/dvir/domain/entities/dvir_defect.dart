/// عيب DVIR — كيان نقي من تفاصيل الخادم (`GET /eld/dvir/defects/{id}`).
/// ما لا يرسله الخادم يبقى null — لا قيم مخترعة ولا افتراضات.
class DvirDefect {
  final int id;
  final int? inspectionId;
  final int? deviceId;
  final int? driverId;
  final String? assetType;
  final String? assetIdentifier;
  final String? itemCode;
  final String? itemName;
  final String? description;
  final String? severity;
  final String? stage;
  final bool? outOfService;
  final DateTime? repairDeadline;
  final List<DvirRepairAction> repairActions;
  final List<DvirDefectCertification> certifications;

  const DvirDefect({
    required this.id,
    this.inspectionId,
    this.deviceId,
    this.driverId,
    this.assetType,
    this.assetIdentifier,
    this.itemCode,
    this.itemName,
    this.description,
    this.severity,
    this.stage,
    this.outOfService,
    this.repairDeadline,
    this.repairActions = const [],
    this.certifications = const [],
  });
}

/// إجراء إصلاح ميكانيكي موثق على العيب.
class DvirRepairAction {
  final int? id;
  final String? performedByName;
  final String? actionPerformed;
  final String? repairNotes;
  final String? workOrderNumber;
  final DateTime? performedAt;

  const DvirRepairAction({
    this.id,
    this.performedByName,
    this.actionPerformed,
    this.repairNotes,
    this.workOrderNumber,
    this.performedAt,
  });
}

/// شهادة اعتماد الناقل للعيب (§396.11 — إجراء الناقل حصراً).
class DvirDefectCertification {
  final int? id;
  final String? certifiedByName;
  final String? certificationType;
  final String? certificationNotes;
  final DateTime? certifiedAt;

  const DvirDefectCertification({
    this.id,
    this.certifiedByName,
    this.certificationType,
    this.certificationNotes,
    this.certifiedAt,
  });
}
