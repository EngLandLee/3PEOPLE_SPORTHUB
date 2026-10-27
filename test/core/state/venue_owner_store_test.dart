import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/domain/entities/court_slot_item.dart';

void main() {
  late VenueOwnerStore store;

  setUp(() {
    store = VenueOwnerStore.instance;
    store.reset();
  });

  test('initial state has owner mode disabled and pre-seeded court slots', () {
    expect(store.isOwnerMode, isFalse);
    expect(store.slots.isNotEmpty, isTrue);
    expect(store.slots.length, equals(128)); // 8 courts * 16 hourly slots
    expect(store.activeVenueName, contains('Tao Đàn'));
    expect(store.activeVenueId, equals('venue_01'));

    final badmintonSlots = store.slots.where((s) => s.sportType == 'badminton');
    final pickleballSlots = store.slots.where((s) => s.sportType == 'pickleball');
    expect(badmintonSlots.length, equals(64));
    expect(pickleballSlots.length, equals(64));
  });

  test('toggleOwnerMode switches owner mode state', () {
    bool? notifiedValue;
    store.isOwnerModeNotifier.addListener(() {
      notifiedValue = store.isOwnerMode;
    });

    store.toggleOwnerMode(true);
    expect(store.isOwnerMode, isTrue);
    expect(notifiedValue, isTrue);

    store.toggleOwnerMode(false);
    expect(store.isOwnerMode, isFalse);
    expect(notifiedValue, isFalse);
  });

  test('reserveSlot changes slot status to reservedManual with customer info and notifies', () {
    int notifyCount = 0;
    store.slotsNotifier.addListener(() {
      notifyCount++;
    });

    final target = store.slots.firstWhere((s) => s.status == CourtSlotStatus.available);
    store.reserveSlot(
      target.slotId,
      customerName: 'Anh Tuấn (Khách quen)',
      customerPhone: '0912 345 678',
    );

    final updated = store.slots.firstWhere((s) => s.slotId == target.slotId);
    expect(updated.status, equals(CourtSlotStatus.reservedManual));
    expect(updated.customerName, equals('Anh Tuấn (Khách quen)'));
    expect(updated.customerPhone, equals('0912 345 678'));
    expect(notifyCount, equals(1));
  });

  test('lockMaintenance and unlockSlot cycle slot availability and notify', () {
    int notifyCount = 0;
    store.slotsNotifier.addListener(() {
      notifyCount++;
    });

    final target = store.slots.firstWhere((s) => s.status == CourtSlotStatus.available);
    store.lockMaintenance(target.slotId);

    var current = store.slots.firstWhere((s) => s.slotId == target.slotId);
    expect(current.status, equals(CourtSlotStatus.maintenance));
    expect(notifyCount, equals(1));

    store.unlockSlot(target.slotId);
    current = store.slots.firstWhere((s) => s.slotId == target.slotId);
    expect(current.status, equals(CourtSlotStatus.available));
    expect(current.customerName, isNull);
    expect(notifyCount, equals(2));
  });

  test('reserveSlot, lockMaintenance, unlockSlot handle non-existent slot gracefully', () {
    final originalLength = store.slots.length;
    store.reserveSlot('non_existent', customerName: 'test', customerPhone: '123');
    store.lockMaintenance('non_existent');
    store.unlockSlot('non_existent');
    expect(store.slots.length, equals(originalLength));
  });

  test('checkInTicket marks checkin timestamp on ticket', () {
    expect(store.getCheckInTime('SH-8291'), isNull);

    final result = store.checkInTicket('SH-8291');
    expect(result, isTrue);
    expect(store.isCheckedIn('SH-8291'), isTrue);
    expect(store.getCheckInTime('SH-8291'), isNotNull);
  });

  test('checkInTicket returns false for non-existent ticket', () {
    final result = store.checkInTicket('INVALID-TICKET');
    expect(result, isFalse);
    expect(store.isCheckedIn('INVALID-TICKET'), isFalse);
    expect(store.getCheckInTime('INVALID-TICKET'), isNull);
  });

  test('CourtSlotItem copyWith, equality and hashCode behave correctly', () {
    final original = store.slots.first;
    final copy = original.copyWith(
      customerName: 'Người mới',
      status: CourtSlotStatus.maintenance,
    );
    expect(copy.customerName, equals('Người mới'));
    expect(copy.status, equals(CourtSlotStatus.maintenance));
    expect(copy.slotId, equals(original.slotId));

    final duplicate = CourtSlotItem(
      slotId: original.slotId,
      courtName: original.courtName,
      sportType: original.sportType,
      timeRange: original.timeRange,
      status: original.status,
      customerName: original.customerName,
      customerPhone: original.customerPhone,
      ticketId: original.ticketId,
      price: original.price,
    );
    expect(original, equals(duplicate));
    expect(original.hashCode, equals(duplicate.hashCode));
  });

  test('SeedData contains partner owner user user_owner_01 and AuthStore can login', () {
    final ownerUser = SeedData.demoUsers.firstWhere(
      (u) => u.userId == 'user_owner_01',
    );
    expect(ownerUser.fullName, equals('Chủ Sân Tao Đàn'));
    expect(ownerUser.phone, equals('0988 888 777'));

    final auth = AuthStore.instance;
    auth.reset();
    final result = auth.login('0988 888 777', '123456');
    expect(result.success, isTrue);
    expect(auth.currentUser?.userId, equals('user_owner_01'));
  });

  test('Tao Đàn slots have tiered pricing according to peak and off-peak hours', () {
    final store = VenueOwnerStore.instance;
    // Hour 8 (08:00 - 09:00) is off-peak: 80k for badminton, 130k for pickleball
    final bdmOffPeak = store.slots.firstWhere((s) => s.slotId == 'court_01_08_00');
    expect(bdmOffPeak.price, equals(80000.0));
    expect(bdmOffPeak.isOffPeakHour, isTrue);
    expect(bdmOffPeak.isPeakHour, isFalse);

    final pkbOffPeak = store.slots.firstWhere((s) => s.slotId == 'court_05_08_00');
    expect(pkbOffPeak.price, equals(130000.0));
    expect(pkbOffPeak.isOffPeakHour, isTrue);

    // Hour 18 (18:00 - 19:00) is peak: 180k for badminton, 240k for pickleball
    final bdmPeak = store.slots.firstWhere((s) => s.slotId == 'court_01_18_00');
    expect(bdmPeak.price, equals(180000.0));
    expect(bdmPeak.isPeakHour, isTrue);

    final pkbPeak = store.slots.firstWhere((s) => s.slotId == 'court_05_18_00');
    expect(pkbPeak.price, equals(240000.0));
    expect(pkbPeak.isPeakHour, isTrue);
  });

  test('calculateDefaultSlotPrice calculates tiered prices for all periods', () {
    // 06:00 - 08:00: 120k bdm / 160k pkb
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'badminton', startHour: 6), equals(120000.0));
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'badminton', startHour: 7), equals(120000.0));
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'pickleball', startHour: 6), equals(160000.0));
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'pickleball', startHour: 7), equals(160000.0));

    // 08:00 - 16:00 (off-peak): 80k bdm / 130k pkb
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'badminton', startHour: 8), equals(80000.0));
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'badminton', startHour: 15), equals(80000.0));
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'pickleball', startHour: 8), equals(130000.0));
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'pickleball', startHour: 15), equals(130000.0));

    // 16:00 - 17:00: 130k bdm / 170k pkb
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'badminton', startHour: 16), equals(130000.0));
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'pickleball', startHour: 16), equals(170000.0));

    // 17:00 - 21:00 (peak): 180k bdm / 240k pkb
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'badminton', startHour: 17), equals(180000.0));
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'badminton', startHour: 20), equals(180000.0));
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'pickleball', startHour: 17), equals(240000.0));
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'pickleball', startHour: 20), equals(240000.0));

    // 21:00 - 22:00: 120k bdm / 150k pkb
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'badminton', startHour: 21), equals(120000.0));
    expect(VenueOwnerStore.calculateDefaultSlotPrice(sportType: 'pickleball', startHour: 21), equals(150000.0));
  });

  test('updateSlotPrice updates slot price and notifies listeners', () {
    final store = VenueOwnerStore.instance;
    final targetSlot = store.slots.firstWhere((s) => s.slotId == 'court_01_06_00');
    final originalPrice = targetSlot.price;

    int notifyCount = 0;
    store.slotsNotifier.addListener(() {
      notifyCount++;
    });

    store.updateSlotPrice('court_01_06_00', 95000.0);

    final updatedSlot = store.slots.firstWhere((s) => s.slotId == 'court_01_06_00');
    expect(updatedSlot.price, equals(95000.0));
    expect(updatedSlot.price, isNot(equals(originalPrice)));
    expect(notifyCount, equals(1));
  });

  test('updateSlotPrice handles non-existent slotId gracefully', () {
    final store = VenueOwnerStore.instance;
    int notifyCount = 0;
    store.slotsNotifier.addListener(() {
      notifyCount++;
    });

    store.updateSlotPrice('non_existent_slot', 99000.0);
    expect(notifyCount, equals(0));
  });
}
