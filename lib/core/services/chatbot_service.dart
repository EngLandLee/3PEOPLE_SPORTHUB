import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../../data/models/ticket_model.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/entities/venue.dart';
import '../state/ticket_store.dart';
import '../utils/court_sport_partition.dart';
import '../utils/currency_formatter.dart';
import '../utils/seed_data.dart';
import '../utils/shift_slot_generator.dart';
import 'venue_sync_service.dart';

/// Core service managing chatbot interactions, dual-mode intent engine
/// (Server LLM Proxy / Local Smart Intent Processor), and context collection.
class ChatbotService {
  ChatbotService._internal() {
    TicketStore.onTicketAdded = notifyBookingPaid;
  }

  static final ChatbotService instance = ChatbotService._internal();

  /// Cleans up any markdown pseudo-UI tags from assistant reply
  static String cleanReply(String raw) {
    return raw
        .replaceAll(
          RegExp(
            r'\[\s*(?:⚡|⚽|🏸|🏀|🏓|📍|Thẻ\s*đặt\s*sân|Thẻ\s*dịch\s*vụ|Thẻ|Nút|Button|Card)[^\]]*\]',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\|[^\n]+\|\n\|[\s:-|]+\|\n(?:\|[^\n]+\|\n?)+',
            multiLine: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'^\s*-{3,}\s*$', multiLine: true), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// Helper to parse time strings like '19h', '7h tối', '19:30', '8h30 sáng'
  static ({String timeStr, String startTime, String endTime}) parseTime(
    String text, {
    String defaultTime = '19:00',
  }) {
    final lower = text.toLowerCase();
    int h = 19;
    int m = 0;
    bool matched = false;

    // Pattern 1: 19h30, 7h, 7h30 tối, 8h tối, 6h chiều, 7h sáng
    final hMatch = RegExp(
      r'(\d{1,2})(?:h|:|\s*giờ\s*)(\d{2})?\s*(sáng|trưa|chiều|tối)?',
      caseSensitive: false,
    ).firstMatch(text);
    if (hMatch != null) {
      h = int.tryParse(hMatch.group(1)!) ?? 19;
      m = int.tryParse(hMatch.group(2) ?? '00') ?? 0;
      final period = hMatch.group(3)?.toLowerCase();
      if ((period == 'tối' || period == 'chiều' || lower.contains('tối') || lower.contains('chiều')) && h < 12) {
        h += 12;
      } else if (period == 'sáng' && h == 12) {
        h = 0;
      }
      matched = true;
    } else {
      // Pattern 2: 19:30 or 07:30
      final colonMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
      if (colonMatch != null) {
        h = int.tryParse(colonMatch.group(1)!) ?? 19;
        m = int.tryParse(colonMatch.group(2)!) ?? 0;
        if ((lower.contains('tối') || lower.contains('chiều')) && h < 12) {
          h += 12;
        }
        matched = true;
      }
    }

    if (!matched) {
      final parts = defaultTime.split(':');
      h = int.tryParse(parts[0]) ?? 19;
      m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    }

    final startHStr = h.toString().padLeft(2, '0');
    final minStr = m.toString().padLeft(2, '0');
    final endH = (h + 1) % 24;
    final endHStr = endH.toString().padLeft(2, '0');

    return (
      timeStr: '$startHStr:$minStr',
      startTime: '$startHStr:$minStr',
      endTime: '$endHStr:$minStr',
    );
  }

  /// Helper to parse date strings like 'ngày mai', 'tối mai', 'hôm nay', 'ngày 30/09'
  static ({String dateStr, String displayDate}) parseDate(String text) {
    final lower = text.toLowerCase();
    final now = DateTime.now();

    if (lower.contains('ngày mai') ||
        lower.contains('tối mai') ||
        lower.contains('sáng mai') ||
        lower.contains('chiều mai') ||
        lower.contains('mai')) {
      final tmr = now.add(const Duration(days: 1));
      final dateStr =
          '${tmr.year}-${tmr.month.toString().padLeft(2, '0')}-${tmr.day.toString().padLeft(2, '0')}';
      return (
        dateStr: dateStr,
        displayDate: 'Ngày mai (${tmr.day.toString().padLeft(2, '0')}/${tmr.month.toString().padLeft(2, '0')})',
      );
    }

    if (lower.contains('mốt') || lower.contains('ngày kia')) {
      final after = now.add(const Duration(days: 2));
      final dateStr =
          '${after.year}-${after.month.toString().padLeft(2, '0')}-${after.day.toString().padLeft(2, '0')}';
      return (
        dateStr: dateStr,
        displayDate: '${after.day.toString().padLeft(2, '0')}/${after.month.toString().padLeft(2, '0')}',
      );
    }

    final dateMatch = RegExp(r'ngày\s*(\d{1,2})[/-](\d{1,2})(?:[/-](\d{4}))?').firstMatch(text);
    if (dateMatch != null) {
      final d = int.tryParse(dateMatch.group(1)!) ?? now.day;
      final m = int.tryParse(dateMatch.group(2)!) ?? now.month;
      final y = dateMatch.group(3) != null
          ? (int.tryParse(dateMatch.group(3)!) ?? now.year)
          : now.year;
      final dateStr = '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      return (
        dateStr: dateStr,
        displayDate: 'Ngày ${d.toString().padLeft(2, '0')}/${m.toString().padLeft(2, '0')}',
      );
    }

    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return (dateStr: todayStr, displayDate: 'Hôm nay');
  }

  /// Helper to find the best available court and actual price for a venue, sport, date, and time.
  /// Returns [isAvailable] = false and [courtNumber] = null if all matching courts are booked or maintenance.
  static ({int? courtNumber, int price, String courtName, bool isAvailable}) findAvailableCourtAndPrice({
    required String venueId,
    required String venueName,
    required String sport,
    required String date,
    required String startTime,
  }) {
    // 1. Resolve Venue object from SeedData
    Venue? venue;
    for (final v in SeedData.sampleVenues) {
      if (v.id == venueId ||
          (venueId == 'venue_01' && v.id == 'venue_q1_04') ||
          (venueId == 'venue_q1_04' && v.id == 'venue_01') ||
          v.name.toLowerCase().contains(venueName.toLowerCase()) ||
          venueName.toLowerCase().contains(v.name.toLowerCase())) {
        venue = v;
        break;
      }
    }
    venue ??= SeedData.sampleVenues[3]; // Default to Tao Đàn

    // 2. Format normalized date 'yyyy-MM-dd'
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    String dateStr;
    final lowerDate = date.toLowerCase();
    if (lowerDate.contains('mai')) {
      final tmr = now.add(const Duration(days: 1));
      dateStr =
          '${tmr.year}-${tmr.month.toString().padLeft(2, '0')}-${tmr.day.toString().padLeft(2, '0')}';
    } else if (lowerDate.contains('mốt') || lowerDate.contains('kia')) {
      final after = now.add(const Duration(days: 2));
      dateStr =
          '${after.year}-${after.month.toString().padLeft(2, '0')}-${after.day.toString().padLeft(2, '0')}';
    } else if (date.isEmpty || lowerDate.contains('hôm nay') || lowerDate.contains('tối nay')) {
      dateStr = todayStr;
    } else if (date.contains('-')) {
      dateStr = date;
    } else {
      dateStr = todayStr;
    }

    // 3. Shift & minute offset
    final hour = int.tryParse(startTime.split(':').first) ?? 19;
    final shift = hour < 12 ? 'morning' : (hour < 17 ? 'afternoon' : 'evening');
    final minuteOffset = startTime.endsWith(':30') ? ':30' : ':00';

    // 4. Generate slots from ShiftSlotGenerator
    final slots = ShiftSlotGenerator.generateSlots(
      date: dateStr,
      courtCount: venue.courtCount,
      shift: shift,
      minuteOffset: minuteOffset,
      venue: venue,
    );

    // 5. Calculate real slot price based on sport & venue base rate
    final sportKey = sport.toLowerCase().contains('pickleball')
        ? 'pickleball'
        : (sport.toLowerCase().contains('bóng đá') ||
                sport.toLowerCase().contains('football')
            ? 'football'
            : 'badminton');

    final calculatedPrice = ShiftSlotGenerator.calculateSlotPrice(
      sportType: sportKey,
      startTime: startTime,
      venueBaseRate: venue.hourlyRate,
    ).toInt();

    // 6. Find first court that is active & matching sport & not booked
    int bestCourt = 1;
    bool found = false;

    for (int c = 1; c <= venue.courtCount; c++) {
      // Check sport partition if venue has multiple sports
      if (venue.sportTypes.length > 1) {
        final courtSport = CourtSportPartition.getSportForCourt(
          venue: venue,
          courtNumber: c,
        );
        if (courtSport != sportKey) {
          continue;
        }
      }

      // Check if court is active (maintenance)
      final isCourtActive = VenueSyncService.instance.isCourtActive(
        venueId: venue.id,
        courtNumber: c,
        venueName: venue.name,
      );
      if (!isCourtActive) continue;

      // Check slot generated status (ShiftSlotGenerator)
      final matching = slots.where((s) => s.courtNumber == c && s.startTime == startTime);
      if (matching.isNotEmpty &&
          (matching.first.status == SlotStatus.booked ||
              matching.first.status == SlotStatus.locked)) {
        continue;
      }

      // Check runtime bookings
      final isBooked = VenueSyncService.instance.isSlotBooked(
        venueId: venue.id,
        courtNumber: c,
        date: dateStr,
        startTime: startTime,
        venueName: venue.name,
      );
      if (isBooked) continue;

      bestCourt = c;
      found = true;
      break;
    }

    if (!found) {
      return (
        courtNumber: null,
        price: calculatedPrice > 0 ? calculatedPrice : 180000,
        courtName: '',
        isAvailable: false,
      );
    }

    return (
      courtNumber: bestCourt,
      price: calculatedPrice > 0 ? calculatedPrice : 180000,
      courtName: 'Sân $bestCourt',
      isAvailable: true,
    );
  }

  /// Validates and synchronizes actionCard from server with client slot availability.
  /// If the court is actually booked or on maintenance, it auto-switches to the first available court
  /// or removes the action card if completely unavailable.
  static (Map<String, dynamic>?, String?) sanitizeServerActionCard(
    Map<String, dynamic>? rawCard, {
    String? originalReply,
  }) {
    if (rawCard == null) return (null, originalReply);
    if (rawCard['type'] != 'booking_card') return (rawCard, originalReply);

    // If it's a payment check card (already has isPaid), preserve it
    if (rawCard['isPaid'] == true) {
      return (rawCard, originalReply);
    }

    final venueId = rawCard['venueId']?.toString() ?? 'venue_01';
    final venueName = rawCard['venueName']?.toString() ?? 'CLB Cầu Lông Tao Đàn';
    final sport = rawCard['sport']?.toString() ?? 'Cầu lông';
    final date = rawCard['date']?.toString() ?? 'Hôm nay';
    final startTime = rawCard['startTime']?.toString() ?? '19:00';

    final courtInfo = findAvailableCourtAndPrice(
      venueId: venueId,
      venueName: venueName,
      sport: sport,
      date: date,
      startTime: startTime,
    );

    if (!courtInfo.isAvailable) {
      final fallbackReply =
          'Rất tiếc, các sân môn $sport tại $venueName vào khung giờ $startTime ($date) đều đã được đặt kín hoặc đang bảo trì rồi ạ.\n\nAnh/chị có thể tham khảo các khung giờ khác hoặc chuyển sang cụm sân lân cận nhé!';
      return (null, fallbackReply);
    }

    final sanitized = Map<String, dynamic>.from(rawCard);
    final prevCourt = sanitized['court']?.toString();
    final prevPrice = (sanitized['price'] as num?)?.toInt();
    sanitized['court'] = courtInfo.courtName;

    // Check if add-ons exist
    final addonsTotal = (sanitized['addonsTotal'] as num?)?.toInt() ?? 0;
    sanitized['basePrice'] = courtInfo.price;
    sanitized['price'] = courtInfo.price + addonsTotal;

    var sanitizedReply = originalReply;
    if (sanitizedReply != null) {
      if (prevCourt != null && prevCourt != courtInfo.courtName) {
        sanitizedReply = sanitizedReply.replaceAll(prevCourt, courtInfo.courtName);
      }
      if (prevPrice != null && prevPrice != sanitized['price']) {
        final oldP = prevPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
        final newP = (sanitized['price'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
        sanitizedReply = sanitizedReply
            .replaceAll('$oldP đ', '$newP đ')
            .replaceAll('$oldPđ', '$newPđ')
            .replaceAll(oldP, newP);
      }
    }

    return (sanitized, sanitizedReply);
  }

  ValueNotifier<List<ChatMessage>>? _messagesNotifier;
  /// Reactive notifier holding the list of conversation messages
  ValueNotifier<List<ChatMessage>> get messagesNotifier =>
      _messagesNotifier ??= ValueNotifier<List<ChatMessage>>([]);

  ValueNotifier<bool>? _isTypingNotifier;
  /// Reactive notifier indicating whether the assistant is currently processing or generating a response
  ValueNotifier<bool> get isTypingNotifier =>
      _isTypingNotifier ??= ValueNotifier<bool>(false);

  bool get isTyping => isTypingNotifier.value;

  /// Holds current pending booking card in conversation
  Map<String, dynamic>? pendingBooking;

  /// Gets the most recent booking card from conversation history or pendingBooking
  Map<String, dynamic>? get latestBookingCard {
    if (pendingBooking != null) return pendingBooking;
    for (final msg in messagesNotifier.value.reversed) {
      if (msg.hasActionCard && msg.actionCard!['type'] == 'booking_card') {
        return msg.actionCard;
      }
    }
    return null;
  }

  /// Current user, screen, and venue context
  ChatContext? currentContext;

  /// Web Admin / API server endpoint
  String serverBaseUrl = 'http://localhost:5173';

  /// Injected HTTP client for network operations & unit testing
  http.Client? httpClient;

  /// Detects whether code is executing inside a Flutter test runner
  bool get isTestEnvironment {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return true;
      }
      final binding = WidgetsBinding.instance;
      return binding.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  /// Candidate server URLs for reaching the backend
  List<String> get candidateServerUrls {
    final urls = <String>[];
    try {
      if (Uri.base.scheme == 'http' || Uri.base.scheme == 'https') {
        final host = Uri.base.host;
        if (host.isNotEmpty) {
          urls.add('${Uri.base.scheme}://$host:5173');
        }
      }
    } catch (_) {}
    if (!urls.contains(serverBaseUrl)) urls.add(serverBaseUrl);
    if (!urls.contains('http://127.0.0.1:5173')) urls.add('http://127.0.0.1:5173');
    if (!urls.contains('http://localhost:5173')) urls.add('http://localhost:5173');
    if (!urls.contains('http://0.0.0.0:5173')) urls.add('http://0.0.0.0:5173');
    return urls;
  }

  /// Updates active chat context
  void updateContext(ChatContext context) {
    currentContext = context;
  }

  final Set<String> _notifiedBookingIds = {};

  /// Clears message history
  void resetMessages() {
    messagesNotifier.value = [];
    isTypingNotifier.value = false;
    _notifiedBookingIds.clear();
    pendingBooking = null;
  }

  /// Adds a message to the conversation
  void addMessage(ChatMessage message) {
    messagesNotifier.value = [...messagesNotifier.value, message];
  }

  /// Notifies chatbot of a successful booking/payment, updating any matching
  /// pending booking cards in the conversation and proactively responding to the user.
  void notifyBookingPaid(TicketModel ticket) {
    if (_notifiedBookingIds.contains(ticket.bookingId)) {
      return;
    }
    _notifiedBookingIds.add(ticket.bookingId);

    // 1. Update existing booking cards in the conversation to isPaid = true
    final currentMessages = List<ChatMessage>.from(messagesNotifier.value);
    bool updatedExisting = false;

    final updatedMessages = currentMessages.map((msg) {
      if (msg.hasActionCard && msg.actionCard!['type'] == 'booking_card') {
        final card = msg.actionCard!;
        final cardVenue = card['venueName']?.toString().toLowerCase() ?? '';
        final ticketVenue = ticket.venueName.toLowerCase();
        final matchesVenue = cardVenue.contains(ticketVenue) || ticketVenue.contains(cardVenue);

        final isAlreadyPaid = card['isPaid'] == true;
        if (!isAlreadyPaid && (matchesVenue || !updatedExisting)) {
          updatedExisting = true;
          return msg.copyWith(
            actionCard: {
              ...card,
              'isPaid': true,
              'isBooked': true,
              'bookingId': ticket.bookingId,
              'ticketId': ticket.id,
              'court': 'Sân ${ticket.courtNumber}',
            },
          );
        }
      }
      return msg;
    }).toList();

    messagesNotifier.value = updatedMessages;

    // 2. Add an assistant confirmation message to celebrate and respond back
    final courtLabel = ticket.courtNumber > 0 ? 'Sân ${ticket.courtNumber}' : 'Sân tiêu chuẩn';
    final formattedPrice = CurrencyFormatter.format(ticket.totalPrice);

    final confirmedMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_booking_paid',
      text: '🎉 **Xác nhận thanh toán thành công!**\n\n'
          'Dạ em đã nhận được thông tin thanh toán cho đơn đặt sân của mình:\n'
          '• **Mã vé:** `${ticket.bookingId}`\n'
          '• **Sân đặt:** ${ticket.venueName} ($courtLabel)\n'
          '• **Khung giờ:** ${ticket.startTime} - ${ticket.endTime} (${ticket.matchDate})\n'
          '• **Đã thanh toán:** $formattedPrice (VietQR)\n\n'
          '👉 Khung giờ đã được giữ chỗ riêng cho bạn trên hệ thống. Khi đến sân, bạn chỉ cần mở mục **Vé của tôi** và xuất trình mã QR để nhận sân nhé! Chúc bạn có một trận đấu thật bùng nổ! 🏸⚽🏓',
      sender: 'assistant',
      timestamp: DateTime.now(),
      actionCard: {
        'type': 'booking_card',
        'venueId': ticket.venueName,
        'venueName': ticket.venueName,
        'sport': ticket.sportType,
        'court': courtLabel,
        'date': ticket.matchDate,
        'time': '${ticket.startTime} - ${ticket.endTime}',
        'startTime': ticket.startTime,
        'endTime': ticket.endTime,
        'price': ticket.totalPrice,
        'isPaid': true,
        'isBooked': true,
        'bookingId': ticket.bookingId,
        'ticketId': ticket.id,
      },
      quickSuggestions: const [
        '🎫 Xem vé của tôi',
        '🔍 Xem trên sơ đồ',
        '📢 Đăng lên Bảng tin Cộng đồng',
      ],
    );

    addMessage(confirmedMessage);

    // Asynchronously sync conversation to server
    unawaited(_syncBookingPaidSession(ticket, confirmedMessage));
  }

  /// Syncs payment confirmation event to server
  Future<void> _syncBookingPaidSession(
    TicketModel ticket,
    ChatMessage confirmedMessage,
  ) async {
    if (isTestEnvironment && httpClient == null) return;
    try {
      final client = httpClient ?? http.Client();
      final shouldClose = httpClient == null;

      final convPayload = {
        'id': 'conv_${DateTime.now().millisecondsSinceEpoch}_paid',
        'userId': currentContext?.userId,
        'userName': currentContext?.userName,
        'currentScreen': currentContext?.currentRoute,
        'venueId': currentContext?.venueId,
        'messages': [
          confirmedMessage.toJson(),
        ],
        'bookingCreated': true,
        'paymentConfirmed': true,
        'ticketId': ticket.bookingId,
        'createdAt': DateTime.now().toIso8601String(),
      };

      for (final baseUrl in candidateServerUrls) {
        try {
          final uri = Uri.parse('$baseUrl/api/chatbot/conversations');
          await client
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(convPayload),
              )
              .timeout(const Duration(milliseconds: 1000));
          break;
        } catch (_) {}
      }

      if (shouldClose) {
        try {
          client.close();
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Sends a message, evaluates via Server LLM proxy or Local Intent Engine,
  /// updates messagesNotifier, logs session asynchronously, and returns assistant message.
  Future<ChatMessage> sendMessage(
    String text, {
    ChatContext? context,
    http.Client? httpClient,
    String? imageUrl,
  }) async {
    final cleanInput = text.trim();
    if (cleanInput.isEmpty && (imageUrl == null || imageUrl.trim().isEmpty)) {
      throw ArgumentError('Message text or imageUrl cannot be empty');
    }

    if (context != null) {
      currentContext = context;
    }

    final userMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_user',
      text: text,
      sender: 'user',
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
    );
    addMessage(userMessage);

    ChatMessage? assistantMessage;
    isTypingNotifier.value = true;

    try {
      // Natural thinking effect in live client
      if (!isTestEnvironment && httpClient == null && this.httpClient == null) {
        await Future.delayed(const Duration(milliseconds: 350));
      }

      // Try server inference if httpClient is injected or not in offline test
      final effectiveContext = context ?? currentContext;
      final effectiveHttpClient = httpClient ?? this.httpClient;
      final shouldAttemptNetwork = effectiveHttpClient != null || !isTestEnvironment;

    if (shouldAttemptNetwork) {
      try {
        final client = effectiveHttpClient ?? http.Client();
        final shouldClose = effectiveHttpClient == null;

        final payload = jsonEncode({
          'message': text,
          'context': effectiveContext?.toJson() ?? {},
          if (imageUrl != null) 'imageUrl': imageUrl,
        });

        if (effectiveHttpClient != null) {
          final uri = Uri.parse('$serverBaseUrl/api/chatbot/message');
          final response = await client
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: payload,
              )
              .timeout(const Duration(milliseconds: 1500));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is Map<String, dynamic> &&
                data['reply'] != null &&
                data['reply'].toString().trim().isNotEmpty) {
              final rawSuggestions = data['quickSuggestions'];
              final quickSuggestions = rawSuggestions is List
                  ? rawSuggestions.map((e) => e.toString()).toList()
                  : null;

              final rawCard = data['actionCard'] is Map<String, dynamic>
                  ? Map<String, dynamic>.from(data['actionCard'] as Map)
                  : null;
              final (sanitizedCard, sanitizedReply) = sanitizeServerActionCard(
                rawCard,
                originalReply: cleanReply(data['reply'].toString()),
              );

              if (sanitizedCard != null && sanitizedCard['type'] == 'booking_card') {
                pendingBooking = sanitizedCard;
              } else if (rawCard != null && rawCard['type'] == 'booking_card' && sanitizedCard == null) {
                pendingBooking = null;
              }

              assistantMessage = ChatMessage(
                id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
                text: sanitizedReply ?? cleanReply(data['reply'].toString()),
                sender: 'assistant',
                timestamp: DateTime.now(),
                actionCard: sanitizedCard,
                quickSuggestions: quickSuggestions,
              );
            }
          }
        } else {
          for (final baseUrl in candidateServerUrls) {
            try {
              final uri = Uri.parse('$baseUrl/api/chatbot/message');
              final response = await client
                  .post(
                    uri,
                    headers: {'Content-Type': 'application/json'},
                    body: payload,
                  )
                  .timeout(const Duration(milliseconds: 3500));

              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                if (data is Map<String, dynamic> &&
                    data['reply'] != null &&
                    data['reply'].toString().trim().isNotEmpty) {
                  final rawSuggestions = data['quickSuggestions'];
                  final quickSuggestions = rawSuggestions is List
                      ? rawSuggestions.map((e) => e.toString()).toList()
                      : null;

                  serverBaseUrl = baseUrl;
                  final rawCard = data['actionCard'] is Map<String, dynamic>
                      ? Map<String, dynamic>.from(data['actionCard'] as Map)
                      : null;
                  final (sanitizedCard, sanitizedReply) = sanitizeServerActionCard(
                    rawCard,
                    originalReply: cleanReply(data['reply'].toString()),
                  );

                  if (sanitizedCard != null && sanitizedCard['type'] == 'booking_card') {
                    pendingBooking = sanitizedCard;
                  } else if (rawCard != null && rawCard['type'] == 'booking_card' && sanitizedCard == null) {
                    pendingBooking = null;
                  }

                  assistantMessage = ChatMessage(
                    id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
                    text: sanitizedReply ?? cleanReply(data['reply'].toString()),
                    sender: 'assistant',
                    timestamp: DateTime.now(),
                    actionCard: sanitizedCard,
                    quickSuggestions: quickSuggestions,
                  );
                  break;
                }
              }
            } catch (_) {}
          }
        }

        if (shouldClose) {
          try {
            client.close();
          } catch (_) {}
        }
      } catch (_) {
        // Fallback to local engine on error or timeout
      }
    }

        // Fallback to smart local intent engine if server didn't reply
        assistantMessage ??= _processLocalIntent(text, effectiveContext, imageUrl: imageUrl);

        addMessage(assistantMessage);

        // Asynchronously sync conversation to server
        unawaited(_syncConversationSession(userMessage, assistantMessage));

        return assistantMessage;
      } finally {
        isTypingNotifier.value = false;
      }
    }

