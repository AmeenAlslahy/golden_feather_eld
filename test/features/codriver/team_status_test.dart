import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/http/eld_endpoints.dart';
import 'package:golden_feather_eld/features/codriver/domain/team_status.dart';

/// `GET /eld/daily-logs/{id}/team` — live body 2026-09-25 + Swagger example.
void main() {
  test('path matches Swagger', () {
    expect(EldEndpoints.teamStatus(1), '/eld/daily-logs/1/team');
  });

  test('live body: no co-driver, HOS isolated, note kept verbatim', () {
    final read = parseTeamStatus(const {
      'success': true,
      'data': {
        'dailyLogId': 1,
        'primaryDriver': {'id': 101, 'name': 'سعد بن محمد العتيبي'},
        'teamModeActive': false,
        'hosRecordsIsolated': true,
        'complianceNote': 'سجلات HOS مستقلة تماماً وفق متطلبات البند 5.8 ولوائح FMCSA',
      },
      'requestId': '1e5806e9',
    })!;
    expect(read.dailyLogId, 1);
    expect(read.primaryDriverName, 'سعد بن محمد العتيبي');
    expect(read.coDriverName, isNull);
    expect(read.teamModeActive, isFalse);
    expect(read.hosRecordsIsolated, isTrue);
    expect(read.complianceNote, contains('5.8'));
  });

  test('missing hosRecordsIsolated stays unknown (never assumed true)', () {
    final read = parseTeamStatus(const {'dailyLogId': 2, 'teamModeActive': true})!;
    expect(read.hosRecordsIsolated, isNull);
    expect(read.teamModeActive, isTrue);
  });

  test('non-object body is unreadable', () {
    expect(parseTeamStatus('x'), isNull);
    expect(parseTeamStatus(const {'data': 'x'}), isNull);
  });
}
