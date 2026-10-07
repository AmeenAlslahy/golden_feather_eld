import 'package:flutter/material.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class EldTableRow {
  final String time;
  final String status;
  final String location;
  final String odom;
  final String eng;
  final String src;
  final Color? statusColor;

  const EldTableRow({
    required this.time,
    required this.status,
    required this.location,
    required this.odom,
    required this.eng,
    required this.src,
    this.statusColor,
  });
}

class EldEventsTable extends StatelessWidget {
  const EldEventsTable({
    super.key,
    required this.rows,
  });

  final List<EldTableRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Text(
            context.loc.noData,
            style: context.styles.muted,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  context.loc.time,
                  style: context.styles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  context.loc.status,
                  style: context.styles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  context.loc.location,
                  style: context.styles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  context.loc.odom,
                  style: context.styles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 55,
                child: Text(
                  context.loc.eng,
                  style: context.styles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  context.loc.src,
                  style: context.styles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        // Rows
        ...rows.map((row) => _EventRow(row: row)),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  final EldTableRow row;
  const _EventRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final valueStyle = context.styles.caption.copyWith(height: 1.3);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              row.time,
              style: valueStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.status,
              style: valueStyle.copyWith(
                color: row.statusColor,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.location,
              style: valueStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              row.odom,
              style: valueStyle,
            ),
          ),
          SizedBox(
            width: 55,
            child: Text(
              row.eng,
              style: valueStyle,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              row.src,
              style: valueStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
