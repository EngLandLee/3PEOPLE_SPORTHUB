import '../../domain/entities/sport_zone.dart';
import '../../domain/entities/venue.dart';

class CourtSportPartition {
  CourtSportPartition._();

  static String getSportForCourt({
    required Venue venue,
    required int courtNumber,
  }) {
    if (venue.sportTypes.isEmpty) return 'badminton';
    if (venue.sportTypes.length == 1) return venue.sportTypes.first;

    // Specific partition for Tân Bình Arena (10 courts, 3 sports)
    if (venue.id == 'venue_tb_05' || venue.courtCount == 10) {
      if (courtNumber <= 4) return 'badminton';
      if (courtNumber <= 7) return 'pickleball';
      return 'football';
    }

    // Generic proportional partition
    final count = venue.sportTypes.length;
    final index = ((courtNumber - 1) * count ~/ venue.courtCount).clamp(0, count - 1);
    return venue.sportTypes[index];
  }

  static List<int> getCourtsForSport({
    required Venue venue,
    required String sportType,
  }) {
    if (sportType == 'all') {
      return List.generate(venue.courtCount, (i) => i + 1);
    }
    return List.generate(venue.courtCount, (i) => i + 1)
        .where((c) => getSportForCourt(venue: venue, courtNumber: c) == sportType)
        .toList();
  }

  static List<SportZone> getZonesForVenue(Venue venue) {
    if (venue.sportTypes.length <= 1) {
      final sport = venue.sportTypes.isNotEmpty ? venue.sportTypes.first : 'badminton';
      final label = _sportLabel(sport);
      final String priceRange;
      if (sport == 'football') {
        priceRange = '250k - 420k';
      } else if (sport == 'pickleball') {
        priceRange = '130k - 220k';
      } else {
        final base = venue.hourlyRate > 0 ? venue.hourlyRate : 160000.0;
        priceRange = '${(base * 0.5 / 1000).toInt()}k - ${(base * 1.125 / 1000).toInt()}k';
      }
      return [
        SportZone(
          zoneId: 'zone_${venue.id}_$sport',
          sportType: sport,
          zoneName: 'Cụm Sân $label',
          facilityDescription: 'Tiêu chuẩn thi đấu chất lượng cao',
          badgeText: 'Chuyên nghiệp',
          courtNumbers: List.generate(venue.courtCount, (i) => i + 1),
          priceRangeDisplay: priceRange,
        ),
      ];
    }

    final List<SportZone> zones = [];
    final charA = 'A'.codeUnitAt(0);
    int index = 0;

    // Order sports by their first court number so physical zones follow court numbering
    final sports = List<String>.from(venue.sportTypes);
    sports.sort((a, b) {
      final aCourts = getCourtsForSport(venue: venue, sportType: a);
      final bCourts = getCourtsForSport(venue: venue, sportType: b);
      final aMin = aCourts.isEmpty ? 999 : aCourts.first;
      final bMin = bCourts.isEmpty ? 999 : bCourts.first;
      return aMin.compareTo(bMin);
    });

    for (final sport in sports) {
      final courts = getCourtsForSport(venue: venue, sportType: sport);
      if (courts.isEmpty) continue;

      final zoneLetter = String.fromCharCode(charA + index);
      final String zoneName;
      final String facilityDesc;
      final String badgeText;
      final String priceRange;

      if (sport == 'football') {
        zoneName = 'Phân khu $zoneLetter: Cụm Sân Bóng Đá Mini';
        facilityDesc = 'Mặt cỏ nhân tạo FIFA Pro • Đèn cao áp • Lưới vây 8m';
        badgeText = 'Ngoài trời';
        priceRange = '250k - 420k';
      } else if (sport == 'pickleball') {
        zoneName = 'Phân khu $zoneLetter: Cụm Sân Pickleball Pro';
        facilityDesc = 'Mặt sơn USAPA giảm chấn • Mái che thoáng khí';
        badgeText = 'Có mái che';
        priceRange = '130k - 220k';
      } else {
        zoneName = 'Phân khu $zoneLetter: Cụm Sân Cầu Lông Tiêu Chuẩn';
        facilityDesc = 'Nhà thi đấu máy lạnh • Thảm BWF chống trượt';
        badgeText = 'Trong nhà';
        final base = venue.hourlyRate > 0 ? venue.hourlyRate : 160000.0;
        priceRange = '${(base * 0.5 / 1000).toInt()}k - ${(base * 1.125 / 1000).toInt()}k';
      }

      zones.add(
        SportZone(
          zoneId: 'zone_${venue.id}_$sport',
          sportType: sport,
          zoneName: zoneName,
          facilityDescription: facilityDesc,
          badgeText: badgeText,
          courtNumbers: courts,
          priceRangeDisplay: priceRange,
        ),
      );
      index++;
    }

    return zones;
  }

  static String _sportLabel(String sport) {
    switch (sport) {
      case 'badminton':
        return 'Cầu Lông';
      case 'pickleball':
        return 'Pickleball';
      case 'football':
        return 'Bóng Đá';
      default:
        return sport;
    }
  }
}

