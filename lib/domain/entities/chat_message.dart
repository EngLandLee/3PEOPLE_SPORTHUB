/// Represents the user, screen, and venue context passed to the chatbot
/// for intelligent context-aware recommendations and booking actions.
class ChatContext {
  final String? userId;
  final String? userName;
  final String? userPhone;
  final String? userRole;
  final String? currentRoute;
  final String? venueId;
  final String? venueName;
  final String? sport;
  final List<String>? availableSlots;
  final bool? isGuest;
  final List<String>? recentBookingIds;

  const ChatContext({
    this.userId,
    this.userName,
    this.userPhone,
    this.userRole,
    this.currentRoute,
    this.venueId,
    this.venueName,
    String? sport,
    String? preferredSport,
    this.availableSlots,
    this.isGuest,
    this.recentBookingIds,
  }) : sport = sport ?? preferredSport;

  /// Alias getters for compatibility with various spec naming conventions
  String? get activeVenueId => venueId;
  String? get activeVenueName => venueName;
  String? get selectedSport => sport;
  String? get preferredSport => sport;

  factory ChatContext.fromJson(Map<String, dynamic> json) {
    return ChatContext(
      userId: json['userId']?.toString(),
      userName: json['userName']?.toString(),
      userPhone: json['userPhone']?.toString(),
      userRole: json['userRole']?.toString(),
      currentRoute: json['currentRoute']?.toString(),
      venueId: json['venueId']?.toString() ?? json['activeVenueId']?.toString(),
      venueName: json['venueName']?.toString() ?? json['activeVenueName']?.toString(),
      sport: json['sport']?.toString() ?? json['selectedSport']?.toString(),
      availableSlots: (json['availableSlots'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      isGuest: json['isGuest'] as bool?,
      recentBookingIds: (json['recentBookingIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (userId != null) map['userId'] = userId;
    if (userName != null) map['userName'] = userName;
    if (userPhone != null) map['userPhone'] = userPhone;
    if (userRole != null) map['userRole'] = userRole;
    if (currentRoute != null) map['currentRoute'] = currentRoute;
    if (venueId != null) map['venueId'] = venueId;
    if (venueName != null) map['venueName'] = venueName;
    if (sport != null) map['sport'] = sport;
    if (availableSlots != null) map['availableSlots'] = availableSlots;
    if (isGuest != null) map['isGuest'] = isGuest;
    if (recentBookingIds != null) map['recentBookingIds'] = recentBookingIds;
    return map;
  }

  ChatContext copyWith({
    String? userId,
    String? userName,
    String? userPhone,
    String? userRole,
    String? currentRoute,
    String? venueId,
    String? venueName,
    String? sport,
    String? preferredSport,
    List<String>? availableSlots,
    bool? isGuest,
    List<String>? recentBookingIds,
  }) {
    return ChatContext(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userRole: userRole ?? this.userRole,
      currentRoute: currentRoute ?? this.currentRoute,
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      sport: sport ?? preferredSport ?? this.sport,
      availableSlots: availableSlots ?? this.availableSlots,
      isGuest: isGuest ?? this.isGuest,
      recentBookingIds: recentBookingIds ?? this.recentBookingIds,
    );
  }
}

/// Represents an individual chat message in the conversation between user and AI assistant.
class ChatMessage {
  final String id;
  final String text;
  final String sender; // 'user' | 'assistant'
  final DateTime timestamp;
  final Map<String, dynamic>? actionCard;
  final List<String>? quickSuggestions;
  final String? imageUrl;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.actionCard,
    this.quickSuggestions,
    this.imageUrl,
  });

  bool get isUser => sender == 'user';
  bool get isAssistant => sender == 'assistant';
  bool get hasActionCard => actionCard != null;
  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      sender: json['sender']?.toString() ?? 'assistant',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      actionCard: json['actionCard'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['actionCard'] as Map)
          : null,
      quickSuggestions: (json['quickSuggestions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
      if (actionCard != null) 'actionCard': actionCard,
      if (quickSuggestions != null) 'quickSuggestions': quickSuggestions,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? text,
    String? sender,
    DateTime? timestamp,
    Map<String, dynamic>? actionCard,
    List<String>? quickSuggestions,
    String? imageUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      actionCard: actionCard ?? this.actionCard,
      quickSuggestions: quickSuggestions ?? this.quickSuggestions,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
