import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../routes.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../../inspection/domain/inspection_transfer.dart';
import '../../../inspection/presentation/providers/inspection_provider.dart';

/// Original information-packet landing: User Manual + Instructions.
class InfoPacketPage extends ConsumerWidget {
  const InfoPacketPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.infoPacket, style: context.styles.appBarTitle),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const EldDrawer(),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.md,
        ),
        children: [
          _PacketStatus(packet: ref.watch(informationPacketProvider)),
          _PacketBlock(
            title: loc.userManual,
            body: loc.infoPacketManualBlurb,
            buttonLabel: loc.viewUserManual.toUpperCase(),
            onPressed: () => context.push(AppRoutes.userManual),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Divider(
              color: context.border,
              height: AppSpacing.dividerHeight,
            ),
          ),
          _PacketBlock(
            title: loc.instructions,
            body: loc.infoPacketInstructionsBlurb,
            buttonLabel: loc.viewInstructions.toUpperCase(),
            onPressed: () => context.push(AppRoutes.instructions),
          ),
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
    return packet.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (view) {
        // Reference layout shows nothing here when the packet is fine;
        // only an incomplete packet (SRS 8.2) gets a warning line.
        if (view.complete) return const SizedBox.shrink();
        final missing = view.missing.join(', ');
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            missing.isEmpty
                ? context.loc.thePacketIsIncomplete
                : context.loc.packetIncompleteMissing(missing),
            textAlign: TextAlign.center,
            style: context.styles.error,
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
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.styles.sectionTitle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.compact),
        Text(
          body,
          textAlign: TextAlign.center,
          style: context.styles.subtitle.copyWith(
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: buttonLabel,
          type: EldButtonType.primary,
          onPressed: onPressed,
        ),
      ],
    );
  }
}
