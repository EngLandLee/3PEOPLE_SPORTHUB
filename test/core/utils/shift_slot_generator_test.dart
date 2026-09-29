import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/court_sport_partition.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/core/utils/shift_slot_generator.dart';
import 'package:sporthub/domain/entities/time_slot.dart';

void main() {
  group('ShiftSlotGenerator', () {
    test('ShiftSlotGenerator generates :00 evening slots with 150k price', () {
      final slots = ShiftSlotGenerator.generateSlots(
        date: '2026-09-06',
        courtCount: 3,
        shift: 'evening',
        minuteOffset: ':00',
      );

      expect(slots.isNotEmpty, true);
      expect(slots.any((s) => s.startTime == '18:00' && s.endTime == '19:00'), true);
      expect(slots.first.price, 150000);
      expect(slots.length, 3 * 6); // 3 courts * 6 intervals
    });

    test('ShiftSlotGenerator generates :30 odd slots like 18:30 and 19:30', () {
      final slots = ShiftSlotGenerator.generateSlots(
        date: '2026-09-06',
        courtCount: 3,
        shift: 'evening',
        minuteOffset: ':30',
      );

      expect(slots.any((s) => s.startTime == '18:30' && s.endTime == '19:30'), true);
      expect(slots.any((s) => s.startTime == '19:30' && s.endTime == '20:30'), true);
      expect(slots.length, 3 * 6);
    });

    test('ShiftSlotGenerator generates morning slots at 120k price', () {
      final slots = ShiftSlotGenerator.generateSlots(
        date: '2026-09-06',
        courtCount: 2,
        shift: 'morning',
        minuteOffset: ':00',
      );

      expect(slots.any((s) => s.startTime == '06:00' && s.endTime == '07:00'), true);
      expect(slots.first.price, 120000);
      expect(slots.length, 2 * 6);
    });

    test('ShiftSlotGenerator generates afternoon slots at 120k price for :00 and :30', () {
      final slots00 = ShiftSlotGenerator.generateSlots(
        date: '2026-09-06',
        courtCount: 2,
        shift: 'afternoon',
        minuteOffset: ':00',
      );
      expect(slots00.any((s) => s.startTime == '12:00' && s.endTime == '13:00'), true);
      expect(slots00.first.price, 120000);
      expect(slots00.length, 2 * 5); // 5 intervals in afternoon

      final slots30 = ShiftSlotGenerator.generateSlots(
        date: '2026-09-06',
        courtCount: 2,
        shift: 'afternoon',
        minuteOffset: ':30',
      );
      expect(slots30.any((s) => s.startTime == '12:30' && s.endTime == '13:30'), true);
      expect(slots30.first.price, 120000);
      expect(slots30.length, 2 * 5);
    });

    test('ShiftSlotGenerator generates slots covering all courts', () {
      final slots = ShiftSlotGenerator.generateSlots(
        date: '2026-09-06',
        courtCount: 4,
        shift: 'morning',
        minuteOffset: ':00',
      );

      final courtNumbers = slots.map((s) => s.courtNumber).toSet();
      expect(courtNumbers, {1, 2, 3, 4});
    });

    test('ShiftSlotGenerator deterministically sets booked and available statuses', () {
      final slotsRun1 = ShiftSlotGenerator.generateSlots(
        date: '2026-09-06',
        courtCount: 5,
        shift: 'evening',
        minuteOffset: ':00',
      );
      final slotsRun2 = ShiftSlotGenerator.generateSlots(
        date: '2026-09-06',
        courtCount: 5,
        shift: 'evening',
        minuteOffset: ':00',
      );

      expect(slotsRun1.length, slotsRun2.length);
      for (int i = 0; i < slotsRun1.length; i++) {
        expect(slotsRun1[i].status, slotsRun2[i].status);
        expect(slotsRun1[i].id, slotsRun2[i].id);
      }

      final bookedCount = slotsRun1.where((s) => s.status == SlotStatus.booked).length;
      final availableCount = slotsRun1.where((s) => s.status == SlotStatus.available).length;
      expect(bookedCount > 0, true);
      expect(availableCount > 0, true);
      final bookedRatio = bookedCount / slotsRun1.length;
      expect(bookedRatio >= 0.15 && bookedRatio <= 0.45, true);
    });

    test('ShiftSlotGenerator handles zero or negative courts gracefully', () {
      final slots = ShiftSlotGenerator.generateSlots(
        date: '2026-09-06',
        courtCount: 0,
        shift: 'morning',
        minuteOffset: ':00',
      );
      expect(slots.isEmpty, true);
    });

    test('calculateSlotPrice gives realistic sport-specific rates', () {
      // Football pitch: Daytime off-peak ~250k, Peak ~290k
      final fbOffPeak = ShiftSlotGenerator.calculateSlotPrice(
        sportType: 'football',
        startTime: '10:00',
      );
      expect(fbOffPeak, equals(250000.0));

      final fbPeak = ShiftSlotGenerator.calculateSlotPrice(
        sportType: 'football',
        startTime: '18:00',
      );
      expect(fbPeak, equals(290000.0));

      // Pickleball: Daytime off-peak ~130k, Peak ~220k
      final pbOffPeak = ShiftSlotGenerator.calculateSlotPrice(
        sportType: 'pickleball',
        startTime: '14:00',
      );
      expect(pbOffPeak, equals(130000.0));

      final pbPeak = ShiftSlotGenerator.calculateSlotPrice(
        sportType: 'pickleball',
        startTime: '19:00',
      );
      expect(pbPeak, equals(220000.0));

      // Badminton at Tao Đàn (base 160k): Off-peak 80k, Peak 180k
      final bdmOffPeak = ShiftSlotGenerator.calculateSlotPrice(
        sportType: 'badminton',
        startTime: '09:00',
        venueBaseRate: 160000.0,
      );
      expect(bdmOffPeak, equals(80000.0));

      final bdmPeak = ShiftSlotGenerator.calculateSlotPrice(
        sportType: 'badminton',
        startTime: '18:00',
        venueBaseRate: 160000.0,
      );
      expect(bdmPeak, equals(180000.0));
    });

    test('Tân Bình Arena generates distinct prices for badminton, pickleball, and football courts', () {
      final tanBinhVenue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_tb_05');
      final slots = ShiftSlotGenerator.generateSlots(
        date: '2026-09-06',
        courtCount: tanBinhVenue.courtCount,
        shift: 'evening',
        minuteOffset: ':00',
        venue: tanBinhVenue,
      );

      // Court 1 (Badminton) at 18:00
      final bdmSlot = slots.firstWhere((s) => s.courtNumber == 1 && s.startTime == '18:00');
      expect(bdmSlot.price, equals(200000.0)); // 180k base * 1.125 = ~200k

      // Court 5 (Pickleball) at 18:00
      final pbSlot = slots.firstWhere((s) => s.courtNumber == 5 && s.startTime == '18:00');
      expect(pbSlot.price, equals(220000.0));

      // Court 8 (Football) at 18:00
      final fbSlot = slots.firstWhere((s) => s.courtNumber == 8 && s.startTime == '18:00');
      expect(fbSlot.price, equals(290000.0));
    });

    test('CourtSportPartition.getZonesForVenue groups Tân Bình Arena into 3 physical zones', () {
      final tanBinhVenue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_tb_05');
      final zones = CourtSportPartition.getZonesForVenue(tanBinhVenue);

      expect(zones.length, equals(3));
      expect(zones[0].sportType, equals('badminton'));
      expect(zones[0].courtNumbers, equals([1, 2, 3, 4]));
      expect(zones[1].sportType, equals('pickleball'));
      expect(zones[1].courtNumbers, equals([5, 6, 7]));
      expect(zones[2].sportType, equals('football'));
      expect(zones[2].courtNumbers, equals([8, 9, 10]));
    });
  });
}
