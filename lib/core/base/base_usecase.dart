import 'package:fpdart/fpdart.dart';
import '../error/failure.dart';

/// واجهة حالة الاستخدام الأساسية
abstract class BaseUseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// حالة استخدام بدون معاملات
abstract class NoParamsUseCase<Type> {
  Future<Either<Failure, Type>> call();
}

/// معاملات فارغة
class NoParams {
  const NoParams();
}


