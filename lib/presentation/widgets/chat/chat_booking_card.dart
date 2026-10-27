import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/external_link_service.dart';
import '../../../core/services/venue_sync_service.dart';
import '../../../core/utils/seed_data.dart';
import '../../../core/utils/currency_formatter.dart';

class VenueContact {
  final String address;
  final String? hotline;

  const VenueContact(this.address, this.hotline);
}

/// An interactive booking card embedded within chat bubbles, allowing
/// users to view recommended venue/court slots and take immediate actions.
class ChatBookingCard extends StatelessWidget {
  final Map<String, dynamic> actionCard;
  final VoidCallback? onBookNow;
  final void Function(Map<String, dynamic> actionCard)? onViewCourtMap;

  const ChatBookingCard({
    super.key,
    required this.actionCard,
    this.onBookNow,
    this.onViewCourtMap,
  });

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

  String _formatTimeSlot(Map<String, dynamic> card) {
    final startTime = card['startTime']?.toString();
    final endTime = card['endTime']?.toString();
    if (startTime != null &&
        endTime != null &&
        startTime.isNotEmpty &&
        endTime.isNotEmpty) {
      return '$startTime - $endTime';
    }
    final time = card['time']?.toString();
    if (time != null && time.isNotEmpty) {
      return time;
    }
    return 'Chưa xác định';
  }

  String _getSportLabel(String? rawSport) {
    if (rawSport == null || rawSport.isEmpty) return 'Thể thao';
    final lower = rawSport.toLowerCase();
    if (lower.contains('badminton') || lower.contains('cầu lông')) {
      return 'Cầu lông';
    }
    if (lower.contains('football') || lower.contains('bóng đá')) {
      return 'Bóng đá';
    }
    if (lower.contains('pickleball')) {
      return 'Pickleball';
    }
    return rawSport;
  }

  String _getSportIcon(String? rawSport) {
    if (rawSport == null || rawSport.isEmpty) return '🏅';
    final lower = rawSport.toLowerCase();
    if (lower.contains('badminton') || lower.contains('cầu lông')) {
      return '🏸';
    }
    if (lower.contains('football') || lower.contains('bóng đá')) {
      return '⚽';
    }
    if (lower.contains('pickleball')) {
      return '🏓';
    }
    return '🏅';
  }

  VenueContact? _resolveVenueContact() {
    final venueId = actionCard['venueId']?.toString();
    final venueName = actionCard['venueName']?.toString().toLowerCase();
    final venues = [
      ...VenueSyncService.instance.venuesNotifier.value,
      ...SeedData.sampleVenues,
    ];
    for (final venue in venues) {
      final isTaoDanAlias =
          (venue.id == 'venue_01' || venue.id == 'venue_q1_04') &&
              (venueId == 'venue_01' || venueId == 'venue_q1_04');
      if (venue.id == venueId ||
          isTaoDanAlias ||
          (venueName != null && venueName.isNotEmpty &&
              venue.name.toLowerCase() == venueName)) {
        return VenueContact(venue.address, venue.hotline);
      }
    }
    final address = actionCard['address']?.toString();
    final hotline = actionCard['hotline']?.toString();
    if ((address?.trim().isNotEmpty ?? false) ||
        (hotline?.trim().isNotEmpty ?? false)) {
      return VenueContact(address ?? '', hotline);
    }
    return null;
  }

  void _showLaunchError(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Không mở được $action. Vui lòng thử lại.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venueName = actionCard['venueName']?.toString() ?? 'Sân thể thao';
    final court = actionCard['court']?.toString() ?? 'Sân tiêu chuẩn';
    final date = actionCard['date']?.toString() ?? 'Hôm nay';
    final timeSlot = _formatTimeSlot(actionCard);
    final priceStr = _formatPrice(actionCard['price']);
    final sportLabel = _getSportLabel(actionCard['sport']?.toString());
    final sportIcon = _getSportIcon(actionCard['sport']?.toString());
    final status = actionCard['status']?.toString() ?? 'Còn trống';
    final isPaid = actionCard['isPaid'] == true || actionCard['isBooked'] == true;
    final venueContact = _resolveVenueContact();
    final address = actionCard['address']?.toString().trim().isNotEmpty == true
        ? actionCard['address'].toString()
        : venueContact?.address ?? '';
    final hotline = actionCard['hotline']?.toString().trim().isNotEmpty == true
        ? actionCard['hotline'].toString()
        : venueContact?.hotline;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Venue name & Sport Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  venueName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sportIcon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      sportLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (address.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(address,
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (address.isNotEmpty)
                TextButton.icon(
                  key: const Key('btn_chat_open_map'),
                  onPressed: () async {
                    if (!await ExternalLinkService.openMap(address) &&
                        context.mounted) {
                      _showLaunchError(context, 'bản đồ');
                    }
                  },
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Mở bản đồ'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
              if (hotline != null && hotline.trim().isNotEmpty)
                TextButton.icon(
                  key: const Key('btn_chat_call_venue'),
                  onPressed: () async {
                    if (!await ExternalLinkService.callPhone(hotline) &&
                        context.mounted) {
                      _showLaunchError(context, 'trình gọi điện');
                    }
                  },
                  icon: const Icon(Icons.call_outlined, size: 16),
                  label: Text('Gọi sân • $hotline'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Court & Availability status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stadium_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      court,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : AppColors.slotAvailable.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle : Icons.circle,
                      size: isPaid ? 12 : 6,
                      color: isPaid ? const Color(0xFF10B981) : AppColors.slotAvailable,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isPaid ? 'Đã thanh toán' : status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPaid ? const Color(0xFF10B981) : AppColors.slotAvailable,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date & Time Slot
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$date • $timeSlot',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (actionCard['addons'] is List && (actionCard['addons'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Dịch vụ đặt thêm:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ...(actionCard['addons'] as List).map(
                    (addon) => Padding(
                      padding: const EdgeInsets.only(left: 17, top: 2),
                      child: Text(
                        '• ${addon.toString()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),

          // Price row
          Row(
            children: [
              Text(
                'Giá dự kiến: ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                priceStr,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action buttons
          if (isPaid) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    'Đã giữ chỗ • ${actionCard['bookingId'] ?? 'Thành công'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton(
              key: const Key('btn_chat_book_now'),
              onPressed: onBookNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '⚡ Đặt & Thanh toán VietQR ngay',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          OutlinedButton(
            key: const Key('btn_chat_view_court_map'),
            onPressed:
                onViewCourtMap != null ? () => onViewCourtMap!(actionCard) : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '🔍 Xem trên sơ đồ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
