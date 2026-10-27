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

/// Represents a specification for an editable field within an [ActionProposal].
class FormFieldSpec {
  final String key;
  final String label;
  final String type;
  final bool required;
  final int? maxLength;
  String currentValue;

  FormFieldSpec({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.maxLength,
    required this.currentValue,
  });

  factory FormFieldSpec.fromJson(Map<String, dynamic> json) {
    return FormFieldSpec(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      required: json['required'] as bool? ?? false,
      maxLength: json['maxLength'] is int
          ? json['maxLength'] as int
          : int.tryParse(json['maxLength']?.toString() ?? ''),
      currentValue: json['currentValue']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'type': type,
      'required': required,
      if (maxLength != null) 'maxLength': maxLength,
      'currentValue': currentValue,
    };
  }

  FormFieldSpec copyWith({
    String? key,
    String? label,
    String? type,
    bool? required,
    int? maxLength,
    String? currentValue,
  }) {
    return FormFieldSpec(
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      required: required ?? this.required,
      maxLength: maxLength ?? this.maxLength,
      currentValue: currentValue ?? this.currentValue,
    );
  }
}

/// Represents an action proposal emitted by the AI assistant in the HAIA architecture,
/// requiring Human-In-The-Loop (HITL) approval before state mutations are executed.
class ActionProposal {
  final String id;
  final String tool;
  String status; // 'pending' | 'approved' | 'rejected' | 'cancelled' | 'executed'
  final Map<String, dynamic> target;
  final List<FormFieldSpec> form;
  final int expiresAt;

  ActionProposal({
    required this.id,
    required this.tool,
    this.status = 'pending',
    required this.target,
    required this.form,
    required this.expiresAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved' || status == 'executed';
  bool get isRejected => status == 'rejected' || status == 'cancelled';
  bool get isExecuted => status == 'executed';
  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  factory ActionProposal.fromJson(Map<String, dynamic> json) {
    return ActionProposal(
      id: json['id']?.toString() ?? '',
      tool: json['tool']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      target: json['target'] is Map
          ? Map<String, dynamic>.from(json['target'] as Map)
          : <String, dynamic>{},
      form: (json['form'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => FormFieldSpec.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          <FormFieldSpec>[],
      expiresAt: json['expiresAt'] is int
          ? json['expiresAt'] as int
          : int.tryParse(json['expiresAt']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tool': tool,
      'status': status,
      'target': target,
      'form': form.map((e) => e.toJson()).toList(),
      'expiresAt': expiresAt,
    };
  }

  ActionProposal copyWith({
    String? id,
    String? tool,
    String? status,
    Map<String, dynamic>? target,
    List<FormFieldSpec>? form,
    int? expiresAt,
  }) {
    return ActionProposal(
      id: id ?? this.id,
      tool: tool ?? this.tool,
      status: status ?? this.status,
      target: target ?? this.target,
      form: form ?? this.form,
      expiresAt: expiresAt ?? this.expiresAt,
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
  final ActionProposal? proposal;

  ChatMessage({
    String? id,
    required this.text,
    String? sender,
    bool? isUser,
    DateTime? timestamp,
    this.actionCard,
    this.quickSuggestions,
    this.imageUrl,
    this.proposal,
  })  : id = id ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sender = sender ?? (isUser == true ? 'user' : 'assistant'),
        timestamp = timestamp ?? DateTime.now();

  bool get isUser => sender == 'user';
  bool get isAssistant => sender == 'assistant';
  bool get hasActionCard => actionCard != null;
  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;
  bool get hasProposal => proposal != null;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      sender: json['sender']?.toString() ?? 'assistant',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      actionCard: json['actionCard'] is Map
          ? Map<String, dynamic>.from(json['actionCard'] as Map)
          : null,
      quickSuggestions: (json['quickSuggestions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      imageUrl: json['imageUrl']?.toString(),
      proposal: json['proposal'] is Map
          ? ActionProposal.fromJson(Map<String, dynamic>.from(json['proposal'] as Map))
          : null,
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
      if (proposal != null) 'proposal': proposal!.toJson(),
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
    ActionProposal? proposal,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      actionCard: actionCard ?? this.actionCard,
      quickSuggestions: quickSuggestions ?? this.quickSuggestions,
      imageUrl: imageUrl ?? this.imageUrl,
      proposal: proposal ?? this.proposal,
    );
  }
}
