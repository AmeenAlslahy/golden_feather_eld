import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/extensions/context_extensions.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/inspection_data.dart';
import '../providers/inspection_provider.dart';

/// شاشة إرسال السجلات
class SendLogsPage extends ConsumerStatefulWidget {
  final bool isEmailMode;

  const SendLogsPage({super.key, this.isEmailMode = false});

  @override
  ConsumerState<SendLogsPage> createState() => _SendLogsPageState();
}

class _SendLogsPageState extends ConsumerState<SendLogsPage> {
  final _emailController = TextEditingController();
  final _routingCodeController = TextEditingController();
  TransferMethod _selectedMethod = TransferMethod.webService;
  bool _isSending = false;
  bool _sent = false;
  bool _exportAsErods = true;

  @override
  void dispose() {
    _emailController.dispose();
    _routingCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (widget.isEmailMode) {
      final email = _emailController.text.trim();
      if (email.isEmpty ||
          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.loc.invalidValue),
            backgroundColor: AppColors.dangerRed,
          ),
        );
        return;
      }
    }

    setState(() => _isSending = true);

    final notifier = ref.read(inspectionProvider.notifier);
    final success = await notifier.sendLogs(
      widget.isEmailMode ? TransferMethod.email : _selectedMethod,
      email: widget.isEmailMode ? _emailController.text : null,
      isErods: _exportAsErods,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
        _sent = success;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEmailMode ? 'Email Logs' : 'Send Logs',
          style: const TextStyle(
            fontSize: AppTypography.bodySize,
            fontWeight: AppTypography.bold,
            color: AppColors.surface,
          ),
        ),
      ),
      body: _sent
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.successGreen, size: 80),
                  AppGap.lg,
                  Text(
                    widget.isEmailMode ? 'Email Sent!' : 'Logs Sent!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isEmailMode) ...[
                    Text(
                      'Send logs via email',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    AppGap.lg,
                    AppTextField(
                      controller: _emailController,
                      label: 'Recipient Email',
                      hint: 'some@email.com',
                      keyboardType: TextInputType.emailAddress,
                      isUnderlined: true,
                    ),
                  ] else ...[
                    Text(
                      'Select transfer method',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    AppGap.md,
                    ...TransferMethod.values
                        .map((method) => RadioListTile<TransferMethod>(
                              title: Text(method.englishName),
                              value: method,
                              groupValue: _selectedMethod,
                              onChanged: (value) {
                                setState(() => _selectedMethod = value!);
                              },
                              activeColor: AppColors.primaryBlue,
                            )),
                    if (_selectedMethod == TransferMethod.webService) ...[
                      AppGap.md,
                      AppTextField(
                        controller: _routingCodeController,
                        label: 'Routing Code',
                        hint: 'Enter officer routing code',
                      ),
                    ],
                  ],
                  AppGap.lg,
                  SwitchListTile(
                    title: Text(context.loc.exportErods),
                    subtitle: Text(context.loc.requiredForFmcsa),
                    value: _exportAsErods,
                    activeThumbColor: AppColors.primaryBlue,
                    onChanged: (val) {
                      setState(() => _exportAsErods = val);
                    },
                  ),
                  AppGap.xl,
                  AppButton(
                    label: widget.isEmailMode ? 'SEND EMAIL' : 'SEND LOGS',
                    isLoading: _isSending,
                    onPressed: _isSending ? null : _handleSend,
                  ),
                ],
              ),
            ),
    );
  }
}
