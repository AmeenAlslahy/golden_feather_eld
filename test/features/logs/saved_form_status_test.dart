import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/logs/data/models/saved_form_dto.dart';

void main() {
  test('a completed server status is the only complete result', () {
    final read = SavedFormDto.fromJson({
      'data': {'formStatus': 'COMPLETED', 'message': 'saved'},
    });

    expect(read.complete, isTrue);
    expect(read.message, 'saved');
  });

  test('an incomplete status does not become complete', () {
    expect(
      SavedFormDto.fromJson({'formStatus': 'INCOMPLETE'}).complete,
      isFalse,
    );
  });

  test('a missing form status is not treated as complete', () {
    final read = SavedFormDto.fromJson({'uniqueId': '1001'});

    expect(read.complete, isNull);
    expect(read.formStatus, isNull);
  });
}
