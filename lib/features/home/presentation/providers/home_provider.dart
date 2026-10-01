import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../routes.dart';
import '../../../../l10n/app_localizations.dart';
/// عنصر في القائمة
class MenuItem {
  final String Function(AppLocalizations) titleBuilder;
  final IconData icon;
  final String route;

  const MenuItem({
    required this.titleBuilder,
    required this.icon,
    required this.route,
  });
}

/// قائمة السائق. About is required by SRS 2.2 (existing About route).
class EldMenu {
  static final List<MenuItem> items = [
    MenuItem(
        titleBuilder: (loc) => loc.statusTitle,
        icon: Icons.access_time,
        route: AppRoutes.home),
    MenuItem(
        titleBuilder: (loc) => loc.logsTitle,
        icon: Icons.description_outlined,
        route: AppRoutes.logs),
    MenuItem(
        titleBuilder: (loc) => loc.dvirTitle,
        icon: Icons.build_outlined,
        route: AppRoutes.dvir),
    MenuItem(
        titleBuilder: (loc) => loc.dotInspection,
        icon: Icons.check_circle_outline,
        route: AppRoutes.inspection),
    MenuItem(
        titleBuilder: (loc) => loc.rules,
        icon: Icons.list_alt,
        route: AppRoutes.rules),
    MenuItem(
        titleBuilder: (loc) => loc.coDriver,
        icon: Icons.person_add_alt,
        route: AppRoutes.codriver),
    MenuItem(
        titleBuilder: (loc) => loc.selectVehicle,
        icon: Icons.airport_shuttle_outlined,
        route: AppRoutes.selectVehicle),
    MenuItem(
        titleBuilder: (loc) => loc.account,
        icon: Icons.person_outline,
        route: AppRoutes.account),
    MenuItem(
        titleBuilder: (loc) => loc.infoPacket,
        icon: Icons.info_outline,
        route: AppRoutes.infoPacket),
    MenuItem(
        titleBuilder: (loc) => loc.aboutTitle,
        icon: Icons.help_outline,
        route: AppRoutes.about),
  ];
}

final menuProvider = Provider<List<MenuItem>>((ref) {
  return EldMenu.items;
});
