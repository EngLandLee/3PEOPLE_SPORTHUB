import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/services/matchmaking_service.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/domain/entities/user_profile.dart';

void main() {
  group('MatchmakingService', () {
    test('computeLocalFallback computes high match score for matching sport, district and skill', () {
      final user = const UserProfile(
        userId: 'user_test_01',
        fullName: 'Test Player',
        phone: '0901234567',
        preferredSport: 'badminton',
        skillLevel: 'Trung bình',
        district: 'Bình Thạnh',
        playTimePreference: 'Buổi tối (18:00 - 21:00)',
      );

      final recs = MatchmakingService.instance.computeLocalFallback(
        user,
        SeedData.sampleCommunityPosts,
      );

      expect(recs.isNotEmpty, isTrue);
      final topMatch = recs.first;
      expect(topMatch.postId, 'post_01');
      expect(topMatch.matchScore, greaterThanOrEqualTo(80));
      expect(topMatch.compatibilityLevel, 'HIGH');
      expect(topMatch.matchReason, contains('Bình Thạnh'));
      expect(topMatch.matchReason, contains('Cầu lông'));
    });

    test('recommends single opponent for 2-player posts and double for 4-player posts', () {
      final userPickleball = const UserProfile(
        userId: 'user_test_02',
        fullName: 'Pickleball Fan',
        phone: '0907654321',
        preferredSport: 'pickleball',
        skillLevel: 'Nâng cao',
        district: 'Thủ Đức',
        playTimePreference: 'Buổi tối (18:00 - 21:00)',
      );

      final recs = MatchmakingService.instance.computeLocalFallback(
        userPickleball,
        SeedData.sampleCommunityPosts,
      );

      final post02Rec = recs.firstWhere((r) => r.postId == 'post_02');
      expect(post02Rec.matchReason, contains('đồng đội đánh đôi'));
    });

    test('excludes closed or full posts', () {
      final user = const UserProfile(
        userId: 'user_test_03',
        fullName: 'Football Fan',
        phone: '0909999999',
        preferredSport: 'football',
        skillLevel: 'Trung bình',
        district: 'Quận 7',
        playTimePreference: 'Buổi tối (18:00 - 21:00)',
      );

      final fullPosts = SeedData.sampleCommunityPosts.map((p) => p.copyWith(isClosed: true)).toList();
      final recs = MatchmakingService.instance.computeLocalFallback(user, fullPosts);
      expect(recs.isEmpty, isTrue);
    });
  });
}
