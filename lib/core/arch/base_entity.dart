import 'package:equatable/equatable.dart';

/// الكيان الأساسي — كل Entities ترث منه للاستفادة من المساواة والمقارنة.
///
/// **المزايا:**
/// - مساواة تلقائية (Equatable) بدون تكرار.
/// - هوية موحدة عبر `id`.
/// - قابلية التوسع والوراثة.
abstract class BaseEntity extends Equatable {
  const BaseEntity();

  /// معرّف الكيان (قد يكون int أو String).
  Object get id;

  @override
  List<Object?> get props => [id];
}

/// كيان بمعرّف رقمي — الأكثر شيوعاً في ELD.
abstract class IntIdEntity extends BaseEntity {
  final int intId;
  const IntIdEntity(this.intId);

  @override
  int get id => intId;
}

/// كيان بمعرّف نصي.
abstract class StringIdEntity extends BaseEntity {
  final String stringId;
  const StringIdEntity(this.stringId);

  @override
  String get id => stringId;
}

/// قيمة لا تتغير (Value Object) — للاستخدام مع الأنواع المغلقة.
abstract class ValueObject<T> extends Equatable {
  final T value;
  const ValueObject(this.value);

  @override
  List<Object?> get props => [value];
}

/// حالة تحميل موحدة لكل الشاشات — ترث منها كل States.
abstract class BaseState extends Equatable {
  final bool isLoading;
  final String? error;
  const BaseState({this.isLoading = false, this.error});

  bool get hasError => error != null && error!.isNotEmpty;
  bool get isEmpty => false;

  @override
  List<Object?> get props => [isLoading, error];
}