  /// Processes intent locally with regex matching and smart entity extraction
  ChatMessage _processLocalIntent(String text, ChatContext? context, {String? imageUrl}) {
    final lower = text.toLowerCase();

    // 0. Check date/time query first to prevent false matching on "bao nhiêu" in priceRegex
    final isDateTimeQuery = RegExp(
      r'(hôm nay|bây giờ|hiện tại).*(ngày mấy|ngày bao nhiêu|thứ mấy|mấy giờ|thời gian)|'
      r'(ngày mấy|ngày bao nhiêu|thứ mấy|mấy giờ).*(hôm nay|bây giờ|hiện tại)|'
      r'^hôm nay ngày bao nhiêu|^bây giờ là mấy giờ|^mấy giờ rồi|^hôm nay thứ mấy',
      caseSensitive: false,
    ).hasMatch(text);

    if (isDateTimeQuery) {
      final now = DateTime.now();
      final dayNames = [
        'Thứ Hai',
        'Thứ Ba',
        'Thứ Tư',
        'Thứ Năm',
        'Thứ Sáu',
        'Thứ Bảy',
        'Chủ Nhật'
      ];
      final dayName = dayNames[now.weekday - 1];
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final userName = context?.userName?.trim();
      final prefix = (userName != null && userName.isNotEmpty)
          ? 'Chào anh/chị $userName! '
          : 'Dạ chào bạn! ';

      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
        text: '${prefix}Hôm nay là **$dayName, ngày $dateStr** (hiện tại là $timeStr) ạ.\n\n'
            'Em có thể hỗ trợ mình tìm sân thể thao hoặc kiểm tra lịch thi đấu hôm nay không ạ?',
        sender: 'assistant',
        timestamp: DateTime.now(),
        quickSuggestions: const [
          '🏸 Cầu lông Q.1 (19h)',
          '🏓 Pickleball Thảo Điền',
          '⚽ Bóng đá mini Q.7',
          'Tình trạng sân hôm nay',
        ],
      );
    }

