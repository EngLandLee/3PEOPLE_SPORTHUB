class UserProfile {
  final String userId;
  final String fullName;
  final String phone;
  final String email;
  final String role; // 'player' | 'partner' | 'owner'
  final String preferredSport;
  final String skillLevel;
  final String district;
  final String playTimePreference;
  final int matchesPlayed;
  final double reputationRating;
  final int onTimeRate;
  final String? venueId;

  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.phone,
    this.email = '',
    this.role = 'player',
    required this.preferredSport,
    required this.skillLevel,
    required this.district,
    required this.playTimePreference,
    this.matchesPlayed = 0,
    this.reputationRating = 5.0,
    this.onTimeRate = 100,
    this.venueId,
  });

  bool get isOwner =>
      role == 'owner' ||
      role == 'partner' ||
      role == 'admin' ||
      role == 'superadmin' ||
      userId == 'user_owner_01' ||
      userId == 'user_admin_01';
  bool get isPlayer => !isOwner;

  UserProfile copyWith({
    String? userId,
    String? fullName,
    String? phone,
    String? email,
    String? role,
    String? preferredSport,
    String? skillLevel,
    String? district,
    String? playTimePreference,
    int? matchesPlayed,
    double? reputationRating,
    int? onTimeRate,
    String? venueId,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      preferredSport: preferredSport ?? this.preferredSport,
      skillLevel: skillLevel ?? this.skillLevel,
      district: district ?? this.district,
      playTimePreference: playTimePreference ?? this.playTimePreference,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      reputationRating: reputationRating ?? this.reputationRating,
      onTimeRate: onTimeRate ?? this.onTimeRate,
      venueId: venueId ?? this.venueId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'role': role,
      'preferredSport': preferredSport,
      'skillLevel': skillLevel,
      'district': district,
      'playTimePreference': playTimePreference,
      'matchesPlayed': matchesPlayed,
      'reputationRating': reputationRating,
      'onTimeRate': onTimeRate,
      'venueId': venueId,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'player',
      preferredSport: json['preferredSport']?.toString() ?? json['preferred_sport']?.toString() ?? 'badminton',
      skillLevel: json['skillLevel']?.toString() ?? json['skill_level']?.toString() ?? 'Beginner',
      district: json['district']?.toString() ?? 'Quận 1',
      playTimePreference: json['playTimePreference']?.toString() ?? 'Buổi tối (18:00 - 21:00)',
      matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
      reputationRating: (json['reputationRating'] as num?)?.toDouble() ?? 5.0,
      onTimeRate: (json['onTimeRate'] as num?)?.toInt() ?? 100,
      venueId: json['venueId']?.toString() ?? json['venue_id']?.toString(),
    );
  }
}
