import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../routes.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';

class EldConnectionState {
  final bool isConnecting;
  final bool hasFailed;

  EldConnectionState({this.isConnecting = false, this.hasFailed = false});

  EldConnectionState copyWith({bool? isConnecting, bool? hasFailed}) {
    return EldConnectionState(
      isConnecting: isConnecting ?? this.isConnecting,
      hasFailed: hasFailed ?? this.hasFailed,
    );
  }
}

class EldConnectionNotifier extends StateNotifier<EldConnectionState> {
  EldConnectionNotifier() : super(EldConnectionState());

  Future<void> attemptConnection() async {
    state = state.copyWith(isConnecting: true, hasFailed: false);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      state = state.copyWith(isConnecting: false, hasFailed: true);
    }
  }
}

final eldConnectionProvider = StateNotifierProvider.autoDispose<
    EldConnectionNotifier, EldConnectionState>((ref) {
  return EldConnectionNotifier();
});

class EldConnectionPage extends ConsumerStatefulWidget {
  const EldConnectionPage({super.key});

  @override
  ConsumerState<EldConnectionPage> createState() => _EldConnectionPageState();
}

class _EldConnectionPageState extends ConsumerState<EldConnectionPage> {
  final TextEditingController _macController =
      TextEditingController(text: '9824');

  @override
  void dispose() {
    _macController.dispose();
    super.dispose();
  }

  Future<void> _attemptConnection() async {
    await ref.read(eldConnectionProvider.notifier).attemptConnection();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardDataProvider);
    final connectionState = ref.watch(eldConnectionProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.compare_arrows,
              color: AppColors.surface, size: 28),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              context.go(AppRoutes.selectVehicle);
            }
          },
        ),
        title: Text(
          dashboard.vehicleId,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.surface,
              ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // شريط التنبيه الأحمر
            if (connectionState.hasFailed)
              Container(
                color: AppColors.dangerRed,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.md,
                ),
                child: Text(
                  '${context.loc.unableToConnect} "${_macController.text}".',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: AppTypography.bodySize,
                    fontWeight: AppTypography.semiBold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (connectionState.hasFailed) ...[
                    // عنوان قائمة التحقق
                    Text(
                      context.loc.verifyFollowingItems,
                      style: const TextStyle(
                        fontSize: AppTypography.bodySize,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildChecklistItem(context.loc.macEnteredCorrectly),
                    _buildChecklistItem(context.loc.hardwareProperlyInstalled),
                    _buildChecklistItem(context.loc.vehiclePowerOn),
                    _buildChecklistItem(context.loc.bluetoothEnabled),
                    _buildChecklistItem(context.loc.gpsEnabled),
                    const SizedBox(height: AppSpacing.lg),
                    Divider(color: Theme.of(context).dividerColor, height: 1),
                    const SizedBox(height: AppSpacing.lg),
                  ] else ...[
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // عنوان حقل MAC
                  Text(
                    context.loc.enterMacAddress,
                    style: const TextStyle(
                      fontSize: AppTypography.bodySize,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ✅ حقل إدخال موحد
                  AppTextField(
                    controller: _macController,
                    hint: '9824',
                    isUnderlined: true,
                    keyboardType: TextInputType.text,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ✅ زر اتصال
                  AppButton(
                    label: context.loc.connect,
                    type: EldButtonType.connect,
                    isLoading: connectionState.isConnecting,
                    onPressed: connectionState.isConnecting
                        ? null
                        : _attemptConnection,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ✅ زر متابعة بدون اتصال
                  AppButton(
                    label: context.loc.continueDisconnected,
                    type: EldButtonType.continueDisconnected,
                    onPressed: connectionState.isConnecting
                        ? null
                        : () => context.go(AppRoutes.home),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ بناء عنصر القائمة بشكل صحيح
  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
        left: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ نقطة بسيطة بدلاً من CircleAvatar
          const Padding(
            padding: EdgeInsets.only(top: 8.0, right: AppSpacing.sm),
            child: Icon(
              Icons.circle,
              size: 6,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: AppTypography.subtitleSize, // 14pt - موحد

                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
