import 'package:fpdart/fpdart.dart' as fp;

import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/result/result.dart';
import '../../../../features/account/domain/entities/rules_screen_model.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/rules_screen_backend.dart';
import '../../eld_engine/mappers/rules_screen_mapper.dart';
import '../../eld_engine/models/rules_screen_dto.dart';

/// In-memory mock for [RulesScreenBackend].
class MockRulesScreenBackend implements RulesScreenBackend {
  Map<String, dynamic> _state = {
    'driver': 100,
    'ruleSource': 'SnSoft - ELD',
    'cycleRule': 'USA 70 hour / 8 day',
    'cargoType': 'Property',
    'restart': '34 Hour Restart',
    'restBreak': '30 Minute Rest Break Required',
    'sixteenHourException': false,
    'options': {
      'cycleRule': [
        'USA 70 hour / 8 day',
        'USA 60 hour / 7 day',
        'Texas 70 hour / 7 day'
      ],
      'cargoType': ['Property', 'Passenger'],
      'restart': ['34 Hour Restart', '24 Hour Restart', 'None'],
      'restBreak': ['30 Minute Rest Break Required', 'None']
    },
    'limits': {
      'cycleHours': 70,
      'cycleDays': 8,
      'maxShiftHours': 14,
      'maxDrivingHours': 11,
      'mandatoryRestHours': 10
    },
    'editableFields': [
      'cycleRule',
      'cargoType',
      'restart',
      'restBreak',
      'sixteenHourException'
    ],
    'readOnlyFields': [],
    'fixedSettings': {},
    'notice': 'All fields are available for local testing.'
  };

  MockRulesScreenBackend();

  @override
  Future<Result<RulesScreenModel>> getRulesScreen({DriverId? driverId}) async {
    final dto = RulesScreenDto.fromJson(_state);
    return fp.Right(RulesScreenMapper.toModel(dto));
  }

  @override
  Future<Result<RulesScreenModel>> saveRulesScreen({
    required DriverId driverId,
    required RawJson update,
  }) async {
    _state = {
      ..._state,
      ...update,
    };
    final dto = RulesScreenDto.fromJson(_state);
    return fp.Right(RulesScreenMapper.toModel(dto));
  }
}
