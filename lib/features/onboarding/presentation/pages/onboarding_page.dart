import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';

/// Onboarding لأول تشغيل (3 شرائح): تتبع تلقائي، فحص المركبة، جاهزية
/// التفتيش. يُعرض مرة واحدة بعلم [LocalStorageService.onboardingSeen]
/// ثم يُعاد التوجيه إلى '/' لتدفق الأذونات/الجلسة الطبيعي.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  static final _slides = <_Slide>[
    _Slide(
      icon: Icons.route,
      title: (loc) => loc.onboardingTitle1,
      body: (loc) => loc.onboardingBody1,
    ),
    _Slide(
      icon: Icons.fact_check_outlined,
      title: (loc) => loc.onboardingTitle2,
      body: (loc) => loc.onboardingBody2,
    ),
    _Slide(
      icon: Icons.verified_user_outlined,
      title: (loc) => loc.onboardingTitle3,
      body: (loc) => loc.onboardingBody3,
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  void _finish() {
    ref.read(localStorageProvider).setOnboardingSeen();
    if (!mounted) return;
    context.goNamed('splash');
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  loc.onboardingSkip,
                  style: context.styles.body.copyWith(
                    color: AppColors.textSecondaryFor(
                        Theme.of(context).brightness),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icon,
                              size: 64, color: AppColors.primaryGold),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          slide.title(loc),
                          textAlign: TextAlign.center,
                          style: context.styles.pageTitle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          slide.body(loc),
                          textAlign: TextAlign.center,
                          style: context.styles.body,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? AppColors.primaryGold
                          : AppColors.textSecondaryFor(
                              Theme.of(context).brightness),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: _isLast
                      ? loc.onboardingGetStarted
                      : loc.onboardingNext,
                  onPressed: _next,
                  type: EldButtonType.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) body;

  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
  });
}
