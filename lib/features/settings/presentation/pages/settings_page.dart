import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../../tracking/data/services/tracking_service.dart';
import 'qr_scanner_page.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/presentation/utils/password_prompt_util.dart';

final advancedSettingsProvider = StateProvider<bool>((ref) => false);
final bufferProvider =
    StateProvider<bool>((ref) => ref.watch(localStorageProvider).buffer);
final wakelockProvider =
    StateProvider<bool>((ref) => ref.watch(localStorageProvider).wakelock);
final stopDetectionProvider =
    StateProvider<bool>((ref) => ref.watch(localStorageProvider).stopDetection);
final preferPlatformProvidersProvider = StateProvider<bool>(
    (ref) => ref.watch(localStorageProvider).preferPlatformProviders);

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(localStorageProvider);
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final loc = AppLocalizations.of(context)!;
    final advanced = ref.watch(advancedSettingsProvider);

    final isHighestAccuracy = storage.accuracy == 'highest';
    final distance = storage.distance;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const EldDrawer(),
      appBar: AppBar(
        title: Text(loc.settingsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.surface),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrScannerPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // 1. معرف الجهاز
          _buildInfoRow(context, loc.idLabel, storage.deviceId),
          Divider(color: Theme.of(context).dividerColor),

          // اللغة
          ListTile(
            title: Text(loc.languageLabel),
            subtitle: Text(isAr ? loc.arabic : loc.english),
            trailing: const Icon(Icons.language, size: 20),
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(isAr ? 'en' : 'ar');
            },
          ),
          Divider(color: Theme.of(context).dividerColor),

          // المظهر
          ListTile(
            title: Text(loc.themeLabel),
            subtitle: Text(ref.watch(themeModeProvider) == ThemeMode.light
                ? loc.lightMode
                : loc.darkMode),
            trailing: const Icon(Icons.brightness_6, size: 20),
            onTap: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          Divider(color: Theme.of(context).dividerColor),

          // 2. عنوان الخادم
          _buildEditableRow(
            context,
            ref,
            loc.urlLabel,
            storage.serverUrl,
            storage.serverUrl,
            (value) async {
              final uri = Uri.tryParse(value);
              if (uri == null ||
                  uri.host.isEmpty ||
                  !(uri.scheme == 'http' || uri.scheme == 'https')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.invalidValue)),
                );
                return;
              }
              await storage.setServerUrl(value);
              await ref.read(trackingServiceProvider).updateConfig();
            },
          ),
          Divider(color: Theme.of(context).dividerColor),

          // 3. دقة الموقع
          _buildAccuracySelector(context, ref, storage.accuracy, (value) async {
            await storage.setAccuracy(value);
            await ref.read(trackingServiceProvider).updateConfig();
          }),
          Divider(color: Theme.of(context).dividerColor),

          // 4. المسافة
          _buildEditableRow(
            context,
            ref,
            loc.distanceLabel,
            '${storage.distance}',
            '${storage.distance}',
            (value) async {
              final val = int.tryParse(value);
              if (val != null) {
                await storage.setDistance(val);
                await ref.read(trackingServiceProvider).updateConfig();
              }
            },
            isNumber: true,
          ),
          Divider(color: Theme.of(context).dividerColor),

          // 5. الفاصل الزمني (يظهر بشروط)
          if (isHighestAccuracy || (Platform.isAndroid && distance == 0)) ...[
            _buildEditableRow(
              context,
              ref,
              loc.intervalLabel,
              storage.interval > 0 ? '${storage.interval}' : loc.disabledValue,
              '${storage.interval}',
              (value) async {
                final val = int.tryParse(value);
                if (val != null) {
                  await storage.setInterval(val);
                  await ref.read(trackingServiceProvider).updateConfig();
                }
              },
              isNumber: true,
            ),
            Divider(color: Theme.of(context).dividerColor),
          ],

          // 6. زاوية الاتجاه (يظهر بشروط)
          if (isHighestAccuracy) ...[
            _buildEditableRow(
              context,
              ref,
              loc.angleLabel,
              storage.angle > 0 ? '${storage.angle}' : loc.disabledValue,
              '${storage.angle}',
              (value) async {
                final val = int.tryParse(value);
                if (val != null) {
                  await storage.setAngle(val);
                  await ref.read(trackingServiceProvider).updateConfig();
                }
              },
              isNumber: true,
            ),
            Divider(color: Theme.of(context).dividerColor),
          ],

          // 7. نبض الثبات
          _buildEditableRow(
            context,
            ref,
            loc.heartbeatLabel,
            storage.heartbeat > 0 ? '${storage.heartbeat}' : loc.disabledValue,
            '${storage.heartbeat}',
            (value) async {
              int? val = int.tryParse(value);
              if (val != null) {
                if (val > 0 && val < 60) {
                  val = 60; // minimum heartbeat is 60 seconds
                }
                await storage.setHeartbeat(val);
                await ref.read(trackingServiceProvider).updateConfig();
              }
            },
            isNumber: true,
          ),
          const SizedBox(height: AppSpacing.lg),

          // 8. إعدادات متقدمة
          SwitchListTile(
            title:
                Text(loc.advancedLabel, style: AppTextStyles(context).bodyBold),
            value: advanced,
            onChanged: (value) async {
              final authenticated =
                  await PasswordPromptUtil.authenticate(context, ref);
              if (authenticated && context.mounted) {
                ref.read(advancedSettingsProvider.notifier).state = value;
              }
            },
          ),

          if (advanced) ...[
            const SizedBox(height: AppSpacing.sm),
            EldCard(
              child: Column(
                children: [
                  // 9. تخزين مؤقت
                  _buildSwitchRow(
                    context,
                    ref,
                    loc.bufferLabel,
                    ref.watch(bufferProvider),
                    (value) async {
                      await storage.setBuffer(value);
                      ref.read(bufferProvider.notifier).state = value;
                      await ref.read(trackingServiceProvider).updateConfig();
                    },
                  ),
                  Divider(color: Theme.of(context).dividerColor),

                  // 10. قفل التنبيه (Android only)
                  if (Platform.isAndroid) ...[
                    _buildSwitchRow(
                      context,
                      ref,
                      loc.wakelockLabel,
                      ref.watch(wakelockProvider),
                      (value) async {
                        await storage.setWakelock(value);
                        ref.read(wakelockProvider.notifier).state = value;
                        await ref.read(trackingServiceProvider).updateConfig();
                      },
                    ),
                    Divider(color: Theme.of(context).dividerColor),
                  ],

                  // 11. اكتشاف التوقف
                  _buildSwitchRow(
                    context,
                    ref,
                    loc.stopDetectionLabel,
                    ref.watch(stopDetectionProvider),
                    (value) async {
                      await storage.setStopDetection(value);
                      ref.read(stopDetectionProvider.notifier).state = value;
                      await ref.read(trackingServiceProvider).updateConfig();
                    },
                  ),
                  Divider(color: Theme.of(context).dividerColor),

                  // 12. استخدام مزودي الموقع الأصليين (Android only)
                  if (Platform.isAndroid) ...[
                    _buildSwitchRow(
                      context,
                      ref,
                      loc.preferPlatformProvidersLabel,
                      ref.watch(preferPlatformProvidersProvider),
                      (value) async {
                        await storage.setPreferPlatformProviders(value);
                        ref
                            .read(preferPlatformProvidersProvider.notifier)
                            .state = value;
                        await ref.read(trackingServiceProvider).updateConfig();
                      },
                    ),
                    Divider(color: Theme.of(context).dividerColor),
                  ],

                  // 13. كلمة المرور
                  ListTile(
                    title: Text(loc.passwordLabel),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _changePassword(context, storage, loc),
                  ),

                  // 14. رسالة تحسين البطارية
                  if (Platform.isAndroid) ...[
                    Divider(color: Theme.of(context).dividerColor),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.battery_alert,
                              color: AppColors.warningYellow, size: 24),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              loc.optimizationMessage,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.warningYellow,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _changePassword(BuildContext context,
      LocalStorageService storage, AppLocalizations loc) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _ChangePasswordDialog(loc: loc),
    );

    if (result != null) {
      await storage.setPassword(result);
    }
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles(context).body),
          Text(value, style: AppTextStyles(context).bodyBold),
        ],
      ),
    );
  }

  Widget _buildEditableRow(
    BuildContext context,
    WidgetRef ref,
    String label,
    String displayValue,
    String editValue,
    Function(String) onSave, {
    bool isNumber = false,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: Text(displayValue),
      trailing: const Icon(Icons.edit, size: 20),
      onTap: () async {
        final authenticated =
            await PasswordPromptUtil.authenticate(context, ref);
        if (authenticated && context.mounted) {
          _showEditDialog(context, label, editValue, onSave, isNumber);
        }
      },
    );
  }

  void _showEditDialog(
    BuildContext context,
    String title,
    String editValue,
    Function(String) onSave,
    bool isNumber,
  ) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => _EditDialog(
        title: title,
        editValue: editValue,
        onSave: onSave,
        isNumber: isNumber,
        loc: loc,
      ),
    );
  }

  Widget _buildAccuracySelector(BuildContext context, WidgetRef ref,
      String current, Function(String) onSelect) {
    final options = ['highest', 'high', 'medium', 'low'];
    final loc = AppLocalizations.of(context)!;

    final labels = {
      'highest': loc.highestAccuracyLabel,
      'high': loc.highAccuracyLabel,
      'medium': loc.mediumAccuracyLabel,
      'low': loc.lowAccuracyLabel,
    };

    return ListTile(
      title: Text(loc.accuracyLabel),
      subtitle: Text(labels[current] ?? current),
      trailing: const Icon(Icons.arrow_drop_down, size: 20),
      onTap: () async {
        final authenticated =
            await PasswordPromptUtil.authenticate(context, ref);
        if (authenticated && context.mounted) {
          showDialog(
            context: context,
            builder: (context) => SimpleDialog(
              title: Text(loc.accuracyLabel),
              children: options
                  .map((option) => SimpleDialogOption(
                        onPressed: () {
                          onSelect(option);
                          Navigator.pop(context);
                        },
                        child: Text(labels[option] ?? option),
                      ))
                  .toList(),
            ),
          );
        }
      },
    );
  }

  Widget _buildSwitchRow(BuildContext context, WidgetRef ref, String label,
      bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label, style: AppTextStyles(context).body),
      value: value,
      onChanged: (val) async {
        final authenticated =
            await PasswordPromptUtil.authenticate(context, ref);
        if (authenticated && context.mounted) {
          onChanged(val);
        }
      },
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final AppLocalizations loc;
  const _ChangePasswordDialog({required this.loc});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
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
      scrollable: true,
      title: Text(widget.loc.passwordLabel),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(labelText: widget.loc.passwordLabel),
        obscureText: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(widget.loc.cancelButton),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.loc.saveButton),
        ),
      ],
    );
  }
}

class _EditDialog extends StatefulWidget {
  final String title;
  final String editValue;
  final Function(String) onSave;
  final bool isNumber;
  final AppLocalizations loc;

  const _EditDialog({
    required this.title,
    required this.editValue,
    required this.onSave,
    required this.isNumber,
    required this.loc,
  });

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.editValue);
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
        keyboardType:
            widget.isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters:
            widget.isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.loc.cancelButton),
        ),
        TextButton(
          onPressed: () {
            widget.onSave(_controller.text);
            Navigator.pop(context);
          },
          child: Text(widget.loc.saveButton),
        ),
      ],
    );
  }
}
