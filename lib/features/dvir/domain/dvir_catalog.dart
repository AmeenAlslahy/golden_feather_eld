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

/// FMCSA § 396.11 standard defect items for trailers.
const List<DvirCatalogItem> kStandardTrailerDefectItems = [
  DvirCatalogItem(code: 'TR_BRAKE_CONN', name: 'Brake Connections', nameAr: 'توصيلات المكابح', category: 'TRAILER', critical: true),
  DvirCatalogItem(code: 'TR_BRAKES', name: 'Brakes', nameAr: 'المكابح', category: 'TRAILER', critical: true),
  DvirCatalogItem(code: 'TR_COUPLING', name: 'Coupling Devices', nameAr: 'أجهزة الربط', category: 'TRAILER', critical: true),
  DvirCatalogItem(code: 'TR_KING_PIN', name: 'Coupling (King) Pin', nameAr: 'مسمار التثبيت (King Pin)', category: 'TRAILER', critical: true),
  DvirCatalogItem(code: 'TR_DOORS', name: 'Doors & Cargo Securement', nameAr: 'الأبواب وتأمين الحمولة', category: 'TRAILER'),
  DvirCatalogItem(code: 'TR_HITCH', name: 'Hitch', nameAr: 'قارنة المقطورة / الخطاف', category: 'TRAILER'),
  DvirCatalogItem(code: 'TR_LANDING_GEAR', name: 'Landing Gear', nameAr: 'أرجل الهبوط', category: 'TRAILER'),
  DvirCatalogItem(code: 'TR_LIGHTS', name: 'Lights - All', nameAr: 'جميع الأضواء', category: 'TRAILER'),
  DvirCatalogItem(code: 'TR_REFLECTORS', name: 'Reflectors & Reflective Tape', nameAr: 'العاكسات والشريط العاكس', category: 'TRAILER'),
  DvirCatalogItem(code: 'TR_ROOF', name: 'Roof', nameAr: 'السقف', category: 'TRAILER'),
  DvirCatalogItem(code: 'TR_SUSPENSION', name: 'Suspension System', nameAr: 'نظام التعليق', category: 'TRAILER', critical: true),
  DvirCatalogItem(code: 'TR_TARPAULIN', name: 'Tarpaulin / Tarp', nameAr: 'غطاء المشمع', category: 'TRAILER'),
  DvirCatalogItem(code: 'TR_TIRES', name: 'Tires', nameAr: 'الإطارات', category: 'TRAILER', critical: true),
  DvirCatalogItem(code: 'TR_WHEELS_RIMS', name: 'Wheels and Rims', nameAr: 'العجلات والجنوط', category: 'TRAILER', critical: true),
  DvirCatalogItem(code: 'TR_OTHER', name: 'Other Trailer Defect', nameAr: 'عطل آخر في المقطورة', category: 'TRAILER'),
];

