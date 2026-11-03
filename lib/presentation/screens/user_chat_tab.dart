import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/auth_store.dart';
import '../../core/state/venue_chat_store.dart';
import '../../core/utils/seed_data.dart';
import '../../domain/entities/venue.dart';
import '../widgets/chat/chatbot_bottom_sheet.dart';

/// Dedicated Chat Tab for regular users/players to manage conversations with Venue Owners and AI Assistant
class UserChatTab extends StatefulWidget {
  const UserChatTab({super.key});

  @override
  State<UserChatTab> createState() => _UserChatTabState();
}

class _UserChatTabState extends State<UserChatTab> {
  String? _selectedVenueId;
  String? _selectedVenueName;
  final TextEditingController _messageInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String venueId, String venueName, String customerId, String customerName) {
    final text = _messageInputController.text.trim();
    if (text.isEmpty) return;
    _messageInputController.clear();

    VenueChatStore.instance.sendMessage(
      venueId: venueId,
      venueName: venueName,
      customerId: customerId,
      customerName: customerName,
      senderRole: 'customer',
      text: text,
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.instance.currentUser;
    final customerId = user?.userId ?? 'user_player_01';
    final customerName = user?.fullName ?? 'Khách đặt sân';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Hộp thư Tin nhắn',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Trợ lý AI SportHub',
            icon: Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
            onPressed: () => ChatbotBottomSheet.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ValueListenableBuilder<List<VenueChatMessage>>(
        valueListenable: VenueChatStore.instance.messagesNotifier,
        builder: (context, allMessages, _) {
          if (_selectedVenueId != null) {
            final threadMessages = VenueChatStore.instance.getThreadMessages(
              venueId: _selectedVenueId!,
              customerId: customerId,
            );

            return _buildDirectChatView(
              venueId: _selectedVenueId!,
              venueName: _selectedVenueName ?? 'Chủ sân',
              customerId: customerId,
              customerName: customerName,
              messages: threadMessages,
            );
          }

          return _buildChatListView(context, customerId, allMessages);
        },
      ),
    );
  }

  Widget _buildChatListView(BuildContext context, String customerId, List<VenueChatMessage> allMessages) {
    // Collect unique venues customer has messaged with
    final customerMessages = allMessages.where((m) => m.customerId == customerId).toList();
    final Map<String, List<VenueChatMessage>> byVenue = {};
    for (final m in customerMessages) {
      byVenue.putIfAbsent(m.venueId, () => []).add(m);
    }

    // Default sample venues to start chat if empty
    final suggestedVenues = SeedData.sampleVenues.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // AI Assistant Card Banner
        _buildAiAssistantBanner(context),
        const SizedBox(height: 18),

        // Section Title: Trò chuyện với Chủ sân
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Trò chuyện với Chủ Sân & CLB',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (byVenue.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${byVenue.length} câu lạc bộ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        if (byVenue.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Icon(Icons.forum_outlined, size: 40, color: AppColors.textSecondary),
                const SizedBox(height: 8),
                Text(
                  'Bạn chưa có cuộc trò chuyện nào với chủ sân',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn một sân thể thao bên dưới để bắt đầu liên hệ hỏi lịch hoặc thuê dụng cụ!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Gợi ý cơ sở hỗ trợ phản hồi nhanh:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...suggestedVenues.map((v) => _buildSuggestedVenueCard(v)),
        ] else ...[
          ...byVenue.entries.map((entry) {
            final venueId = entry.key;
            final thread = entry.value;
            thread.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            final lastMsg = thread.last;
            final unreadCount = thread.where((m) => m.isFromOwner && !m.isRead).length;

            return _buildVenueThreadTile(
              venueId: venueId,
              venueName: lastMsg.venueName,
              lastMsg: lastMsg,
              unreadCount: unreadCount,
            );
          }),
          const SizedBox(height: 16),
          Text(
            'Liên hệ câu lạc bộ khác:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...suggestedVenues
              .where((v) => !byVenue.containsKey(v.id))
              .map((v) => _buildSuggestedVenueCard(v)),
        ],
      ],
    );
  }

  Widget _buildAiAssistantBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      'Trợ lý AI SportHub',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '24/7 ONLINE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tư vấn lịch sân, luật chơi, gợi ý đối thủ ghép kèo & giải đáp thắc mắc tức thì.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: const Key('btn_open_ai_chat_from_tab'),
            onPressed: () => ChatbotBottomSheet.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Chat ngay',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueThreadTile({
    required String venueId,
    required String venueName,
    required VenueChatMessage lastMsg,
    required int unreadCount,
  }) {
    final time =
        '${lastMsg.timestamp.hour.toString().padLeft(2, '0')}:${lastMsg.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        key: Key('user_chat_thread_$venueId'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                venueName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              time,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              if (lastMsg.isFromCustomer) ...[
                Icon(Icons.done_all_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  lastMsg.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
        ),
        onTap: () {
          setState(() {
            _selectedVenueId = venueId;
            _selectedVenueName = venueName;
          });
        },
      ),
    );
  }

  Widget _buildSuggestedVenueCard(Venue venue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.cardBorder.withValues(alpha: 0.5),
          child: Icon(Icons.sports_tennis_rounded, color: AppColors.primary, size: 20),
        ),
        title: Text(
          venue.name,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          venue.address,
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: OutlinedButton(
          onPressed: () {
            setState(() {
              _selectedVenueId = venue.id;
              _selectedVenueName = venue.name;
            });
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            'Nhắn tin',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectChatView({
    required String venueId,
    required String venueName,
    required String customerId,
    required String customerName,
    required List<VenueChatMessage> messages,
  }) {
    return Column(
      children: [
        // Top Back Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => setState(() => _selectedVenueId = null),
              ),
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Icon(Icons.storefront_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venueName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Chủ sân đang hoạt động',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Chat Messages List
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 44, color: AppColors.textSecondary),
                      const SizedBox(height: 10),
                      Text(
                        'Bắt đầu nhắn tin với $venueName',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, idx) {
                    final m = messages[idx];
                    final isMe = m.isFromCustomer;
                    final time =
                        '${m.timestamp.hour.toString().padLeft(2, '0')}:${m.timestamp.minute.toString().padLeft(2, '0')}';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                          border: Border.all(
                            color: isMe ? Colors.transparent : AppColors.cardBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.text,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isMe ? AppColors.onPrimary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe
                                    ? AppColors.onPrimary.withValues(alpha: 0.7)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Input bar
        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.cardBorder)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('user_chat_input_field'),
                    controller: _messageInputController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(venueId, venueName, customerId, customerName),
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn cho $venueName...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('btn_send_user_chat'),
                  icon: Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: () => _sendMessage(venueId, venueName, customerId, customerName),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
