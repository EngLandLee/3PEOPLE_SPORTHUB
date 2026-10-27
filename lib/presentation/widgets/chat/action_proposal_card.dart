import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/chat_message.dart';

/// An interactive card widget representing an [ActionProposal] emitted by the chatbot
/// in the HAIA (Human-AI-Interaction Architecture) requiring explicit user confirmation (HITL).
class ActionProposalCard extends StatefulWidget {
  final ActionProposal proposal;
  final VoidCallback? onCancel;
  final void Function(Map<String, String> edits)? onApprove;

  const ActionProposalCard({
    super.key,
    required this.proposal,
    this.onCancel,
    this.onApprove,
  });

  @override
  State<ActionProposalCard> createState() => _ActionProposalCardState();
}

class _ActionProposalCardState extends State<ActionProposalCard> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (final field in widget.proposal.form) {
      _controllers[field.key] = TextEditingController(text: field.currentValue);
    }
  }

  @override
  void didUpdateWidget(covariant ActionProposalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proposal.id != widget.proposal.id) {
      for (final controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();
      _initControllers();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleApprove() {
    final edits = <String, String>{};
    for (final field in widget.proposal.form) {
      edits[field.key] =
          _controllers[field.key]?.text.trim() ?? field.currentValue;
    }
    widget.onApprove?.call(edits);
  }

  String _formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return '0 đ';
    if (rawPrice is num) {
      return CurrencyFormatter.format(rawPrice);
    }
    final str = rawPrice.toString();
    if (str.contains('đ') || str.contains('VND') || str.contains('₫')) {
      return str;
    }
    final parsed = num.tryParse(str);
    if (parsed != null) {
      return CurrencyFormatter.format(parsed);
    }
    return str;
  }

  IconData _getSportIcon(String? sport, String? courtName) {
    final combined = '${sport ?? ''} ${courtName ?? ''}'.toLowerCase();
    if (combined.contains('cầu lông') || combined.contains('badminton')) {
      return Icons.sports_tennis;
    }
    if (combined.contains('bóng đá') ||
        combined.contains('football') ||
        combined.contains('soccer')) {
      return Icons.sports_soccer;
    }
    if (combined.contains('tennis') || combined.contains('quần vợt')) {
      return Icons.sports_tennis;
    }
    if (combined.contains('pickleball')) {
      return Icons.sports_baseball;
    }
    if (combined.contains('bóng rổ') || combined.contains('basketball')) {
      return Icons.sports_basketball;
    }
    if (combined.contains('bóng chuyền') || combined.contains('volleyball')) {
      return Icons.sports_volleyball;
    }
    return Icons.event_available_rounded;
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    final status = widget.proposal.status;
    final isExpired = widget.proposal.isExpired && widget.proposal.isPending;

    if (status == 'executed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.slotAvailable.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.slotAvailable.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: const Text(
          '✅ Đã xác nhận & đặt sân thành công',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.slotAvailable,
          ),
        ),
      );
    }

    if (status == 'cancelled') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'Đã hủy đề xuất',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    if (status == 'rejected') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Đã từ chối đề xuất',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
      );
    }

    if (status == 'approved') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'Đang xử lý đặt sân...',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (isExpired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: const Text(
          '⏰ Đề xuất đã hết hạn',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.warning,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.proposal.target;
    final courtName = target['courtName']?.toString() ??
        target['court']?.toString() ??
        'Sân tiêu chuẩn';
    final venueName = target['venueName']?.toString() ??
        target['activeVenueName']?.toString() ??
        target['venue']?.toString() ??
        'Chưa xác định';
    final date = target['date']?.toString() ?? 'Hôm nay';

    String timeSlot = target['timeSlot']?.toString() ??
        target['time']?.toString() ??
        '';
    if (timeSlot.isEmpty) {
      final startTime = target['startTime']?.toString();
      final endTime = target['endTime']?.toString();
      if (startTime != null &&
          endTime != null &&
          startTime.isNotEmpty &&
          endTime.isNotEmpty) {
        timeSlot = '$startTime - $endTime';
      } else {
        timeSlot = 'Chưa xác định';
      }
    }

    final price = _formatPrice(target['price']);
    final sport = target['sport']?.toString();
    final isPending = widget.proposal.isPending && !widget.proposal.isExpired;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSportIcon(sport, courtName),
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ĐỀ XUẤT ĐẶT SÂN',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 11,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Xác nhận (HITL)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Target Details Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cardBorder.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.storefront_outlined,
                  label: 'Địa điểm',
                  value: venueName,
                  isBold: true,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  icon: Icons.sports_tennis_outlined,
                  label: 'Sân',
                  value: courtName,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Ngày',
                  value: date,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Khung giờ',
                  value: timeSlot,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  icon: Icons.payments_outlined,
                  label: 'Giá dự kiến',
                  value: price,
                  valueColor: AppColors.primary,
                  isBold: true,
                ),
              ],
            ),
          ),

          // Editable Form Fields (e.g. Note)
          if (widget.proposal.form.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...widget.proposal.form.map((field) {
              if (!isPending) {
                final val =
                    _controllers[field.key]?.text.trim() ?? field.currentValue;
                if (val.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${field.label}: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          val,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final maxLen =
                  field.maxLength ?? (field.type == 'textarea' ? 200 : null);
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _controllers[field.key],
                      maxLines: field.type == 'textarea' ? 3 : 1,
                      maxLength: maxLen,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhập ${field.label.toLowerCase()}...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Status or Action Buttons
          const SizedBox(height: 12),
          if (!isPending)
            _buildStatusBanner()
          else
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: widget.onCancel != null
                        ? () => widget.onCancel!()
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.cardBorder, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _handleApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Xác nhận đặt sân',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
