import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../../../features/logs/domain/entities/audit_entry.dart';
import '../../../../features/logs/data/providers/log_repository_providers.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/inspection_transfer.dart';
import '../providers/inspection_provider.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/constants/fmcsa_constants.dart';

/// FMCSA ELD submission mailbox (49 CFR §395 Appendix A, telematics email
/// option). Shown pre-filled; the officer can replace it.
const String kFmcsaEldEmail = FmcsaConstants.fmcsaSubEmail;

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
  /// تحقق بريد فعلي (شكل محلي) بدل مجرد احتواء على '@' و'.'.
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _emailController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isSending = false;
  bool _sent = false;
  String? _outcomeText;
  TransferMethod _selectedMethod = TransferMethod.webService;

  @override
  void initState() {
    super.initState();
    if (widget.isEmailMode) {
      // SRS 8.4: the prefilled FMCSA mailbox is shown for the inspector's
      // PDF handover, and the output-file comment (4–60) is always sent.
      _emailController.text = kFmcsaEldEmail;
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
    return _emailPattern.hasMatch(email);
  }

  /// القناة الفعالة: شاشة البريد بريد دائماً، وشاشة الإرسال حسب الاختيار.
  bool get _usesEmail =>
      widget.isEmailMode || _selectedMethod == TransferMethod.email;

  Future<void> _handleSend() async {
    if (_usesEmail && !_emailValid) {
      _snack(context.loc.enterValidEmail);
      return;
    }
    // SRS 8.4: output-file comment 4–60 on both channels (the email screen
    // starts with a default the officer may replace).
    final commentError = isValidInspectionComment(_commentController.text)
        ? null
        : context.loc.inspectionCommentErrorLength;
    if (commentError != null) {
      _snack(commentError);
      return;
    }

    setState(() => _isSending = true);
    final comment = _commentController.text;
    // I8: النتيجة تعود من الـ notifier كقيمة — لا تلمس حالة التفتيش.
    final outcome = await ref
        .read(inspectionProvider.notifier)
        .sendLogs(
          widget.isEmailMode ? TransferMethod.email : _selectedMethod,
          email: _usesEmail ? _emailController.text.trim() : null,
          // SRS 8.4 deviation (owner decision 2026-10-03): the routing
          // code field was removed from both channels; the contract and
          // repository keep accepting it, the UI no longer collects it.
          comment: comment,
        );
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _sent = outcome.accepted;
      _outcomeText = outcome.text;
    });
    if (!outcome.accepted) {
      _snack(outcome.text);
    }

    // SRS 8.10: كل عملية نقل تُدوَّن في سجل التدقيق — القناة والنتيجة
    // ورسالة الخطأ عند الفشل. لا يُحذف الإدخال أبداً. فشل التدقيق نفسه
    // لا يمس تجربة النقل إطلاقاً (يُسجَّل ولا يُرمى للواجهة).
    try {
      final driverId = ref.read(currentDriverIdProvider);
      final userName = ref.read(authStateProvider).user?.fullName;
      final errorText = outcome.accepted ? null : outcome.text;
      // await لا unawaited داخل try — الاستثناء غير المتزامن كان يهرب من
      // الـ try/catch بلا التقاط؛ الكتابة بعد إظهار النتيجة فلا تأخير يُرى.
      await ref
          .read(logRepositoryProvider)
          .logAudit(
            AuditEntry(
              id: 'transfer-${DateTime.now().millisecondsSinceEpoch}',
              timestamp: DateTime.now(),
              driverId: driverId?.toString() ?? '',
              newStatus: outcome.accepted ? 'SENT' : 'FAILED',
              reason: errorText ?? _commentController.text,
              action: widget.isEmailMode ? 'email_logs' : 'send_logs',
              entityType: 'transfer',
              entityId: driverId?.toString(),
              userName: userName,
              userRole: 'driver',
            ),
          );
    } catch (e) {
      AppLogger.error('Transfer audit entry failed', e);
    }
  }

  void _snack(String message) {
    AppFeedback.error(context, anyErrorUserMessage(message, loc: context.loc));
  }

  @override
  Widget build(BuildContext context) {
    final message = _outcomeText;
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
          ? _buildSuccessView(context, message, loc)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Reference layout (screenshots 3 / 9): one heading line,
                  // one or two labelled underline fields, one SEND button.
                  Text(
                    widget.isEmailMode ? loc.sendLogsViaEmail : loc.send8Logs,
                    style: context.styles.subtitle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (widget.isEmailMode) ...[
                    _FieldLabel(loc.recipientEmail),
                    AppTextField(
                      controller: _emailController,
                      hint: 'some@email.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _FieldLabel(loc.comment),
                    AppTextField(
                      controller: _commentController,
                      hint: '',
                      keyboardType: TextInputType.text,
                    ),
                  ] else ...[
                    _FieldLabel(loc.comment),
                    AppTextField(
                      controller: _commentController,
                      hint: '',
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _FieldLabel(loc.dataTransferType),
                    DropdownButtonFormField<TransferMethod>(
                      initialValue: _selectedMethod,
                      dropdownColor: Theme.of(
                        context,
                      ).inputDecorationTheme.fillColor,
                      decoration: const InputDecoration(),
                      items: [
                        DropdownMenuItem(
                          value: TransferMethod.webService,
                          child: Text(
                            loc.transferMethodWebServices,
                            style: context.styles.body,
                          ),
                        ),
                        DropdownMenuItem(
                          value: TransferMethod.email,
                          child: Text(
                            loc.transferMethodEmail,
                            style: context.styles.body,
                          ),
                        ),
                      ],
                      onChanged: (method) {
                        if (method != null) {
                          setState(() => _selectedMethod = method);
                        }
                      },
                    ),
                    // SRS 8.4: عند اختيار Email يظهر حقل المرسل إليه.
                    if (_selectedMethod == TransferMethod.email) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _FieldLabel(loc.recipientEmail),
                      AppTextField(
                        controller: _emailController,
                        hint: 'some@email.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ],
                  const SizedBox(height: 40),
                  AppButton(
                    label: loc.sendAction,
                    type: EldButtonType.primary,
                    isLoading: _isSending,
                    onPressed: _handleSend,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSuccessView(
    BuildContext context,
    String? message,
    AppLocalizations loc,
  ) {
    final isOffline = message != null && message.startsWith('OFFLINE_GENERATED:');
    final localPath = isOffline ? message.substring('OFFLINE_GENERATED:'.length) : null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF28A745),
              size: 64,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isOffline
                  ? loc.offlineEldGeneratedTitle
                  : (message ?? loc.transferAccepted),
              textAlign: TextAlign.center,
              style: context.styles.pageTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isOffline
                  ? loc.offlineEldGeneratedDesc
                  : (message ?? loc.transferAccepted),
              textAlign: TextAlign.center,
              style: context.styles.body,
            ),
            if (isOffline && localPath != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: loc.shareOrExportCsv,
                type: EldButtonType.primary,
                onPressed: () {
                  Share.shareXFiles(
                    [XFile(localPath)],
                    text: 'FMCSA ELD Output File - Roadside Inspection',
                  );
                },
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: loc.okButton,
              type: EldButtonType.secondary,
              onPressed: () => Navigator.pop(context),
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
    return Text(text, style: context.styles.sectionTitle);
  }
}
