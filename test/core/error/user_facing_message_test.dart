import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/user_facing_message.dart';

void main() {
  test('prefers serverMessage and never dumps the exception', () {
    const error = ValidationError(
      code: 'VALIDATION_ERROR',
      l10nKey: 'validationError',
      cause: FormatException('Unexpected character (at offset 0)'),
      context: {
        'serverMessage':
            'القاعدة التنظيمية المحددة لا تدعم استثناء الـ 16 ساعة',
      },
    );

    final text = appErrorUserMessage(error, isArabic: true);
    expect(text, contains('16'));
    expect(text, isNot(contains('FormatException')));
    expect(text, isNot(contains('ValidationError')));
  });

  test('network error has no stack text', () {
    const error = NetworkError(
      code: 'network.connectionFailed',
      l10nKey: 'networkConnectionFailed',
    );
    expect(appErrorUserMessage(error, isArabic: false), contains('server'));
    expect(appErrorUserMessage(error, isArabic: true), contains('الخادم'));
  });
}
