/// Shared enums used across backend contracts.
/// These mirror the wire values from the Swagger spec.
library;

enum InspectionTransferType {
  webServices('WEB_SERVICES'),
  email('EMAIL'),
  usb('USB'),
  bluetooth('BLUETOOTH');

  const InspectionTransferType(this.wire);
  final String wire;
}

enum InspectionTransferProtocol {
  usbHostMode('USB_HOST_MODE'),
  bluetoothLe('BLUETOOTH_LE'),
  qrCode('QR_CODE'),
  webServices('WEB_SERVICES'),
  email('EMAIL');

  const InspectionTransferProtocol(this.wire);
  final String wire;
}

enum ReportFormat {
  pdf('pdf'),
  csv('csv'),
  json('json'),
  xml('xml'),
  html('html');

  const ReportFormat(this.wire);
  final String wire;
}

enum UnidentifiedTab {
  unclaimed('UNCLAIMED'),
  rejected('REJECTED');

  const UnidentifiedTab(this.wire);
  final String wire;
}

enum DutyStatusAction {
  switchPrimary('switch-primary'),
  legacySwitch('legacy-switch');

  const DutyStatusAction(this.wire);
  final String wire;
}
