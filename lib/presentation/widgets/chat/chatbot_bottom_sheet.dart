import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/chatbot_service.dart';
import '../../../core/services/venue_sync_service.dart';
import '../../../core/state/auth_store.dart';
import '../../../core/state/notification_store.dart';
import '../../../core/state/ticket_store.dart';
import '../../../core/state/venue_owner_store.dart';
import '../../../core/utils/seed_data.dart';
import '../../../core/utils/sport_image_catalog.dart';
import '../../../data/models/ticket_model.dart';
import '../../../domain/entities/app_notification.dart';
import '../../../domain/entities/community_post.dart';
import '../../../domain/entities/time_slot.dart';
import '../../../domain/entities/venue.dart';
import '../../../main.dart';
import '../auth_guard_sheet.dart';
import 'chat_message_bubble.dart';
import 'chat_typing_indicator.dart';

/// Modal bottom sheet providing full AI chatbot assistance with context awareness,
/// quick prompt chips, real-time message stream, and one-tap booking execution.
class ChatbotBottomSheet extends StatefulWidget {
  final Venue? currentVenue;
  final String currentRoute;
  final DateTime? selectedDate;
  final Function(Map<String, dynamic> actionCard)? onBookNowAction;
  final Function(Map<String, dynamic> actionCard)? onViewCourtMapAction;

  const ChatbotBottomSheet({
    super.key,
    this.currentVenue,
    this.currentRoute = '/home',
    this.selectedDate,
    this.onBookNowAction,
    this.onViewCourtMapAction,
  });

  /// Opens the Chatbot bottom sheet
  static Future<void> show(
    BuildContext context, {
    Venue? currentVenue,
    String currentRoute = '/home',
    DateTime? selectedDate,
    Function(Map<String, dynamic> actionCard)? onBookNowAction,
    Function(Map<String, dynamic> actionCard)? onViewCourtMapAction,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChatbotBottomSheet(
        currentVenue: currentVenue,
        currentRoute: currentRoute,
        selectedDate: selectedDate,
        onBookNowAction: onBookNowAction,
        onViewCourtMapAction: onViewCourtMapAction,
      ),
    );
  }

  @override
  State<ChatbotBottomSheet> createState() => _ChatbotBottomSheetState();
}

