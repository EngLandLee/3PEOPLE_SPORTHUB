import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/app_notification.dart';
import '../services/venue_sync_service.dart';
import 'notification_store.dart';

/// Single message in a 1-1 customer <-> venue owner direct chat thread
class VenueChatMessage {
  final String id;
  final String venueId;
  final String venueName;
  final String customerId;
  final String customerName;
  final String senderRole; // 'customer' or 'owner'
  final String text;
  final DateTime timestamp;
  final bool isRead;

  const VenueChatMessage({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.customerId,
    required this.customerName,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  bool get isFromCustomer => senderRole == 'customer';
  bool get isFromOwner => senderRole == 'owner';

  Map<String, dynamic> toJson() => {
        'id': id,
        'venueId': venueId,
        'venueName': venueName,
        'customerId': customerId,
        'customerName': customerName,
        'senderRole': senderRole,
        'text': text,
        'createdAt': timestamp.toIso8601String(),
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
      };

  factory VenueChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime = DateTime.now();
    final timeStr = json['createdAt'] ?? json['timestamp'];
    if (timeStr != null) {
      parsedTime = DateTime.tryParse(timeStr.toString()) ?? DateTime.now();
    }
    return VenueChatMessage(
      id: json['id']?.toString() ??
          'msg_${DateTime.now().millisecondsSinceEpoch}',
      venueId: json['venueId']?.toString() ?? 'venue_01',
      venueName: json['venueName']?.toString() ?? 'CLB Thể Thao',
      customerId: json['customerId']?.toString() ?? 'user_player_01',
      customerName: json['customerName']?.toString() ?? 'Khách đặt sân',
      senderRole: json['senderRole']?.toString() ?? 'customer',
      text: json['text']?.toString() ?? '',
      timestamp: parsedTime,
      isRead: json['isRead'] == true,
    );
  }

  VenueChatMessage copyWith({
    String? id,
    String? venueId,
    String? venueName,
    String? customerId,
    String? customerName,
    String? senderRole,
    String? text,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return VenueChatMessage(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Store managing real-time chat interactions between Players and Venue Owners
class VenueChatStore {
  static final VenueChatStore instance = VenueChatStore._internal();

  VenueChatStore._internal() {
    reset();
    loadLocally();
    fetchMessagesFromServer();
  }

  bool get _isTestEnv {
    try {
      final name = WidgetsBinding.instance.runtimeType.toString();
      return name.contains('Test');
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveLocally() async {
    if (_isTestEnv) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sporthub_venue_chat.json');
      final list = messagesNotifier.value.map((m) => m.toJson()).toList();
      await file.writeAsString(jsonEncode(list));
    } catch (_) {}
  }

  Future<void> loadLocally() async {
    if (_isTestEnv) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sporthub_venue_chat.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final data = jsonDecode(content) as List<dynamic>;
          final loaded = data
              .whereType<Map<String, dynamic>>()
              .map((j) => VenueChatMessage.fromJson(j))
              .toList();
          if (loaded.isNotEmpty) {
            messagesNotifier.value = loaded;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> fetchMessagesFromServer() async {
    if (_isTestEnv) return;
    try {
      final baseUrl = VenueSyncService.instance.serverBaseUrl;
      final res = await http
          .get(Uri.parse('$baseUrl/api/chat/messages'))
          .timeout(const Duration(milliseconds: 1500));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        final serverMsgs = data
            .whereType<Map<String, dynamic>>()
            .map((j) => VenueChatMessage.fromJson(j))
            .toList();
        if (serverMsgs.isNotEmpty) {
          final currentMap = {for (final m in messagesNotifier.value) m.id: m};
          for (final s in serverMsgs) {
            currentMap[s.id] = s;
          }
          final merged = currentMap.values.toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          messagesNotifier.value = merged;
          await _saveLocally();
        }
      }
    } catch (_) {}
  }

  Future<void> _dispatchServer(VenueChatMessage msg) async {
    if (_isTestEnv) return;
    try {
      final baseUrl = VenueSyncService.instance.serverBaseUrl;
      await http.post(
        Uri.parse('$baseUrl/api/chat/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(msg.toJson()),
      ).timeout(const Duration(milliseconds: 2000));
    } catch (_) {}
  }

  final ValueNotifier<List<VenueChatMessage>> messagesNotifier =
      ValueNotifier<List<VenueChatMessage>>([]);

  List<VenueChatMessage> get messages => messagesNotifier.value;

  void reset() {
    final now = DateTime.now();
    messagesNotifier.value = [
      VenueChatMessage(
        id: 'msg_vchat_01',
        venueId: 'venue_01',
        venueName: 'CLB Cầu Lông Tao Đàn',
        customerId: 'user_player_01',
        customerName: 'Nguyễn Văn An',
        senderRole: 'customer',
        text: 'Dạ chào chủ sân, sân bên mình tối nay có sẵn vợt cho thuê không ạ?',
        timestamp: now.subtract(const Duration(minutes: 45)),
        isRead: true,
      ),
      VenueChatMessage(
        id: 'msg_vchat_02',
        venueId: 'venue_01',
        venueName: 'CLB Cầu Lông Tao Đàn',
        customerId: 'user_player_01',
        customerName: 'Nguyễn Văn An',
        senderRole: 'owner',
        text:
            'Chào bạn An! Sân Tao Đàn luôn có sẵn vợt Yonex chính hãng và nước điện giải tại quầy lễ tân nhé. Bạn cứ ghé quầy nhận sân là có!',
        timestamp: now.subtract(const Duration(minutes: 30)),
        isRead: true,
      ),
      VenueChatMessage(
        id: 'msg_vchat_03',
        venueId: 'venue_01',
        venueName: 'CLB Cầu Lông Tao Đàn',
        customerId: 'user_player_02',
        customerName: 'Trần Thị Mai',
        senderRole: 'customer',
        text: 'Anh ơi, sân số 3 đèn chiếu sáng có đủ tốt cho đánh đôi không anh?',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
    ];
  }

  /// Sends a message from customer or owner
  void sendMessage({
    required String venueId,
    required String venueName,
    required String customerId,
    required String customerName,
    required String senderRole,
    required String text,
  }) {
    if (text.trim().isEmpty) return;
    final newMsg = VenueChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      venueId: venueId,
      venueName: venueName,
      customerId: customerId,
      customerName: customerName,
      senderRole: senderRole,
      text: text.trim(),
      timestamp: DateTime.now(),
      isRead: false,
    );

    messagesNotifier.value = [...messagesNotifier.value, newMsg];
    _saveLocally();
    _dispatchServer(newMsg);

    // If customer sends a message, notify the venue owner and simulate an auto-reply
    if (senderRole == 'customer') {
      NotificationStore.instance.addNotification(
        AppNotification(
          id: 'notif_chat_${newMsg.id}',
          title: 'Tin nhắn mới từ $customerName 💬',
          message: '$customerName: "$text"',
          timestamp: DateTime.now(),
          type: NotificationType.system,
          role: NotificationRole.owner,
          isRead: false,
        ),
      );

      Future.delayed(const Duration(milliseconds: 1000), () {
        final autoReply = VenueChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_reply',
          venueId: venueId,
          venueName: venueName,
          customerId: customerId,
          customerName: customerName,
          senderRole: 'owner',
          text:
              'Dạ CLB $venueName xin chào bạn! Chúng tôi đã nhận được tin nhắn của bạn và sẽ phản hồi chi tiết ngay ạ.',
          timestamp: DateTime.now(),
          isRead: false,
        );
        messagesNotifier.value = [...messagesNotifier.value, autoReply];
        _saveLocally();
      });
    }
  }

  /// Returns messages for a specific conversation thread between a customer and venue
  List<VenueChatMessage> getThreadMessages({
    required String venueId,
    required String customerId,
  }) {
    return messagesNotifier.value
        .where((m) =>
            (venueId.isEmpty ||
                m.venueId == venueId ||
                (venueId == 'venue_01' && m.venueId == 'venue_q1_04') ||
                (venueId == 'venue_q1_04' && m.venueId == 'venue_01')) &&
            m.customerId == customerId)
        .toList();
  }

  /// Groups threads for the owner view
  List<({String customerId, String customerName, VenueChatMessage lastMessage, int unreadCount})>
      getOwnerThreads(String venueId) {
    final relevant = messagesNotifier.value.where((m) =>
        venueId.isEmpty ||
        m.venueId == venueId ||
        (venueId == 'venue_01' && m.venueId == 'venue_q1_04') ||
        (venueId == 'venue_q1_04' && m.venueId == 'venue_01') ||
        m.venueId.isNotEmpty);

    final Map<String, List<VenueChatMessage>> byCustomer = {};
    for (final m in relevant) {
      byCustomer.putIfAbsent(m.customerId, () => []).add(m);
    }

    final result = <({
      String customerId,
      String customerName,
      VenueChatMessage lastMessage,
      int unreadCount
    })>[];

    for (final entry in byCustomer.entries) {
      final thread = entry.value;
      if (thread.isEmpty) continue;
      thread.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final last = thread.last;
      final unread = thread.where((m) => m.isFromCustomer && !m.isRead).length;

      result.add((
        customerId: entry.key,
        customerName: last.customerName,
        lastMessage: last,
        unreadCount: unread,
      ));
    }

    // Sort latest conversation first
    result.sort(
        (a, b) => b.lastMessage.timestamp.compareTo(a.lastMessage.timestamp));
    return result;
  }
}
