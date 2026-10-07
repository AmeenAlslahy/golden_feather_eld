import 'package:fpdart/fpdart.dart' as fp;
import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
import '../../../contracts/raw_json.dart';
import '../../../contracts/rules_screen_backend.dart';
import '../../eld_engine/models/rules_screen_dto.dart';
import '../../eld_engine/mappers/rules_screen_mapper.dart';

/// In-memory mock for [RulesScreenBackend].
class MockRulesScreenBackend implements RulesScreenBackend {
  Map<String, dynamic> _state = {
    // موحد مع بقية الموكات (101) — 100 هنا كانت تولّد تضاربًا في الاختبارات.
    "driver": 101,
    "ruleSource": "SnSoft - ELD",
    // القيم يجب أن تطابق CycleRule.wire — النصوص الطويلة السابقة كانت
    // تجعل أي حفظ في وضع الموك يُرسل قيمة لا يعترف بها fromWire.
    "cycleRule": "USA 70/8",
    "cargoType": "Property",
    "restart": "34 Hour Restart",
    "restBreak": "30 Minute Rest Break Required",
    "sixteenHourException": false,
    "options": {
      "cycleRule": [
        "USA 70/8",
        "USA 60/7",
        "CANADA_SOUTH_70_7"
      ],
      "cargoType": ["Property", "Passenger"],
      "restart": ["34 Hour Restart", "24 Hour Restart", "None"],
      "restBreak": ["30 Minute Rest Break Required", "None"]
    },
    "limits": {
      "cycleHours": 70,
      "cycleDays": 8,
      "maxShiftHours": 14,
      "maxDrivingHours": 11,
      "mandatoryRestHours": 10
    },
    "editableFields": [
      "cycleRule",
      "cargoType",
      "restart",
      "restBreak",
      "sixteenHourException"
    ],
    "readOnlyFields": [],
    "fixedSettings": {},
    "notice": "All fields are available for local testing."
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
