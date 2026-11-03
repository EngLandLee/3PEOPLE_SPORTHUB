class MatchRecommendation {
  final String postId;
  final int matchScore;
  final String compatibilityLevel;
  final String matchReason;

  const MatchRecommendation({
    required this.postId,
    required this.matchScore,
    required this.compatibilityLevel,
    required this.matchReason,
  });

  factory MatchRecommendation.fromJson(Map<String, dynamic> json) {
    return MatchRecommendation(
      postId: (json['postId'] ?? json['id'] ?? '').toString(),
      matchScore: (json['matchScore'] as num?)?.toInt() ?? 80,
      compatibilityLevel: (json['compatibilityLevel'] ?? 'HIGH').toString(),
      matchReason: (json['matchReason'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'matchScore': matchScore,
      'compatibilityLevel': compatibilityLevel,
      'matchReason': matchReason,
    };
  }
}
