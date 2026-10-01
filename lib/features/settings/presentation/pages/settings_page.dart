import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../account/presentation/providers/account_provider.dart';

// final fleetSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
//   final result = await ref.watch(configBackendProvider).getSettings();
//   return result.fold((error) => throw error, (json) => json);
// });

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _url;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(
      text: ref.read(localStorageProvider).serverUrl,
    );
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    final raw = _url.text.trim();
    if (raw.isEmpty) {
      AppFeedback.error(context, context.loc.enterServerUrl);
      return;
    }
    final uri = Uri.tryParse(raw);
    final validHttp =
        uri != null &&
        uri.hasAuthority &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    if (!validHttp) {
      AppFeedback.error(context, context.loc.invalidServerUrl);
      return;
    }
    setState(() => _saving = true);
    final prefs = ref.read(localStorageProvider);
    await prefs.setServerUrl(raw);
    await prefs.setBackendType('eld');
    if (!mounted) return;
    setState(() => _saving = false);
    AppFeedback.success(context, context.loc.serverUrlSaved);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    // final fleet = ref.watch(fleetSettingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.loc.settingsTitle,
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const EldDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          // ref.invalidate(fleetSettingsProvider);
          // await ref.read(fleetSettingsProvider.future);
          await Future.delayed(const Duration(milliseconds: 500));
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
                    context.loc.interfaceLanguage,
                    style: context.styles.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: 'ar',
                        label: Text(context.loc.languageArabic),
                      ),
                      ButtonSegment(
                        value: 'en',
                        label: Text(context.loc.languageEnglish),
                      ),
                      ButtonSegment(
                        value: 'es',
                        label: Text(context.loc.languageSpanish),
                      ),
                    ],
                    selected: {locale.languageCode},
                    onSelectionChanged: (value) async {
                      final code = value.first;
                      ref.read(localeProvider.notifier).setLocale(code);
                      
                      final accountState = ref.read(accountProvider);
                      // If user is logged in, sync to server
                      if (accountState.accountData != null) {
                        final langName = code == 'ar' ? 'Arabic' : (code == 'es' ? 'Spanish' : 'English');
                        final currentOdo = accountState.accountData?.odometer ?? 'mi';
                        await ref.read(accountProvider.notifier).updatePreferences(
                          language: langName,
                          odometerUnit: currentOdo,
                        );
                      }
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
                    context.loc.appearance,
                    style: context.styles.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(context.loc.themeSystem),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(context.loc.themeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(context.loc.themeDark),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (value) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(value.first);
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
                    context.loc.serverUrl,
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
                    label: context.loc.saveButton,
                    isLoading: _saving,
                    onPressed: _saving ? null : _saveUrl,
                  ),
                ],
              ),
            ),

            // Fleet settings card removed per user request
          ],
        ),
      ),
    );
  }

  // }
}
