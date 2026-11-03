import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/state/venue_owner_store.dart';
import '../../../domain/entities/court_slot_item.dart';

class OwnerScheduleTab extends StatefulWidget {
  const OwnerScheduleTab({super.key});

  @override
  State<OwnerScheduleTab> createState() => _OwnerScheduleTabState();
}

class _OwnerScheduleTabState extends State<OwnerScheduleTab> {
  String _selectedSport = 'all'; // 'all', 'badminton', 'pickleball'
  String _selectedShift = 'all'; // 'all', 'morning', 'evening'

  int _getStartHour(String timeRange) {
    final parts = timeRange.split(':');
    if (parts.isNotEmpty) {
      return int.tryParse(parts[0].trim()) ?? 0;
    }
    return 0;
  }

  bool _matchesShift(CourtSlotItem slot) {
    if (_selectedShift == 'all') return true;
    final hour = _getStartHour(slot.timeRange);
    if (_selectedShift == 'morning') {
      return hour >= 6 && hour < 14;
    } else if (_selectedShift == 'evening') {
      return hour >= 14 && hour < 22;
    }
    return true;
  }

  bool _matchesSport(CourtSlotItem slot) {
    if (_selectedSport == 'all') return true;
    return slot.sportType.toLowerCase() == _selectedSport.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CourtSlotItem>>(
      valueListenable: VenueOwnerStore.instance.slotsNotifier,
      builder: (context, allSlots, child) {
        final filteredSlots = allSlots.where((s) {
          return _matchesSport(s) && _matchesShift(s);
        }).toList();

        // Summary statistics
        final bookedCount =
            allSlots.where((s) => s.status == CourtSlotStatus.bookedApp).length;
        final manualCount = allSlots
            .where((s) => s.status == CourtSlotStatus.reservedManual)
            .length;
        final maintenanceCount = allSlots
            .where((s) => s.status == CourtSlotStatus.maintenance)
            .length;
        final availableCount =
            allSlots.where((s) => s.status == CourtSlotStatus.available).length;

        // Group filtered slots by court
        final Map<String, List<CourtSlotItem>> groupedCourts = {};
        for (final slot in filteredSlots) {
          groupedCourts.putIfAbsent(slot.courtName, () => []).add(slot);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live status row
              _buildLivePulseHeader(),
              const SizedBox(height: 12),

              // Filter Bar (Sport & Shift)
              _buildFilterSection(),
              const SizedBox(height: 14),

              // Summary Stats Row
              _buildSummaryStatsRow(
                totalSlots: allSlots.length,
                bookedCount: bookedCount,
                manualCount: manualCount,
                maintenanceCount: maintenanceCount,
                availableCount: availableCount,
              ),
              const SizedBox(height: 16),

              // Court Matrix Sections
              if (groupedCourts.isEmpty)
                _buildEmptyState()
              else
                ...groupedCourts.entries.map((entry) {
                  return _buildCourtCard(context, entry.key, entry.value);
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLivePulseHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Lịch trực tiếp',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 12, color: AppColors.warning),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Hôm nay • ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shift filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildShiftFilterChip(
                key: const Key('schedule_filter_shift_all'),
                label: 'Tất cả ca',
                value: 'all',
              ),
              const SizedBox(width: 8),
              _buildShiftFilterChip(
                key: const Key('schedule_filter_shift_morning'),
                label: 'Ca Sáng (06:00 - 14:00)',
                value: 'morning',
              ),
              const SizedBox(width: 8),
              _buildShiftFilterChip(
                key: const Key('schedule_filter_shift_evening'),
                label: 'Ca Tối (14:00 - 22:00)',
                value: 'evening',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Sport filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSportFilterChip(
                key: const Key('schedule_filter_sport_all'),
                label: 'Tất cả môn',
                value: 'all',
              ),
              const SizedBox(width: 8),
              _buildSportFilterChip(
                key: const Key('schedule_filter_sport_badminton'),
                label: '🏸 Cầu lông',
                value: 'badminton',
              ),
              const SizedBox(width: 8),
              _buildSportFilterChip(
                key: const Key('schedule_filter_sport_pickleball'),
                label: '🎾 Pickleball',
                value: 'pickleball',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShiftFilterChip({
    required Key key,
    required String label,
    required String value,
  }) {
    final isSelected = _selectedShift == value;
    return GestureDetector(
      key: key,
      onTap: () => setState(() => _selectedShift = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSportFilterChip({
    required Key key,
    required String label,
    required String value,
  }) {
    final isSelected = _selectedSport == value;
    return GestureDetector(
      key: key,
      onTap: () => setState(() => _selectedSport = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.warning.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.warning : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.warning : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStatsRow({
    required int totalSlots,
    required int bookedCount,
    required int manualCount,
    required int maintenanceCount,
    required int availableCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatPill(
            label: 'Tổng slot',
            count: '$totalSlots',
            color: AppColors.textPrimary,
            bgColor: AppColors.surface,
          ),
          const SizedBox(width: 6),
          _buildStatPill(
            label: 'Khách App',
            count: '$bookedCount',
            color: AppColors.primary,
            bgColor: AppColors.primary.withValues(alpha: 0.12),
          ),
          const SizedBox(width: 6),
          _buildStatPill(
            label: 'Khách gọi',
            count: '$manualCount',
            color: AppColors.warning,
            bgColor: AppColors.warning.withValues(alpha: 0.12),
          ),
          const SizedBox(width: 6),
          _buildStatPill(
            label: 'Bảo trì',
            count: '$maintenanceCount',
            color: AppColors.error,
            bgColor: AppColors.error.withValues(alpha: 0.12),
          ),
          const SizedBox(width: 6),
          _buildStatPill(
            label: 'Trống',
            count: '$availableCount',
            color: AppColors.textSecondary,
            bgColor: AppColors.surface,
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required String label,
    required String count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtCard(
    BuildContext context,
    String courtName,
    List<CourtSlotItem> slots,
  ) {
    final firstSlot = slots.first;
    final isBadminton = firstSlot.sportType == 'badminton';
    final occupiedSlots =
        slots.where((s) => s.status != CourtSlotStatus.available).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Court Card Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isBadminton
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isBadminton
                      ? Icons.sports_tennis_rounded
                      : Icons.sports_baseball_rounded,
                  size: 18,
                  color: isBadminton ? AppColors.primary : AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courtName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBadminton
                          ? 'Sân Thảm Tiêu Chuẩn'
                          : 'Mặt Sân Chống Trượt',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  '$occupiedSlots/${slots.length} đặt',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: occupiedSlots > 0
                        ? AppColors.warning
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),

          // Slots Wrap Matrix
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                slots.map((slot) => _buildSlotTile(context, slot)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotTile(BuildContext context, CourtSlotItem slot) {
    Color borderColor;
    Color bgColor;
    String statusLabel;
    Color statusColor;
    String subtitle;
    List<BoxShadow> shadows = [];

    switch (slot.status) {
      case CourtSlotStatus.bookedApp:
        borderColor = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.15);
        statusLabel = 'Khách App';
        statusColor = AppColors.primary;
        subtitle = slot.customerName ?? '#${slot.ticketId ?? ''}';
        shadows = [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ];
        break;
      case CourtSlotStatus.reservedManual:
        borderColor = AppColors.warning;
        bgColor = AppColors.warning.withValues(alpha: 0.15);
        statusLabel = 'Khách đặt lẻ';
        statusColor = AppColors.warning;
        subtitle = slot.customerName ?? (slot.customerPhone ?? 'Đã giữ');
        shadows = [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.2),
            blurRadius: 6,
          ),
        ];
        break;
      case CourtSlotStatus.maintenance:
        borderColor = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.15);
        statusLabel = 'Bảo trì';
        statusColor = AppColors.error;
        subtitle = 'Đang bảo trì';
        break;
      case CourtSlotStatus.available:
        borderColor = AppColors.cardBorder;
        bgColor = AppColors.background;
        statusLabel = 'Trống';
        statusColor = AppColors.textSecondary;
        subtitle = '${(slot.price / 1000).toInt()}k';
        break;
    }

    return GestureDetector(
      key: Key('slot_tile_${slot.slotId}'),
      onTap: () => _openSlotActionSheet(context, slot),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 82,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: shadows,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Time range display
            Text(
              slot.timeRange.split(' - ').first,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            // Status label badge
            Text(
              statusLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 2),
            // Subtitle (Price / Customer / Note)
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                color: slot.status == CourtSlotStatus.available
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: slot.status == CourtSlotStatus.available
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            if (slot.status == CourtSlotStatus.available &&
                (slot.isPeakHour || slot.isOffPeakHour)) ...[
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: slot.isPeakHour
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: slot.isPeakHour
                        ? AppColors.warning.withValues(alpha: 0.5)
                        : AppColors.secondary.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  slot.isPeakHour ? '🔥 Vàng' : 'Ưu đãi',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: slot.isPeakHour
                        ? AppColors.warning
                        : AppColors.secondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openSlotActionSheet(BuildContext context, CourtSlotItem slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SlotActionBottomSheet(slot: slot),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy khung giờ phù hợp',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vui lòng chọn bộ lọc khác để xem lịch thi đấu',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotActionBottomSheet extends StatefulWidget {
  final CourtSlotItem slot;

  const _SlotActionBottomSheet({required this.slot});

  @override
  State<_SlotActionBottomSheet> createState() => _SlotActionBottomSheetState();
}

class _SlotActionBottomSheetState extends State<_SlotActionBottomSheet> {
  bool _isReserving = false;
  bool _isAdjustingPrice = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _priceController.text = widget.slot.price.toInt().toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final isBadminton = slot.sportType == 'badminton';

    return Container(
      key: const Key('owner_slot_action_sheet'),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle Pill
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isBadminton
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isBadminton
                        ? Icons.sports_tennis_rounded
                        : Icons.sports_baseball_rounded,
                    color: isBadminton ? AppColors.primary : AppColors.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot.courtName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Khung giờ: ${slot.timeRange}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(slot.status),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.cardBorder),
            const SizedBox(height: 12),

            // Content based on slot status
            if (slot.status == CourtSlotStatus.available)
              _buildAvailableSection(context, slot)
            else if (slot.status == CourtSlotStatus.bookedApp)
              _buildBookedAppSection(context, slot)
            else if (slot.status == CourtSlotStatus.reservedManual)
              _buildReservedManualSection(context, slot)
            else if (slot.status == CourtSlotStatus.maintenance)
              _buildMaintenanceSection(context, slot),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(CourtSlotStatus status) {
    String label;
    Color color;
    switch (status) {
      case CourtSlotStatus.bookedApp:
        label = 'Khách App';
        color = AppColors.primary;
        break;
      case CourtSlotStatus.reservedManual:
        label = 'Khách đặt lẻ';
        color = AppColors.warning;
        break;
      case CourtSlotStatus.maintenance:
        label = 'Bảo trì';
        color = AppColors.error;
        break;
      case CourtSlotStatus.available:
        label = 'Sân trống';
        color = AppColors.secondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAvailableSection(BuildContext context, CourtSlotItem slot) {
    if (_isReserving) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Giữ chỗ khách gọi điện',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nhập tên và số điện thoại người liên hệ để ghi nhận vào hệ thống:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('manual_reserve_name_input'),
            controller: _nameController,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Tên khách hàng',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              hintText: 'VD: Nguyễn Khách Gọi Điện',
              hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.person_outline_rounded,
                  color: AppColors.warning),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.warning, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('manual_reserve_phone_input'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Số điện thoại',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              hintText: 'VD: 0912 345 678',
              hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.5)),
              prefixIcon:
                  const Icon(Icons.phone_outlined, color: AppColors.warning),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.warning, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isReserving = false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Hủy',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  key: const Key('manual_reserve_confirm_button'),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    final phone = _phoneController.text.trim();
                    if (name.isEmpty) return;
                    VenueOwnerStore.instance.reserveSlot(
                      slot.slotId,
                      customerName: name,
                      customerPhone: phone,
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Xác nhận giữ chỗ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (_isAdjustingPrice) {
      final presets = [80000, 100000, 120000, 150000, 180000, 240000];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Điều chỉnh giá giờ ${slot.timeRange}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Giá hiện tại: ${(slot.price).toInt()}đ',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Text(
            'Mức giá gợi ý nhanh:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((p) {
              final label = '${(p / 1000).toInt()}k';
              return ActionChip(
                label: Text(label),
                backgroundColor: AppColors.background,
                labelStyle: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                side: BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                onPressed: () {
                  setState(() {
                    _priceController.text = p.toString();
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('slot_price_input'),
            controller: _priceController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Giá mới (VNĐ)',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              hintText: 'VD: 95000',
              hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.payments_outlined,
                  color: AppColors.secondary),
              suffixText: 'đ',
              suffixStyle: TextStyle(
                  color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.secondary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isAdjustingPrice = false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Hủy',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  key: const Key('confirm_update_price_button'),
                  onPressed: () {
                    final entered =
                        double.tryParse(_priceController.text.trim());
                    if (entered == null || entered <= 0) return;
                    VenueOwnerStore.instance
                        .updateSlotPrice(slot.slotId, entered);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Đã cập nhật giá sân thành công')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    '💾 Áp dụng giá mới',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 18, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Giá niêm yết: ${(slot.price).toInt()}đ • Đang sẵn sàng nhận khách',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Action: Manual Reserve
        ElevatedButton.icon(
          key: const Key('action_manual_reserve'),
          onPressed: () => setState(() => _isReserving = true),
          icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
          label: const Text(
            '📞 Giữ chỗ khách gọi điện',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        // Action: Update Slot Price
        ElevatedButton.icon(
          key: const Key('action_update_slot_price'),
          onPressed: () {
            setState(() {
              _isAdjustingPrice = true;
              _priceController.text = slot.price.toInt().toString();
            });
          },
          icon: const Icon(Icons.price_change_rounded, size: 18),
          label: const Text(
            '💵 Điều chỉnh giá giờ này',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        // Action: Lock Maintenance
        OutlinedButton.icon(
          key: const Key('action_lock_maintenance'),
          onPressed: () {
            VenueOwnerStore.instance.lockMaintenance(slot.slotId);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.lock_outline_rounded,
              size: 18, color: AppColors.error),
          label: const Text(
            '🔒 Khóa sân bảo trì',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildBookedAppSection(BuildContext context, CourtSlotItem slot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Khách đặt qua App SportHub',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      slot.ticketId ?? 'Mã vé',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildDetailItem(Icons.person_rounded, 'Khách hàng',
                  slot.customerName ?? 'Khách đặt qua App'),
              const SizedBox(height: 6),
              _buildDetailItem(Icons.phone_rounded, 'Số điện thoại',
                  slot.customerPhone ?? 'Chưa cập nhật'),
              const SizedBox(height: 6),
              _buildDetailItem(
                Icons.check_circle_rounded,
                'Trạng thái thanh toán',
                'Đã thanh toán online (${slot.price.toInt()}đ)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Đang kết nối cuộc gọi tới ${slot.customerPhone ?? ''}')),
            );
          },
          icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
          label: Text('Gọi cho khách (${slot.customerPhone ?? ''})'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Đóng', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildReservedManualSection(BuildContext context, CourtSlotItem slot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Khách đặt giữ chỗ qua điện thoại',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 10),
              _buildDetailItem(Icons.person_rounded, 'Người giữ chỗ',
                  slot.customerName ?? 'Khách gọi'),
              const SizedBox(height: 6),
              _buildDetailItem(Icons.phone_rounded, 'Số điện thoại',
                  slot.customerPhone ?? 'Chưa cung cấp'),
              const SizedBox(height: 6),
              _buildDetailItem(
                Icons.payments_rounded,
                'Hình thức',
                'Thanh toán tại quầy khi nhận sân',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Action: Unlock slot
        ElevatedButton.icon(
          key: const Key('action_unlock_slot'),
          onPressed: () {
            VenueOwnerStore.instance.unlockSlot(slot.slotId);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.lock_open_rounded, size: 18),
          label: const Text(
            '🔓 Mở khóa sân (Trả lại sân trống)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceSection(BuildContext context, CourtSlotItem slot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sân đang tạm khóa bảo trì',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Khách không thể đặt ô này trên ứng dụng.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Action: Unlock slot
        ElevatedButton.icon(
          key: const Key('action_unlock_slot'),
          onPressed: () {
            VenueOwnerStore.instance.unlockSlot(slot.slotId);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.lock_open_rounded, size: 18),
          label: const Text(
            '🔓 Mở khóa sân (Trả lại sân trống)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
