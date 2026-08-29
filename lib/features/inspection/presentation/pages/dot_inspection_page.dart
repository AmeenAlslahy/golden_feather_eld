import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../domain/entities/inspection_data.dart';
import '../providers/inspection_provider.dart';
import 'send_logs_page.dart';
import '../../../../core/services/file_sharing_service.dart';

/// شاشة DOT Inspection
class DotInspectionPage extends ConsumerStatefulWidget {
  const DotInspectionPage({super.key});

  @override
  ConsumerState<DotInspectionPage> createState() => _DotInspectionPageState();
}

class _DotInspectionPageState extends ConsumerState<DotInspectionPage> {
  final _pinController = TextEditingController();
  int _currentDayIndex = 0;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _showPinSetupDialog() {
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.loc.setInspectionPin),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.loc.enter4DigitPin,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: confirmPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.loc.confirmPin,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () {
              if (newPinController.text == confirmPinController.text &&
                  newPinController.text.length == 4) {
                ref.read(inspectionProvider.notifier).setPinCode(newPinController.text);
                ref.read(inspectionProvider.notifier).startInspection();
                Navigator.pop(context);
              }
            },
            child: Text(context.loc.startInspection),
          ),
        ],
      ),
    );
  }

  void _showUnlockDialog() {
    final unlockController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.loc.enterPinToUnlock),
        content: TextField(
          controller: unlockController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              final success = ref.read(inspectionProvider.notifier).unlock(unlockController.text);
              if (success) {
                ref.read(inspectionProvider.notifier).endInspection();
                setState(() => _currentDayIndex = 0);
                Navigator.pop(context);
              } else {
                unlockController.clear();
              }
            },
            child: Text(context.loc.unlock),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inspectionState = ref.watch(inspectionProvider);
    final currentDay = inspectionState.days.isNotEmpty
        ? inspectionState.days[_currentDayIndex]
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        automaticallyImplyLeading: !inspectionState.isInspectionMode,
        title: Text(
          context.loc.dotInspection,
          style: const TextStyle(
            fontSize: AppTypography.bodySize,
            fontWeight: AppTypography.bold,
            color: AppColors.surface,
          ),
        ),
        leading: inspectionState.isInspectionMode
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.surface),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
      ),
      drawer: inspectionState.isInspectionMode ? null : const EldDrawer(),
      body: PopScope(
        canPop: !inspectionState.isInspectionMode,
        onPopInvokedWithResult: (didPop, result) {
          if (inspectionState.isInspectionMode && !didPop) {
            _showUnlockDialog();
          }
        },
        child: inspectionState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : !inspectionState.isInspectionMode
                ? _buildStartInspection()
                : _buildInspectionView(currentDay, inspectionState),
      ),
    );
  }

  /// شاشة بدء التفتيش
  Widget _buildStartInspection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            Icon(Icons.assignment_turned_in,
                size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.loc.dotInspection,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.loc.startInspectionDesc,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: context.loc.startInspection.toUpperCase(),
              icon: Icons.lock,
              onPressed: _showPinSetupDialog,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: context.loc.sendLogs.toUpperCase(),
              type: EldButtonType.send,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SendLogsPage()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: context.loc.emailLogs.toUpperCase(),
              type: EldButtonType.send,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SendLogsPage(isEmailMode: true),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'تنزيل ومشاركة التقارير (EXCEL)',
              icon: Icons.share,
              onPressed: () async {
                try {
                  // إظهار مؤشر التحميل
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('جاري تجهيز وتنزيل التقرير...')),
                  );
                  // استدعاء خدمة المشاركة (تم إضافة معلمات افتراضية لتجنب خطأ 400 من الخادم)
                  final now = DateTime.now().toUtc();
                  final from = now.subtract(const Duration(days: 1)).toIso8601String();
                  final to = now.toIso8601String();
                  await ref.read(fileSharingServiceProvider).downloadAndShare(
                    '/api/reports/route',
                    queryParameters: {
                      'deviceId': 0, // معرف وهمي أو حقيقي إذا توفر
                      'from': from,
                      'to': to,
                    },
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dangerRed),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            // شهادة FMCSA
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified, color: AppColors.successGreen, size: 32),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'هذا التطبيق متوافق مع المعايير الدولية لسلامة النقل وإدارة الأساطيل'
                        : 'This application is compliant with international fleet safety standards',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: AppTypography.captionSize,
                      color: AppColors.successGreen,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Golden Feather ELD v1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTypography.smallSize,
                      color: AppColors.successGreen.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// عرض التفتيش مع السجلات
  Widget _buildInspectionView(InspectionDayData? currentDay, InspectionState state) {
    return Column(
      children: [
        // التنقل بين الأيام
        Container(
          color: AppColors.primaryBlue.withValues(alpha: 0.05),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentDayIndex < state.days.length - 1
                    ? () => setState(() => _currentDayIndex++)
                    : null,
              ),
              Text(
                currentDay?.formattedDate ?? '',
                style: const TextStyle(
                  fontSize: AppTypography.bodySize,
                  fontWeight: AppTypography.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentDayIndex > 0
                    ? () => setState(() => _currentDayIndex--)
                    : null,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // تفاصيل اليوم
        Expanded(
          child: currentDay == null
              ? Center(child: Text(context.loc.noData))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      EldCard(
                        child: Column(
                          children: [
                            _buildHosRow(context.loc.drivingStatus, '${currentDay.drivingHours}h', AppColors.successGreen),
                            const Divider(),
                            _buildHosRow(context.loc.onDuty, '${currentDay.onDutyHours}h', AppColors.warningYellow),
                            const Divider(),
                            _buildHosRow(context.loc.offDuty, '${currentDay.offDutyHours}h', AppColors.textSecondary),
                            const Divider(),
                            _buildHosRow(context.loc.sleeperBerth, '${currentDay.sleeperHours}h', AppColors.primaryBlue),
                            const Divider(),
                            _buildHosRow(context.loc.certified, currentDay.isCertified ? context.loc.yes : context.loc.no,
                                currentDay.isCertified ? AppColors.successGreen : AppColors.dangerRed),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: context.loc.endInspection.toUpperCase(),
                        type: EldButtonType.danger,
                        onPressed: () {
                          _showUnlockDialog();
                        },
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHosRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: AppTypography.bodySize)),
          Text(value,
              style: TextStyle(
                fontSize: AppTypography.bodySize,
                fontWeight: AppTypography.bold,
                color: color,
              )),
        ],
      ),
    );
  }
}
