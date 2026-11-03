import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/match_recommendation.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/entities/user_profile.dart';
import 'venue_sync_service.dart';

class MatchmakingService {
  MatchmakingService._internal();
  static final MatchmakingService instance = MatchmakingService._internal();

  http.Client client = http.Client();

  Future<List<MatchRecommendation>> getRecommendations({
    required UserProfile userProfile,
    required List<CommunityPost> posts,
  }) async {
    // 1. Try calling backend matchmaking endpoint (connected to local Qwen)
    try {
      final backendUrl = VenueSyncService.instance.serverBaseUrl;
      final uri = Uri.parse('$backendUrl/api/matchmaking/recommendations');
      final payload = {
        'userProfile': {
          'userId': userProfile.userId,
          'fullName': userProfile.fullName,
          'preferredSport': userProfile.preferredSport,
          'district': userProfile.district,
          'skillLevel': userProfile.skillLevel,
          'playTimePreference': userProfile.playTimePreference,
        },
        'posts': posts.map((p) => {
          'id': p.id,
          'title': p.title,
          'sportType': p.sportType,
          'district': p.district,
          'skillLevel': p.skillLevel,
          'venueName': p.venueName,
          'scheduledTime': p.scheduledTime,
          'requiredPlayers': p.requiredPlayers,
          'currentPlayers': p.currentPlayers,
          'isClosed': p.isClosed,
        }).toList(),
      };

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(milliseconds: 3500));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map && data['recommendations'] is List) {
          final list = (data['recommendations'] as List)
              .map((e) => MatchRecommendation.fromJson(e as Map<String, dynamic>))
              .where((r) => r.postId.isNotEmpty)
              .toList();
          if (list.isNotEmpty) return list;
        }
      }
    } catch (_) {
      // Backend / Ollama offline or timed out, fall through to native local engine
    }

    // 2. Direct Ollama candidates on host / emulator (if accessible directly)
    final candidateUrls = [
      'http://10.0.2.2:11434',
      'http://localhost:11434',
    ];

    for (final baseUrl in candidateUrls) {
      try {
        final prompt = 'Bạn là AI chuyên gia ghép kèo thể thao SportHub. So khớp người chơi với các bài đăng thể thao. Trả về đúng JSON format: {"recommendations": [{"postId": "id", "matchScore": 95, "compatibilityLevel": "HIGH", "matchReason": "giải thích ngắn gọn 1 câu tiếng Việt"}]}';
        final userMsg = 'Người chơi: ${jsonEncode({
          'preferredSport': userProfile.preferredSport,
          'district': userProfile.district,
          'skillLevel': userProfile.skillLevel,
        })}\nDanh sách kèo: ${jsonEncode(posts.take(6).map((p) => {
          'id': p.id,
          'sportType': p.sportType,
          'district': p.district,
          'skillLevel': p.skillLevel,
          'requiredPlayers': p.requiredPlayers,
          'currentPlayers': p.currentPlayers,
        }).toList())}';

        final res = await client.post(
          Uri.parse('$baseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': 'qwen2.5:1.5b',
            'stream': false,
            'format': 'json',
            'messages': [
              {'role': 'system', 'content': prompt},
              {'role': 'user', 'content': userMsg},
            ],
            'options': {'temperature': 0.3},
          }),
        ).timeout(const Duration(milliseconds: 3000));

        if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          final content = data['message']?['content']?.toString();
          if (content != null && content.isNotEmpty) {
            final parsed = jsonDecode(content);
            final rawList = parsed is List ? parsed : (parsed['recommendations'] as List?);
            if (rawList != null && rawList.isNotEmpty) {
              return rawList
                  .map((e) => MatchRecommendation.fromJson(e as Map<String, dynamic>))
                  .where((r) => r.postId.isNotEmpty)
                  .toList();
            }
          }
        }
      } catch (_) {
        // try next candidate or fallback
      }
    }

    // 3. Native on-device heuristic engine (Instant, 100% offline, guaranteed smooth)
    return computeLocalFallback(userProfile, posts);
  }

  List<MatchRecommendation> computeLocalFallback(
    UserProfile user,
    List<CommunityPost> posts,
  ) {
    final userSport = user.preferredSport.toLowerCase().trim();
    final userDistrict = user.district.toLowerCase().trim();
    final userSkill = user.skillLevel.toLowerCase().trim();

    final candidates = posts.where((p) {
      if (p.isClosed) return false;
      if (p.isFull) return false;
      if (p.authorId == user.userId) return false;
      return true;
    }).toList();

    final scored = candidates.map((post) {
      int score = 45;
      final postSport = post.sportType.toLowerCase().trim();
      final postDistrict = post.district.toLowerCase().trim();
      final postSkill = post.skillLevel.toLowerCase().trim();

      // Sport match (+35)
      if (userSport.isNotEmpty && (postSport.contains(userSport) || userSport.contains(postSport))) {
        score += 35;
      }

      // District match (+25)
      if (userDistrict.isNotEmpty && (postDistrict.contains(userDistrict) || userDistrict.contains(postDistrict))) {
        score += 25;
      } else if (_isNeighborDistrict(userDistrict, postDistrict)) {
        score += 15;
      }

      // Skill level (+20)
      if (userSkill.isNotEmpty && (postSkill.contains(userSkill) || userSkill.contains(postSkill))) {
        score += 20;
      } else {
        score += 10;
      }

      // Time match (+10)
      if (user.playTimePreference.toLowerCase().contains('tối') &&
          post.scheduledTime.toLowerCase().contains('tối')) {
        score += 10;
      }

      if (score > 98) score = 98;

      String kind;
      if (post.requiredPlayers == 2) {
        kind = 'đối thủ solo 1-1';
      } else if (post.requiredPlayers == 4) {
        kind = 'đồng đội đánh đôi';
      } else {
        kind = 'đội nhóm';
      }

      final reason = 'Gợi ý $kind: Cùng chơi ${_sportDisplay(post.sportType)} tại ${post.district}, trình độ ${post.skillLevel} ngang tài ngang sức!';

      return MatchRecommendation(
        postId: post.id,
        matchScore: score,
        compatibilityLevel: score >= 80 ? 'HIGH' : 'MEDIUM',
        matchReason: reason,
      );
    }).toList();

    scored.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return scored.take(5).toList();
  }

  bool _isNeighborDistrict(String a, String b) {
    const neighbors = {
      'bình thạnh': ['quận 1', 'phú nhuận', 'gò vấp', 'thủ đức', 'quận 2'],
      'quận 1': ['quận 3', 'quận 4', 'bình thạnh', 'quận 5'],
      'thủ đức': ['quận 2', 'quận 9', 'bình thạnh'],
      'quận 7': ['quận 4', 'quận 8', 'nhà bè'],
    };
    for (final entry in neighbors.entries) {
      if (a.contains(entry.key)) {
        return entry.value.any((n) => b.contains(n));
      }
    }
    return false;
  }

  String _sportDisplay(String sport) {
    switch (sport.toLowerCase()) {
      case 'badminton':
        return 'Cầu lông';
      case 'pickleball':
        return 'Pickleball';
      case 'football':
        return 'Bóng đá';
      case 'tennis':
        return 'Tennis';
      default:
        return sport;
    }
  }
}
