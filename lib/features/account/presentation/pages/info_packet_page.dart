import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../../inspection/domain/inspection_transfer.dart';
import '../../../inspection/presentation/providers/inspection_provider.dart';
import 'instructions_page.dart';
import 'user_manual_page.dart';

/// Original information-packet landing: User Manual + Instructions.
class InfoPacketPage extends ConsumerWidget {
  const InfoPacketPage({super.key});

  static const _manualBlurbEn =
      'The user\'s manual, instruction sheet, and malfunction instruction sheet can be in electronic form. This is in accordance with the federal register titled "Regulatory Guidance Concerning Electronic Signatures and Documents" (76 FR 411).';
  static const _manualBlurbAr =
      'يجوز أن يكون دليل المستخدم وورقة التعليمات وورقة تعليمات الأعطال بصيغة إلكترونية، وفق السجل الفيدرالي بعنوان "إرشاد تنظيمي بشأن التوقيعات والمستندات الإلكترونية" (76 FR 411).';
  static const _instructionsBlurbEn =
      'In addition to the above, a supply of blank driver\'s records of duty status (RODS) graph-grids sufficient to record the driver\'s duty status and other related information for a minimum of 8 days must be onboard the commercial motor vehicle (CMV).';
  static const _instructionsBlurbAr =
      'بالإضافة إلى ما سبق، يجب أن تكون في المركبة التجارية نماذج فارغة لسجلات حالة الخدمة (RODS) تكفي لتسجيل حالة السائق والمعلومات ذات الصلة لمدة لا تقل عن 8 أيام.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.eldAppBar,
        title: Text(
          isArabic ? loc.infoPacket : 'Information Packet',
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
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.xl),
          _PacketStatus(packet: ref.watch(informationPacketProvider)),
          _PacketBlock(
            title: loc.userManual,
            body: isArabic ? _manualBlurbAr : _manualBlurbEn,
            buttonLabel: loc.viewUserManual.toUpperCase(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserManualPage()),
              );
            },
          ),
          const Divider(height: 1),
          _PacketBlock(
            title: loc.instructions,
            body: isArabic ? _instructionsBlurbAr : _instructionsBlurbEn,
            buttonLabel: loc.viewInstructions.toUpperCase(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InstructionsPage()),
              );
            },
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _PacketStatus extends StatelessWidget {
  const _PacketStatus({required this.packet});

  final AsyncValue<InformationPacketView> packet;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return packet.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (view) {
        // Reference layout shows nothing here when the packet is fine;
        // only an incomplete packet (SRS 8.2) gets a warning line.
        if (view.complete) return const SizedBox.shrink();
        final missing = view.missing.join(', ');
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: Text(
            missing.isEmpty
                ? (isArabic ? 'الحزمة غير مكتملة.' : 'The packet is incomplete.')
                : (isArabic
                    ? 'الحزمة غير مكتملة: $missing'
                    : 'Packet incomplete: $missing'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.dangerRed),
          ),
        );
      },
    );
  }
}

class _PacketBlock extends StatelessWidget {
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _PacketBlock({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: buttonLabel,
            type: EldButtonType.dark,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
