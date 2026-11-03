import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/state/venue_chat_store.dart';
import '../../../core/state/venue_owner_store.dart';

/// Tab for Venue Owner to view and respond to real-time customer chat inquiries
class OwnerChatTab extends StatefulWidget {
  const OwnerChatTab({super.key});

  @override
  State<OwnerChatTab> createState() => _OwnerChatTabState();
}

class _OwnerChatTabState extends State<OwnerChatTab> {
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String? _selectedVenueId;
  String? _selectedVenueName;
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _sendReply(String venueId, String venueName) {
    final text = _replyController.text.trim();
    if (text.isEmpty || _selectedCustomerId == null) return;
    _replyController.clear();

    VenueChatStore.instance.sendMessage(
      venueId: _selectedVenueId ?? venueId,
      venueName: _selectedVenueName ?? venueName,
      customerId: _selectedCustomerId!,
      customerName: _selectedCustomerName ?? 'Khách hàng',
      senderRole: 'owner',
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final venueId = VenueOwnerStore.instance.activeVenueId;
    final venueName = VenueOwnerStore.instance.activeVenueName;

    return ValueListenableBuilder<List<VenueChatMessage>>(
      valueListenable: VenueChatStore.instance.messagesNotifier,
      builder: (context, messages, _) {
        final threads = VenueChatStore.instance.getOwnerThreads(venueId);

        if (_selectedCustomerId != null) {
          final effectiveVenueId = _selectedVenueId ?? venueId;
          final effectiveVenueName = _selectedVenueName ?? venueName;
          final threadMessages = VenueChatStore.instance.getThreadMessages(
            venueId: effectiveVenueId,
            customerId: _selectedCustomerId!,
          );

          return _buildConversationDetail(
            venueId: effectiveVenueId,
            venueName: effectiveVenueName,
            customerName: _selectedCustomerName ?? 'Khách hàng',
            messages: threadMessages,
          );
        }

        return _buildThreadList(threads, venueName);
      },
    );
  }

  Widget _buildThreadList(
    List<({String customerId, String customerName, VenueChatMessage lastMessage, int unreadCount})>
        threads,
    String venueName,
  ) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.cardBorder),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_chat_unread_rounded,
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
                      'Hộp thư Khách hàng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Trao đổi trực tiếp 1-1 với khách đặt tại $venueName',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${threads.length} cuộc hội thoại',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: threads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có tin nhắn nào từ khách hàng',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: threads.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppColors.cardBorder),
                  itemBuilder: (context, index) {
                    final t = threads[index];
                    final isCustomer = t.lastMessage.isFromCustomer;
                    final time =
                        '${t.lastMessage.timestamp.hour.toString().padLeft(2, '0')}:${t.lastMessage.timestamp.minute.toString().padLeft(2, '0')}';

                    return ListTile(
                      key: Key('owner_chat_thread_${t.customerId}'),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          t.customerName.isNotEmpty
                              ? t.customerName[0].toUpperCase()
                              : 'K',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.customerName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            if (!isCustomer) ...[
                              Icon(Icons.done_all_rounded,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                t.lastMessage.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: t.unreadCount > 0
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontWeight: t.unreadCount > 0
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (t.unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${t.unreadCount}',
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
                          _selectedCustomerId = t.customerId;
                          _selectedCustomerName = t.customerName;
                          _selectedVenueId = t.lastMessage.venueId;
                          _selectedVenueName = t.lastMessage.venueName;
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildConversationDetail({
    required String venueId,
    required String venueName,
    required String customerName,
    required List<VenueChatMessage> messages,
  }) {
    return Column(
      children: [
        // App bar for thread detail
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Row(
            children: [
              IconButton(
                key: const Key('btn_back_to_threads'),
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() {
                    _selectedCustomerId = null;
                    _selectedCustomerName = null;
                  });
                },
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  customerName.isNotEmpty ? customerName[0].toUpperCase() : 'K',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Khách đặt tại $venueName',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Message List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final m = messages[index];
              final isMe = m.isFromOwner;
              final time =
                  '${m.timestamp.hour.toString().padLeft(2, '0')}:${m.timestamp.minute.toString().padLeft(2, '0')}';

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isMe
                          ? Colors.transparent
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.text,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isMe ? AppColors.onPrimary : AppColors.textPrimary,
                          height: 1.3,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.cardBorder)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('owner_chat_reply_input'),
                    controller: _replyController,
                    onSubmitted: (_) => _sendReply(venueId, venueName),
                    decoration: InputDecoration(
                      hintText: 'Nhập câu trả lời cho khách hàng...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('btn_owner_send_reply'),
                  icon: Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: () => _sendReply(venueId, venueName),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
