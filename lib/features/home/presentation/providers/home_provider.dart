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

/// قائمة السائق. About is required by SRS 2.2 (existing About route).
class EldMenu {
  static const List<MenuItem> items = [
    MenuItem(
        title: 'Status',
        arabicTitle: 'الحالة',
        icon: Icons.access_time,
        route: AppRoutes.home),
    MenuItem(
        title: 'Logs',
        arabicTitle: 'السجلات',
        icon: Icons.description_outlined,
        route: AppRoutes.logs),
    MenuItem(
        title: 'DVIR',
        arabicTitle: 'فحص المركبة',
        icon: Icons.build_outlined,
        route: AppRoutes.dvir),
    MenuItem(
        title: 'DOT Inspection',
        arabicTitle: 'تفتيش DOT',
        icon: Icons.check_circle_outline,
        route: AppRoutes.inspection),
    MenuItem(
        title: 'Rules',
        arabicTitle: 'القواعد',
        icon: Icons.list_alt,
        route: AppRoutes.rules),
    MenuItem(
        title: 'Co-driver',
        arabicTitle: 'سائق مساعد',
        icon: Icons.person_add_alt,
        route: AppRoutes.codriver),
    MenuItem(
        title: 'Select Vehicle',
        arabicTitle: 'اختيار المركبة',
        icon: Icons.airport_shuttle_outlined,
        route: AppRoutes.selectVehicle),
    MenuItem(
        title: 'Account',
        arabicTitle: 'الحساب',
        icon: Icons.person_outline,
        route: AppRoutes.account),
    MenuItem(
        title: 'Information Packet',
        arabicTitle: 'حزمة المعلومات',
        icon: Icons.info_outline,
        route: AppRoutes.infoPacket),
    MenuItem(
        title: 'About',
        arabicTitle: 'حول التطبيق',
        icon: Icons.help_outline,
        route: AppRoutes.about),
  ];
}

final menuProvider = Provider<List<MenuItem>>((ref) {
  return EldMenu.items;
});