class _ChatbotBottomSheetState extends State<ChatbotBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _attachedImageUrl;

  @override
  void initState() {
    super.initState();
    ChatbotService.instance.updateContext(_buildCurrentContext());
    ChatbotService.instance.messagesNotifier.addListener(_onMessagesUpdated);
    ChatbotService.instance.isTypingNotifier.addListener(_onMessagesUpdated);

    if (ChatbotService.instance.messagesNotifier.value.isEmpty) {
      final greeting = widget.currentVenue != null
          ? 'Xin chào! Em là trợ lý AI SportHub. Em có thể hỗ trợ bạn tìm sân trống, giải đáp quy định và đặt lịch nhanh tại ${widget.currentVenue!.name}. Bạn cần giúp gì ạ?'
          : 'Xin chào! Em là trợ lý AI SportHub. Em có thể gợi ý sân gần bạn, kiểm tra khung giờ trống và đặt sân nhanh chóng!';
      ChatbotService.instance.addMessage(
        ChatMessage(
          id: 'msg_init_${DateTime.now().millisecondsSinceEpoch}',
          text: greeting,
          sender: 'assistant',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  @override
  void dispose() {
    ChatbotService.instance.messagesNotifier.removeListener(_onMessagesUpdated);
    ChatbotService.instance.isTypingNotifier.removeListener(_onMessagesUpdated);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMessagesUpdated() {
    if (mounted) {
      setState(() {});
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  ChatContext _buildCurrentContext() {
    final authUser = AuthStore.instance.currentUser;
    final isGuest = AuthStore.instance.isGuest;
    final isOwner = VenueOwnerStore.instance.isOwnerMode;
    final venue = widget.currentVenue;
    final preferredSport = authUser?.preferredSport;

    return ChatContext(
      userId: isGuest ? null : authUser?.userId,
      userName: isOwner
          ? (authUser?.fullName ?? 'Chủ sân Tao Đàn')
          : (isGuest ? null : authUser?.fullName),
      userPhone: isGuest ? null : authUser?.phone,
      userRole: isOwner ? 'owner' : (isGuest ? 'guest' : 'player'),
      currentRoute: widget.currentRoute,
      venueId: isOwner
          ? VenueOwnerStore.instance.activeVenueId
          : venue?.id,
      venueName: isOwner
          ? VenueOwnerStore.instance.activeVenueName
          : venue?.name,
      sport: venue != null && venue.sportTypes.isNotEmpty
          ? venue.sportTypes.first
          : (preferredSport != null && preferredSport.isNotEmpty
              ? preferredSport
              : null),
      isGuest: isGuest,
    );
  }

  void _sendTextMessage() {
    final text = _textController.text.trim();
    final img = _attachedImageUrl;
    if (text.isEmpty && img == null) return;
    _textController.clear();
    setState(() {
      _attachedImageUrl = null;
    });

    final effectiveText = text.isEmpty
        ? 'Hãy hỗ trợ tôi tạo bài đăng tuyển thành viên / ghép kèo với ảnh đính kèm này'
        : text;

    ChatbotService.instance.sendMessage(
      effectiveText,
      imageUrl: img,
      context: _buildCurrentContext(),
    );
  }

  void _onChipTap(String prompt) {
    if (prompt.contains('Xem vé của tôi') || prompt.contains('xem vé')) {
      Navigator.of(context).pop();
      Navigator.of(context).popUntil((route) => route.isFirst);
      MainNavigationController.switchToTab?.call(2);
      return;
    }
    if (prompt.contains('Xem trên sơ đồ')) {
      final msgs = ChatbotService.instance.messagesNotifier.value;
      final latestCardMsg = msgs.reversed.cast<ChatMessage?>().firstWhere(
            (m) =>
                m != null &&
                m.hasActionCard &&
                m.actionCard!['type'] == 'booking_card',
            orElse: () => null,
          );
      if (latestCardMsg != null) {
        _handleViewCourtMap(latestCardMsg.actionCard!);
        return;
      }
    }
    if (prompt.contains('Đăng lên Bảng tin Cộng đồng') || prompt.contains('đăng bài')) {
      _handlePublishToCommunity();
      return;
    }
    ChatbotService.instance.sendMessage(
      prompt,
      context: _buildCurrentContext(),
    );
  }

  void _handlePublishToCommunity() {
    if (AuthStore.instance.isGuest) {
      AuthGuardSheet.show(context, actionName: 'đăng bài tuyển thành viên');
      return;
    }

    Map<String, dynamic>? recCard;
    for (final m in ChatbotService.instance.messagesNotifier.value.reversed) {
      if (m.actionCard != null && m.actionCard!['type'] == 'recruitment_card') {
        recCard = m.actionCard;
        break;
      }
    }

    final sport = recCard?['sportType']?.toString() ?? 'badminton';
    final venueName = recCard?['venueName']?.toString() ??
        widget.currentVenue?.name ??
        'CLB Cầu Lông Tao Đàn';
    final title = recCard?['title']?.toString() ?? 'Kèo Giao Lưu Cầu Lông - $venueName';
    final img = recCard?['imageUrl']?.toString();

    final post = CommunityPost(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      authorName: AuthStore.instance.currentUser?.fullName ?? 'Người dùng SportHub',
      sportType: sport,
      district: widget.currentVenue?.district ?? 'Quận 1',
      skillLevel: recCard?['skillLevel']?.toString() ?? 'Trung bình (2.0 - 3.5)',
      venueName: venueName,
      scheduledTime: recCard?['scheduledTime']?.toString() ?? '19:00 - 21:00 Hôm nay',
      requiredPlayers: 4,
      currentPlayers: 2,
      shareFee: 45000,
      note: 'Bài đăng được tạo qua Trợ lý AI SportHub. Hoan nghênh mọi người cùng tham gia!',
      imageUrl: img,
    );

    CommunityFeedStore.instance.addPost(post);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Đã đăng bài tuyển thành viên lên Bảng tin Cộng đồng thành công!'),
        backgroundColor: Colors.green,
      ),
    );

    ChatbotService.instance.addMessage(
      ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_published',
        text:
            '🎉 Em đã đăng bài tuyển thành viên **"$title"** lên Bảng tin Cộng đồng SportHub thành công! Bạn có thể vào tab **Cộng đồng** để theo dõi danh sách người đăng ký tham gia nhé. 🏸',
        sender: 'assistant',
        timestamp: DateTime.now(),
        quickSuggestions: const [
          '⚡ Đặt & Thanh toán VietQR ngay',
          '🔍 Xem trên sơ đồ',
        ],
      ),
    );
  }

  void _showImageAttachmentModal() {
    final sport = widget.currentVenue != null && widget.currentVenue!.sportTypes.isNotEmpty
        ? widget.currentVenue!.sportTypes.first
        : 'badminton';
    final presets = [
      ...SportImageCatalog.getPresetsForSport(sport),
      if (sport != 'badminton') ...SportImageCatalog.getPresetsForSport('badminton'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bCtx) {
        final urlController = TextEditingController();
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Gửi ảnh tuyển thành viên / ghép kèo',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Chọn ảnh hoạt động thể thao hoặc nhập URL ảnh để AI phân tích và tự động tạo bài tuyển thành viên.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ảnh mẫu thể thao SportHub:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: presets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, idx) {
                      final url = presets[idx];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _attachedImageUrl = url;
                          });
                          Navigator.of(bCtx).pop();
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 90,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.background,
                                child: const Icon(Icons.image, size: 20),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hoặc nhập liên kết ảnh:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('input_custom_chat_image_url'),
                        controller: urlController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'https://images.unsplash.com/...',
                          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const Key('btn_confirm_chat_image_url'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final val = urlController.text.trim();
                        if (val.isNotEmpty) {
                          setState(() {
                            _attachedImageUrl = val;
                          });
                        }
                        Navigator.of(bCtx).pop();
                      },
                      child: const Text('Đính kèm', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('🏸 Tuyển 2 người đánh đôi 19h', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setState(() {
                          _attachedImageUrl = presets.first;
                          _textController.text = 'Tuyển 2 thành viên đánh đôi cầu lông 19:00 tối nay';
                        });
                        Navigator.of(bCtx).pop();
                      },
                    ),
                    ActionChip(
                      label: const Text('🏓 Ghép kèo Pickleball 2.5 - 3.0', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setState(() {
                          _attachedImageUrl = presets.length > 1 ? presets[1] : presets.first;
                          _textController.text = 'Ghép kèo Pickleball giao lưu trình độ 2.5 - 3.0';
                        });
                        Navigator.of(bCtx).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleBookNow(Map<String, dynamic> actionCard) {
    if (widget.onBookNowAction != null) {
      widget.onBookNowAction!(actionCard);
      return;
    }

    if (AuthStore.instance.isGuest) {
      AuthGuardSheet.show(context, actionName: 'đặt sân');
      return;
    }

    final bookingId =
        'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final venueName = actionCard['venueName']?.toString() ??
        widget.currentVenue?.name ??
        'CLB Cầu Lông Tao Đàn';
    final venueId = actionCard['venueId']?.toString() ??
        widget.currentVenue?.id ??
        'venue_01';
    final rawSport = actionCard['sport']?.toString() ?? 'badminton';
    final courtStr = actionCard['court']?.toString() ?? 'Sân 1';
    final courtNumber =
        int.tryParse(RegExp(r'\d+').firstMatch(courtStr)?.group(0) ?? '1') ?? 1;
    final startTime = actionCard['startTime']?.toString() ??
        actionCard['time']?.toString() ??
        '19:00';
    final endTime = actionCard['endTime']?.toString() ?? '20:00';
    final date = actionCard['date']?.toString() ?? 'Hôm nay';
    final rawPrice = actionCard['price'];
    final totalPrice = (rawPrice is num) ? rawPrice.toDouble() : 180000.0;

    final user = AuthStore.instance.currentUser;
    final customerName = user?.fullName ?? 'Khách hàng';
    final customerPhone = user?.phone ?? '0901234567';

    final sport = rawSport.toLowerCase().contains('badminton') ||
            rawSport.toLowerCase().contains('cầu lông')
        ? 'badminton'
        : (rawSport.toLowerCase().contains('pickleball')
            ? 'pickleball'
            : 'football');

    final parsedAddons = extractAddonCountsFromCard(actionCard);
    final targetVenue = SeedData.sampleVenues.firstWhere(
      (v) =>
          v.id == venueId ||
          v.name.toLowerCase().contains(venueName.toLowerCase()),
      orElse: () => widget.currentVenue ?? SeedData.sampleVenues.first,
    );

    final baseCourtPrice = (actionCard['basePrice'] is num)
        ? (actionCard['basePrice'] as num).toDouble()
        : (totalPrice - ((actionCard['addonsTotal'] is num) ? (actionCard['addonsTotal'] as num).toDouble() : 0.0));

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final normalizedDate = (date.toLowerCase().contains('hôm nay') || date.trim().isEmpty)
        ? todayStr
        : date;

    double durationHours =
        (actionCard['durationHours'] as num?)?.toDouble() ?? 1.0;
    if (durationHours <= 0 && endTime.isNotEmpty) {
      final sParts = startTime.split(':');
      final eParts = endTime.split(':');
      if (sParts.length >= 2 && eParts.length >= 2) {
        final sH = int.tryParse(sParts[0]) ?? 19;
        final sM = int.tryParse(sParts[1]) ?? 0;
        final eH = int.tryParse(eParts[0]) ?? (sH + 1);
        final eM = int.tryParse(eParts[1]) ?? 0;
        final diff = ((eH * 60 + eM) - (sH * 60 + sM)) / 60.0;
        if (diff > 0) durationHours = diff;
      }
    }

    final totalHours = (durationHours > 0 ? durationHours : 1.0).ceil();
    final startParts = startTime.split(':');
    final startH = int.tryParse(startParts[0]) ?? 19;
    final startM =
        startParts.length > 1 ? (int.tryParse(startParts[1]) ?? 0) : 0;
    final singleSlotPrice =
        (baseCourtPrice > 0 ? baseCourtPrice : totalPrice) / totalHours;

    final selectedSlots = <TimeSlot>[];
    for (int i = 0; i < totalHours; i++) {
      final curH = startH + i;
      final curNextH = curH + 1;
      final curStart =
          '${curH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}';
      final curEnd = (i == totalHours - 1 && endTime.isNotEmpty)
          ? endTime
          : '${curNextH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}';
      selectedSlots.add(
        TimeSlot(
          id: 'slot_${courtNumber}_${curStart.replaceAll(':', '_')}',
          date: normalizedDate,
          courtNumber: courtNumber,
          startTime: curStart,
          endTime: curEnd,
          price: singleSlotPrice,
          status: SlotStatus.available,
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => VietQrPaymentDialog(
        venue: targetVenue,
        grandTotal: totalPrice,
        selectedSlots: selectedSlots,
        addonCounts: parsedAddons,
        onConfirmed: () {
          Navigator.of(ctx).pop();

          final now = DateTime.now();
          final todayStr =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          final normalizedDate = (date.toLowerCase().contains('hôm nay') || date.trim().isEmpty)
              ? todayStr
              : date;

          final ticket = TicketModel(
            id: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
            bookingId: bookingId,
            venueName: venueName,
            sportType: sport,
            courtNumber: courtNumber,
            matchDate: normalizedDate,
            startTime: startTime,
            endTime: endTime,
            totalPrice: totalPrice,
            qrCodeData: 'SPORTHUB|$bookingId|${totalPrice.toInt()}',
            status: 'paid',
            createdAt: DateTime.now().toIso8601String(),
            district: widget.currentVenue?.district ?? 'Quận 1',
          );

          TicketStore.instance.addTicket(ticket);

          VenueSyncService.instance.syncBooking(
            bookingId: bookingId,
            venueId: venueId,
            courtNumber: courtNumber,
            courtName: courtStr,
            venueName: venueName,
            sport: sport,
            date: normalizedDate,
            startTime: startTime,
            endTime: endTime,
            totalPrice: totalPrice,
            customerName: customerName,
            customerPhone: customerPhone,
            paymentMethod: 'vietqr',
          );

          NotificationStore.instance.addNotification(
            AppNotification(
              id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Thanh toán VietQR & Đặt sân thành công! 🏸',
              message:
                  'Vé đặt $courtStr tại $venueName ($startTime - $endTime) đã được thanh toán qua VietQR. Mã vé: $bookingId.',
              timestamp: DateTime.now(),
              type: NotificationType.booking,
              role: NotificationRole.player,
              isRead: false,
              targetId: bookingId,
            ),
          );

          ChatbotService.instance.notifyBookingPaid(ticket);
        },
      ),
    );
  }

  void _handleViewCourtMap(Map<String, dynamic> actionCard) {
    if (widget.onViewCourtMapAction != null) {
      widget.onViewCourtMapAction!(actionCard);
      return;
    }

    final courtStr = actionCard['court']?.toString() ?? 'Sân 1';
    final courtNumber =
        int.tryParse(RegExp(r'\d+').firstMatch(courtStr)?.group(0) ?? '1') ?? 1;
    final venueId =
        actionCard['venueId']?.toString() ?? widget.currentVenue?.id ?? 'venue_01';
    final venueName = actionCard['venueName']?.toString() ??
        widget.currentVenue?.name ??
        'CLB Cầu Lông Tao Đàn';
    final startTime = actionCard['startTime']?.toString() ??
        actionCard['time']?.toString() ??
        '19:00';
    final endTime = actionCard['endTime']?.toString() ?? '20:00';
    final rawSport = actionCard['sport']?.toString() ?? 'badminton';
    final sport = rawSport.toLowerCase().contains('pickleball')
        ? 'pickleball'
        : (rawSport.toLowerCase().contains('football') ||
                rawSport.toLowerCase().contains('bóng đá')
            ? 'football'
            : 'badminton');

    final parsedAddons = extractAddonCountsFromCard(actionCard);

    Navigator.of(context).pop();

    final targetVenue = SeedData.sampleVenues.firstWhere(
      (v) =>
          v.id == venueId ||
          v.name.toLowerCase().contains(venueName.toLowerCase()),
      orElse: () => widget.currentVenue ?? SeedData.sampleVenues.first,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => VenueDetailScreen(
          venue: targetVenue,
          targetCourtNumber: courtNumber,
          targetStartTime: startTime,
          targetEndTime: endTime,
          targetSport: sport,
          initialViewMode: 'court_map',
          initialAddonCounts: parsedAddons,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isOwner = VenueOwnerStore.instance.isOwnerMode;
    final venueName = isOwner
        ? VenueOwnerStore.instance.activeVenueName
        : (widget.currentVenue?.name ?? 'SportHub');
    final isGuest = AuthStore.instance.isGuest;
    final authUser = AuthStore.instance.currentUser;
    final preferredSport = authUser?.preferredSport;
    final userName = isOwner
        ? 'Chủ sân: ${authUser?.fullName ?? 'Quản lý sân'}'
        : (isGuest
            ? 'Khách vãng lai'
            : 'Khách hàng: ${authUser?.fullName ?? 'Người dùng'}');

    final userSport = preferredSport?.toLowerCase();
    final sportChipLabel = userSport == 'pickleball'
        ? 'pickleball'
        : (userSport == 'football' || userSport == 'bóng đá' ? 'bóng đá' : 'cầu lông');

    final defaultChips = isOwner
        ? const [
            'Tình trạng sân hôm nay',
            'Doanh thu hôm nay',
            'Số vé chờ check-in',
            'Chính sách hoàn hủy',
          ]
        : (widget.currentVenue != null
            ? const [
                'Sân trống tối nay?',
                'Quy định giày',
                'Đặt sân 19:00',
                'Chính sách hủy',
              ]
            : [
                'Tìm sân gần tôi',
                'Đặt sân $sportChipLabel 19h',
                'Bảng giá sân',
              ]);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.smart_toy,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trợ lý AI SportHub',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ValueListenableBuilder<bool>(
                            valueListenable: ChatbotService.instance.isTypingNotifier,
                            builder: (context, isTyping, _) {
                              return Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: isTyping ? AppColors.primary : AppColors.slotAvailable,
                                      shape: BoxShape.circle,
                                      boxShadow: isTyping
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary.withValues(alpha: 0.6),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isTyping ? 'Đang soạn câu trả lời...' : 'Đang hoạt động',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isTyping ? AppColors.primary : AppColors.textSecondary,
                                      fontWeight: isTyping ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('btn_chatbot_clear_session'),
                      icon: const Icon(Icons.refresh_rounded),
                      color: AppColors.textSecondary,
                      tooltip: 'Xóa hội thoại / Phiên mới',
                      onPressed: () {
                        setState(() {
                          ChatMessageBubble.resetRevealedCache();
                          ChatbotService.instance.resetMessages();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã làm mới phiên hội thoại Chatbot'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Context Awareness Banner
              Container(
                key: const Key('chatbot_context_banner'),
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                color: AppColors.primary.withValues(alpha: 0.08),
                child: Text(
                  '📍 Đang ở: $venueName • 👤 $userName',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const Divider(height: 1),

              // Messages List
              Expanded(
                child: ValueListenableBuilder<List<ChatMessage>>(
                  valueListenable: ChatbotService.instance.messagesNotifier,
                  builder: (context, messages, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: ChatbotService.instance.isTypingNotifier,
                      builder: (context, isTyping, _) {
                        final totalItems = messages.length + (isTyping ? 1 : 0);
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: totalItems,
                          itemBuilder: (context, index) {
                            if (index < messages.length) {
                              final msg = messages[index];
                              return ChatMessageBubble(
                                message: msg,
                                onBookNow: msg.hasActionCard
                                    ? () => _handleBookNow(msg.actionCard!)
                                    : null,
                                onViewCourtMap:
                                    msg.hasActionCard ? _handleViewCourtMap : null,
                              );
                            }
                            return const ChatTypingIndicator(
                              key: Key('chatbot_typing_indicator'),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // Dynamic 1-Tap Quick Action Chips (Above Input Field)
              ValueListenableBuilder<List<ChatMessage>>(
                valueListenable: ChatbotService.instance.messagesNotifier,
                builder: (context, msgs, _) {
                  final latestAsst =
                      msgs.reversed.cast<ChatMessage?>().firstWhere(
                            (m) => m != null && m.isAssistant,
                            orElse: () => msgs.isNotEmpty ? msgs.last : null,
                          );
                  final latest =
                      latestAsst ?? (msgs.isNotEmpty ? msgs.last : null);
                  final hasDynamic = latest != null &&
                      latest.quickSuggestions != null &&
                      latest.quickSuggestions!.isNotEmpty;

                  final chips =
                      hasDynamic ? latest.quickSuggestions! : defaultChips;
                  if (chips.isEmpty) return const SizedBox.shrink();

                  return Container(
                    height: 44,
                    color: AppColors.surface,
                    child: ListView.separated(
                      key: const Key('chat_quick_suggestions_list'),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      itemCount: chips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final chipText = chips[index];
                        return InkWell(
                          onTap: () => _onChipTap(chipText),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: hasDynamic
                                    ? AppColors.primary
                                    : AppColors.cardBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  chipText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // Image preview banner if attached
              if (_attachedImageUrl != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _attachedImageUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 40,
                            height: 40,
                            color: AppColors.background,
                            child: const Icon(Icons.image, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '📷 Đã đính kèm ảnh tuyển thành viên',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'AI sẽ hỗ trợ tạo bài đăng ghép kèo',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _attachedImageUrl = null),
                        tooltip: 'Gỡ ảnh',
                      ),
                    ],
                  ),
                ),

              const Divider(height: 1),

              // Bottom Input Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                color: AppColors.surface,
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('btn_chat_attach_image'),
                      icon: Icon(
                        _attachedImageUrl != null
                            ? Icons.image_rounded
                            : Icons.add_photo_alternate_outlined,
                        color: _attachedImageUrl != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 24,
                      ),
                      onPressed: _showImageAttachmentModal,
                      tooltip: 'Đính kèm ảnh tuyển thành viên',
                    ),
                    Expanded(
                      child: TextField(
                        key: const Key('chat_input_field'),
                        controller: _textController,
                        onSubmitted: (_) => _sendTextMessage(),
                        decoration: InputDecoration(
                          hintText: _attachedImageUrl != null
                              ? 'Nhập yêu cầu tuyển thành viên hoặc gửi...'
                              : 'Hỏi trợ lý AI, đặt sân, tuyển thành viên...',
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.cardBorder.withValues(
                            alpha: AppColors.isDark ? 0.3 : 0.15,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        key: const Key('btn_chat_send'),
                        icon: Icon(
                          Icons.send_rounded,
                          color: AppColors.onPrimary,
                          size: 19,
                        ),
                        onPressed: _sendTextMessage,
                        tooltip: 'Gửi tin nhắn',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
