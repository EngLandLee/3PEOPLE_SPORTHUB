import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/chatbot_service.dart';
import 'chat_booking_card.dart';
import 'chat_table_card.dart';

/// A chat bubble widget representing either user or assistant messages.
/// Features distinct avatar identifiers, subtle timestamping,
/// streaming typewriter effects for AI replies, and animated card transitions.
class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onBookNow;
  final void Function(Map<String, dynamic> actionCard)? onViewCourtMap;
  final bool? enableAnimation;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onBookNow,
    this.onViewCourtMap,
    this.enableAnimation,
  });

  /// Cache of message IDs that have already finished their entrance / typing animation
  static final Set<String> _revealedMessageIds = <String>{};

  /// Clears animation cache (used on session resets)
  static void resetRevealedCache() {
    _revealedMessageIds.clear();
  }

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with TickerProviderStateMixin {
  late int _displayedChars;
  late bool _isTypingComplete;
  Timer? _typewriterTimer;

  late final AnimationController _entranceController;
  late final AnimationController _cardController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool get _shouldAnimate {
    if (widget.enableAnimation != null) {
      return widget.enableAnimation!;
    }
    // Automatically disable in test environments to avoid pumpAndSettle timeouts
    if (ChatbotService.instance.isTestEnvironment) {
      return false;
    }
    // Only animate new assistant messages
    return widget.message.isAssistant &&
        !ChatMessageBubble._revealedMessageIds.contains(widget.message.id);
  }

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    if (_shouldAnimate) {
      _displayedChars = 0;
      _isTypingComplete = false;
      _entranceController.forward();
      _startTypewriter();
    } else {
      _displayedChars = widget.message.text.length;
      _isTypingComplete = true;
      _entranceController.value = 1.0;
      _cardController.value = 1.0;
      ChatMessageBubble._revealedMessageIds.add(widget.message.id);
    }
  }

  @override
  void didUpdateWidget(ChatMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id ||
        oldWidget.message.text != widget.message.text) {
      if (_shouldAnimate) {
        _displayedChars = 0;
        _isTypingComplete = false;
        _startTypewriter();
      } else {
        _displayedChars = widget.message.text.length;
        _isTypingComplete = true;
        _cardController.value = 1.0;
      }
    }
  }

  void _startTypewriter() {
    _typewriterTimer?.cancel();
    final fullText = widget.message.text;

    if (fullText.isEmpty) {
      _finishTyping();
      return;
    }

    // Progressive streaming: 2-3 characters every 14ms (fast, natural AI typing)
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 14), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _displayedChars = (_displayedChars + 3).clamp(0, fullText.length);
        if (_displayedChars >= fullText.length) {
          _finishTyping();
        }
      });
    });
  }

  void _finishTyping() {
    _typewriterTimer?.cancel();
    _displayedChars = widget.message.text.length;
    _isTypingComplete = true;
    ChatMessageBubble._revealedMessageIds.add(widget.message.id);
    if (mounted) {
      _cardController.forward();
      setState(() {});
    }
  }

  void _skipAnimation() {
    if (!_isTypingComplete) {
      _finishTyping();
      _cardController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _entranceController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<TextSpan> _parseMarkdownSpans(String text, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final regExp = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;
    for (final match in regExp.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));
      lastIndex = match.end;
    }
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }
    return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    final timeStr = _formatTimestamp(widget.message.timestamp);
    final hasBookingCard = widget.message.hasActionCard &&
        (widget.message.actionCard?['type'] == null ||
            widget.message.actionCard?['type'] == 'booking_card');
    final hasTableCard = widget.message.hasActionCard &&
        widget.message.actionCard?['type'] == 'table_card';

    final avatar = CircleAvatar(
      radius: 14,
      backgroundColor: isUser
          ? AppColors.primary.withValues(alpha: 0.18)
          : AppColors.primary.withValues(alpha: 0.15),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 16,
        color: AppColors.primary,
      ),
    );

    final currentSubstr = _displayedChars < widget.message.text.length
        ? widget.message.text.substring(0, _displayedChars)
        : widget.message.text;

    final bubbleContent = GestureDetector(
      onTap: _skipAnimation,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.message.hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                    maxWidth: 260,
                  ),
                  child: Image.network(
                    widget.message.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      width: 200,
                      color: AppColors.cardBorder.withValues(alpha: 0.2),
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.message.text.isNotEmpty) const SizedBox(height: 8),
            ],
            if (widget.message.text.isNotEmpty)
              Text.rich(
                TextSpan(
                  children: [
                    ..._parseMarkdownSpans(
                      currentSubstr,
                      TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    if (!_isTypingComplete && widget.message.isAssistant)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          width: 2.5,
                          height: 14,
                          margin: const EdgeInsets.only(left: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    final mainBubble = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            avatar,
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82,
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  bubbleContent,
                  if (hasBookingCard) ...[
                    const SizedBox(height: 8),
                    if (_isTypingComplete)
                      FadeTransition(
                        opacity: _cardController,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _cardController,
                            curve: Curves.easeOutCubic,
                          )),
                          child: ChatBookingCard(
                            actionCard: widget.message.actionCard!,
                            onBookNow: widget.onBookNow,
                            onViewCourtMap: widget.onViewCourtMap,
                          ),
                        ),
                      ),
                  ],
                  if (hasTableCard) ...[
                    const SizedBox(height: 8),
                    if (_isTypingComplete)
                      FadeTransition(
                        opacity: _cardController,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _cardController,
                            curve: Curves.easeOutCubic,
                          )),
                          child: ChatTableCard(
                            cardData: widget.message.actionCard!,
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            avatar,
          ],
        ],
      ),
    );

    if (!_shouldAnimate) {
      return mainBubble;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: mainBubble,
      ),
    );
  }
}
