import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import 'local_storage_service.dart';
import '../../l10n/app_localizations.dart';

/// خدمة حماية كلمة المرور - مستوحاة من password_service.dart الأصلي
class PasswordService {
  final LocalStorageService _storage;

  PasswordService(this._storage);

  /// التحقق من كلمة المرور قبل الإجراءات الحساسة
  /// ترجع true إذا نجح التحقق أو لم تكن هناك كلمة مرور
  Future<bool> authenticate(BuildContext context) async {
    final storedPassword = await _storage.password;

    // إذا لم تكن هناك كلمة مرور، اسمح بالمرور
    if (storedPassword == null || storedPassword.isEmpty) return true;

    bool? result;

    if (!context.mounted) return false;

    final loc = AppLocalizations.of(context)!;

    result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PasswordDialog(
        storedPassword: storedPassword,
        title: loc.passwordLabel,
        label: loc.passwordLabel,
        cancelButton: loc.cancelButton,
        okButton: loc.okButton,
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

  /// تعيين كلمة المرور
  Future<void> setPassword(String password) async {
    await _storage.setPassword(password);
  }

  /// إزالة كلمة المرور
  Future<void> removePassword() async {
    await _storage.removePassword();
  }

  /// هل توجد كلمة مرور
  Future<bool> get hasPassword => _storage.hasPassword;
}

/// مزود خدمة كلمة المرور
final passwordServiceProvider = Provider<PasswordService>((ref) {
  final storage = ref.watch(localStorageProvider);
  return PasswordService(storage);
});

class _PasswordDialog extends StatefulWidget {
  final String storedPassword;
  final String title;
  final String label;
  final String cancelButton;
  final String okButton;

  const _PasswordDialog({
    required this.storedPassword,
    required this.title,
    required this.label,
    required this.cancelButton,
    required this.okButton,
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
          onPressed: () {
            Navigator.pop(context, widget.storedPassword == _controller.text);
          },
          child: Text(widget.okButton),
        ),
      ],
    );
  }
}
