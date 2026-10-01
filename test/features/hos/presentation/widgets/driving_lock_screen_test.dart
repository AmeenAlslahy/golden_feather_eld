import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('driving_lock_screen uses kDebugMode for bypass (Release simulation)', () {
    final file = File('lib/features/hos/presentation/widgets/driving_lock_screen.dart');
    final content = file.readAsStringSync();
    
    // Ensure that the bypass is guarded by kDebugMode
    expect(
      content.contains('if (kDebugMode)') || content.contains('kDebugMode ?') || content.contains('kDebugMode\n'),
      isTrue,
      reason: 'Bypass must be guarded by kDebugMode to be stripped in release builds.',
    );
  });
}
