import 'package:flutter/material.dart';
import '../../domain/duty_status/duty_status_code.dart';

class StatusColorHelper {
  static Color getStatusColor(String status) {
    return DutyStatusCode.fromAny(status).displayColor;
  }
}
