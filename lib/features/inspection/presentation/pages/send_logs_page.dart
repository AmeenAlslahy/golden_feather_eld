import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../../../features/logs/domain/entities/audit_entry.dart';
import '../../../../features/logs/presentation/providers/logs_provider.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/inspection_data.dart';
import '../../domain/inspection_transfer.dart';
import '../providers/inspection_provider.dart';
import '../../../../core/widgets/app_feedback.dart';

/// FMCSA ELD submission mailbox (49 CFR §395 Appendix A, telematics email
/// option). Shown pre-filled; the officer can replace it.
const String kFmcsaEldEmail = 'fmcsaeldsub@dot.gov';

/// Default output-file comment for the email channel (4–60 chars).
const String kDefaultEmailComment = 'Email logs transfer';

/// Email Logs (preset recipient + comment) vs Send Logs (comment 4–60 + Email type).
class SendLogsPage extends ConsumerStatefulWidget {
  final bool isEmailMode;

  const SendLogsPage({super.key, this.isEmailMode = false});

  @override
  ConsumerState<SendLogsPage> createState() => _SendLogsPageState();
}

class _SendLogsPageState extends ConsumerState<SendLogsPage> {
  final _emailController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isSending = false;
  bool _sent = false;


  @override
  void initState() {
    super.initState();
    if (widget.isEmailMode) {
      // SRS 8.4: the output-file comment (4–60) is always sent; the
      // reference layout shows only the recipient field on this screen.
      _commentController.text = kDefaultEmailComment;
    }
    _emailController.addListener(() => setState(() {}));
    _commentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  bool get _emailValid {
    final email = _emailController.text.trim();
    return email.contains('@') && email.contains('.');
  }

  bool get _canSend {
    if (_isSending) return false;
    if (widget.isEmailMode && !_emailValid) return false;
    return inspectionCommentError(_commentController.text, loc: context.loc) == null;
  }

  Future<void> _handleSend() async {
    if (widget.isEmailMode && !_emailValid) {
      _snack(context.loc.enterValidEmail);
      return;
    }
    // SRS 8.4: output-file comment 4–60 on both channels (the email screen
    // starts with a default the officer may replace).
    final commentError = inspectionCommentError(
      _commentController.text,
      loc: context.loc,
    );
    if (commentError != null) {
      _snack(commentError);
      return;
    }

    setState(() => _isSending = true);
    final comment = _commentController.text;
    final success = await ref
        .read(inspectionProvider.notifier)
        .sendLogs(
          // Both screens use the server's EMAIL channel (openapi: EMAIL is the
          // default; the Send screen shows "Data Transfer Type: Email").
          TransferMethod.email,
          email: widget.isEmailMode ? _emailController.text.trim() : null,
          comment: comment,
        );
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _sent = success;
    });
    if (!success) {
      final error = ref.read(inspectionProvider).error;
      if (error != null) _snack(error);
    }

    // SRS 8.10: كل عملية نقل تُدوَّن في سجل التدقيق — القناة والنتيجة
    // ورسالة الخطأ عند الفشل. لا يُحذف الإدخال أبداً. فشل التدقيق نفسه
    // لا يمس تجربة النقل إطلاقاً (يُسجَّل ولا يُرمى للواجهة).
    try {
      final driverId = ref.read(currentDriverIdProvider);
      final userName = ref.read(authStateProvider).user?.fullName;
      final errorText =
          success ? null : ref.read(inspectionProvider).error;
      unawaited(ref.read(logsProvider.notifier).saveAuditEntry(AuditEntry(
            id: 'transfer-${DateTime.now().millisecondsSinceEpoch}',
            timestamp: DateTime.now(),
            driverId: driverId?.toString() ?? '',
            newStatus: success ? 'SENT' : 'FAILED',
            reason: errorText ?? _commentController.text,
            action: widget.isEmailMode ? 'email_logs' : 'send_logs',
            entityType: 'transfer',
            entityId: driverId?.toString(),
            userName: userName,
            userRole: 'driver',
          )));
    } catch (e) {
      AppLogger.error('Transfer audit entry failed', e);
    }
  }

  void _snack(String message) {
    AppFeedback.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final message = ref.watch(inspectionProvider).transferMessage;
    final loc = context.loc;
    final title = widget.isEmailMode ? loc.emailLogs : loc.sendLogs;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: context.styles.appBarTitle),
      ),
      body: _sent
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  message ?? loc.transferAccepted,
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
                  // Reference layout (screenshots 3 / 9): one heading line,
                  // one or two labelled underline fields, one SEND button.
                  Text(
                    widget.isEmailMode ? loc.sendLogsViaEmail : loc.send8Logs,
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondaryFor(
                        Theme.of(context).brightness,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (widget.isEmailMode) ...[
                    _FieldLabel(loc.recipientEmail),
                    AppTextField(
                      controller: _emailController,
                      hint: 'some@email.com',
                      keyboardType: TextInputType.emailAddress,
                      isUnderlined: true,
                    ),
                  ] else ...[
                    _FieldLabel(loc.comment),
                    AppTextField(
                      controller: _commentController,
                      hint: '',
                      isUnderlined: true,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _FieldLabel(loc.dataTransferType),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 10),
                      child: Text(
                        loc.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimaryFor(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  const SizedBox(height: 40),
                  AppButton(
                    label: loc.sendAction,
                    type: _canSend ? EldButtonType.agree : EldButtonType.send,
                    isLoading: _isSending,
                    onPressed: _handleSend,
                  ),
                ],
              ),
            ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryFor(Theme.of(context).brightness),
      ),
    );
  }
}
