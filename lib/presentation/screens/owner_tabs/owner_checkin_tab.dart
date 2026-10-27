import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/venue_sync_service.dart';
import '../../../core/state/venue_owner_store.dart';
import '../../../domain/entities/court_slot_item.dart';

class OwnerCheckinTab extends StatefulWidget {
  const OwnerCheckinTab({super.key});

  @override
  State<OwnerCheckinTab> createState() => _OwnerCheckinTabState();
}

class _OwnerCheckinTabState extends State<OwnerCheckinTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'pending', 'checked_in'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  String _getAddOnsSummary(String? ticketId) {
    if (ticketId == null || ticketId.isEmpty) {
      return 'Không có (Chỉ thuê sân)';
    }
    final clean = ticketId.trim().toUpperCase();
    final bookings = VenueSyncService.instance.bookingsNotifier.value;
    final booking = bookings.firstWhere(
      (b) =>
          (b['id']?.toString().toUpperCase() == clean) ||
          (b['bookingId']?.toString().toUpperCase() == clean),
      orElse: () => <String, dynamic>{},
    );
    final addOns = booking['addOns'];
    if (addOns is List && addOns.isNotEmpty) {
      final summaryList = <String>[];
      for (final item in addOns) {
        if (item is Map) {
          final qty = item['quantity'] ?? item['qty'] ?? 1;
          final name = item['name'] ?? 'Dịch vụ';
          summaryList.add('${qty}x $name');
        }
      }
      if (summaryList.isNotEmpty) {
        return summaryList.join(', ');
      }
    }
    return 'Không có (Chỉ thuê sân)';
  }

  void _openQrScannerModal(BuildContext context) {
    final TextEditingController qrInputController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final store = VenueOwnerStore.instance;
            final bookedSlots = store.slots
                .where((s) =>
                    s.ticketId != null || s.status == CourtSlotStatus.bookedApp)
                .toList();

            return Container(
              key: const Key('qr_scanner_modal'),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: AppColors.secondary, width: 2),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sheet handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: AppColors.secondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quét mã QR Check-in',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Nhập hoặc quét mã vé để xác nhận vào sân',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: AppColors.textSecondary),
                          onPressed: () => Navigator.of(modalContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Simulated Camera Viewport
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Scanning grid effect
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.secondary,
                                    width: 2.5,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 56,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Hướng camera về phía mã QR của khách',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Manual code input
                    TextField(
                      key: const Key('qr_input_field'),
                      controller: qrInputController,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Nhập mã vé (VD: SH-8291)',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                          fontSize: 14,
                          letterSpacing: 0,
                        ),
                        prefixIcon: const Icon(
                            Icons.confirmation_number_outlined,
                            color: AppColors.secondary),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.secondary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick select chips
                    if (bookedSlots.isNotEmpty) ...[
                      Text(
                        'Vé khả dụng hôm nay (chạm để chọn nhanh):',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: bookedSlots.map((slot) {
                          final isChecked =
                              store.isCheckedIn(slot.ticketId ?? '');
                          return ActionChip(
                            avatar: Icon(
                              isChecked
                                  ? Icons.check_circle_rounded
                                  : Icons.confirmation_number_rounded,
                              size: 14,
                              color: isChecked
                                  ? AppColors.primary
                                  : AppColors.secondary,
                            ),
                            label: Text(
                              '${slot.ticketId} (${slot.customerName ?? "Khách"})',
                              style: TextStyle(
                                fontSize: 11,
                                color: isChecked
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                decoration: isChecked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            backgroundColor: AppColors.background,
                            side: BorderSide(
                              color: isChecked
                                  ? AppColors.cardBorder
                                  : AppColors.secondary.withValues(alpha: 0.5),
                            ),
                            onPressed: () {
                              qrInputController.text = slot.ticketId ?? '';
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Confirm check-in button
                    ElevatedButton.icon(
                      key: const Key('qr_submit_checkin_button'),
                      onPressed: () {
                        final code =
                            qrInputController.text.trim().toUpperCase();
                        if (code.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập mã vé'),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                          return;
                        }
                        final success = store.checkInTicket(code);
                        if (success) {
                          VenueSyncService.instance.checkInBooking(code);
                          Navigator.of(modalContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('✅ Check-in thành công mã vé: $code'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '❌ Không tìm thấy mã vé: $code tại cơ sở này'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text(
                        'Xác nhận Check-in ngay',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CourtSlotItem>>(
      valueListenable: VenueOwnerStore.instance.slotsNotifier,
      builder: (context, allSlots, child) {
        final store = VenueOwnerStore.instance;

        // Extract all booked slots with tickets
        final bookedTickets = allSlots.where((s) {
          return s.ticketId != null || s.status == CourtSlotStatus.bookedApp;
        }).toList();

        // Apply search and status filtering
        final filteredTickets = bookedTickets.where((slot) {
          final isChecked = store.isCheckedIn(slot.ticketId ?? '');
          if (_filterStatus == 'pending' && isChecked) return false;
          if (_filterStatus == 'checked_in' && !isChecked) return false;

          if (_searchQuery.isEmpty) return true;
          final name = (slot.customerName ?? '').toLowerCase();
          final phone = (slot.customerPhone ?? '').toLowerCase();
          final ticket = (slot.ticketId ?? '').toLowerCase();
          final court = slot.courtName.toLowerCase();
          return name.contains(_searchQuery) ||
              phone.contains(_searchQuery) ||
              ticket.contains(_searchQuery) ||
              court.contains(_searchQuery);
        }).toList();

        final totalCount = bookedTickets.length;
        final checkedInCount = bookedTickets
            .where((s) => store.isCheckedIn(s.ticketId ?? ''))
            .length;
        final pendingCount = totalCount - checkedInCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Action header with QR button
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soát Vé & Check-in',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Quản lý lượt khách vào sân hôm nay',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    key: const Key('open_qr_scanner_button'),
                    onPressed: () => _openQrScannerModal(context),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text(
                      'Quét mã QR',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search bar
              TextField(
                key: const Key('checkin_search_input'),
                controller: _searchController,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên khách, SĐT, mã vé (SH-...)...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textSecondary),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.secondary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Overview stats row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricPill(
                      label: 'Tổng vé',
                      value: '$totalCount',
                      color: AppColors.secondary,
                      icon: Icons.confirmation_number_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricPill(
                      label: 'Đã nhận sân',
                      value: '$checkedInCount',
                      color: AppColors.primary,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricPill(
                      label: 'Chưa đến',
                      value: '$pendingCount',
                      color: AppColors.warning,
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter status chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Tất cả ($totalCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('pending', 'Chưa check-in ($pendingCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'checked_in', 'Đã nhận sân ($checkedInCount)'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Booking list
              if (filteredTickets.isEmpty)
                _buildEmptyState()
              else
                ...filteredTickets.map((slot) {
                  return _buildTicketCard(context, slot, store);
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.secondary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(
      BuildContext context, CourtSlotItem slot, VenueOwnerStore store) {
    final ticketId = slot.ticketId ?? 'SH-0000';
    final isCheckedIn = store.isCheckedIn(ticketId);
    final checkInTime = store.getCheckInTime(ticketId);
    final addOns = _getAddOnsSummary(ticketId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCheckedIn
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.warning.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isCheckedIn
                ? AppColors.primary.withValues(alpha: 0.05)
                : AppColors.warning.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Ticket ID & Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isCheckedIn
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.confirmation_number_rounded,
                          size: 16, color: AppColors.textPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ticketId,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            letterSpacing: 1.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCheckedIn
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isCheckedIn ? AppColors.primary : AppColors.warning,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCheckedIn
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        size: 13,
                        color:
                            isCheckedIn ? AppColors.primary : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCheckedIn ? 'Đã nhận sân' : 'Chưa check-in',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCheckedIn
                              ? AppColors.primary
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer details
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppColors.secondary.withValues(alpha: 0.2),
                      child: const Icon(Icons.person_rounded,
                          size: 20, color: AppColors.secondary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot.customerName ?? 'Khách đặt qua App',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined,
                                  size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                slot.customerPhone ?? '0901 234 567',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatVnd(slot.price),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: AppColors.cardBorder, height: 1),
                const SizedBox(height: 10),

                // Court & Time range
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.sports_tennis_rounded,
                              size: 15, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              slot.courtName,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 15, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Text(
                          slot.timeRange,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Add-ons summary
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined,
                          size: 14, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Text(
                        'Dịch vụ kèm: ',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Expanded(
                        child: Text(
                          addOns,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom check-in action
                const SizedBox(height: 12),
                if (!isCheckedIn)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: Key('confirm_checkin_$ticketId'),
                      onPressed: () {
                        store.checkInTicket(ticketId);
                        VenueSyncService.instance.checkInBooking(ticketId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '✅ Check-in thành công cho ${slot.customerName ?? ticketId}'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text(
                        'Xác nhận Check-in',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            checkInTime != null
                                ? 'Khách đã nhận sân lúc ${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}'
                                : 'Khách đã nhận sân',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Không tìm thấy lượt đặt vé phù hợp',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Thử tìm với tên khách, số điện thoại hoặc mã vé khác',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