    // 1. Follow-up / Booking modification intent ("đổi sang 20h", "chuyển sang 20h", "lùi lại 20h", "20h thì sao")
    final hasPendingOrRecent = pendingBooking != null || latestBookingCard != null;
    final changeTimeMatch = RegExp(
      r'(?:đổi|chuyển|dời|lùi|thay\s*đổi|lấy|chọn)\s*(?:sang|qua|lịch\s*sang|thành|giờ\s*sang)?\s*(\d{1,2})(?:h|:|\s*giờ)(\d{2})?\s*(tối|sáng|chiều)?|'
      r'^(\d{1,2})(?:h|:|\s*giờ)(\d{2})?\s*(?:thì\s*sao|được\s*không|nhé|nha)|'
      r'(?:đổi|chuyển)\s*(?:sang|qua|lịch\s*sang)?\s*(ngày\s*mai|mai|hôm\s*nay|tối\s*mai)',
      caseSensitive: false,
    ).firstMatch(text);

    if (hasPendingOrRecent && changeTimeMatch != null) {
      final existing = latestBookingCard ?? pendingBooking!;
      final venueId = existing['venueId']?.toString() ?? 'venue_01';
      final venueName = existing['venueName']?.toString() ?? 'CLB Cầu Lông Tao Đàn';
      final sport = existing['sport']?.toString() ?? 'Cầu lông';

      final parsedTime = parseTime(text, defaultTime: existing['startTime']?.toString() ?? '19:00');
      final parsedDate = parseDate(text);
      final dateUsed = (text.contains('mai') || text.contains('ngày'))
          ? parsedDate.displayDate
          : (existing['date']?.toString() ?? 'Hôm nay');

      final courtInfo = findAvailableCourtAndPrice(
        venueId: venueId,
        venueName: venueName,
        sport: sport,
        date: dateUsed,
        startTime: parsedTime.startTime,
      );

      if (courtInfo.isAvailable) {
        final existingAddonsTotal = (existing['addonsTotal'] as num?)?.toInt() ?? 0;
        final newTotalPrice = courtInfo.price + existingAddonsTotal;

        final updatedCard = {
          ...existing,
          'time': parsedTime.timeStr,
          'startTime': parsedTime.startTime,
          'endTime': parsedTime.endTime,
          'court': courtInfo.courtName,
          'price': newTotalPrice,
          'basePrice': courtInfo.price,
          'date': dateUsed,
        };
        pendingBooking = updatedCard;

        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: 'Dạ, em đã đổi khung giờ sang **${parsedTime.startTime} - ${parsedTime.endTime}** ($dateUsed) cho anh/chị tại **$venueName** (${courtInfo.courtName}). Thẻ đặt sân đã được cập nhật bên dưới nhé!',
          sender: 'assistant',
          timestamp: DateTime.now(),
          actionCard: updatedCard,
          quickSuggestions: const [
            '⚡ Đặt & Thanh toán VietQR ngay',
            '🔍 Xem trên sơ đồ',
            '🏸 Đặt thêm vợt',
            '🥤 Thêm nước bù khoáng',
          ],
        );
      } else {
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: 'Rất tiếc, khung giờ **${parsedTime.startTime}** tại **$venueName** ($sport) đã kín sân rồi ạ. Anh/chị có muốn giữ khung giờ **${existing['time']}** trước đó hay tham khảo khung giờ khác không ạ?',
          sender: 'assistant',
          timestamp: DateTime.now(),
          actionCard: existing,
          quickSuggestions: [
            'Giữ khung giờ ${existing['time']}',
            '🏸 Xem khung giờ khác',
            '🏟️ Chọn cụm sân khác',
          ],
        );
      }
    }

    // 2. Payment confirmation / Ticket check query
    final isPaymentQuery = RegExp(
      r'thanh\s*toán\s*(?:rồi|thành\s*công|chưa|xong)|đã\s*(?:chuyển\s*khoản|thanh\s*toán|đặt\s*sân\s*chưa)|kiểm\s*tra\s*(?:thanh\s*toán|vé|tiền)|xem\s*(?:lại\s*)?vé|mã\s*vé',
      caseSensitive: false,
    ).hasMatch(text);

    if (isPaymentQuery) {
      final tickets = TicketStore.instance.tickets;
      final codeMatch = RegExp(r'(?:BK|SH)[a-zA-Z0-9_-]+', caseSensitive: false).firstMatch(text);

      TicketModel? targetTicket;
      if (codeMatch != null) {
        final code = codeMatch.group(0)!.toLowerCase();
        targetTicket = tickets.cast<TicketModel?>().firstWhere(
          (t) => t != null && (t.bookingId.toLowerCase() == code || t.id.toLowerCase() == code),
          orElse: () => null,
        );
      }

      if (targetTicket == null && latestBookingCard != null && latestBookingCard!['bookingId'] != null) {
        final bId = latestBookingCard!['bookingId'].toString().toLowerCase();
        targetTicket = tickets.cast<TicketModel?>().firstWhere(
          (t) => t != null && t.bookingId.toLowerCase() == bId,
          orElse: () => null,
        );
      }

      if (targetTicket == null && context?.venueName != null) {
        final vName = context!.venueName!.toLowerCase();
        targetTicket = tickets.cast<TicketModel?>().firstWhere(
          (t) => t != null && t.venueName.toLowerCase().contains(vName),
          orElse: () => null,
        );
      }

      targetTicket ??= tickets.isNotEmpty ? tickets.last : null;

      if (targetTicket != null) {
        final courtLabel = targetTicket.courtNumber > 0
            ? 'Sân ${targetTicket.courtNumber}'
            : 'Sân tiêu chuẩn';
        final formattedPrice = CurrencyFormatter.format(targetTicket.totalPrice);

        if (targetTicket.status == 'paid') {
          return ChatMessage(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
            text: '🎉 Dạ em đã kiểm tra hệ thống và xác nhận đơn đặt sân mã **${targetTicket.bookingId}** tại **${targetTicket.venueName}** ($courtLabel, ${targetTicket.startTime} - ${targetTicket.endTime}) với số tiền **$formattedPrice** đã được thanh toán thành công qua VietQR rồi ạ!\n\n'
                'Khung giờ đã được giữ chỗ riêng cho anh/chị. Khi đến sân, anh/chị chỉ cần xuất trình mã QR trong mục **Vé của tôi** để nhận sân nhé! Chúc anh/chị có buổi chơi thể thao thật vui vẻ! 🏸⚽🏓',
            sender: 'assistant',
            timestamp: DateTime.now(),
            actionCard: {
              'type': 'booking_card',
              'venueId': targetTicket.venueName,
              'venueName': targetTicket.venueName,
              'sport': targetTicket.sportType,
              'court': courtLabel,
              'date': targetTicket.matchDate,
              'time': '${targetTicket.startTime} - ${targetTicket.endTime}',
              'startTime': targetTicket.startTime,
              'endTime': targetTicket.endTime,
              'price': targetTicket.totalPrice,
              'isPaid': true,
              'isBooked': true,
              'bookingId': targetTicket.bookingId,
              'ticketId': targetTicket.id,
            },
            quickSuggestions: const [
              '🎫 Xem vé của tôi',
              '🔍 Xem trên sơ đồ',
              '📢 Đăng lên Bảng tin Cộng đồng',
            ],
          );
        } else {
          return ChatMessage(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
            text: 'Dạ em kiểm tra đơn đặt sân mã **${targetTicket.bookingId}** tại **${targetTicket.venueName}** ($courtLabel, ${targetTicket.startTime} - ${targetTicket.endTime}) hiện đang ở trạng thái **Chờ thanh toán** (chưa ghi nhận chuyển khoản).\n\n'
                'Anh/chị vui lòng nhấn nút quét mã VietQR bên dưới để hoàn tất giữ chỗ nhé!',
            sender: 'assistant',
            timestamp: DateTime.now(),
            actionCard: {
              'type': 'booking_card',
              'venueId': targetTicket.venueName,
              'venueName': targetTicket.venueName,
              'sport': targetTicket.sportType,
              'court': courtLabel,
              'date': targetTicket.matchDate,
              'time': '${targetTicket.startTime} - ${targetTicket.endTime}',
              'startTime': targetTicket.startTime,
              'endTime': targetTicket.endTime,
              'price': targetTicket.totalPrice,
              'isPaid': false,
              'bookingId': targetTicket.bookingId,
              'ticketId': targetTicket.id,
            },
            quickSuggestions: const [
              '⚡ Đặt & Thanh toán VietQR ngay',
              '🎫 Xem vé của tôi',
            ],
          );
        }
      } else {
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: 'Dạ em đã kiểm tra trên hệ thống và chưa tìm thấy đơn đặt sân nào của anh/chị. Anh/chị có thể đặt sân ngay trên ứng dụng hoặc nhắn cho em để được hỗ trợ giữ chỗ nhé!',
          sender: 'assistant',
          timestamp: DateTime.now(),
          quickSuggestions: const [
            '🏸 Cầu lông Q.1 (19h)',
            '🏓 Pickleball Thảo Điền',
            '⚽ Bóng đá mini Q.7',
          ],
        );
      }
    }

    // 3. Owner specific intents (doanh thu, check-in, tình trạng sân)
    final isOwner = context?.userRole == 'owner';
    if (isOwner) {
      if (lower.contains('doanh thu')) {
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: '📊 **Báo cáo Doanh thu hôm nay (CLB Tao Đàn):**\n\n'
              '• Tổng doanh thu dự kiến: **1.480.000đ**\n'
              '• Đặt qua SportHub: **4 lượt** (940.000đ)\n'
              '• Đặt tại quầy / Khách quen: **3 lượt** (540.000đ)\n'
              '• Tỷ lệ thanh toán online: **100% qua VietQR**',
          sender: 'assistant',
          timestamp: DateTime.now(),
          actionCard: const {
            'type': 'table_card',
            'title': 'Bảng Phân Tích Doanh Thu',
            'subtitle': 'Cập nhật theo thời gian thực',
            'icon': 'revenue',
            'headers': ['Kênh đặt', 'Số lượt', 'Doanh thu', 'Hình thức TT'],
            'rows': [
              ['SportHub App', '4 lượt', '940.000đ', '100% VietQR'],
              ['Tại quầy / Khách quen', '3 lượt', '540.000đ', 'Tiền mặt / CK'],
              ['Dịch vụ phụ (Nước, Cầu)', '5 đơn', '180.000đ', 'Tại quầy'],
              ['TỔNG DOANH THU', '12 lượt', '1.660.000đ', 'Đã đối soát'],
            ],
            'footer': '💡 Tiền từ đơn đặt qua app được quyết toán tự động về tài khoản VietQR của sân.',
          },
          quickSuggestions: const [
            'Tình trạng sân hôm nay',
            'Số vé chờ check-in',
            'Chính sách hoàn hủy',
          ],
        );
      }
      if (lower.contains('check-in') || lower.contains('soát vé') || lower.contains('chờ check-in')) {
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: '🎫 **Danh sách vé chờ Check-in hôm nay:**\n\n'
              '1. **SH-8291** - Nguyễn Văn An (Sân 1 lúc 18:00 - Cầu lông)\n'
              '2. **SH-8292** - Trần Thuỳ Linh (Sân 1 lúc 19:00 - Cầu lông)\n'
              '3. **SH-7714** - Lê Minh (Sân 5 lúc 18:00 - Pickleball)\n\n'
              '👉 Bạn có thể dùng mục **Soát vé QR** trên thanh điều hướng để quét mã vé khi khách tới quầy.',
          sender: 'assistant',
          timestamp: DateTime.now(),
          actionCard: const {
            'type': 'table_card',
            'title': 'Bảng Vé Chờ Check-in Hôm Nay',
            'subtitle': 'Danh sách khách đặt qua ứng dụng',
            'icon': 'ticket',
            'headers': ['Mã vé', 'Khách hàng', 'Sân & Môn', 'Giờ', 'Trạng thái'],
            'rows': [
              ['SH-8291', 'Nguyễn Văn An', 'Sân 1 (Cầu lông)', '18:00', 'Chờ check-in'],
              ['SH-8292', 'Trần Thuỳ Linh', 'Sân 1 (Cầu lông)', '19:00', 'Chờ check-in'],
              ['SH-7714', 'Lê Minh', 'Sân 5 (Pickleball)', '18:00', 'Chờ check-in'],
              ['SH-6520', 'Chú Ba (Quầy)', 'Sân 2 (Cầu lông)', '17:00', 'Đã nhận sân'],
            ],
            'footer': '💡 Bấm mục Soát vé QR trên thanh điều hướng để quét mã vé cho khách khi tới sân.',
          },
          quickSuggestions: const [
            'Doanh thu hôm nay',
            'Tình trạng sân hôm nay',
          ],
        );
      }
      if (lower.contains('tình trạng sân') || lower.contains('lịch sân') || lower.contains('sơ đồ')) {
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: '🏟️ **Tình trạng cụm sân Tao Đàn hôm nay:**\n\n'
              '• Tổng số sân: **8 sân** (Sân 1-4 Cầu lông, Sân 5-8 Pickleball)\n'
              '• Suất đã được đặt: **7 suất** (Tỷ lệ lấp đầy: 85% khung giờ tối)\n'
              '• Giờ vàng (18:00 - 20:00): **Kín 100% sân 1, sân 2 và sân 5**\n'
              '• Sân bảo trì định kỳ: **Sân 4 (12h) & Sân 7 (14h)**',
          sender: 'assistant',
          timestamp: DateTime.now(),
          actionCard: const {
            'type': 'table_card',
            'title': 'Bảng Tình Trạng 8 Sân Tao Đàn',
            'subtitle': 'Khung giờ hoạt động 06:00 - 22:00',
            'icon': 'court',
            'headers': ['Sân', 'Môn thể thao', 'Giờ mở', 'Lấp đầy', 'Trạng thái'],
            'rows': [
              ['Sân 1', 'Cầu lông', '06:00 - 22:00', '8/16 slot', 'Kín 18h-20h'],
              ['Sân 2', 'Cầu lông', '06:00 - 22:00', '7/16 slot', 'Kín 17h-19h'],
              ['Sân 3', 'Cầu lông', '06:00 - 22:00', '5/16 slot', 'Còn trống'],
              ['Sân 4', 'Cầu lông', '06:00 - 22:00', '4/16 slot', 'Bảo trì 12h'],
              ['Sân 5', 'Pickleball', '06:00 - 22:00', '9/16 slot', 'Kín 18h-21h'],
              ['Sân 6', 'Pickleball', '06:00 - 22:00', '6/16 slot', 'Còn trống'],
              ['Sân 7', 'Pickleball', '06:00 - 22:00', '3/16 slot', 'Bảo trì 14h'],
              ['Sân 8', 'Pickleball', '06:00 - 22:00', '5/16 slot', 'Còn trống'],
            ],
            'footer': '💡 Khung giờ tối 18h-21h đã kín 85% công suất.',
          },
          quickSuggestions: const [
            'Doanh thu hôm nay',
            'Số vé chờ check-in',
          ],
        );
      }
      if (lower.contains('hoàn') || lower.contains('hủy') || lower.contains('chính sách')) {
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: '📋 **Chính sách hoàn hủy & Quyền lợi của chủ sân:**\n\n'
              '• Khách hủy trước > 24h: **Hoàn 100%** (Sân tự động mở lại slot cho khách mới).\n'
              '• Khách hủy trong 12h - 24h: **Hoàn 50%** (Sân nhận 50% tiền cọc).\n'
              '• Khách hủy dưới 12h: **Không hoàn tiền** (Sân nhận đủ 100% tiền slot).',
          sender: 'assistant',
          timestamp: DateTime.now(),
          actionCard: const {
            'type': 'table_card',
            'title': 'Bảng Tỷ Lệ Hoàn Tiền & Quyền Lợi Sân',
            'subtitle': 'Quy định đối soát SportHub',
            'icon': 'policy',
            'headers': ['Thời gian báo hủy', 'Khách nhận lại', 'Sân thu phí', 'Quy trình xử lý'],
            'rows': [
              ['> 24 giờ trước giờ chơi', 'Hoàn 100%', '0% phí', 'Mở lại slot tự động'],
              ['12 - 24 giờ trước giờ chơi', 'Hoàn 50%', 'Thu 50% tiền cọc', 'Chuyển vào ví sân'],
              ['< 12 giờ trước giờ chơi', 'Không hoàn (0%)', 'Thu 100% tiền đặt', 'Bảo lưu doanh thu sân'],
            ],
            'footer': '💡 Chính sách giúp bảo vệ doanh thu tối đa cho chủ sân khi khách báo hủy sát giờ.',
          },
          quickSuggestions: const [
            'Doanh thu hôm nay',
            'Tình trạng sân hôm nay',
          ],
        );
      }
    }

    // 4. Recruitment / Member finding / Matchmaking assistance
    final isRecruitment = imageUrl != null ||
        RegExp(
          r'tuyển\s*thành\s*viên|tuyển\s*người|tìm\s*bạn|ghép\s*kèo|tìm\s*kèo|kèo\s*giao\s*lưu|cần\s*người|cần\s*thành\s*viên|tuyển\s*thêm|tìm\s*người',
          caseSensitive: false,
        ).hasMatch(text);

    if (isRecruitment) {
      // 4.1 Resolve venue & district
      String venueName = (context?.venueName != null && context!.venueName!.isNotEmpty)
          ? context.venueName!
          : 'CLB Cầu Lông Tao Đàn';
      String district = 'Quận 1';

      if (lower.contains('bình thạnh') || lower.contains('binh thanh')) {
        venueName = 'CLB Cầu Lông & Pickleball Bình Thạnh Sport';
        district = 'Quận Bình Thạnh';
      } else if (lower.contains('thảo điền') || lower.contains('thao dien') || lower.contains('thủ đức')) {
        venueName = 'Thảo Điền Pickleball Hub';
        district = 'TP. Thủ Đức';
      } else if (lower.contains('tân bình') || lower.contains('tan binh')) {
        venueName = 'Khu Liên Hợp Thể Thao Tân Bình Arena';
        district = 'Quận Tân Bình';
      } else if (lower.contains('quận 7') || lower.contains('nam sài gòn') || lower.contains('q7')) {
        venueName = 'Sân Bóng Đá Mini Nam Sài Gòn';
        district = 'Quận 7';
      } else if (venueName.contains('Bình Thạnh')) {
        district = 'Quận Bình Thạnh';
      } else if (venueName.contains('Thảo Điền')) {
        district = 'TP. Thủ Đức';
      } else if (venueName.contains('Tân Bình')) {
        district = 'Quận Tân Bình';
      } else if (venueName.contains('Nam Sài Gòn')) {
        district = 'Quận 7';
      }

      // 4.2 Sport
      final rawSport = context?.sport ??
          (lower.contains('pickleball') || lower.contains('🏓')
              ? 'pickleball'
              : (lower.contains('bóng đá') || lower.contains('football') || lower.contains('⚽')
                  ? 'football'
                  : 'badminton'));
      final sportTitle = rawSport == 'pickleball'
          ? 'Pickleball'
          : (rawSport == 'football' ? 'Bóng đá' : 'Cầu lông');
      final sportIcon = rawSport == 'pickleball'
          ? '🏓'
          : (rawSport == 'football' ? '⚽' : '🏸');

      // 4.3 Player count extraction
      int requiredPlayers = 4;
      int currentPlayers = 2;
      final playerMatch = RegExp(
        r'(?:cần|tuyển|tìm)\s*(\d+)\s*(?:người|bạn|thành\s*viên|slot|chỗ|tay\s*vợt)?|(\d+)\s*(?:người|bạn|thành\s*viên|slot|chỗ)',
        caseSensitive: false,
      ).firstMatch(text);
      if (playerMatch != null) {
        final needed = int.tryParse(playerMatch.group(1) ?? playerMatch.group(2) ?? '2') ?? 2;
        if (lower.contains('đánh đơn') || lower.contains('kèo đơn')) {
          requiredPlayers = 2;
          currentPlayers = (2 - needed).clamp(1, 2);
        } else {
          requiredPlayers = (needed > 2) ? needed + 1 : 4;
          currentPlayers = (requiredPlayers - needed).clamp(1, requiredPlayers - 1);
        }
      } else if (lower.contains('đánh đơn') || lower.contains('kèo đơn')) {
        requiredPlayers = 2;
        currentPlayers = 1;
      }

      // 4.4 Time & Date extraction
      final parsedTime = parseTime(text);
      final parsedDate = parseDate(text);
      final scheduledTime = '${parsedTime.startTime} - ${parsedTime.endTime} ${parsedDate.displayDate}';

      // 4.5 Skill level extraction
      String skillLevel = 'Trung bình (2.0 - 3.5)';
      if (lower.contains('mới chơi') || lower.contains('người mới') || lower.contains('cơ bản') || lower.contains('newbie')) {
        skillLevel = 'Mới bắt đầu (1.0 - 2.0)';
      } else if (lower.contains('khá') || lower.contains('pro') || lower.contains('nâng cao') || lower.contains('chuyên')) {
        skillLevel = 'Khá - Nâng cao (3.5+)';
      } else if (lower.contains('giao lưu') || lower.contains('vui vẻ')) {
        skillLevel = 'Giao lưu vui vẻ (Mọi trình độ)';
      }

      // 4.6 Share fee extraction
      double shareFee = 45000.0;
      final feeMatch = RegExp(r'(\d{2,3})\s*[kK]|(\d{4,6})\s*đ').firstMatch(text);
      if (feeMatch != null) {
        if (feeMatch.group(1) != null) {
          shareFee = (double.tryParse(feeMatch.group(1)!) ?? 45) * 1000;
        } else if (feeMatch.group(2) != null) {
          shareFee = double.tryParse(feeMatch.group(2)!) ?? 45000.0;
        }
      }

      final neededCount = requiredPlayers - currentPlayers;
      final recruitmentCard = {
        'type': 'recruitment_card',
        'title': 'Kèo Giao Lưu $sportTitle - $venueName',
        'venueName': venueName,
        'sportType': rawSport,
        'district': district,
        'skillLevel': skillLevel,
        'scheduledTime': scheduledTime,
        'requiredPlayers': requiredPlayers,
        'currentPlayers': currentPlayers,
        'shareFee': shareFee,
        'note': 'Giao lưu rèn luyện sức khỏe, vui vẻ và kết nối đam mê thể thao!',
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      final hasImg = imageUrl != null && imageUrl.isNotEmpty;
      final replyText = hasImg
          ? '$sportIcon Em đã chuẩn bị sẵn bài đăng tuyển thành viên kèm hình ảnh cho anh/chị:\n\n'
            '📌 **${recruitmentCard['title']}**\n'
            '📍 **Địa điểm**: $venueName ($district)\n'
            '⏰ **Thời gian**: $scheduledTime\n'
            '👥 **Cần tuyển**: $neededCount thành viên (Hiện có $currentPlayers/$requiredPlayers người)\n'
            '⭐ **Trình độ**: $skillLevel\n'
            '💰 **Chi phí chia sẻ**: ${CurrencyFormatter.format(shareFee)}/người\n\n'
            '👉 Bạn có thể nhấn **"📢 Đăng lên Bảng tin Cộng đồng"** để tìm người ghép kèo ngay nhé!'
          : '$sportIcon Em đã chuẩn bị sẵn bài đăng tuyển thành viên cho anh/chị:\n\n'
            '📌 **${recruitmentCard['title']}**\n'
            '📍 **Địa điểm**: $venueName ($district)\n'
            '⏰ **Thời gian**: $scheduledTime\n'
            '👥 **Cần tuyển**: $neededCount thành viên (Hiện có $currentPlayers/$requiredPlayers người)\n'
            '⭐ **Trình độ**: $skillLevel\n'
            '💰 **Chi phí chia sẻ**: ${CurrencyFormatter.format(shareFee)}/người\n\n'
            '👉 Hãy nhấn **"📢 Đăng lên Bảng tin Cộng đồng"** bên dưới để đăng bài ngay nhé!';

      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
        text: replyText,
        sender: 'assistant',
        timestamp: DateTime.now(),
        actionCard: recruitmentCard,
        quickSuggestions: const [
          '📢 Đăng lên Bảng tin Cộng đồng',
          '⚡ Đặt & Thanh toán VietQR ngay',
          '🔍 Xem trên sơ đồ',
        ],
      );
    }

    // Direct community publish confirmation
    if (lower.contains('đăng lên bảng tin') || lower.contains('đăng bài')) {
      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
        text: '🎉 Em đã hỗ trợ đăng bài tuyển thành viên lên Bảng tin Cộng đồng SportHub thành công! Các tay vợt trong khu vực sẽ nhận được thông báo để tham gia cùng bạn nhé. 🏸',
        sender: 'assistant',
        timestamp: DateTime.now(),
        quickSuggestions: const [
          '⚡ Đặt & Thanh toán VietQR ngay',
          '🔍 Xem trên sơ đồ',
        ],
      );
    }

    // 5. Add-on services / extra items (nước uống, bù khoáng, ống cầu, thuê vợt...)
    final addonCheckRegex = RegExp(
      r'nước|khoáng|bù khoáng|pocari|aquafina|ống cầu|quả cầu|hộp cầu|thuê vợt|vợt|bóng|đặt thêm|thêm',
      caseSensitive: false,
    );

    if (addonCheckRegex.hasMatch(text)) {
      final addons = <String>[];
      final itemsDesc = <String>[];
      final addonCounts = <String, int>{};
      int addonsTotal = 0;

      // 5.1 Mineral water / Pocari
      final waterMatch = RegExp(
        r'(\d+)?\s*(?:chai|lon|bình)?\s*(?:nước\s*bù\s*khoáng|pocari|nước\s*khoáng|nước\s*suối|nước)',
        caseSensitive: false,
      ).firstMatch(text);
      if (waterMatch != null) {
        final qty = int.tryParse(waterMatch.group(1) ?? '1') ?? 1;
        final itemPrice = 15000 * qty;
        addons.add('${qty}x Pocari Sweat Bù Khoáng (+${CurrencyFormatter.format(itemPrice)})');
        itemsDesc.add('$qty chai nước Pocari bù khoáng (${CurrencyFormatter.format(itemPrice)})');
        addonsTotal += itemPrice;
        addonCounts['drink_pocari'] = (addonCounts['drink_pocari'] ?? 0) + qty;
      }

      // 5.2 Shuttlecocks (ống cầu / quả cầu)
      final shuttleMatch = RegExp(
        r'(\d+)?\s*(?:ống|hộp|trái|quả)?\s*(?:cầu\s*lông|ống\s*cầu|quả\s*cầu|hộp\s*cầu|cầu)',
        caseSensitive: false,
      ).firstMatch(text);
      if (shuttleMatch != null && !shuttleMatch.group(0)!.toLowerCase().contains('sân')) {
        final qty = int.tryParse(shuttleMatch.group(1) ?? '1') ?? 1;
        final isSingle = RegExp(r'quả|trái', caseSensitive: false).hasMatch(shuttleMatch.group(0)!) &&
            !RegExp(r'ống|hộp', caseSensitive: false).hasMatch(shuttleMatch.group(0)!);
        final unitPrice = isSingle ? 22000 : 240000;
        final itemPrice = unitPrice * qty;
        final unitLabel = isSingle ? 'quả cầu lông' : 'ống cầu lông Hải Yến';
        addons.add('${qty}x ${isSingle ? 'Quả Cầu Lông' : 'Ống Cầu Lông Hải Yến'} (+${CurrencyFormatter.format(itemPrice)})');
        itemsDesc.add('$qty $unitLabel (${CurrencyFormatter.format(itemPrice)})');
        addonsTotal += itemPrice;
        final key = isSingle ? 'gear_shuttle_single' : 'gear_shuttle_tube';
        addonCounts[key] = (addonCounts[key] ?? 0) + qty;
      }

      // 5.3 Rackets (vợt)
      final racketMatch = RegExp(
        r'(\d+)?\s*(?:cây|chiếc|cặp)?\s*(?:vợt\s*cầu\s*lông|vợt\s*pickleball|vợt)',
        caseSensitive: false,
      ).firstMatch(text);
      if (racketMatch != null) {
        final qty = int.tryParse(racketMatch.group(1) ?? '1') ?? 1;
        final itemPrice = 30000 * qty;
        addons.add('${qty}x Vợt Cầu Lông Yonex (+${CurrencyFormatter.format(itemPrice)})');
        itemsDesc.add('$qty cây vợt (${CurrencyFormatter.format(itemPrice)})');
        addonsTotal += itemPrice;
        addonCounts['rent_badminton'] = (addonCounts['rent_badminton'] ?? 0) + qty;
      }

      if (itemsDesc.isNotEmpty) {
        final existingCard = latestBookingCard;
        String venueName;
        String venueId;
        String sport;
        String date;
        String time;
        String startTime;
        String endTime;
        String courtName;
        int baseCourtPrice;

        Map<String, int> mergedAddonCounts = {};

        if (existingCard != null) {
          venueName = existingCard['venueName']?.toString() ?? 'CLB Cầu Lông Tao Đàn';
          venueId = existingCard['venueId']?.toString() ?? 'venue_01';
          sport = existingCard['sport']?.toString() ?? 'Cầu lông';
          date = existingCard['date']?.toString() ?? 'Hôm nay';
          time = existingCard['time']?.toString() ?? '19:00';
          startTime = existingCard['startTime']?.toString() ?? '19:00';
          endTime = existingCard['endTime']?.toString() ?? '20:00';
          courtName = existingCard['court']?.toString() ?? 'Sân 1';
          baseCourtPrice = (existingCard['basePrice'] as num?)?.toInt() ??
              ((existingCard['price'] as num?)?.toInt() ?? 180000) -
                  ((existingCard['addonsTotal'] as num?)?.toInt() ?? 0);

          mergedAddonCounts = Map<String, int>.from(existingCard['addonCounts'] ?? {});
        } else {
          venueName = (context?.venueName != null && context!.venueName!.isNotEmpty)
              ? context.venueName!
              : 'CLB Cầu Lông Tao Đàn';
          venueId = context?.venueId ?? 'venue_01';
          sport = (context?.sport != null && context!.sport!.isNotEmpty)
              ? context.sport!
              : 'Cầu lông';
          date = 'Hôm nay';
          time = '19:00';
          startTime = '19:00';
          endTime = '20:00';

          final courtInfo = findAvailableCourtAndPrice(
            venueId: venueId,
            venueName: venueName,
            sport: sport,
            date: date,
            startTime: startTime,
          );
          courtName = courtInfo.isAvailable ? courtInfo.courtName : 'Sân 1';
          baseCourtPrice = courtInfo.price;
        }

        // Merge newly ordered addons with any existing addon counts
        for (final entry in addonCounts.entries) {
          mergedAddonCounts[entry.key] = (mergedAddonCounts[entry.key] ?? 0) + entry.value;
        }

        // Recompute all addon strings and total cost
        final recomputedAddons = <String>[];
        int totalAddonsCost = 0;

        if (mergedAddonCounts.containsKey('drink_pocari') && mergedAddonCounts['drink_pocari']! > 0) {
          final q = mergedAddonCounts['drink_pocari']!;
          final c = q * 15000;
          recomputedAddons.add('${q}x Pocari Sweat Bù Khoáng (+${CurrencyFormatter.format(c)})');
          totalAddonsCost += c;
        }
        if (mergedAddonCounts.containsKey('gear_shuttle_tube') && mergedAddonCounts['gear_shuttle_tube']! > 0) {
          final q = mergedAddonCounts['gear_shuttle_tube']!;
          final c = q * 240000;
          recomputedAddons.add('${q}x Ống Cầu Lông Hải Yến (+${CurrencyFormatter.format(c)})');
          totalAddonsCost += c;
        }
        if (mergedAddonCounts.containsKey('gear_shuttle_single') && mergedAddonCounts['gear_shuttle_single']! > 0) {
          final q = mergedAddonCounts['gear_shuttle_single']!;
          final c = q * 22000;
          recomputedAddons.add('${q}x Quả Cầu Lông (+${CurrencyFormatter.format(c)})');
          totalAddonsCost += c;
        }
        if (mergedAddonCounts.containsKey('rent_badminton') && mergedAddonCounts['rent_badminton']! > 0) {
          final q = mergedAddonCounts['rent_badminton']!;
          final c = q * 30000;
          recomputedAddons.add('${q}x Vợt Cầu Lông Yonex (+${CurrencyFormatter.format(c)})');
          totalAddonsCost += c;
        }

        final grandTotal = baseCourtPrice + totalAddonsCost;

        final actionCard = {
          if (existingCard != null) ...existingCard,
          'type': 'booking_card',
          'venueId': venueId,
          'venueName': venueName,
          'sport': sport,
          'date': date,
          'time': time,
          'startTime': startTime,
          'endTime': endTime,
          'court': courtName,
          'price': grandTotal,
          'basePrice': baseCourtPrice,
          'addonsTotal': totalAddonsCost,
          'addons': recomputedAddons,
          'addonCounts': mergedAddonCounts,
        };

        pendingBooking = actionCard;

        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: 'Dạ, em đã ghi nhận thêm dịch vụ cho anh/chị: ${itemsDesc.join(' và ')}. Đơn đặt sân tại $venueName ($courtName, $time) đã cập nhật phụ phí dịch vụ ${CurrencyFormatter.format(totalAddonsCost)}, tổng thanh toán là ${CurrencyFormatter.format(grandTotal)}. Nhân viên sân sẽ chuẩn bị sẵn sàng khi mình tới nhé!',
          sender: 'assistant',
          timestamp: DateTime.now(),
          actionCard: actionCard,
          quickSuggestions: const [
            '⚡ Đặt & Thanh toán VietQR ngay',
            '🔍 Xem trên sơ đồ',
            '🏸 Đặt thêm vợt',
            '🥤 Thêm nước bù khoáng',
          ],
        );
      }
    }

    // 6. Pricing query (Context-aware)
    final priceRegex = RegExp(r'giá|bao nhiêu|bảng giá|chi phí', caseSensitive: false);
    if (priceRegex.hasMatch(text)) {
      final s = context?.sport?.toLowerCase() ?? '';
      final isPickle = lower.contains('pickleball') || lower.contains('🏓') || s.contains('pickleball');
      final isFoot = lower.contains('bóng đá') || lower.contains('football') || lower.contains('soccer') || lower.contains('⚽') || s.contains('football') || s.contains('bóng');

      final vName = (context?.venueName != null && context!.venueName!.isNotEmpty)
          ? context.venueName!
          : (lower.contains('thảo điền')
              ? 'Thảo Điền Pickleball Hub'
              : (lower.contains('nam sài gòn') || lower.contains('quận 7')
                  ? 'Sân Bóng Đá Mini Nam Sài Gòn'
                  : (lower.contains('bình thạnh')
                      ? 'CLB Cầu Lông & Pickleball Bình Thạnh Sport'
                      : (lower.contains('tân bình')
                          ? 'Khu Liên Hợp Thể Thao Tân Bình Arena'
                          : 'CLB Cầu Lông Tao Đàn'))));

      final parsedTime = parseTime(text);
      final hasSpecificHour = RegExp(r'(\d{1,2})(?:h|:|\s*giờ)', caseSensitive: false).hasMatch(text);

      if (hasSpecificHour) {
        final slotPrice = ShiftSlotGenerator.calculateSlotPrice(
          sportType: isPickle ? 'pickleball' : (isFoot ? 'football' : 'badminton'),
          startTime: parsedTime.startTime,
        ).toInt();
        final sportLabel = isPickle ? 'Pickleball' : (isFoot ? 'Bóng đá' : 'Cầu lông');
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: 'Khung giờ **${parsedTime.startTime}** tại **$vName** (môn $sportLabel) có giá là **${CurrencyFormatter.format(slotPrice)}/giờ** ạ. Anh/chị có thể đặt trực tiếp trên app để giữ chỗ ngay nhé!',
          sender: 'assistant',
          timestamp: DateTime.now(),
          quickSuggestions: [
            '⚡ Đặt sân $sportLabel ${parsedTime.startTime}',
            'Chính sách hoàn hủy',
          ],
        );
      }

      if (isPickle) {
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: 'Giá thuê sân Pickleball tại $vName dao động từ **130.000đ - 220.000đ/giờ** tuỳ theo khung giờ (giờ vàng sau 17:00 thường là 220.000đ/giờ). Anh/chị có thể đặt trực tiếp trên app để nhận ưu đãi nhé!',
          sender: 'assistant',
          timestamp: DateTime.now(),
          quickSuggestions: const [
            '🏓 Đặt sân Pickleball 19h',
            'Chính sách hoàn hủy',
          ],
        );
      } else if (isFoot) {
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: 'Giá thuê sân bóng đá mini tại $vName dao động từ **250.000đ - 420.000đ/giờ** tuỳ theo khung giờ (giờ vàng sau 17:00 thường là 420.000đ/giờ). Anh/chị có thể đặt trực tiếp trên app để nhận ưu đãi nhé!',
          sender: 'assistant',
          timestamp: DateTime.now(),
          quickSuggestions: const [
            '⚽ Đặt sân bóng đá 19h',
            'Chính sách hoàn hủy',
          ],
        );
      } else {
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: 'Giá thuê sân cầu lông dao động từ 100.000đ - 180.000đ/giờ tuỳ theo khung giờ (giờ vàng sau 17:00 thường là 150.000đ - 180.000đ/giờ). Anh/chị có thể đặt trực tiếp trên app để nhận ưu đãi nhé!',
          sender: 'assistant',
          timestamp: DateTime.now(),
          quickSuggestions: const [
            '🏸 Đặt sân cầu lông 19h',
            'Chính sách hoàn hủy',
          ],
        );
      }
    }

    // 7. Cancellation / Policy query
    final policyRegex = RegExp(r'hủy|đổi lịch|chính sách', caseSensitive: false);
    if (policyRegex.hasMatch(text)) {
      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
        text: 'Chính sách SportHub: Quý khách được phép hủy hoặc đổi lịch miễn phí trước 24 giờ so với giờ chơi. Nếu hủy trong vòng 12-24 giờ, hỗ trợ hoàn tiền 50% hoặc bảo lưu suất chơi.',
        sender: 'assistant',
        timestamp: DateTime.now(),
      );
    }

    // 8. Booking intent (Expanded)
    final bookingRegex = RegExp(
      r'đặt\s*sân|book|thuê\s*sân|giữ\s*chỗ|tìm\s*sân|sân\s*trống|còn\s*sân|'
      r'chơi\s*(?:cầu\s*lông|pickleball|bóng\s*đá|thể\s*thao)|kiểm\s*tra\s*sân|'
      r'lấy\s*sân|muốn\s*sân|cần\s*sân|'
      r'(?:cầu\s*lông|pickleball|bóng\s*đá).*(?:\d{1,2}\s*h|tối|sáng|chiều|sân)|'
      r'(?:\d{1,2}\s*h|tối|sáng|chiều).*(?:cầu\s*lông|pickleball|bóng\s*đá)|'
      r'🏸|🏓|⚽',
      caseSensitive: false,
    );
    const defaultQuickSuggestions = [
      '🏸 Cầu lông Q.1 (19h)',
      '🏓 Pickleball Thảo Điền',
      '🏸 Cầu lông Bình Thạnh',
      '⚽ Bóng đá mini Q.7',
    ];

    if (bookingRegex.hasMatch(text)) {
      final parsedTime = parseTime(text);
      final parsedDate = parseDate(text);

      // Match district / location keywords to target venue
      String venueId = 'venue_01';
      String venueName = 'CLB Cầu Lông Tao Đàn';
      String sport = 'Cầu lông';

      if (lower.contains('bình thạnh') || lower.contains('binh thanh')) {
        venueId = 'venue_bt_01';
        venueName = 'CLB Cầu Lông & Pickleball Bình Thạnh Sport';
        sport = lower.contains('pickleball') || lower.contains('🏓') ? 'Pickleball' : 'Cầu lông';
      } else if (lower.contains('thảo điền') ||
          lower.contains('thao dien') ||
          lower.contains('thủ đức') ||
          lower.contains('thu duc')) {
        venueId = 'venue_td_02';
        venueName = 'Thảo Điền Pickleball Hub';
        sport = 'Pickleball';
      } else if (lower.contains('tân bình') || lower.contains('tan binh')) {
        venueId = 'venue_tb_05';
        venueName = 'Khu Liên Hợp Thể Thao Tân Bình Arena';
        if (lower.contains('bóng đá') ||
            lower.contains('bong da') ||
            lower.contains('football') ||
            lower.contains('soccer') ||
            lower.contains('⚽')) {
          sport = 'Bóng đá';
        } else if (lower.contains('pickleball') || lower.contains('🏓')) {
          sport = 'Pickleball';
        } else {
          sport = 'Cầu lông';
        }
      } else if (lower.contains('quận 7') ||
          lower.contains('quan 7') ||
          lower.contains('q7') ||
          lower.contains('q.7') ||
          lower.contains('nam sài gòn') ||
          lower.contains('nam sai gon')) {
        venueId = 'venue_q7_03';
        venueName = 'Sân Bóng Đá Mini Nam Sài Gòn';
        sport = 'Bóng đá';
      } else if (lower.contains('tao đàn') ||
          lower.contains('tao dan') ||
          lower.contains('quận 1') ||
          lower.contains('quan 1') ||
          lower.contains('q1') ||
          lower.contains('q.1')) {
        venueId = 'venue_01';
        venueName = 'CLB Cầu Lông Tao Đàn';
        sport = lower.contains('pickleball') || lower.contains('🏓') ? 'Pickleball' : 'Cầu lông';
      } else if (context?.venueId != null && context!.venueId!.isNotEmpty) {
        venueId = context.venueId!;
        venueName = (context.venueName != null && context.venueName!.isNotEmpty)
            ? context.venueName!
            : 'CLB Cầu Lông Tao Đàn';
        if (context.sport != null && context.sport!.isNotEmpty) {
          final s = context.sport!.toLowerCase();
          if (s.contains('badminton') || s.contains('cầu lông')) {
            sport = 'Cầu lông';
          } else if (s.contains('football') || s.contains('bóng đá')) {
            sport = 'Bóng đá';
          } else if (s.contains('pickleball')) {
            sport = 'Pickleball';
          } else if (s.contains('tennis')) {
            sport = 'Tennis';
          } else {
            sport = context.sport!;
          }
        } else if (lower.contains('cầu lông') || lower.contains('badminton') || lower.contains('🏸')) {
          sport = 'Cầu lông';
        } else if (lower.contains('bóng đá') || lower.contains('football') || lower.contains('soccer') || lower.contains('⚽')) {
          sport = 'Bóng đá';
        } else if (lower.contains('pickleball') || lower.contains('🏓')) {
          sport = 'Pickleball';
        } else if (lower.contains('tennis') || lower.contains('quần vợt')) {
          sport = 'Tennis';
        }
      } else {
        final preferred = (context?.sport ?? '').toLowerCase();
        if (lower.contains('bóng đá') ||
            lower.contains('football') ||
            lower.contains('soccer') ||
            lower.contains('⚽') ||
            (!lower.contains('cầu lông') && (preferred.contains('bóng') || preferred.contains('football')))) {
          venueId = 'venue_q7_03';
          venueName = 'Sân Bóng Đá Mini Nam Sài Gòn';
          sport = 'Bóng đá';
        } else if (lower.contains('pickleball') ||
            lower.contains('🏓') ||
            (!lower.contains('cầu lông') && preferred.contains('pickleball'))) {
          venueId = 'venue_td_02';
          venueName = 'Thảo Điền Pickleball Hub';
          sport = 'Pickleball';
        } else if (lower.contains('tennis') || lower.contains('quần vợt')) {
          venueId = 'venue_01';
          venueName = 'CLB Cầu Lông Tao Đàn';
          sport = 'Tennis';
        } else {
          venueId = 'venue_01';
          venueName = 'CLB Cầu Lông Tao Đàn';
          sport = 'Cầu lông';
        }
      }

      final courtInfo = findAvailableCourtAndPrice(
        venueId: venueId,
        venueName: venueName,
        sport: sport,
        date: parsedDate.dateStr,
        startTime: parsedTime.startTime,
      );

      // Do NOT create booking card if all courts are booked or maintenance
      if (!courtInfo.isAvailable) {
        pendingBooking = null;
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: 'Rất tiếc, các sân môn $sport tại $venueName vào khung giờ ${parsedTime.startTime} (${parsedDate.displayDate}) đều đã được đặt kín hoặc đang bảo trì rồi ạ.\n\nAnh/chị có thể tham khảo các khung giờ khác hoặc chuyển sang cụm sân lân cận nhé!',
          sender: 'assistant',
          timestamp: DateTime.now(),
          quickSuggestions: [
            '🏸 Xem khung giờ khác',
            '🏟️ Cụm sân lân cận',
            '🎫 Xem vé của tôi',
          ],
        );
      }

      final actionCard = {
        'type': 'booking_card',
        'venueId': venueId,
        'venueName': venueName,
        'sport': sport,
        'date': parsedDate.displayDate,
        'time': parsedTime.timeStr,
        'startTime': parsedTime.startTime,
        'endTime': parsedTime.endTime,
        'court': courtInfo.courtName,
        'price': courtInfo.price,
      };

      pendingBooking = actionCard;

      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
        text: 'Em đã tìm thấy sân trống phù hợp theo yêu cầu của anh/chị tại $venueName vào lúc ${parsedTime.timeStr}. Anh/chị có thể nhấn nút đặt và thanh toán VietQR ngay trên thẻ bên dưới nhé!',
        sender: 'assistant',
        timestamp: DateTime.now(),
        actionCard: actionCard,
        quickSuggestions: defaultQuickSuggestions,
      );
    }

    // 9. Greeting
    final greetingRegex = RegExp(r'chào|hello|hi|bạn là ai', caseSensitive: false);
    if (greetingRegex.hasMatch(text)) {
      final userName = context?.userName?.trim();
      final greetingPrefix = (userName != null && userName.isNotEmpty)
          ? 'Chào anh/chị $userName! '
          : 'Xin chào! ';
      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
        text: '${greetingPrefix}Em là trợ lý AI SportHub. Em có thể hỗ trợ anh/chị tìm sân trống, gợi ý giờ chơi, kiểm tra giá và đặt sân nhanh chóng!',
        sender: 'assistant',
        timestamp: DateTime.now(),
        quickSuggestions: defaultQuickSuggestions,
      );
    }

    // 10. Default fallback
    return ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
      text: 'Dạ, em có thể hỗ trợ anh/chị tìm sân trống, kiểm tra giá hoặc đặt lịch nhanh chóng. Anh/chị muốn tìm sân môn thể thao nào và vào khung giờ nào ạ?',
      sender: 'assistant',
      timestamp: DateTime.now(),
    );
  }

  /// Syncs session conversation asynchronously with the admin web server
  Future<void> _syncConversationSession(
    ChatMessage userMsg,
    ChatMessage assistantMsg,
  ) async {
    if (isTestEnvironment && httpClient == null) return;

    try {
      final client = httpClient ?? http.Client();
      final shouldClose = httpClient == null;

      final convPayload = {
        'id': 'conv_${DateTime.now().millisecondsSinceEpoch}',
        'userId': currentContext?.userId,
        'userName': currentContext?.userName,
        'currentScreen': currentContext?.currentRoute,
        'venueId': currentContext?.venueId,
        'messages': [
          userMsg.toJson(),
          assistantMsg.toJson(),
        ],
        'bookingCreated': assistantMsg.hasActionCard,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final uri = Uri.parse('$serverBaseUrl/api/chatbot/conversations');
      await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(convPayload),
          )
          .timeout(const Duration(milliseconds: 1000));

      if (shouldClose) {
        try {
          client.close();
        } catch (_) {}
      }
    } catch (_) {
      // Fire-and-forget sync error handling
    }
  }
}
