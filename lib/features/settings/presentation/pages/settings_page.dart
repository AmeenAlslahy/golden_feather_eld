import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/widgets/eld_info_row.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../../../core/widgets/app_feedback.dart';

final fleetSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final result = await ref.watch(configBackendProvider).getSettings();
  return result.fold((error) => throw error, (json) => json);
});

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _url;
  bool _saving = false;

  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: ref.read(localStorageProvider).serverUrl);
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    final raw = _url.text.trim();
    if (raw.isEmpty) {
      AppFeedback.error(
          context, _arabic ? 'أدخل عنوان الخادم.' : 'Enter the server URL.');
      return;
    }
    final uri = Uri.tryParse(raw);
    final validHttp = uri != null &&
        uri.hasAuthority &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    if (!validHttp) {
      AppFeedback.error(
        context,
        _arabic
            ? 'عنوان غير صالح. مثال: https://server.example.com'
            : 'Invalid URL. Example: https://server.example.com',
      );
      return;
    }
    setState(() => _saving = true);
    final prefs = ref.read(localStorageProvider);
    await prefs.setServerUrl(raw);
    await prefs.setBackendType('eld');
    if (!mounted) return;
    setState(() => _saving = false);
    AppFeedback.success(
        context, _arabic ? 'تم حفظ عنوان الخادم.' : 'Server URL saved.');
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final fleet = ref.watch(fleetSettingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _arabic ? 'الإعدادات' : 'Settings',
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.surface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const EldDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(fleetSettingsProvider);
          await ref.read(fleetSettingsProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _arabic ? 'لغة الواجهة' : 'Interface language',
                    style: context.styles.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: 'ar',
                        label: Text(_arabic ? 'العربية' : 'Arabic'),
                      ),
                      ButtonSegment(
                        value: 'en',
                        label: Text(_arabic ? 'الإنجليزية' : 'English'),
                      ),
                    ],
                    selected: {locale.languageCode == 'ar' ? 'ar' : 'en'},
                    onSelectionChanged: (value) {
                      ref.read(localeProvider.notifier).setLocale(value.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _arabic ? 'المظهر' : 'Appearance',
                    style: context.styles.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(_arabic ? 'النظام' : 'System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(_arabic ? 'فاتح' : 'Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(_arabic ? 'داكن' : 'Dark'),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (value) {
                      ref.read(themeModeProvider.notifier).setThemeMode(value.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _arabic ? 'عنوان الخادم' : 'Server URL',
                    style: context.styles.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _url,
                    hint: 'https://snsoft.cloud',
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: _arabic ? 'حفظ' : 'Save',
                    isLoading: _saving,
                    onPressed: _saving ? null : _saveUrl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _arabic ? 'إعدادات الأسطول' : 'Fleet settings',
                    style: context.styles.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  fleet.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => EldRetryView(
                      message: anyErrorUserMessage(error, isArabic: _arabic),
                      onRetry: () => ref.invalidate(fleetSettingsProvider),
                    ),
                    data: (json) {
                      final rows = _flatten(json);
                      if (rows.isEmpty) {
                        return EldRetryView(
                          message: _arabic
                              ? 'لا توجد إعدادات معروضة.'
                              : 'No settings returned.',
                          isError: false,
                          onRetry: () => ref.invalidate(fleetSettingsProvider),
                        );
                      }
                      return Column(
                        children: [
                          for (var i = 0; i < rows.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            EldInfoRow(label: rows[i].$1, value: rows[i].$2),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<(String, String)> _flatten(Map<String, dynamic> json, [String prefix = '']) {
    final rows = <(String, String)>[];
    json.forEach((key, value) {
      final label = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        rows.addAll(_flatten(value, label));
      } else if (value is List) {
        rows.add((label, value.join(', ')));
      } else if (value != null) {
        rows.add((label, value.toString()));
      }
    });
    return rows;
  }
}
