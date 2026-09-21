import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/services/local_storage_service.dart';

/// Settings screen where the user enters the backend URL.
///
/// **T4.0a scope:** UI + persistence only.
/// **T4.0b:** adds real "Test Connection" probe against `/eld/health`.
class ServerConfigPage extends ConsumerStatefulWidget {
  const ServerConfigPage({super.key});

  @override
  ConsumerState<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends ConsumerState<ServerConfigPage> {
  late final TextEditingController _urlController;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(localStorageProvider);
    _urlController = TextEditingController(text: prefs.serverUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final raw = _urlController.text.trim();
    if (raw.isEmpty) {
      _showError('Please enter a server URL.');
      return;
    }

    final prefs = ref.read(localStorageProvider);
    await prefs.setServerUrl(raw);
    await prefs.setBackendType('eld');

    if (!mounted) return;
    _showSuccess('Server config saved (not yet verified).');
  }

  Future<void> _onClear() async {
    final prefs = ref.read(localStorageProvider);
    await prefs.setServerUrl('');
    await prefs.setBackendType('mock');
    _urlController.clear();
    if (!mounted) return;
    _showSuccess('Server config cleared. Using Mock backend.');
  }

  Future<void> _onTestConnection() async {
    final prefs = ref.read(localStorageProvider);
    if (prefs.serverUrl.isEmpty) {
      _showError('Please save a server URL first.');
      return;
    }

    setState(() => _isTesting = true);

    try {
      final healthBackend = ref.read(healthBackendProvider);
      final result = await healthBackend.checkLiveness();
      
      if (!mounted) return;

      if (result.isRight()) {
        _showSuccess('Connection successful! Backend is ready.');
      } else {
        final error = result.getLeft().toNullable();
        _showError('Connection failed: ${error ?? "Unknown error"}');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Connection error: $e');
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(localStorageProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Server Configuration'),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current status
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    prefs.backendType == 'mock'
                        ? 'No server configured. Using Mock backend.'
                        : 'URL: ${prefs.serverUrl}',
                    style: const TextStyle(
                      fontSize: AppTypography.bodySize,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // URL input
            AppTextField(
              controller: _urlController,
              label: 'Server Base URL',
              hint: 'https://snsoft.cloud/api',
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.md),

            // Save button
            AppButton(
              label: 'Save',
              type: EldButtonType.agree,
              onPressed: _onSave,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Test Connection button
            AppButton(
              label: _isTesting ? 'Testing...' : 'Test Connection',
              type: EldButtonType.agree,
              onPressed: _isTesting ? null : _onTestConnection,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Clear button
            AppButton(
              label: 'Clear (use Mock)',
              type: EldButtonType.continueDisconnected,
              onPressed: _onClear,
            ),

            const SizedBox(height: AppSpacing.lg),
            Text(
              'Note: real connection testing will be available in the next task.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
