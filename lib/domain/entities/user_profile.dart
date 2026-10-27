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
}
