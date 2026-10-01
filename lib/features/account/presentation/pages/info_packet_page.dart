import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.infoPacket,
          style: context.styles.appBarTitle,
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
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
            body: loc.infoPacketManualBlurb,
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
            body: loc.infoPacketInstructionsBlurb,
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
            style: context.styles.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            textAlign: TextAlign.center,
            style: context.styles.subtitle,
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
