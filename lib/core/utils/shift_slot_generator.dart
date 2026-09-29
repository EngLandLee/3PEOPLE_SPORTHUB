import '../../domain/entities/time_slot.dart';
import '../../domain/entities/venue.dart';
import 'court_sport_partition.dart';

/// Utility class to dynamically generate realistic [TimeSlot] lists for courts
/// based on shift ('morning', 'afternoon', 'evening') and minute offset (':00' vs ':30').
class ShiftSlotGenerator {
  ShiftSlotGenerator._();

  static const List<(String, String)> _morning00 = [
    ('06:00', '07:00'),
    ('07:00', '08:00'),
    ('08:00', '09:00'),
    ('09:00', '10:00'),
    ('10:00', '11:00'),
    ('11:00', '12:00'),
  ];

  static const List<(String, String)> _morning30 = [
    ('06:30', '07:30'),
    ('07:30', '08:30'),
    ('08:30', '09:30'),
    ('09:30', '10:30'),
    ('10:30', '11:30'),
    ('11:30', '12:30'),
  ];

  static const List<(String, String)> _afternoon00 = [
    ('12:00', '13:00'),
    ('13:00', '14:00'),
    ('14:00', '15:00'),
    ('15:00', '16:00'),
    ('16:00', '17:00'),
  ];

  static const List<(String, String)> _afternoon30 = [
    ('12:30', '13:30'),
    ('13:30', '14:30'),
    ('14:30', '15:30'),
    ('15:30', '16:30'),
    ('16:30', '17:30'),
  ];

  static const List<(String, String)> _evening00 = [
    ('17:00', '18:00'),
    ('18:00', '19:00'),
    ('19:00', '20:00'),
    ('20:00', '21:00'),
    ('21:00', '22:00'),
    ('22:00', '23:00'),
  ];

  static const List<(String, String)> _evening30 = [
    ('16:30', '17:30'),
    ('17:30', '18:30'),
    ('18:30', '19:30'),
    ('19:30', '20:30'),
    ('20:30', '21:30'),
    ('21:30', '22:30'),
  ];

  static double calculateSlotPrice({
    required String sportType,
    required String startTime,
    double venueBaseRate = 160000.0,
  }) {
    final startHour = int.tryParse(startTime.split(':').first) ?? 12;
    final isFootball = sportType.contains('football') || sportType.contains('bóng đá');
    final isPickleball = sportType.contains('pickleball');

    if (isFootball) {
      if (startHour >= 17 && startHour < 21) return 290000.0;
      return 250000.0;
    } else if (isPickleball) {
      if (startHour >= 6 && startHour < 8) return 160000.0;
      if (startHour >= 8 && startHour < 16) return 130000.0;
      if (startHour >= 16 && startHour < 17) return 170000.0;
      if (startHour >= 17 && startHour < 21) return 220000.0;
      return 150000.0;
    } else {
      final base = venueBaseRate > 0 ? venueBaseRate : 160000.0;
      if (startHour >= 6 && startHour < 8) return (base * 0.75 / 5000).round() * 5000.0;
      if (startHour >= 8 && startHour < 16) return (base * 0.50 / 5000).round() * 5000.0;
      if (startHour >= 16 && startHour < 17) return (base * 0.85 / 5000).round() * 5000.0;
      if (startHour >= 17 && startHour < 21) return (base * 1.125 / 10000).round() * 10000.0;
      return (base * 0.75 / 5000).round() * 5000.0;
    }
  }

  /// Generates a list of [TimeSlot]s for all courts from 1 to [courtCount].
  ///
  /// - [shift]: 'morning', 'afternoon', or 'evening'
  /// - [minuteOffset]: ':00' or ':30'
  /// - [venue]: Optional venue context to calculate sport-aware tiered prices.
  /// - Morning/Afternoon default price: 120,000 VND
  /// - Evening default price: 150,000 VND
  /// - Approximately 30% of slots are deterministically marked as booked.
  static List<TimeSlot> generateSlots({
    required String date,
    required int courtCount,
    required String shift,
    required String minuteOffset,
    Venue? venue,
  }) {
    if (courtCount <= 0) return const [];

    final normalizedShift = shift.trim().toLowerCase();
    final isHalfHour = minuteOffset.contains('30');

    final List<(String, String)> intervals;
    final double defaultPrice;

    switch (normalizedShift) {
      case 'morning':
        intervals = isHalfHour ? _morning30 : _morning00;
        defaultPrice = 120000.0;
        break;
      case 'afternoon':
        intervals = isHalfHour ? _afternoon30 : _afternoon00;
        defaultPrice = 120000.0;
        break;
      case 'evening':
        intervals = isHalfHour ? _evening30 : _evening00;
        defaultPrice = 150000.0;
        break;
      default:
        return const [];
    }

    final List<TimeSlot> result = [];

    for (final interval in intervals) {
      final startTime = interval.$1;
      final endTime = interval.$2;

      for (int court = 1; court <= courtCount; court++) {
        final id = '${date}_c${court}_${startTime.replaceAll(':', '')}';
        final seed = _deterministicHash('$date-$court-$startTime');
        final isBooked = (seed % 10) < 3; // ~30% booked

        final double slotPrice;
        if (venue != null) {
          final sportType = CourtSportPartition.getSportForCourt(
            venue: venue,
            courtNumber: court,
          );
          slotPrice = calculateSlotPrice(
            sportType: sportType,
            startTime: startTime,
            venueBaseRate: venue.hourlyRate,
          );
        } else {
          slotPrice = defaultPrice;
        }

        result.add(
          TimeSlot(
            id: id,
            date: date,
            courtNumber: court,
            startTime: startTime,
            endTime: endTime,
            price: slotPrice,
            status: isBooked ? SlotStatus.booked : SlotStatus.available,
          ),
        );
      }
    }

    return result;
  }

  /// Simple deterministic string hash (31-multiplier)
  static int _deterministicHash(String str) {
    int hash = 0;
    for (int i = 0; i < str.length; i++) {
      hash = (31 * hash + str.codeUnitAt(i)) & 0x7fffffff;
    }
    return hash;
  }
}
