import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/http/eld_endpoints.dart';

void main() {
  group('EldEndpoints', () {
    test('Authentication & Standard Traccar Entities match expected routes', () {
      expect(EldEndpoints.authSession, '/session');
      expect(EldEndpoints.password, '/password');
      expect(EldEndpoints.devices, '/devices');
      expect(EldEndpoints.positions, '/positions');
      expect(EldEndpoints.events, '/events');
      expect(EldEndpoints.drivers, '/drivers');
      expect(EldEndpoints.socket, '/socket');
    });

    test('ELD Module core endpoints match OAS 3.0.1 routes', () {
      expect(EldEndpoints.account, '/eld/account');
      expect(EldEndpoints.accountPreferences, '/eld/account/preferences');
      expect(EldEndpoints.statusDashboard, '/eld/hos/dashboard');
      expect(EldEndpoints.status, '/eld/hos/dashboard');
      expect(EldEndpoints.updateDutyStatus, '/eld/hos/status');
      expect(EldEndpoints.statusRecap, '/eld/hos/recap');
      expect(EldEndpoints.rulesScreen, '/eld/driver-rules');
      expect(EldEndpoints.dailyLogs, '/eld/daily-logs');
      expect(EldEndpoints.recordDutyStatusEvent, '/eld/hos');
      expect(EldEndpoints.recordDutyStatus, '/eld/hos');
      expect(EldEndpoints.legacyGraphGridTimeline, '/eld/duty-status/graph-grid');
      expect(EldEndpoints.graphGridTimeline, '/eld/duty-status/graph-grid');
      expect(EldEndpoints.dvir, '/eld/dvir');
      expect(EldEndpoints.dvirCatalog, '/eld/dvir/catalog');
      expect(EldEndpoints.inspections, '/eld/inspections');
      expect(EldEndpoints.hardwareAlerts, '/eld/hardware/alerts');
      expect(EldEndpoints.hardwareManualMode, '/eld/hardware/manual-mode');
      expect(EldEndpoints.hardwareReadiness, '/eld/hardware/readiness');
      expect(EldEndpoints.hardwareStatus, '/eld/hardware/status');
      expect(EldEndpoints.unidentifiedEvents, '/eld/unidentified');
      expect(EldEndpoints.unidentifiedEvent(5), '/eld/unidentified/5');
      expect(EldEndpoints.unidentifiedSummary, '/eld/unidentified/summary');
      expect(EldEndpoints.companyVehicles, '/eld/vehicles');
      expect(EldEndpoints.myVehicles, '/eld/vehicles/my-vehicles');
    });

    test('Parameterized endpoints format correctly', () {
      expect(EldEndpoints.dailyLogDetails(42), '/eld/daily-logs/42');
      expect(EldEndpoints.respondCarrierEdit(42, 'edit_1'),
          '/eld/daily-logs/42/carrier-edits/edit_1/respond');
      expect(EldEndpoints.certifyLog(42), '/eld/daily-logs/42/certify');
      expect(EldEndpoints.reassignDriving(42, 7),
          '/eld/daily-logs/42/events/7/reassign-driving');
      expect(EldEndpoints.dailyLogForm(42), '/eld/daily-logs/42/form');
      expect(EldEndpoints.dailyLogFormOptions(42),
          '/eld/daily-logs/42/form/options');
      expect(EldEndpoints.dailyLogEvents(42), '/eld/daily-logs/42/events');
      expect(EldEndpoints.dailyLogEvent(42, 1004),
          '/eld/daily-logs/42/events/1004');
      expect(EldEndpoints.dailyLogEventsOptions(42),
          '/eld/daily-logs/42/events/options');
      expect(EldEndpoints.dailyLogSummary, '/eld/daily-logs/summary');
      expect(EldEndpoints.lockLog(42), '/eld/daily-logs/42/lock');
      expect(EldEndpoints.checkReadiness(42), '/eld/daily-logs/42/readiness');
      expect(EldEndpoints.teamStatus(42), '/eld/daily-logs/42/team');
      expect(EldEndpoints.eldSession(106), '/eld/sessions/106');
      expect(EldEndpoints.getSession(106), '/eld/sessions/106');
      expect(EldEndpoints.sessionMembers(99), '/eld/sessions/99/members');
      expect(EldEndpoints.legacyEditDutyStatus(15), '/eld/duty-status/15');
      expect(EldEndpoints.editDutyStatus(15), '/eld/duty-status/15');
      expect(EldEndpoints.legacyEditDutyStatusForm(15),
          '/eld/duty-status/15/edit-form');
      expect(
          EldEndpoints.editDutyStatusForm(15), '/eld/duty-status/15/edit-form');
      expect(EldEndpoints.dvirDetails(8), '/eld/dvir/8');
      expect(EldEndpoints.dvirNextDriverReview(8), '/eld/dvir/8/review');
      expect(EldEndpoints.dvirPrevious('TRK-101'), '/eld/dvir/pre-trip/TRK-101');
      expect(EldEndpoints.dvirDefectDetails(3), '/eld/dvir/defects/3');
      expect(EldEndpoints.dvirVehicleDefects('TRK-101'),
          '/eld/dvir/defects/device/TRK-101');
      expect(EldEndpoints.claimUnidentified(5), '/eld/unidentified/5/claim');
      expect(EldEndpoints.rejectUnidentified(5), '/eld/unidentified/5/reject');
    });
  });
}
