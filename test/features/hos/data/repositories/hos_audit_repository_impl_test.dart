import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/features/hos/data/repositories/hos_audit_repository_impl.dart';

void main() {
  late HosAuditRepositoryImpl repository;
  late Box<String> mockBox;

  setUp(() async {
    Hive.init('test_hive_dir');
    mockBox = await Hive.openBox<String>('test_audit_box');
    await mockBox.clear();
    repository = HosAuditRepositoryImpl(mockBox);
  });

  tearDown(() async {
    await mockBox.clear();
    await mockBox.close();
  });

  test('logViolation saves new violation', () async {
    final v = HosViolation(
      type: HosViolationType.dailyDrivingExceeded,
      level: ViolationLevel.critical,
      message: 'Test violation',
      timestamp: DateTime.utc(2023, 1, 1, 10, 0),
    );
    await repository.logViolation(v);
    
    final all = await repository.getViolations();
    expect(all.length, 1);
    expect(all.first.type, HosViolationType.dailyDrivingExceeded);
  });

  test('logViolation deduplicates same violation type on same day', () async {
    final v1 = HosViolation(
      type: HosViolationType.dailyDrivingExceeded,
      level: ViolationLevel.critical,
      message: 'Test violation 1',
      timestamp: DateTime.utc(2023, 1, 1, 10, 0),
    );
    final v2 = HosViolation(
      type: HosViolationType.dailyDrivingExceeded,
      level: ViolationLevel.critical,
      message: 'Test violation 2',
      timestamp: DateTime.utc(2023, 1, 1, 15, 0),
    );
    
    await repository.logViolation(v1);
    await repository.logViolation(v2); // Should be deduplicated
    
    final all = await repository.getViolations();
    expect(all.length, 1);
    expect(all.first.message, 'Test violation 1');
  });

  test('logViolation allows same violation type on different days', () async {
    final v1 = HosViolation(
      type: HosViolationType.dailyDrivingExceeded,
      level: ViolationLevel.critical,
      message: 'Test violation day 1',
      timestamp: DateTime.utc(2023, 1, 1, 10, 0),
    );
    final v2 = HosViolation(
      type: HosViolationType.dailyDrivingExceeded,
      level: ViolationLevel.critical,
      message: 'Test violation day 2',
      timestamp: DateTime.utc(2023, 1, 2, 10, 0),
    );
    
    await repository.logViolation(v1);
    await repository.logViolation(v2); 
    
    final all = await repository.getViolations();
    expect(all.length, 2);
  });
}
