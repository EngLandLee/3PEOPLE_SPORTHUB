import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/constants/app_colors.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
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
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
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
    AuthStore.instance.reset();
    final customer = SeedData.demoUsers.first;
    AuthStore.instance.login(customer.phone, '123456');
  });

  testWidgets('Main screen renders SportHub brand, tabs and venues', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    expect(find.text('SportHub'), findsWidgets);
    expect(find.text('Đặt sân'), findsOneWidget);
    expect(find.text('Cộng đồng'), findsOneWidget);
    expect(find.text('Vé của tôi'), findsOneWidget);
    expect(find.byKey(const Key('floating_chat_bubble')), findsOneWidget);
  });

  testWidgets('Bottom navigation switches tabs cleanly', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Switch to Community / Matchmaking tab
    await tester.tap(find.text('Cộng đồng'));
    await tester.pumpAndSettle();

    // Switch to AI matchmaking mode
    await tester.tap(find.text('✨ Gợi ý đối thủ AI'));
    await tester.pumpAndSettle();

    expect(find.text('Trợ lý Matchmaker AI'), findsOneWidget);
    expect(find.text('✨ Phân tích đối thủ phù hợp'), findsOneWidget);

    // Switch to My Tickets tab
    await tester.tap(find.text('Vé của tôi'));
    await tester.pumpAndSettle();

    expect(find.text('SPORTHUB PASS'), findsWidgets);
    expect(find.text('SÂN CẦU LÔNG BÌNH THẠNH'), findsOneWidget);
    expect(find.text('✅ ĐÃ THANH TOÁN'), findsWidgets);

    // Switch back to Booking tab
    await tester.tap(find.text('Đặt sân'));
    await tester.pumpAndSettle();

    expect(find.text('Cụm sân nổi bật tại TP.HCM'), findsOneWidget);
  });

  testWidgets('Navigates to VenueDetailScreen when tapping a venue', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    final ctaFinder = find.text('Xem lịch sân').first;
    await tester.tap(ctaFinder);
    await tester.pumpAndSettle();

    expect(find.text('Chạm vào ô xanh để chọn slot. Ma trận tự động cập nhật thời gian thực.'), findsOneWidget);
  });

  test('SeedData contains venues across diverse districts', () {
    final districts = SeedData.sampleVenues.map((v) => v.district).toSet();
    expect(districts.contains('Bình Thạnh'), isTrue);
    expect(districts.contains('Thủ Đức'), isTrue);
    expect(districts.contains('Quận 7'), isTrue);
    expect(districts.contains('Quận 1'), isTrue);
    expect(districts.contains('Tân Bình'), isTrue);
  });

  testWidgets('Searching by text filters the venue list in realtime', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Verify initial venue is shown
    expect(find.text('CLB Cầu Lông & Pickleball Bình Thạnh Sport'), findsOneWidget);

    // Enter "Tao Đàn" into search field
    await tester.enterText(find.byType(TextField), 'Tao Đàn');
    await tester.pumpAndSettle();

    // Verify only Tao Đàn is visible
    expect(find.text('CLB Cầu Lông Tao Đàn - Quận 1'), findsOneWidget);
    expect(find.text('CLB Cầu Lông & Pickleball Bình Thạnh Sport'), findsNothing);
    expect(find.text('Thảo Điền Pickleball Hub'), findsNothing);

    // Tap clear button
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // List is restored
    expect(find.text('CLB Cầu Lông & Pickleball Bình Thạnh Sport'), findsOneWidget);
  });

  testWidgets('Selecting district from bottom sheet filters venue list', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Tap location pill
    final locationPill = find.byKey(const Key('location_pill'));
    expect(locationPill, findsOneWidget);
    await tester.tap(locationPill);
    await tester.pumpAndSettle();

    // Verify bottom sheet opened and lists districts
    expect(find.text('Tất cả TP.HCM'), findsWidgets);
    expect(find.text('Quận 7'), findsOneWidget);

    // Tap "Quận 7"
    await tester.tap(find.text('Quận 7'));
    await tester.pumpAndSettle();

    // Verify location pill updates to "Quận 7"
    expect(find.textContaining('Quận 7'), findsWidgets);
    expect(find.text('📍 Quận 7, TP.HCM ▾'), findsOneWidget);

    // Verify only Nam Sài Gòn venue is shown
    expect(find.text('Sân Bóng Đá Mini Nam Sài Gòn'), findsOneWidget);
    expect(find.text('CLB Cầu Lông Tao Đàn - Quận 1'), findsNothing);
    expect(find.text('CLB Cầu Lông & Pickleball Bình Thạnh Sport'), findsNothing);
  });

  testWidgets('Empty state displays when no venues match and resets cleanly', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Enter nonexistent query
    await tester.enterText(find.byType(TextField), 'SanKhongTonTai123');
    await tester.pumpAndSettle();

    // Verify empty state is displayed
    expect(find.text('Không tìm thấy sân nào phù hợp'), findsOneWidget);
    expect(find.text('Thử tìm kiếm với từ khóa khác hoặc xóa bớt bộ lọc'), findsOneWidget);
    final iconFinder = find.byIcon(Icons.search_off_rounded);
    expect(iconFinder, findsOneWidget);
    final iconWidget = tester.widget<Icon>(iconFinder);
    expect(iconWidget.color, AppColors.primary);

    // Tap "Đặt lại bộ lọc" button
    await tester.tap(find.byKey(const Key('reset_filters_button')));
    await tester.pumpAndSettle();

    // Verify full list restored
    expect(find.text('Không tìm thấy sân nào phù hợp'), findsNothing);
    expect(find.text('CLB Cầu Lông & Pickleball Bình Thạnh Sport'), findsOneWidget);
  });

  testWidgets('District bottom sheet shows new header title and can be dismissed via close button', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Tap location pill to open bottom sheet
    await tester.tap(find.byKey(const Key('location_pill')));
    await tester.pumpAndSettle();

    // Verify title 'Chọn khu vực / Quận'
    expect(find.text('Chọn khu vực / Quận'), findsOneWidget);

    // Find the close button in the bottom sheet and tap it
    final closeBtnFinder = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byIcon(Icons.close_rounded),
    );
    expect(closeBtnFinder, findsOneWidget);
    await tester.tap(closeBtnFinder);
    await tester.pumpAndSettle();

    // Bottom sheet is closed
    expect(find.text('Chọn khu vực / Quận'), findsNothing);
  });

  testWidgets('Dynamic venue counter updates accurately when filtering', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    final totalVenues = SeedData.sampleVenues.length;
    expect(find.text('($totalVenues cụm sân)'), findsOneWidget);

    // Filter by text "Tao Đàn" (1 result)
    await tester.enterText(find.byType(TextField), 'Tao Đàn');
    await tester.pumpAndSettle();
    expect(find.text('(1 cụm sân)'), findsOneWidget);

    // Clear search
    await tester.tap(find.byKey(const Key('clear_search_button')));
    await tester.pumpAndSettle();
    expect(find.text('($totalVenues cụm sân)'), findsOneWidget);
  });
}

