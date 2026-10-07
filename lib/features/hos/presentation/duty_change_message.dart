import 'package:flutter/widgets.dart';

import '../../../core/extensions/context_extensions.dart';
import '../domain/engine/tracking/duty_status_tracker.dart';

String dutyChangeMessage(BuildContext context, String code) {
  final lang = Localizations.localeOf(context).languageCode;
  switch (code) {
    case DutyStampRefusal.moving:
      return context.loc.errorCannotChangeStatusWhileMoving;
    case DutyStampRefusal.sessionMissing:
      return context.loc.sessionMissing;
    case DutyStampRefusal.timeUnavailable:
      return switch (lang) {
        'ar' => 'لم يُسجل الواجب لأن وقت الخادم غير متاح.',
        'es' => 'El estado de servicio no se registró porque la hora del servidor no está disponible.',
        _ => 'Duty status was not recorded because server time is unavailable.',
      };
    case DutyStampRefusal.notReady:
      return switch (lang) {
        'ar' => 'حالة الواجب غير جاهزة.',
        'es' => 'El estado de servicio no está listo.',
        _ => 'Duty status is not ready.',
      };
    case DutyStampRefusal.unmapped:
      return switch (lang) {
        'ar' => 'حالة الواجب غير معروفة.',
        'es' => 'El estado de servicio no es reconocido.',
        _ => 'Duty status is not recognized.',
      };
    case DutyStampRefusal.serverRejected:
      return switch (lang) {
        'ar' => 'لم يقبل الخادم تغيير الحالة. تحقق من الاتصال وحاول مجدداً.',
        'es' => 'El servidor no aceptó el cambio de estado de servicio. Verifique su conexión e intente nuevamente.',
        _ => 'The server did not accept the duty status change. Check your connection and try again.',
      };
    default:
      return code;
  }
}

String dutyChangeAcceptedMessage(BuildContext context) {
  final lang = Localizations.localeOf(context).languageCode;
  return switch (lang) {
    'ar' => 'قبل الخادم تغيير حالة الواجب.',
    'es' => 'El servidor aceptó el cambio de estado de servicio.',
    _ => 'The server accepted the duty status change.',
  };
}

String annotationRequiredMessage(BuildContext context) {
  final lang = Localizations.localeOf(context).languageCode;
  return switch (lang) {
    'ar' => 'يجب كتابة ملاحظة للقيادة الشخصية أو حركة الساحة.',
    'es' => 'Se requiere una anotación para uso personal o movimientos de patio.',
    _ => 'An annotation is required for personal conveyance or yard moves.',
  };
}
