import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../error/failure.dart';

/// إضافة (Extension) لتسهيل تعامل المطورين مع Either وتحويلها مباشرة إلى AsyncValue.
/// بدلاً من كتابة match() معقدة، يمكنك استخدام هذه الإضافة بسطر واحد.
extension EitherToAsyncValue<L extends Failure, R> on Either<L, R> {
  /// تحويل Either إلى AsyncValue ليتعامل معها Riverpod بسهولة في واجهة المستخدم
  /// مثال الاستخدام:
  /// final result = await repository.getData();
  /// state = result.toAsyncValue();
  AsyncValue<R> toAsyncValue() {
    return match(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (data) => AsyncValue.data(data),
    );
  }

  /// إذا كنت تريد استخراج البيانات أو رمي الخطأ ليتم التقاطه بواسطة `AsyncValue.guard`
  /// مثال الاستخدام:
  /// state = await AsyncValue.guard(() async => (await repository.getData()).getOrThrow());
  R getOrThrow() {
    return match(
      (failure) => throw failure,
      (data) => data,
    );
  }
}
