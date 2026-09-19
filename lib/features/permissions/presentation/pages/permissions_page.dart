import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import 'package:go_router/go_router.dart';

/// صفحة طلب الصلاحيات الأولية
class PermissionsPage extends ConsumerStatefulWidget {
  const PermissionsPage({super.key});

  @override
  ConsumerState<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends ConsumerState<PermissionsPage> {
  bool _locationGranted = false;
  bool _bluetoothGranted = false;
  bool _notificationGranted = false;
  bool _batteryGranted = false;
  bool _cameraGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final locationStatus = await Permission.location.status;
    final bluetoothStatus = await Permission.bluetooth.status;
    final notificationStatus = await Permission.notification.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    final cameraStatus = await Permission.camera.status;

    setState(() {
      _locationGranted = locationStatus.isGranted;
      _bluetoothGranted = bluetoothStatus.isGranted;
      _notificationGranted = notificationStatus.isGranted;
      _batteryGranted = batteryStatus.isGranted;
      _cameraGranted = cameraStatus.isGranted;
    });
  }

  Future<void> _requestLocation() async {
    final status = await Permission.location.request();
    final alwaysStatus = await Permission.locationAlways.request();
    setState(
        () => _locationGranted = alwaysStatus.isGranted || status.isGranted);

    if (!status.isGranted) {
      _showRequiredPermissionDialog(
        title: 'صلاحية الموقع مطلوبة',
        message: 'يحتاج تطبيق ELD إلى الوصول للموقع الجغرافي بشكل دائم '
            'لتسجيل مسار المركبة وساعات القيادة تلقائياً.\n\n'
            'هذا متطلب قانوني من FMCSA ولا يمكن عمل التطبيق بدونه.',
        isRequired: true,
      );
    }
  }

  Future<void> _requestBluetooth() async {
    final status = await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    setState(() => _bluetoothGranted = status.isGranted);

    if (!status.isGranted) {
      _showRequiredPermissionDialog(
        title: 'صلاحية البلوتوث',
        message: 'يحتاج التطبيق للاتصال بجهاز ELD في المركبة.\n\n'
            'يمكنك المتابعة بدون بلوتوث ولكن سيتم تسجيل '
            'ساعات القيادة يدوياً.',
        isRequired: false,
      );
    }
  }

  Future<void> _requestNotification() async {
    final status = await Permission.notification.request();
    setState(() => _notificationGranted = status.isGranted);
  }

  Future<void> _requestBattery() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    setState(() => _batteryGranted = status.isGranted);
  }

  Future<void> _requestCamera() async {
    final status = await Permission.camera.request();
    setState(() => _cameraGranted = status.isGranted);
  }

  void _showRequiredPermissionDialog({
    required String title,
    required String message,
    required bool isRequired,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isRequired ? Icons.error : Icons.warning_amber,
              color: isRequired ? AppColors.dangerRed : AppColors.warningYellow,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          if (!isRequired)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToLogin();
              },
              child: Text(context.loc.continueWithout),
            ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (isRequired) {
                // إعادة طلب الصلاحية
                _requestLocation();
              } else {
                _navigateToLogin();
              }
            },
            child: Text(isRequired ? 'منح الصلاحية' : 'موافق'),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    if (_locationGranted) {
      context.goNamed('login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // شعار التطبيق
              Icon(
                Icons.local_shipping,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),

              Text(
                'صلاحيات التطبيق',
                textAlign: TextAlign.center,
                style: AppTextStyles(context).pageTitle,
              ),
              const SizedBox(height: 8),
              Text(
                'يحتاج تطبيق ELD للصلاحيات التالية\nللعمل بشكل قانوني',
                textAlign: TextAlign.center,
                style: AppTextStyles(context).body,
              ),
              const SizedBox(height: 48),

              // الصلاحيات المطلوبة
              _buildPermissionTile(
                icon: Icons.location_on,
                title: 'الموقع الجغرافي',
                subtitle: 'لتسجيل مسار المركبة وساعات القيادة تلقائياً',
                isRequired: true,
                isGranted: _locationGranted,
                onRequest: _requestLocation,
              ),
              const SizedBox(height: AppSpacing.md),

              _buildPermissionTile(
                icon: Icons.bluetooth,
                title: 'البلوتوث',
                subtitle: 'للاتصال بجهاز ELD في المركبة',
                isRequired: false,
                isGranted: _bluetoothGranted,
                onRequest: _requestBluetooth,
              ),
              const SizedBox(height: AppSpacing.md),

              _buildPermissionTile(
                icon: Icons.notifications,
                title: 'الإشعارات',
                subtitle: 'للحصول على تنبيهات ساعات القيادة',
                isRequired: false,
                isGranted: _notificationGranted,
                onRequest: _requestNotification,
              ),
              _buildPermissionTile(
                icon: Icons.battery_alert,
                title: 'توفير البطارية',
                subtitle: 'يجب تعطيله لضمان عمل التتبع في الخلفية',
                isRequired: true,
                isGranted: _batteryGranted,
                onRequest: _requestBattery,
              ),
              const SizedBox(height: AppSpacing.md),

              _buildPermissionTile(
                icon: Icons.camera_alt,
                title: 'الكاميرا',
                subtitle: 'لالتقاط صور فحص المركبة (DVIR)',
                isRequired: false,
                isGranted: _cameraGranted,
                onRequest: _requestCamera,
              ),
              const Spacer(),

              // زر المتابعة
              AppButton(
                label: (_locationGranted && _batteryGranted)
                    ? 'متابعة'
                    : 'منح الصلاحيات',
                onPressed: (_locationGranted && _batteryGranted)
                    ? _navigateToLogin
                    : () {
                        if (!_locationGranted) _requestLocation();
                        if (!_batteryGranted) _requestBattery();
                      },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isRequired,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: isGranted ? AppColors.successGreen : AppColors.textSecondary,
          size: 32,
        ),
        title: Row(
          children: [
            Expanded(child: Text(title)),
            if (isRequired)
              const AppStatusBadge(
                label: 'مطلوب',
                type: AppStatusBadgeType.error,
              ),
          ],
        ),
        subtitle: Text(subtitle),
        trailing: isGranted
            ? const Icon(Icons.check_circle, color: AppColors.successGreen)
            : TextButton(
                onPressed: onRequest,
                child: Text(context.loc.grant),
              ),
      ),
    );
  }
}
