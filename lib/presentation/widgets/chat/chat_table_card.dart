import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Interactive table card for venue owner operations and structured reports.
/// Optimized for mobile with horizontal scrolling, badge styling, and action triggers.
class ChatTableCard extends StatelessWidget {
  final Map<String, dynamic> cardData;
  final VoidCallback? onActionTap;

  const ChatTableCard({
    super.key,
    required this.cardData,
    this.onActionTap,
  });

  Color _getBadgeColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('chờ check-in') ||
        lower.contains('chờ') ||
        lower.contains('bảo trì') ||
        lower.contains('50%')) {
      return Colors.amber.shade800;
    }
    if (lower.contains('đã') ||
        lower.contains('còn') ||
        lower.contains('100%') ||
        lower.contains('tốt') ||
        lower.contains('thành công')) {
      return Colors.green.shade700;
    }
    if (lower.contains('kín') ||
        lower.contains('hủy') ||
        lower.contains('0%') ||
        lower.contains('khóa') ||
        lower.contains('đầy')) {
      return Colors.red.shade700;
    }
    return AppColors.primary;
  }

  Color _getBadgeBgColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('chờ check-in') ||
        lower.contains('chờ') ||
        lower.contains('bảo trì') ||
        lower.contains('50%')) {
      return Colors.amber.withValues(alpha: 0.15);
    }
    if (lower.contains('đã') ||
        lower.contains('còn') ||
        lower.contains('100%') ||
        lower.contains('tốt') ||
        lower.contains('thành công')) {
      return Colors.green.withValues(alpha: 0.15);
    }
    if (lower.contains('kín') ||
        lower.contains('hủy') ||
        lower.contains('0%') ||
        lower.contains('khóa') ||
        lower.contains('đầy')) {
      return Colors.red.withValues(alpha: 0.15);
    }
    return AppColors.primary.withValues(alpha: 0.12);
  }

  @override
  Widget build(BuildContext context) {
    final title = cardData['title']?.toString() ?? 'Báo Cáo Vận Hành';
    final subtitle = cardData['subtitle']?.toString();
    final iconName = cardData['icon']?.toString() ?? 'table';
    final headersRaw = cardData['headers'];
    final headers = headersRaw is List
        ? headersRaw.map((e) => e.toString()).toList()
        : <String>[];
    final rowsRaw = cardData['rows'];
    final rows = rowsRaw is List
        ? rowsRaw
            .map((row) {
              if (row is List) return row.map((e) => e.toString()).toList();
              return <String>[row.toString()];
            })
            .map((row) => headers.isEmpty
                ? row
                : List<String>.generate(
                    headers.length,
                    (index) => index < row.length ? row[index] : '',
                  ))
            .toList()
        : <List<String>>[];
    final footer = cardData['footer']?.toString();
    final actionLabel = cardData['actionLabel']?.toString();

    IconData headerIcon;
    switch (iconName) {
      case 'ticket':
        headerIcon = Icons.confirmation_number_rounded;
        break;
      case 'money':
      case 'revenue':
        headerIcon = Icons.monetization_on_rounded;
        break;
      case 'court':
        headerIcon = Icons.sports_tennis_rounded;
        break;
      case 'policy':
        headerIcon = Icons.rule_folder_rounded;
        break;
      default:
        headerIcon = Icons.table_chart_rounded;
    }

    return Container(
      key: const Key('chat_table_card'),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Card Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: AppColors.primary.withValues(alpha: 0.09),
              child: Row(
                children: [
                  Icon(headerIcon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      'CLB Tao Đàn',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Horizontal scrollable table
            if (headers.isNotEmpty && rows.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: DataTable(
                  horizontalMargin: 12,
                  columnSpacing: 16,
                  headingRowHeight: 34,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 46,
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.cardBorder.withValues(alpha: 0.25),
                  ),
                  columns: headers.map((h) {
                    return DataColumn(
                      label: Text(
                        h,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  rows: rows.asMap().entries.map((entry) {
                    final rowIndex = entry.key;
                    final rowData = entry.value;
                    final isEven = rowIndex % 2 == 0;
                    final isTotalRow = rowData.any((cell) =>
                        cell.toUpperCase().contains('TỔNG') ||
                        cell.toUpperCase().contains('TOTAL'));

                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>(
                        (states) {
                          if (isTotalRow) {
                            return AppColors.primary.withValues(alpha: 0.08);
                          }
                          return isEven
                              ? Colors.transparent
                              : AppColors.cardBorder.withValues(alpha: 0.1);
                        },
                      ),
                      cells: rowData.asMap().entries.map((cellEntry) {
                        final colIndex = cellEntry.key;
                        final cellText = cellEntry.value;
                        final isStatusCol = colIndex == rowData.length - 1;

                        // Check if last column or special cell is status badge
                        final hasBadge = isStatusCol &&
                            !isTotalRow &&
                            (cellText.contains('Chờ') ||
                                cellText.contains('Đã') ||
                                cellText.contains('Kín') ||
                                cellText.contains('Còn') ||
                                cellText.contains('Bảo trì') ||
                                cellText.contains('Hoàn'));

                        if (hasBadge) {
                          final color = _getBadgeColor(cellText);
                          final bg = _getBadgeBgColor(cellText);
                          return DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                cellText,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                          );
                        }

                        return DataCell(
                          Text(
                            cellText,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isTotalRow || colIndex == 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isTotalRow
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),

            // Footer note
            if (footer != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        footer,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action button if available
            if (actionLabel != null) ...[
              const Divider(height: 1),
              InkWell(
                onTap: onActionTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  color: AppColors.primary.withValues(alpha: 0.05),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        actionLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
