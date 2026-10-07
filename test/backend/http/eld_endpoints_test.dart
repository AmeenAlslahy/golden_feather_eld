import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/http/eld_endpoints.dart';

void main() {
  group('EldEndpoints', () {
    test('Authentication & Standard Traccar Entities match expected routes', () {
      expect(EldEndpoints.session, '/session');
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
      expect(EldEndpoints.status, '/eld/status');
      expect(EldEndpoints.updateDutyStatus, '/eld/status/duty-status');
      expect(EldEndpoints.statusRecap, '/eld/status/recap');
      expect(EldEndpoints.rulesScreen, '/eld/rules-screen');
      expect(EldEndpoints.dailyLogs, '/eld/daily-logs');
      expect(EldEndpoints.recordDutyStatus, '/eld/duty-status');
      expect(EldEndpoints.graphGridTimeline, '/eld/duty-status/graph-grid');
      expect(EldEndpoints.dvir, '/eld/dvir');
      expect(EldEndpoints.dvirCatalog, '/eld/dvir/catalog');
      expect(EldEndpoints.inspections, '/eld/dot-inspection');
      expect(EldEndpoints.hardwareAlerts, '/eld/hardware/alerts');
      expect(EldEndpoints.hardwareManualMode, '/eld/hardware/manual-mode');
      expect(EldEndpoints.hardwareReadiness, '/eld/hardware/readiness');
      expect(EldEndpoints.hardwareStatus, '/eld/hardware/status');
      expect(EldEndpoints.unidentifiedEvents, '/eld/unidentified-events');
      expect(EldEndpoints.companyVehicles, '/eld/company-vehicles');
      expect(EldEndpoints.myVehicles, '/eld/company-vehicles/my-vehicles');
    });

    test('Parameterized endpoints format correctly', () {
      expect(EldEndpoints.dailyLogDetails(42), '/eld/daily-logs/42');
      expect(EldEndpoints.respondCarrierEdit(42, 'edit_1'),
          '/eld/daily-logs/42/carrier-edits/edit_1/respond');
      expect(EldEndpoints.certifyLog(42), '/eld/daily-logs/42/certify');
      expect(EldEndpoints.reassignDriving(42, 7),
          '/eld/daily-logs/42/events/7/reassign-driving');
      expect(EldEndpoints.dailyLogForm(42), '/eld/daily-logs/42/form');
      expect(EldEndpoints.dailyLogGraphGrid(42), '/eld/daily-logs/42/graph-grid');
      expect(EldEndpoints.lockLog(42), '/eld/daily-logs/42/lock');
      expect(EldEndpoints.checkReadiness(42), '/eld/daily-logs/42/readiness');
      expect(EldEndpoints.teamStatus(42), '/eld/daily-logs/42/team');
      expect(EldEndpoints.getSession(106), '/eld/sessions/106');
      expect(EldEndpoints.sessionMembers(99), '/eld/sessions/99/members');
      expect(EldEndpoints.editDutyStatus(15), '/eld/duty-status/15');
      expect(EldEndpoints.editDutyStatusForm(15), '/eld/duty-status/15/edit-form');
      expect(EldEndpoints.dvirDetails(8), '/eld/dvir/8');
      expect(EldEndpoints.dvirNextDriverReview(8), '/eld/dvir/8/review');
      expect(EldEndpoints.dvirPrevious('TRK-101'), '/eld/dvir/pre-trip/TRK-101');
      expect(EldEndpoints.dvirDefectDetails(3), '/eld/dvir/defects/3');
      expect(EldEndpoints.dvirVehicleDefects('TRK-101'),
          '/eld/dvir/defects/device/TRK-101');
      expect(EldEndpoints.claimUnidentified(5), '/eld/unidentified-events/5/claim');
      expect(EldEndpoints.rejectUnidentified(5), '/eld/unidentified-events/5/reject');
    });
  });
}
