import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/venue_sync_service.dart';
import '../../../core/state/venue_owner_store.dart';
import '../../../domain/entities/court_slot_item.dart';

class OwnerRevenueTab extends StatefulWidget {
  const OwnerRevenueTab({super.key});

  @override
  State<OwnerRevenueTab> createState() => _OwnerRevenueTabState();
}

class _OwnerRevenueTabState extends State<OwnerRevenueTab> {
  String _selectedPeriod = 'today'; // 'today', 'week', 'month'

  String _formatVnd(num amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} đ';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: VenueSyncService.instance.bookingsNotifier,
      builder: (context, allBookings, _) {
        return ValueListenableBuilder<List<CourtSlotItem>>(
          valueListenable: VenueOwnerStore.instance.slotsNotifier,
          builder: (context, allSlots, child) {
            // Compute revenue and occupancy
            final bookedSlots = allSlots
                .where(
                  (s) =>
                      s.status == CourtSlotStatus.bookedApp ||
                      s.status == CourtSlotStatus.reservedManual,
                )
                .toList();

            final double courtRevenue = bookedSlots.fold(
              0.0,
              (sum, slot) => sum + slot.price,
            );

            // Add-ons revenue dynamically computed from real bookings
            double addOnsRevenue = 0.0;
            final Map<String, Map<String, dynamic>> aggregatedAddons = {};
            for (final b in allBookings) {
              final items = b['addOns'];
              if (items is List) {
                for (final item in items) {
                  if (item is Map) {
                    final name =
                        (item['name'] ?? item['id'] ?? 'Dịch vụ') as String;
                    final unitPrice =
                        ((item['price'] ?? item['unitPrice'] ?? 0) as num).toInt();
                    final qty =
                        ((item['quantity'] ?? item['qty'] ?? 1) as num).toInt();
                    addOnsRevenue += unitPrice * qty;
                    if (aggregatedAddons.containsKey(name)) {
                      aggregatedAddons[name]!['qty'] =
                          (aggregatedAddons[name]!['qty'] as int) + qty;
                    } else {
                      aggregatedAddons[name] = {
                        'name': name,
                        'qty': qty,
                        'unitPrice': unitPrice,
                      };
                    }
                  }
                }
              }
            }

            final double totalTodayRevenue = courtRevenue + addOnsRevenue;

            // Occupancy calculation
            final int totalSlotsCount = allSlots.isEmpty ? 1 : allSlots.length;
            final double occupancyRate =
                (bookedSlots.length / totalSlotsCount) * 100;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Báo Cáo Doanh Thu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Theo dõi hiệu suất sân và các nguồn thu dịch vụ',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),

              // Period Filter Chips
              Row(
                children: [
                  _buildPeriodChip(
                    key: const Key('revenue_period_today'),
                    label: 'Hôm nay',
                    value: 'today',
                  ),
                  const SizedBox(width: 8),
                  _buildPeriodChip(
                    key: const Key('revenue_period_week'),
                    label: 'Tuần này',
                    value: 'week',
                  ),
                  const SizedBox(width: 8),
                  _buildPeriodChip(
                    key: const Key('revenue_period_month'),
                    label: 'Tháng này',
                    value: 'month',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Primary Metric Card: Tổng doanh thu hôm nay
              _buildPrimaryRevenueCard(
                  totalTodayRevenue, courtRevenue, addOnsRevenue),
              const SizedBox(height: 14),

              // Secondary Metrics Row: Tỷ lệ lấp đầy & Số lượt khách
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Tỷ lệ lấp đầy',
                      value: '${occupancyRate.toStringAsFixed(1)}%',
                      subtitle:
                          '${bookedSlots.length}/$totalSlotsCount khung giờ',
                      icon: Icons.pie_chart_rounded,
                      accentColor: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Số lượt khách',
                      value: '${bookedSlots.length} lượt',
                      subtitle:
                          'App: ${bookedSlots.where((s) => s.status == CourtSlotStatus.bookedApp).length} • Sân: ${bookedSlots.where((s) => s.status == CourtSlotStatus.reservedManual).length}',
                      icon: Icons.groups_rounded,
                      accentColor: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 7-day revenue chart
              _buildSevenDayChartSection(totalTodayRevenue),
              const SizedBox(height: 20),

              // Add-ons breakdown section
              _buildAddOnsSection(addOnsRevenue, aggregatedAddons),
              const SizedBox(height: 20),

              // Peak hour & smart recommendation
              _buildOptimizationCard(),
            ],
          ),
        );
      },
    );
  },
);
  }

  Widget _buildPeriodChip({
    required Key key,
    required String label,
    required String value,
  }) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        key: key,
        onTap: () => setState(() => _selectedPeriod = value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.warning : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.warning : AppColors.cardBorder,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.warning.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.black : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryRevenueCard(
      double total, double courtRevenue, double addOnsRevenue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFFFFBEB),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng doanh thu hôm nay',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded,
                        size: 13, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      '+14.8%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatVnd(total),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiền thuê sân',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatVnd(courtRevenue),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: AppColors.cardBorder),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dịch vụ / Add-ons',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatVnd(addOnsRevenue),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSevenDayChartSection(double todayRevenue) {
    final List<Map<String, dynamic>> days = [
      {'day': 'T2', 'amount': 2400000},
      {'day': 'T3', 'amount': 2900000},
      {'day': 'T4', 'amount': 3200000},
      {'day': 'T5', 'amount': 2750000},
      {'day': 'T6', 'amount': 3800000},
      {'day': 'T7', 'amount': 4600000},
      {'day': 'CN', 'amount': todayRevenue.toInt(), 'isToday': true},
    ];

    final maxVal = days.map((d) => d['amount'] as int).fold(1, (m, v) => v > m ? v : m);
    for (final d in days) {
      d['height'] = (d['amount'] as int) / maxVal;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biểu đồ doanh thu 7 ngày qua',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Đơn vị: VNĐ',
                  style:
                      TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Bar Chart
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((data) {
                final heightFactor = data['height'] as double;
                final isToday = (data['isToday'] as bool?) ?? false;
                final day = data['day'] as String;
                final amount = (data['amount'] as int) / 1000000;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${amount.toStringAsFixed(1)}M',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? AppColors.warning
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 100 * heightFactor,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isToday
                                  ? [AppColors.warning, const Color(0xFFEA580C)]
                                  : [
                                      AppColors.secondary
                                          .withValues(alpha: 0.7),
                                      AppColors.secondary
                                          .withValues(alpha: 0.3),
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          day,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.w500,
                            color: isToday
                                ? AppColors.warning
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddOnsSection(
    double totalAddOns,
    Map<String, Map<String, dynamic>> addOnItemsMap,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dịch vụ bán kèm (Add-ons)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tổng: ${_formatVnd(totalAddOns)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (addOnItemsMap.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 36,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có dịch vụ phụ hôm nay',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Các đơn bán nước giải khát, thuê vợt sẽ hiển thị khi khách đặt.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...addOnItemsMap.values.map((item) {
              final name = item['name'] as String;
              final qty = item['qty'] as int;
              final unitPrice = item['unitPrice'] as int;
              final totalItem = qty * unitPrice;
              final icon = _getAddonIcon(name);
              final color = _getAddonColor(name);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 16, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$qty x ${_formatVnd(unitPrice)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatVnd(totalItem),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  IconData _getAddonIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('nước') ||
        lower.contains('pocari') ||
        lower.contains('aquafina') ||
        lower.contains('revive')) {
      return Icons.local_drink_rounded;
    }
    if (lower.contains('vợt')) {
      return Icons.sports_tennis_rounded;
    }
    if (lower.contains('cầu') || lower.contains('bóng')) {
      return Icons.sports_baseball_rounded;
    }
    return Icons.shopping_bag_rounded;
  }

  Color _getAddonColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('pocari')) return AppColors.secondary;
    if (lower.contains('aquafina')) return const Color(0xFF38BDF8);
    if (lower.contains('vợt')) return AppColors.primary;
    if (lower.contains('cầu') || lower.contains('bóng')) return AppColors.warning;
    return AppColors.secondary;
  }

  Widget _buildOptimizationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.insights_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gợi ý tối ưu doanh thu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Khung giờ 12:00 - 15:00 đang có 75% sân trống. Cân nhắc chạy chương trình giảm 20% Happy Hour để tăng công suất lấp đầy!',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
