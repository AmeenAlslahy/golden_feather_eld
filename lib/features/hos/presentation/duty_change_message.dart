import 'package:flutter/widgets.dart';

import '../../../core/extensions/context_extensions.dart';
import '../domain/engine/tracking/duty_status_tracker.dart';

String dutyChangeMessage(BuildContext context, String code) {
  switch (code) {
    case DutyStampRefusal.moving:
      return context.loc.errorCannotChangeStatusWhileMoving;
    case DutyStampRefusal.sessionMissing:
      return context.loc.sessionMissing;
    case DutyStampRefusal.timeUnavailable:
      return context.loc.dutyChangeTimeUnavailable;
    case DutyStampRefusal.notReady:
      return context.loc.dutyChangeNotReady;
    case DutyStampRefusal.unmapped:
      return context.loc.dutyChangeUnmapped;
    case DutyStampRefusal.serverRejected:
      return context.loc.dutyChangeServerRejected;
    default:
      return code;
  }
}

String dutyChangeAcceptedMessage(BuildContext context) {
  return context.loc.dutyChangeAccepted;
}

String annotationRequiredMessage(BuildContext context) {
  return context.loc.annotationRequiredForPcYm;
}

