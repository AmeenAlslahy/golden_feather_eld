import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../routes.dart';

/// عنصر في القائمة
class MenuItem {
  final String title;
  final String arabicTitle;
  final IconData icon;
  final String route;

  const MenuItem({
    required this.title,
    required this.arabicTitle,
    required this.icon,
    required this.route,
  });
}

/// قائمة ELD الرئيسية
class EldMenu {
  static const List<MenuItem> items = [
    MenuItem(title: 'Status', arabicTitle: 'الحالة', icon: Icons.dashboard, route: AppRoutes.home),
    MenuItem(title: 'Logs', arabicTitle: 'السجلات', icon: Icons.list_alt, route: AppRoutes.logs),
    MenuItem(title: 'DVIR', arabicTitle: 'فحص المركبة', icon: Icons.engineering, route: AppRoutes.dvir),
    MenuItem(title: 'Vehicles', arabicTitle: 'المركبات', icon: Icons.local_shipping, route: AppRoutes.selectVehicle),
    MenuItem(title: 'Inspection', arabicTitle: 'التفتيش', icon: Icons.assignment_turned_in, route: AppRoutes.inspection),
    MenuItem(title: 'Co-Driver', arabicTitle: 'سائق مساعد', icon: Icons.people, route: AppRoutes.codriver),
    MenuItem(title: 'Account', arabicTitle: 'الحساب', icon: Icons.person, route: AppRoutes.account),
    MenuItem(title: 'Rules', arabicTitle: 'القواعد', icon: Icons.gavel, route: AppRoutes.rules),
    MenuItem(title: 'Info Packet', arabicTitle: 'الوثائق', icon: Icons.description, route: AppRoutes.infoPacket),
    MenuItem(title: 'Settings', arabicTitle: 'الإعدادات', icon: Icons.settings, route: AppRoutes.settings),
    MenuItem(title: 'Reports', arabicTitle: 'التقارير', icon: Icons.assessment, route: AppRoutes.reports),
    MenuItem(title: 'Tracking', arabicTitle: 'تتبع الموقع', icon: Icons.location_on, route: AppRoutes.tracking),
    MenuItem(title: 'Tracking Logs', arabicTitle: 'سجلات التتبع', icon: Icons.history, route: AppRoutes.trackingLogs),
    MenuItem(title: 'Developer Options', arabicTitle: 'خيارات المطور', icon: Icons.code, route: AppRoutes.developerOptions),
  ];
}

/// مزود القائمة
final menuProvider = Provider<List<MenuItem>>((ref) {
  return EldMenu.items;
});



