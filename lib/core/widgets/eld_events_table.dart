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
  final String? notes;
  final Color? statusColor;

  const EldTableRow({
    required this.time,
    required this.status,
    required this.location,
    required this.odom,
    required this.eng,
    required this.src,
    this.notes,
    this.statusColor,
  });
}

/// Official dense RODS events table (FMCSA 49 CFR 395.8).
class EldEventsTable extends StatelessWidget {
  const EldEventsTable({super.key, required this.rows});

  final List<EldTableRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Text(context.loc.noData, style: context.styles.muted),
        ),
      );
    }

    final headerStyle = context.styles.caption.copyWith(
      fontSize: 11.5,
      fontWeight: AppTypography.bold,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      height: 1.25,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const minTableWidth = 620.0;
        final tableWidth = constraints.maxWidth > minTableWidth
            ? constraints.maxWidth
            : minTableWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text('Time (ET)', style: headerStyle),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text('Code', style: headerStyle),
                      ),
                      Expanded(child: Text('Location', style: headerStyle)),
                      SizedBox(
                        width: 80,
                        child: Text('Odometer', style: headerStyle),
                      ),
                      SizedBox(
                        width: 75,
                        child: Text('Engine Hours', style: headerStyle),
                      ),
                      SizedBox(
                        width: 65,
                        child: Text('Origin', style: headerStyle),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text('Notes', style: headerStyle),
                      ),
                    ],
                  ),
                ),
                // Rows
                for (var i = 0; i < rows.length; i++)
                  _EventRow(row: rows[i], isEven: i.isEven),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventRow extends StatelessWidget {
  final EldTableRow row;
  final bool isEven;
  const _EventRow({required this.row, required this.isEven});

  @override
  Widget build(BuildContext context) {
    final valueStyle = context.styles.caption.copyWith(
      fontSize: 11.5,
      fontWeight: AppTypography.regular,
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.3,
    );

    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isEven
            ? cs.surface
            : cs.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(row.time, style: valueStyle)),
          SizedBox(
            width: 110,
            child: Text(
              row.status,
              style: valueStyle.copyWith(
                color: row.statusColor,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.location,
              style: valueStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 80, child: Text(row.odom, style: valueStyle)),
          SizedBox(width: 75, child: Text(row.eng, style: valueStyle)),
          SizedBox(
            width: 65,
            child: Text(
              row.src,
              style: valueStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              row.notes ?? '',
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
