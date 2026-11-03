import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

/// Card widget displayed in chatbot for recruitment / matchmaking proposals.
class ChatRecruitmentCard extends StatelessWidget {
  final Map<String, dynamic> cardData;
  final VoidCallback? onPublish;

  const ChatRecruitmentCard({
    super.key,
    required this.cardData,
    this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final title = cardData['title']?.toString() ?? 'Tuyển thành viên ghép kèo';
    final venueName = cardData['venueName']?.toString() ?? 'Sân thể thao';
    final district = cardData['district']?.toString() ?? 'TP.HCM';
    final scheduledTime =
        cardData['scheduledTime']?.toString() ?? '19:00 - 21:00 Hôm nay';
    final requiredPlayers =
        (cardData['requiredPlayers'] as num?)?.toInt() ?? 4;
    final currentPlayers =
        (cardData['currentPlayers'] as num?)?.toInt() ?? 2;
    final needed = requiredPlayers - currentPlayers;
    final skillLevel =
        cardData['skillLevel']?.toString() ?? 'Trung bình (2.0 - 3.5)';
    final shareFee = (cardData['shareFee'] as num?)?.toDouble() ?? 45000;
    final imageUrl = cardData['imageUrl']?.toString();
    final sport = cardData['sportType']?.toString() ?? 'badminton';
    final isPickleball = sport.contains('pickleball');
    final isFootball = sport.contains('football') || sport.contains('bóng đá');

    final sportBadge = isPickleball
        ? '🏓 Pickleball'
        : (isFootball ? '⚽ Bóng đá' : '🏸 Cầu lông');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'BÀI TUYỂN THÀNH VIÊN',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  sportBadge,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Attached Image if available
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: AppColors.cardBorder.withValues(alpha: 0.3),
                    child: const Center(
                      child: Icon(Icons.image_outlined,
                          size: 32, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Body Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                // Info Rows
                _buildInfoRow(
                  Icons.location_on_outlined,
                  '$venueName ($district)',
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  Icons.access_time_rounded,
                  scheduledTime,
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  Icons.group_outlined,
                  'Cần tuyển: $needed người (Hiện có $currentPlayers/$requiredPlayers)',
                  highlight: true,
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  Icons.star_outline_rounded,
                  'Trình độ: $skillLevel',
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  Icons.payments_outlined,
                  'Phí giao lưu: ${CurrencyFormatter.format(shareFee.toInt())}/người',
                ),

                const SizedBox(height: 14),

                // Publish Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('btn_publish_recruitment_to_community'),
                    icon: const Icon(Icons.campaign_rounded, size: 18),
                    label: const Text(
                      '📢 Đăng lên Bảng tin Cộng đồng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: onPublish,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool highlight = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: highlight ? AppColors.primary : AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
