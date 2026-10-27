import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/notification_store.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/core/theme/theme_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/domain/entities/app_notification.dart';
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
    AuthStore.instance.loginWithDemo(SeedData.demoUsers.first);
    NotificationStore.instance.resetSeedData();
    VenueOwnerStore.instance.toggleOwnerMode(false);
  });

  testWidgets('Consumer Explore header displays notification bell with badge and opens sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    final bellFinder = find.byKey(const Key('notification_bell_button'));
    expect(bellFinder, findsOneWidget);

    await tester.tap(bellFinder);
    await tester.pumpAndSettle();

    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Nhắc lịch thi đấu sắp tới 🏸'), findsOneWidget);
  });

  testWidgets('Tapping booking notification deep-links to Tickets tab', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notification_bell_button')));
    await tester.pumpAndSettle();

    // Tap the booking notification
    await tester.tap(find.text('Nhắc lịch thi đấu sắp tới 🏸'));
    await tester.pumpAndSettle();

    // Sheet dismissed and navigated to Tickets tab
    expect(find.text('SPORTHUB PASS'), findsWidgets);
  });

  testWidgets('Tapping community notification deep-links to Community tab', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notification_bell_button')));
    await tester.pumpAndSettle();

    // Tap the community notification
    await tester.tap(find.text('Lời mời ghép trận mới 👥'));
    await tester.pumpAndSettle();

    // Sheet dismissed and navigated to Community tab
    expect(find.text('Cộng Đồng Thể Thao'), findsOneWidget);
  });

  testWidgets('Partner Owner header displays notification bell and opens owner sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    final ownerUser = SeedData.demoUsers.firstWhere((u) => u.isOwner);
    AuthStore.instance.loginWithDemo(ownerUser);
    VenueOwnerStore.instance.toggleOwnerMode(true);

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    final ownerBellFinder = find.byKey(const Key('notification_bell_button_owner'));
    expect(ownerBellFinder, findsOneWidget);

    await tester.tap(ownerBellFinder);
    await tester.pumpAndSettle();

    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Đơn đặt sân mới qua App ⚡'), findsOneWidget);
  });

  testWidgets('Booking payment confirmation dispatches booking notification to store', (tester) async {
    final initialCount = NotificationStore.instance.getUnreadCount(role: NotificationRole.player);

    const bookingId = 'BK-TEST-12345';
    NotificationStore.instance.addNotification(
      AppNotification(
        id: 'notif_booking_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Đặt sân thành công! 🎉',
        message: 'Bạn đã đặt thành công 1 ca tại Sân Cầu Lông Tao Đàn. Mã vé: $bookingId.',
        timestamp: DateTime.now(),
        type: NotificationType.booking,
        role: NotificationRole.player,
        targetId: bookingId,
      ),
    );

    expect(
      NotificationStore.instance.getUnreadCount(role: NotificationRole.player),
      equals(initialCount + 1),
    );

    final notifs = NotificationStore.instance.getNotificationsForRole(NotificationRole.player);
    expect(notifs.first.targetId, equals(bookingId));
    expect(notifs.first.type, equals(NotificationType.booking));
  });
}
