import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/inspection_data.dart';
import '../../domain/inspection_transfer.dart';
import '../providers/dot_inspection_providers.dart';
import '../providers/inspection_provider.dart';

/// Email Logs (recipient only) vs Send Logs (comment 4–60 + Email type).
class SendLogsPage extends ConsumerStatefulWidget {
  final bool isEmailMode;

  const SendLogsPage({super.key, this.isEmailMode = false});

  @override
  ConsumerState<SendLogsPage> createState() => _SendLogsPageState();
}

class _SendLogsPageState extends ConsumerState<SendLogsPage> {
  final _emailController = TextEditingController();
  final _commentController = TextEditingController();
  final _routingController = TextEditingController();
  bool _isSending = false;
  bool _sent = false;

  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _commentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _commentController.dispose();
    _routingController.dispose();
    super.dispose();
  }

  bool get _emailValid {
    final email = _emailController.text.trim();
    return email.contains('@') && email.contains('.');
  }

  bool get _canSend {
    if (_isSending) return false;
    if (widget.isEmailMode) return _emailValid;
    return inspectionCommentError(_commentController.text) == null;
  }

  Future<void> _handleSend() async {
    if (widget.isEmailMode) {
      if (!_emailValid) {
        _snack(_arabic ? 'أدخل بريداً صالحاً.' : 'Enter a valid email.');
        return;
      }
    } else {
      final commentError = inspectionCommentError(
        _commentController.text,
        isArabic: _arabic,
      );
      if (commentError != null) {
        _snack(commentError);
        return;
      }
    }

    setState(() => _isSending = true);
    final comment = widget.isEmailMode
        ? 'Email logs transfer'
        : _commentController.text;
    final routing = _routingController.text.trim();
    final success = await ref.read(inspectionProvider.notifier).sendLogs(
          TransferMethod.email,
          email: widget.isEmailMode ? _emailController.text.trim() : null,
          comment: comment,
          routingCode: routing.isEmpty ? null : routing,
        );
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _sent = success;
    });
    if (!success) {
      final error = ref.read(inspectionProvider).error;
      if (error != null) _snack(error);
    } else {
      ref.invalidate(transferAuditProvider);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.dangerRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = ref.watch(inspectionProvider).transferMessage;
    final title = widget.isEmailMode
        ? (_arabic ? 'بريد السجلات' : 'Email Logs')
        : (_arabic ? 'إرسال السجلات' : 'Send Logs');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: context.styles.appBarTitle,
        ),
      ),
      body: _sent
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  message ??
                      (_arabic
                          ? 'قبل الخادم طلب النقل.'
                          : 'The server accepted the transfer request.'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.isEmailMode
                        ? (_arabic
                            ? 'إرسال السجلات عبر البريد'
                            : 'Send logs via email')
                        : (_arabic ? 'إرسال 8 سجلات' : 'Send 8 Logs'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (widget.isEmailMode) ...[
                    AppTextField(
                      controller: _emailController,
                      label: _arabic ? 'بريد المستلم' : 'Recipient Email',
                      hint: '',
                      keyboardType: TextInputType.emailAddress,
                      isUnderlined: true,
                    ),
                  ] else ...[
                    AppTextField(
                      controller: _commentController,
                      label: _arabic ? 'تعليق' : 'Comment',
                      hint: '',
                      isUnderlined: true,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      _arabic ? 'نوع نقل البيانات' : 'Data Transfer Type',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _arabic ? 'بريد إلكتروني' : 'Email',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Divider(height: 24),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    controller: _routingController,
                    label: _arabic ? 'رمز التوجيه' : 'Routing Code',
                    hint: '',
                    isUnderlined: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: _arabic ? 'إرسال' : 'SEND',
                    type: _canSend ? EldButtonType.agree : EldButtonType.send,
                    isLoading: _isSending,
                    onPressed: _handleSend,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _TransferHistory(isArabic: _arabic),
                ],
              ),
            ),
    );
  }
}

class _TransferHistory extends ConsumerWidget {
  const _TransferHistory({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audit = ref.watch(transferAuditProvider);
    return audit.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => Text(
        error is AppError
            ? appErrorUserMessage(error, isArabic: isArabic)
            : (isArabic
                ? 'تعذر جلب سجل النقل.'
                : 'Could not load transfer history.'),
        style: context.styles.muted,
        textAlign: TextAlign.center,
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return Text(
            isArabic ? 'لا يوجد سجل نقل بعد.' : 'No transfer history yet.',
            style: context.styles.muted,
            textAlign: TextAlign.center,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isArabic ? 'آخر عمليات النقل' : 'Recent transfers',
              style: context.styles.sectionTitle,
            ),
            const SizedBox(height: 8),
            for (final row in rows.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  [
                    row.channel,
                    row.status,
                    row.recipient,
                    row.transferredAt,
                  ].where((part) => part.isNotEmpty).join(' · '),
                  style: context.styles.caption,
                ),
              ),
          ],
        );
      },
    );
  }
}
