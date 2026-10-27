import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/services/venue_sync_service.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/notification_store.dart';
import 'package:sporthub/core/state/ticket_store.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/core/theme/theme_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/domain/entities/app_notification.dart';
import 'package:sporthub/domain/entities/court_slot_item.dart';
import 'package:sporthub/main.dart';

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    ThemeStore.instance.setThemeMode(ThemeMode.light);
    AuthStore.instance.reset();
    NotificationStore.instance.resetSeedData();
    VenueOwnerStore.instance.reset();
    TicketStore.instance.reset();
  });

  testWidgets(
      'End-to-End: Customer books Tao Dan court -> switch to Admin/Partner account -> Admin receives court & notification',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));

    // 1. Log in as Customer (Nguyễn Văn An)
    final customer = SeedData.demoUsers.first; // userId: user_demo_01
    final loginCustResult = AuthStore.instance.login(customer.phone, '123456');
    expect(loginCustResult.success, isTrue);
    expect(AuthStore.instance.currentUser?.fullName, equals('Nguyễn Văn An'));
    expect(AuthStore.instance.currentUser?.isOwner, isFalse);

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Verify consumer app UI is active
    expect(find.text('SportHub'), findsOneWidget);
    expect(find.byKey(const Key('notification_bell_button')), findsOneWidget);

    // 2. Customer performs booking for Tao Dan Sân 2 lúc 20:00 - 21:00
    const testBookingId = 'BK-E2E-TAODAN-999';
    const testCustomerName = 'Nguyễn Văn An';
    const testCustomerPhone = '0909 123 456';
    const testPrice = 180000.0;

    // Simulate booking via VenueSyncService & NotificationStore
    final syncSuccess = await VenueSyncService.instance.createBooking(
      bookingId: testBookingId,
      venueId: 'venue_01', // CLB Cầu Lông & Pickleball Tao Đàn
      courtNumber: 2,
      courtName: 'Sân Cầu Lông 02',
      venueName: 'CLB Cầu Lông Tao Đàn',
      sport: 'badminton',
      date: '27/10/2026',
      startTime: '20:00',
      endTime: '21:00',
      totalPrice: testPrice,
      customerName: testCustomerName,
      customerPhone: testCustomerPhone,
    );
    expect(syncSuccess, isTrue);

    // Dispatch player notification
    NotificationStore.instance.addNotification(
      AppNotification(
        id: 'notif_booking_e2e_player',
        title: 'Đã ghi nhận yêu cầu đặt sân',
        message:
            'Đã ghi nhận 1 ca tại CLB Cầu Lông Tao Đàn; mã booking: $testBookingId.',
        timestamp: DateTime.now(),
        type: NotificationType.booking,
        role: NotificationRole.player,
        targetId: testBookingId,
      ),
    );

    // Dispatch owner notification
    NotificationStore.instance.addNotification(
      AppNotification(
        id: 'notif_booking_e2e_owner',
        title: '⚡ Đơn đặt sân mới qua App',
        message:
            'Khách hàng $testCustomerName vừa đặt Sân 2 (20:00 - 21:00) tại CLB Cầu Lông Tao Đàn. Mã vé: $testBookingId.',
        timestamp: DateTime.now(),
        type: NotificationType.partner,
        role: NotificationRole.owner,
        targetId: testBookingId,
      ),
    );

    // 3. Switch account: Logout customer and Login as Partner/Owner
    AuthStore.instance.logout();
    await tester.pumpAndSettle();

    // Verify redirected to AuthScreen
    expect(find.byKey(const Key('auth_tab_login')), findsOneWidget);

    // Log in as Partner (Chủ Sân Tao Đàn)
    final loginOwnerResult =
        AuthStore.instance.login('partner@taodan.vn', '123456');
    expect(loginOwnerResult.success, isTrue);
    expect(AuthStore.instance.currentUser?.isOwner, isTrue);
    expect(VenueOwnerStore.instance.isOwnerMode, isTrue);

    await tester.pumpAndSettle();

    // 4. Verify Owner Navigation Screen is loaded
    expect(find.text('SportHub Partner'), findsOneWidget);
    expect(find.text('CLB Cầu Lông & Pickleball Tao Đàn'), findsOneWidget);

    // 5. Verify Notification Bell reflects the new booking for the owner
    final ownerBellFinder =
        find.byKey(const Key('notification_bell_button_owner'));
    expect(ownerBellFinder, findsOneWidget);

    // Open Owner Notification Center
    await tester.tap(ownerBellFinder);
    await tester.pumpAndSettle();

    // Verify the booking notification is displayed
    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('⚡ Đơn đặt sân mới qua App'), findsOneWidget);
    expect(
      find.textContaining('Khách hàng Nguyễn Văn An vừa đặt Sân 2'),
      findsOneWidget,
    );

    // Close notification sheet
    final closeBtn = find.byIcon(Icons.close_rounded);
    if (closeBtn.evaluate().isNotEmpty) {
      await tester.tap(closeBtn.first);
      await tester.pumpAndSettle();
    } else {
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
    }

    // 6. Verify Booked Court in Owner Schedule Tab (Lịch sân)
    final bookedCourtSlot = VenueOwnerStore.instance.slots.firstWhere(
      (s) => s.ticketId == testBookingId,
    );
    expect(bookedCourtSlot.status, equals(CourtSlotStatus.bookedApp));
    expect(bookedCourtSlot.customerName, equals('Nguyễn Văn An'));
    expect(bookedCourtSlot.customerPhone, equals('0909 123 456'));
    expect(bookedCourtSlot.courtName, contains('02'));

    // Verify UI renders the booked court slot
    expect(find.textContaining('Nguyễn Văn An'), findsWidgets);

    // 7. Verify Customer's Booking in Owner Check-in Tab (Soát vé)
    await tester.tap(find.byKey(const Key('owner_tab_checkin')));
    await tester.pumpAndSettle();

    expect(find.text('Soát Vé & Check-in'), findsOneWidget);
    expect(find.textContaining('BK-E2E-TAODAN-999'), findsOneWidget);
    expect(find.textContaining('Nguyễn Văn An'), findsWidgets);

    // Check-in action
    final checkinBtn = find.byKey(Key('confirm_checkin_$testBookingId'));
    expect(checkinBtn, findsOneWidget);

    // Ensure visible in scroll view and tap
    await tester.ensureVisible(checkinBtn);
    await tester.pumpAndSettle();
    await tester.tap(checkinBtn);
    await tester.pumpAndSettle();

    // Verify ticket is checked in
    expect(VenueOwnerStore.instance.isCheckedIn(testBookingId), isTrue);
  });
}
