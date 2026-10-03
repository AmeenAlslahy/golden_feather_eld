import 'package:equatable/equatable.dart';
import 'defect_enums.dart';

/// One §396.11 catalog item from `GET /eld/dvir/catalog`.
///
/// نموذج صرف — قراءة جسم الخادم في `data/mappers/dvir_mappers.dart`.
class DvirCatalogItem extends Equatable {
  final String code;
  final String name;
  final String? nameAr;
  final String category;
  final bool mandatory;
  final bool critical;

  const DvirCatalogItem({
    required this.code,
    required this.name,
    this.nameAr,
    this.category = '',
    this.mandatory = false,
    this.critical = false,
  });

  @override
  List<Object?> get props => [code, name, nameAr, category, mandatory, critical];
}

/// A catalog item the driver marked as defective, with an optional note.
class DvirDefectSelection extends Equatable {
  final DvirCatalogItem item;
  final String? description;
  final DefectSeverity? severity;
  final DefectLifecycleStage stage;

  const DvirDefectSelection({
    required this.item,
    this.description,
    this.severity,
    this.stage = DefectLifecycleStage.open,
  });

  @override
  List<Object?> get props => [item, description];
}
