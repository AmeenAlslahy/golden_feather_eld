import 'package:flutter/widgets.dart';

import '../../../core/extensions/context_extensions.dart';
import '../domain/engine/tracking/duty_status_tracker.dart';

String dutyChangeMessage(BuildContext context, String code) {
  final arabic = Localizations.localeOf(context).languageCode == 'ar';
  switch (code) {
    case DutyStampRefusal.moving:
      return context.loc.errorCannotChangeStatusWhileMoving;
    case DutyStampRefusal.sessionMissing:
      return context.loc.sessionMissing;
    case DutyStampRefusal.timeUnavailable:
      return arabic
          ? 'لم يُسجل الواجب لأن وقت الخادم غير متاح.'
          : 'Duty status was not recorded because server time is unavailable.';
    case DutyStampRefusal.notReady:
      return arabic ? 'حالة الواجب غير جاهزة.' : 'Duty status is not ready.';
    case DutyStampRefusal.unmapped:
      return arabic ? 'حالة الواجب غير معروفة.' : 'Duty status is not recognized.';
    case DutyStampRefusal.serverRejected:
      return arabic
          ? 'لم يقبل الخادم تغيير الحالة. تحقق من الاتصال وحاول مجدداً.'
          : 'The server did not accept the duty status change. Check your connection and try again.';
    default:
      return code;
  }
}

String dutyChangeAcceptedMessage(BuildContext context) {
  final arabic = Localizations.localeOf(context).languageCode == 'ar';
  return arabic
      ? 'قبل الخادم تغيير حالة الواجب.'
      : 'The server accepted the duty status change.';
}
