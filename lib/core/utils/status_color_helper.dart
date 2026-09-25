import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusColorHelper {
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ON':
        return AppColors.primaryGold;
      case 'OFF':
        return AppColors.textSecondary;
      case 'D':
      case 'DRIVING':
        return AppColors.successGreen;
      case 'SB':
        return AppColors.warningYellow;
      case 'YM':
      case 'PC':
        return AppColors.primaryGold;
      default:
        return AppColors.textSecondary;
    }
  }
}
