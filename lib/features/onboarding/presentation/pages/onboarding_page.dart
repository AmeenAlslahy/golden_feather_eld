import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

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

  static const _slides = <_Slide>[
    _Slide(
      icon: Icons.route,
      titleEn: 'Your hours, recorded automatically',
      titleAr: 'ساعاتك تُسجَّل تلقائياً',
      bodyEn:
          'The ELD tracks your driving status against FMCSA limits the moment '
          'the vehicle moves — no paperwork, no guessing.',
      bodyAr:
          'يتتبع جهاز ELD حالة قيادتك مقابل حدود FMCSA لحظة تحرك المركبة — '
          'بلا أوراق وبلا تخمين.',
    ),
    _Slide(
      icon: Icons.fact_check_outlined,
      titleEn: 'Inspect your vehicle with confidence',
      titleAr: 'افحص مركبتك بثقة',
      bodyEn:
          'Daily DVIR before and after the trip, defect tracking with repair '
          'certifications, and §396.13 review — all in one place.',
      bodyAr:
          'فحص يومي قبل وبعد الرحلة، تتبع العيوب مع شهادات الإصلاح، ومراجعة '
          '§396.13 — كل ذلك في مكان واحد.',
    ),
    _Slide(
      icon: Icons.verified_user_outlined,
      titleEn: 'Always ready for the inspector',
      titleAr: 'جاهز للمفتش دائماً',
      bodyEn:
          'Your records, information packet, and transfer options live on the '
          'device — even when there is no internet on the road.',
      bodyAr:
          'سجلاتك وحزمتك القانونية وخيارات النقل على متن الجهاز — حتى بلا '
          'إنترنت على الطريق.',
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

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
                  isArabic ? 'تخطي' : 'Skip',
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
                          isArabic ? slide.titleAr : slide.titleEn,
                          textAlign: TextAlign.center,
                          style: context.styles.pageTitle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          isArabic ? slide.bodyAr : slide.bodyEn,
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
                      ? (isArabic ? 'ابدأ الآن' : 'GET STARTED')
                      : (isArabic ? 'التالي' : 'NEXT'),
                  onPressed: _next,
                  type: EldButtonType.send,
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
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;

  const _Slide({
    required this.icon,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
  });
}
