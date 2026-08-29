import 'package:equatable/equatable.dart';

/// حالة أساسية لجميع مقدمي الحالة
abstract class BaseState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final String? arabicErrorMessage;

  const BaseState({
    this.isLoading = false,
    this.errorMessage,
    this.arabicErrorMessage,
  });

  bool get hasError => errorMessage != null || arabicErrorMessage != null;

  @override
  List<Object?> get props => [isLoading, errorMessage, arabicErrorMessage];
}

/// مزيج للتحميل
mixin LoadingMixin {
  bool get isLoading;
}

/// مزيج للخطأ
mixin ErrorMixin {
  String? get errorMessage;
  String? get arabicErrorMessage;
  bool get hasError => errorMessage != null || arabicErrorMessage != null;
}


