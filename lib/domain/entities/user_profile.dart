class UserProfile {
  final String userId;
  final String fullName;
  final String phone;
  final String preferredSport;
  final String skillLevel;
  final String district;
  final String playTimePreference;
  final int matchesPlayed;
  final double reputationRating;
  final int onTimeRate;

  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.preferredSport,
    required this.skillLevel,
    required this.district,
    required this.playTimePreference,
    this.matchesPlayed = 0,
    this.reputationRating = 5.0,
    this.onTimeRate = 100,
  });

  UserProfile copyWith({
    String? userId,
    String? fullName,
    String? phone,
    String? preferredSport,
    String? skillLevel,
    String? district,
    String? playTimePreference,
    int? matchesPlayed,
    double? reputationRating,
    int? onTimeRate,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      preferredSport: preferredSport ?? this.preferredSport,
      skillLevel: skillLevel ?? this.skillLevel,
      district: district ?? this.district,
      playTimePreference: playTimePreference ?? this.playTimePreference,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      reputationRating: reputationRating ?? this.reputationRating,
      onTimeRate: onTimeRate ?? this.onTimeRate,
    );
  }
}
