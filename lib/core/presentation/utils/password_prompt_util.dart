import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../services/password_service.dart';
import '../../../l10n/app_localizations.dart';

/// أداة مساعدة لإظهار واجهة التحقق من كلمة المرور
class PasswordPromptUtil {
  static Future<bool> authenticate(BuildContext context, WidgetRef ref) async {
    final passwordService = ref.read(passwordServiceProvider);
    
    if (!await passwordService.hasPassword) {
      return true;
    }

    if (!context.mounted) return false;

    final loc = AppLocalizations.of(context)!;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PasswordDialog(
        title: loc.passwordLabel,
        label: loc.passwordLabel,
        cancelButton: loc.cancelButton,
        okButton: loc.okButton,
        onVerify: (input) async {
          return await passwordService.verifyPassword(input);
        },
      ),
    );

    if (result != true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.passwordError),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return false;
    }

    return result == true;
  }
}

class _PasswordDialog extends StatefulWidget {
  final String title;
  final String label;
  final String cancelButton;
  final String okButton;
  final Future<bool> Function(String) onVerify;

  const _PasswordDialog({
    required this.title,
    required this.label,
    required this.cancelButton,
    required this.okButton,
    required this.onVerify,
  });

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(widget.cancelButton),
        ),
        FilledButton(
          onPressed: () async {
            final isValid = await widget.onVerify(_controller.text);
            if (context.mounted) {
              Navigator.pop(context, isValid);
            }
          },
          child: Text(widget.okButton),
        ),
      ],
    );
  }
}
