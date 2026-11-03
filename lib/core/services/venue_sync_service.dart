import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/venue.dart';
import '../state/notification_store.dart';
import '../state/ticket_store.dart';
import '../state/venue_owner_store.dart';
import '../utils/seed_data.dart';
import 'supabase_service.dart';

/// Service for synchronizing venue court availability and status
/// between the SportHub Admin/Partner Web Portal and the Flutter Mobile App.
class VenueSyncService {
  VenueSyncService._internal() {
    loadLocalBookings();
  }

  static final VenueSyncService instance = VenueSyncService._internal();

  static const String envBackend = String.fromEnvironment('BACKEND_URL');

  String serverBaseUrl = envBackend.isNotEmpty
      ? (envBackend.endsWith('/')
          ? envBackend.substring(0, envBackend.length - 1)
          : envBackend)
      : 'http://localhost:5173';
  bool isSyncEnabled = true;

  /// List of active venues synced between Web Admin and Mobile App
  final ValueNotifier<List<Venue>> venuesNotifier =
      ValueNotifier<List<Venue>>(List.of(SeedData.sampleVenues));

  /// Maps venueId (e.g. 'venue_01', 'venue_q1_04') to a list of inactive court numbers (e.g. [1])
  final ValueNotifier<Map<String, List<int>>> inactiveCourtsNotifier =
      ValueNotifier<Map<String, List<int>>>({
    'venue_01': [1],
    'venue_q1_04': [1],
  });

  final ValueNotifier<DateTime?> lastSyncTimeNotifier =
      ValueNotifier<DateTime?>(null);

  /// List of synced bookings across Web Admin and Mobile App
  final ValueNotifier<List<Map<String, dynamic>>> bookingsNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  Timer? _pollTimer;

  Future<File?> _getBookingsFile() async {
    try {
      if (isTestEnvironment) return null;
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/sporthub_bookings.json');
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveBookingsLocally() async {
    try {
      final file = await _getBookingsFile();
      if (file == null) return;
      final jsonStr = jsonEncode(bookingsNotifier.value);
      await file.writeAsString(jsonStr, flush: true);
    } catch (_) {}
  }

  Future<void> loadLocalBookings() async {
    try {
      final file = await _getBookingsFile();
      if (file == null || !await file.exists()) return;
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        final decoded = jsonDecode(content);
        if (decoded is List) {
          final list = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          final current =
              List<Map<String, dynamic>>.from(bookingsNotifier.value);
          final existingIds = current
              .map((b) => (b['id'] ?? b['bookingId'])?.toString())
              .toSet();
          for (final b in list) {
            final id = (b['id'] ?? b['bookingId'])?.toString();
            if (id != null && !existingIds.contains(id)) {
              current.add(b);
            }
          }
          bookingsNotifier.value = List.unmodifiable(current);
        }
      }
    } catch (_) {}
  }

  /// Detects if running in a flutter test harness to avoid unexpected network calls or lingering timers
  bool get isTestEnvironment {
    try {
      final name = WidgetsBinding.instance.runtimeType.toString();
      return name.contains('Test');
    } catch (_) {
      return false;
    }
  }

  /// List of candidate server URLs to reach Admin Web API
  List<String> get candidateServerUrls {
    final urls = <String>[];
    const envBackend = String.fromEnvironment('BACKEND_URL');
    if (envBackend.isNotEmpty && !urls.contains(envBackend)) {
      urls.add(envBackend);
    }
    try {
      if (Uri.base.scheme == 'http' || Uri.base.scheme == 'https') {
        final host = Uri.base.host;
        if (host.isNotEmpty) {
          urls.add('${Uri.base.scheme}://$host:5173');
        }
      }
    } catch (_) {}
    if (!urls.contains(serverBaseUrl)) urls.add(serverBaseUrl);
    if (!urls.contains('http://localhost:5173')) {
      urls.add('http://localhost:5173');
    }
    if (!urls.contains('http://127.0.0.1:5173')) {
      urls.add('http://127.0.0.1:5173');
    }
    if (!urls.contains('http://0.0.0.0:5173')) urls.add('http://0.0.0.0:5173');
    return urls;
  }

  /// Checks if a specific court at a venue is currently active and open for booking.
  bool isCourtActive({
    required String venueId,
    required int courtNumber,
    String? venueName,
  }) {
    final map = inactiveCourtsNotifier.value;

    // Check direct venueId match
    if (map[venueId]?.contains(courtNumber) == true) {
      return false;
    }

    // Check Tao Đàn aliases (venue_01 in web admin <-> venue_q1_04 in mobile)
    final isTaoDan =
        (venueName != null && venueName.toLowerCase().contains('tao đàn')) ||
            venueId == 'venue_01' ||
            venueId == 'venue_q1_04' ||
            venueId.contains('tao_dan');

    if (isTaoDan) {
      if (map['venue_01']?.contains(courtNumber) == true ||
          map['venue_q1_04']?.contains(courtNumber) == true) {
        return false;
      }
    }

    return true;
  }

  /// Manually set court status for tests or local overrides
  void setCourtActive({
    required String venueId,
    required int courtNumber,
    required bool isActive,
  }) {
    final current = Map<String, List<int>>.from(
      inactiveCourtsNotifier.value.map(
        (k, v) => MapEntry(k, List<int>.from(v)),
      ),
    );

    final list = current[venueId] ?? <int>[];
    if (isActive) {
      list.remove(courtNumber);
    } else {
      if (!list.contains(courtNumber)) {
        list.add(courtNumber);
      }
    }
    current[venueId] = list;

    // Tao Đàn aliasing
    if (venueId == 'venue_01' || venueId == 'venue_q1_04') {
      current['venue_01'] = List<int>.from(list);
      current['venue_q1_04'] = List<int>.from(list);
    }

    inactiveCourtsNotifier.value = Map.unmodifiable(current);
  }

  bool _isMatchingDate(String d1, String d2) {
    if (d1.trim() == d2.trim()) return true;
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final isD1Today =
        d1.toLowerCase().contains('hôm nay') || d1.trim() == todayStr;
    final isD2Today =
        d2.toLowerCase().contains('hôm nay') || d2.trim() == todayStr;
    if (isD1Today && isD2Today) return true;

    try {
      DateTime? dt1;
      DateTime? dt2;
      if (d1.contains('-')) {
        final p = d1.split('-');
        if (p.length == 3) {
          dt1 = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        }
      } else if (d1.contains('/')) {
        final p = d1.split('/');
        if (p.length == 3) {
          dt1 = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        }
      }
      if (d2.contains('-')) {
        final p = d2.split('-');
        if (p.length == 3) {
          dt2 = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        }
      } else if (d2.contains('/')) {
        final p = d2.split('/');
        if (p.length == 3) {
          dt2 = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        }
      }
      if (dt1 != null && dt2 != null) {
        return dt1.year == dt2.year &&
            dt1.month == dt2.month &&
            dt1.day == dt2.day;
      }
    } catch (_) {}

    return false;
  }

  /// Checks if a slot at a court has already been booked
  bool isSlotBooked({
    required String venueId,
    required int courtNumber,
    required String date,
    required String startTime,
    String? venueName,
  }) {
    final isTaoDan =
        (venueName != null && venueName.toLowerCase().contains('tao đàn')) ||
            venueId == 'venue_01' ||
            venueId == 'venue_q1_04' ||
            venueId.contains('tao_dan');

    for (final b in bookingsNotifier.value) {
      final bVenueId = b['venueId']?.toString() ?? '';
      final bCourtNumber =
          int.tryParse(b['courtNumber']?.toString() ?? '') ?? 0;
      final bDate = b['date']?.toString() ?? '';
      final bStartTime = b['startTime']?.toString() ?? '';
      final bTimeSlot = b['timeSlot']?.toString() ?? '';

      final venueMatches = (bVenueId == venueId) ||
          (isTaoDan && (bVenueId == 'venue_01' || bVenueId == 'venue_q1_04'));

      if (venueMatches && bCourtNumber == courtNumber) {
        if (date.isNotEmpty &&
            (bDate.isEmpty || !_isMatchingDate(bDate, date))) {
          continue;
        }
        if (bStartTime == startTime || bTimeSlot.startsWith(startTime)) {
          return true;
        }
        // Support multi-hour booking overlap (e.g. 18:00 - 20:00 blocks both 18:00 and 19:00)
        final slotStartMin = _parseTimeToMinutes(startTime);
        String bookingEndTime = b['endTime']?.toString() ?? '';
        if (bookingEndTime.isEmpty && bTimeSlot.contains('-')) {
          final slotParts = bTimeSlot.split('-');
          if (slotParts.length >= 2) {
            bookingEndTime = slotParts[1].trim();
          }
        }
        final bookingStartMin = _parseTimeToMinutes(bStartTime.isNotEmpty
            ? bStartTime
            : bTimeSlot.split('-').first.trim());
        final bookingEndMin = _parseTimeToMinutes(bookingEndTime);

        if (slotStartMin != null &&
            bookingStartMin != null &&
            bookingEndMin != null) {
          if (slotStartMin >= bookingStartMin && slotStartMin < bookingEndMin) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static int? _parseTimeToMinutes(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    final parts = timeStr.trim().split(':');
    if (parts.isEmpty) return null;
    final h = int.tryParse(parts[0]);
    if (h == null) return null;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return h * 60 + m;
  }

  /// Creates a new booking, persists locally and syncs with Web Admin Portal (/api/bookings)
  Future<bool> createBooking({
    required String bookingId,
    required String venueId,
    required int courtNumber,
    required String courtName,
    required String venueName,
    required String sport,
    required String date,
    required String startTime,
    required String endTime,
    required double totalPrice,
    required String customerName,
    required String customerPhone,
    String paymentMethod = 'vietqr',
    List<Map<String, dynamic>>? addOns,
    http.Client? client,
  }) async {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final normalizedDate =
        (date.toLowerCase().contains('hôm nay') || date.trim().isEmpty)
            ? todayStr
            : date;

    final newBooking = {
      'id': bookingId,
      'slotId': 'court_0${courtNumber}_${startTime.replaceAll(':', '_')}',
      'courtNumber': courtNumber,
      'courtName': courtName,
      'venueId': (venueId == 'venue_q1_04') ? 'venue_01' : venueId,
      'venueName': venueName,
      'sport': sport,
      'date': normalizedDate,
      'timeSlot': '$startTime - $endTime',
      'startTime': startTime,
      'endTime': endTime,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'price': totalPrice,
      // Creating a booking/reservation is not proof that money was received.
      // A verified provider webhook or server-side reconciliation must promote
      // this record to `paid`.
      'paymentStatus': 'pending',
      'paymentMethod': paymentMethod,
      'checkedIn': false,
      'addOns': addOns ?? [],
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Immediately update local in-memory bookings for snappy UI
    final current = List<Map<String, dynamic>>.from(bookingsNotifier.value);
    current.removeWhere((b) => b['id'] == bookingId);
    current.insert(0, newBooking);
    bookingsNotifier.value = List.unmodifiable(current);
    _saveBookingsLocally();

    void rollbackLocalBooking() {
      bookingsNotifier.value = List.unmodifiable(
        bookingsNotifier.value.where((booking) => booking['id'] != bookingId),
      );
      _saveBookingsLocally();
    }

    // Synchronize to mobile owner store ONLY if Tao Dan
    final isTaoDanVenue = venueId == 'venue_01' ||
        venueId == 'venue_q1_04' ||
        venueName.toLowerCase().contains('tao đàn');
    if (isTaoDanVenue) {
      try {
        VenueOwnerStore.instance.recordAppBooking(
          courtNumber: courtNumber,
          startTime: startTime,
          endTime: endTime,
          ticketId: bookingId,
          customerName: customerName,
          customerPhone: customerPhone,
          price: totalPrice,
        );
      } catch (_) {}
    }

    // Dispatch notifications for both customer and venue owner
    try {
      NotificationStore.instance.addNotification(
        AppNotification(
          id: 'notif_player_bk_$bookingId',
          title: 'Đặt sân thành công! 🎟️',
          message:
              'Bạn đã đặt $courtName tại $venueName ($startTime - $endTime, ngày $normalizedDate).',
          timestamp: DateTime.now(),
          type: NotificationType.booking,
          role: NotificationRole.player,
          isRead: false,
        ),
      );
      NotificationStore.instance.addNotification(
        AppNotification(
          id: 'notif_owner_bk_$bookingId',
          title: 'Lịch Đặt Sân Mới 🏟️',
          message:
              'Khách hàng $customerName vừa đặt $courtName ($startTime - $endTime, ngày $normalizedDate).',
          timestamp: DateTime.now(),
          type: NotificationType.booking,
          role: NotificationRole.owner,
          isRead: false,
        ),
      );
    } catch (_) {}

    // Synchronize to Supabase PostgreSQL with concurrency safety if configured
    if (SupabaseService.instance.isConfigured) {
      try {
        await SupabaseService.instance.createBookingSafely(
          bookingId: bookingId,
          venueId: venueId,
          venueName: venueName,
          courtNumber: courtNumber,
          courtName: courtName,
          sport: sport,
          date: date,
          startTime: startTime,
          endTime: endTime,
          customerName: customerName,
          customerPhone: customerPhone,
          price: totalPrice,
          paymentMethod: paymentMethod,
          addOns: addOns,
        );
      } catch (e) {
        debugPrint('⚠️ [VenueSyncService] Supabase createBookingSafely fallback notice: $e');
      }
    }

    if (!isSyncEnabled) return true;
    if (client == null && isTestEnvironment) return true;

    final httpClient = client ?? http.Client();
    try {
      if (client != null) {
        final uri = Uri.parse('$serverBaseUrl/api/bookings');
        final response = await httpClient
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(newBooking),
            )
            .timeout(const Duration(milliseconds: 2500));
        final success =
            response.statusCode == 200 || response.statusCode == 201;
        if (!success) rollbackLocalBooking();
        return success;
      }

      for (final baseUrl in candidateServerUrls) {
        try {
          final uri = Uri.parse('$baseUrl/api/bookings');
          final response = await httpClient
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(newBooking),
              )
              .timeout(const Duration(milliseconds: 1500));
          if (response.statusCode == 200 || response.statusCode == 201) {
            serverBaseUrl = baseUrl;
            return true;
          }
        } catch (_) {}
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      if (client == null) {
        try {
          httpClient.close();
        } catch (_) {}
      }
    }
  }

  /// Alias for createBooking to ensure compatibility with various caller conventions
  Future<bool> syncBooking({
    required String bookingId,
    required String venueId,
    required int courtNumber,
    required String courtName,
    required String venueName,
    required String sport,
    required String date,
    required String startTime,
    required String endTime,
    required double totalPrice,
    required String customerName,
    required String customerPhone,
    String paymentMethod = 'vietqr',
    List<Map<String, dynamic>>? addOns,
    http.Client? client,
  }) =>
      createBooking(
        bookingId: bookingId,
        venueId: venueId,
        courtNumber: courtNumber,
        courtName: courtName,
        venueName: venueName,
        sport: sport,
        date: date,
        startTime: startTime,
        endTime: endTime,
        totalPrice: totalPrice,
        customerName: customerName,
        customerPhone: customerPhone,
        paymentMethod: paymentMethod,
        addOns: addOns,
        client: client,
      );

  /// Synchronizes check-in of a booking ticket with backend server (/api/checkin)
  /// and updates local store state.
  Future<bool> checkInBooking(String ticketId, {http.Client? client}) async {
    final cleanId = ticketId.trim().toUpperCase();

    // 1. Update local bookingsNotifier
    final current = List<Map<String, dynamic>>.from(bookingsNotifier.value);
    bool foundInNotifier = false;
    for (int i = 0; i < current.length; i++) {
      final b = current[i];
      if ((b['id']?.toString().toUpperCase() == cleanId) ||
          (b['bookingId']?.toString().toUpperCase() == cleanId)) {
        current[i] = {
          ...b,
          'checkedIn': true,
          'checkedInAt': DateTime.now().toIso8601String(),
        };
        foundInNotifier = true;
        break;
      }
    }
    if (foundInNotifier) {
      bookingsNotifier.value = List.unmodifiable(current);
      _saveBookingsLocally();
    }

    // 2. Update VenueOwnerStore & TicketStore
    try {
      VenueOwnerStore.instance.checkIn(ticketId);
      TicketStore.instance.updateTicketStatus(ticketId, 'checked_in');
    } catch (_) {}

    // 3. Synchronize check-in to Supabase PostgreSQL if configured
    if (SupabaseService.instance.isConfigured) {
      try {
        await SupabaseService.instance.checkInTicket(ticketId);
      } catch (e) {
        debugPrint('⚠️ [VenueSyncService] Supabase checkInTicket fallback notice: $e');
      }
    }

    if (!isSyncEnabled) return true;
    if (client == null && isTestEnvironment) return true;

    final httpClient = client ?? http.Client();
    final payload = jsonEncode({'ticketId': ticketId});
    try {
      if (client != null) {
        final uri = Uri.parse('$serverBaseUrl/api/checkin');
        final response = await httpClient
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: payload,
            )
            .timeout(const Duration(milliseconds: 2500));
        return response.statusCode == 200 || response.statusCode == 201;
      }

      for (final baseUrl in candidateServerUrls) {
        try {
          final uri = Uri.parse('$baseUrl/api/checkin');
          final response = await httpClient
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: payload,
              )
              .timeout(const Duration(milliseconds: 1500));
          if (response.statusCode == 200 || response.statusCode == 201) {
            serverBaseUrl = baseUrl;
            return true;
          }
        } catch (_) {}
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      if (client == null) {
        try {
          httpClient.close();
        } catch (_) {}
      }
    }
  }

  /// Fetches latest sync state from Web Admin Portal (/api/sync)
  Future<bool> syncWithServer({http.Client? client}) async {
    if (!isSyncEnabled) return false;
    // In test environment, skip real network requests unless a custom client is explicitly provided
    if (client == null && isTestEnvironment) {
      return false;
    }

    final httpClient = client ?? http.Client();
    try {
      Map<String, dynamic>? data;

      if (client != null) {
        final uri = Uri.parse('$serverBaseUrl/api/sync');
        final response = await httpClient
            .get(uri)
            .timeout(const Duration(milliseconds: 1500));
        if (response.statusCode == 200) {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        }
      } else {
        for (final baseUrl in candidateServerUrls) {
          try {
            final uri = Uri.parse('$baseUrl/api/sync');
            final response = await httpClient
                .get(uri)
                .timeout(const Duration(milliseconds: 1200));
            if (response.statusCode == 200) {
              data = jsonDecode(response.body) as Map<String, dynamic>;
              serverBaseUrl = baseUrl;
              break;
            }
          } catch (_) {}
        }
      }

      if (data != null) {
        final Map<String, List<int>> parsedMap = {};

        // Parse inactiveCourtsByVenue
        final rawInactive =
            data['inactiveCourtsByVenue'] as Map<String, dynamic>?;
        if (rawInactive != null) {
          for (final entry in rawInactive.entries) {
            if (entry.value is List) {
              parsedMap[entry.key] = (entry.value as List)
                  .map((e) => int.tryParse(e.toString()) ?? 0)
                  .where((e) => e > 0)
                  .toList();
            }
          }
        }

        // Also parse courts array for any isActive == false
        final rawCourts = data['courts'] as List<dynamic>?;
        if (rawCourts != null) {
          for (final rawCourt in rawCourts) {
            if (rawCourt is Map<String, dynamic>) {
              final vId = rawCourt['venueId']?.toString() ?? '';
              final cNum =
                  int.tryParse(rawCourt['courtNumber']?.toString() ?? '') ?? 0;
              final active = rawCourt['isActive'] == true;
              if (vId.isNotEmpty && cNum > 0 && !active) {
                parsedMap[vId] = parsedMap[vId] ?? [];
                if (!parsedMap[vId]!.contains(cNum)) {
                  parsedMap[vId]!.add(cNum);
                }
              }
            }
          }
        }

        // Alias Tao Đàn (venue_01 <-> venue_q1_04)
        if (parsedMap.containsKey('venue_01')) {
          parsedMap['venue_q1_04'] = List<int>.from(parsedMap['venue_01']!);
        } else if (parsedMap.containsKey('venue_q1_04')) {
          parsedMap['venue_01'] = List<int>.from(parsedMap['venue_q1_04']!);
        }

        inactiveCourtsNotifier.value = Map.unmodifiable(parsedMap);

        // Parse venues array if returned by server
        final rawVenues = data['venues'] as List<dynamic>?;
        if (rawVenues != null && rawVenues.isNotEmpty) {
          final List<Venue> parsedVenues = [];
          for (final rv in rawVenues) {
            if (rv is Map<String, dynamic>) {
              final id = rv['id']?.toString() ?? '';
              final name = rv['name']?.toString() ?? '';
              final address = rv['address']?.toString() ?? '';
              final district = rv['district']?.toString() ?? '';
              final hotline = rv['hotline']?.toString().trim();
              final sports = (rv['sports'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  ['badminton'];
              final hourlyRate =
                  (rv['baseHourlyRate'] as num?)?.toDouble() ?? 150000.0;
              final imageUrl = rv['imageUrl']?.toString() ?? '';
              final count = (rv['totalCourts'] as num?)?.toInt() ?? 6;
              final isActive = rv['isActive'] != false;

              if (id.isNotEmpty && name.isNotEmpty && isActive) {
                // Find existing seed venue to preserve amenities / rating if present
                final existing = SeedData.sampleVenues
                    .where((s) =>
                        s.id == id ||
                        (id == 'venue_01' && s.id == 'venue_q1_04'))
                    .firstOrNull;

                parsedVenues.add(
                  Venue(
                    id: (id == 'venue_01') ? 'venue_q1_04' : id,
                    name: name,
                    address: address.isNotEmpty ? address : (existing?.address ?? ''),
                    district: district,
                    hotline: (hotline?.isNotEmpty ?? false)
                        ? hotline
                        : existing?.hotline,
                    sportTypes: sports,
                    hourlyRate: hourlyRate,
                    courtCount: count,
                    imageUrls: imageUrl.isNotEmpty
                        ? [imageUrl]
                        : (existing?.imageUrls ?? []),
                    rating: existing?.rating ?? 4.8,
                    reviewCount: existing?.reviewCount ?? 100,
                    amenities: existing?.amenities ??
                        ['Máy lạnh', 'WiFi', 'Căn tin', 'Bãi giữ xe'],
                  ),
                );
              }
            }
          }
          if (parsedVenues.isNotEmpty) {
            venuesNotifier.value = List.unmodifiable(parsedVenues);
          }
        }

        // Parse bookings array if returned by server and merge with Realtime bookings
        final rawBookings = data['bookings'] as List<dynamic>?;
        if (rawBookings != null) {
          final List<Map<String, dynamic>> parsedBookings = [];
          final Set<String> seenIds = {};
          final existingIds = bookingsNotifier.value
              .map((b) => (b['id'] ?? b['bookingId'])?.toString() ?? '')
              .toSet();

          for (final rb in rawBookings) {
            if (rb is Map<String, dynamic>) {
              final map = Map<String, dynamic>.from(rb);
              final id = (map['id'] ?? map['bookingId'])?.toString() ?? '';
              if (id.isNotEmpty) {
                seenIds.add(id);
                if (!existingIds.contains(id) && existingIds.isNotEmpty) {
                  try {
                    NotificationStore.instance.addNotification(
                      AppNotification(
                        id: 'notif_server_bk_$id',
                        title: 'Lịch Đặt Sân Mới 🏟️',
                        message:
                            'Khách hàng ${map['customerName'] ?? 'Khách'} vừa đặt ${map['courtName'] ?? 'Sân'} (${map['timeSlot'] ?? ''}, ngày ${map['date'] ?? ''}).',
                        timestamp: DateTime.now(),
                        type: NotificationType.booking,
                        role: NotificationRole.owner,
                        isRead: false,
                      ),
                    );
                  } catch (_) {}
                }
              }
              parsedBookings.add(map);
            }
          }
          for (final existing in bookingsNotifier.value) {
            final id =
                (existing['id'] ?? existing['bookingId'])?.toString() ?? '';
            if (id.isNotEmpty && !seenIds.contains(id)) {
              parsedBookings.add(existing);
            }
          }
          bookingsNotifier.value = List.unmodifiable(parsedBookings);
          _saveBookingsLocally();
        }

        if (client == null && SupabaseService.instance.isConfigured) {
          await syncFromSupabaseCloud();
        }

        lastSyncTimeNotifier.value = DateTime.now();
        return true;
      }

      if (client == null && SupabaseService.instance.isConfigured) {
        final cloudSynced = await syncFromSupabaseCloud();
        if (cloudSynced) {
          lastSyncTimeNotifier.value = DateTime.now();
          return true;
        }
      }
    } catch (_) {
      // Graceful fallback: keep current in-memory state on network failure or timeout
    } finally {
      if (client == null) {
        try {
          httpClient.close();
        } catch (_) {}
      }
    }
    return false;
  }

  /// Synchronizes venues and bookings directly from Supabase PostgreSQL Cloud
  /// when configured, ensuring multi-device APK deployments stay in sync anywhere.
  Future<bool> syncFromSupabaseCloud() async {
    if (!SupabaseService.instance.isConfigured) return false;
    bool syncedAny = false;
    try {
      final rows = await SupabaseService.instance.fetchBookings();
      if (rows.isNotEmpty) {
        final current = List<Map<String, dynamic>>.from(bookingsNotifier.value);
        bool changed = false;
        for (final row in rows) {
          final id = (row['booking_id'] ?? row['id'])?.toString();
          if (id == null || id.isEmpty) continue;
          final formatted = <String, dynamic>{
            'id': id,
            'bookingId': id,
            'venueId': row['venue_id'] ?? 'venue_01',
            'venueName': row['venue_name'],
            'courtNumber':
                int.tryParse(row['court_number']?.toString() ?? '') ?? 1,
            'courtName': row['court_name'] ?? 'Sân 1',
            'sport': row['sport'] ?? 'badminton',
            'date': row['date']?.toString() ?? '',
            'timeSlot': row['time_slot'] ??
                '${row['start_time'] ?? '18:00'} - ${row['end_time'] ?? '19:00'}',
            'startTime': row['start_time'] ?? '18:00',
            'endTime': row['end_time'] ?? '19:00',
            'customerName': row['customer_name'] ?? 'Khách hàng',
            'customerPhone': row['customer_phone'] ?? '',
            'price': (row['price'] as num?)?.toDouble() ?? 0.0,
            'paymentStatus': row['payment_status'] ?? 'pending',
            'paymentMethod': row['payment_method'] ?? 'vietqr',
            'checkedIn': row['checked_in'] == true,
            'checkedInAt': row['checked_in_at'],
            'addOns': row['add_ons'] is List ? row['add_ons'] : [],
          };
          final existingIdx = current.indexWhere(
            (b) => b['id'] == id || b['bookingId'] == id,
          );
          if (existingIdx == -1) {
            current.add(formatted);
            changed = true;
          } else if (current[existingIdx]['checkedIn'] !=
                  formatted['checkedIn'] ||
              current[existingIdx]['paymentStatus'] !=
                  formatted['paymentStatus']) {
            current[existingIdx] = {
              ...current[existingIdx],
              ...formatted,
            };
            changed = true;
          }
          if (formatted['checkedIn'] == true) {
            TicketStore.instance.updateTicketStatus(id, 'checked_in');
          }
        }
        if (changed) {
          bookingsNotifier.value = List.unmodifiable(current);
        }
        syncedAny = true;
      }
    } catch (_) {}
    return syncedAny;
  }

  /// Starts polling the admin web server every [interval]
  void startPolling({Duration interval = const Duration(seconds: 2)}) {
    if (!isSyncEnabled || isTestEnvironment) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) {
      syncWithServer();
    });
    // Immediately trigger initial sync
    syncWithServer();

    // Subscribe to Supabase Realtime WebSocket changes if configured
    if (SupabaseService.instance.isConfigured) {
      SupabaseService.instance.subscribeToLiveBookings(
        onInsert: (newRecord) {
          final id = (newRecord['booking_id'] ?? newRecord['id'])?.toString();
          if (id != null && !bookingsNotifier.value.any((b) => b['id'] == id)) {
            final formatted = {
              'id': id,
              'bookingId': id,
              'venueId': newRecord['venue_id'],
              'courtNumber':
                  int.tryParse(newRecord['court_number']?.toString() ?? '') ?? 1,
              'courtName': newRecord['court_name'],
              'sport': newRecord['sport'],
              'date': newRecord['date']?.toString(),
              'timeSlot': newRecord['time_slot'] ??
                  '${newRecord['start_time'] ?? '18:00'} - ${newRecord['end_time'] ?? '19:00'}',
              'startTime': newRecord['start_time'],
              'endTime': newRecord['end_time'],
              'customerName': newRecord['customer_name'],
              'customerPhone': newRecord['customer_phone'],
              'price': (newRecord['price'] as num?)?.toDouble() ?? 0.0,
              'paymentStatus': newRecord['payment_status'] ?? 'pending',
              'paymentMethod': newRecord['payment_method'] ?? 'vietqr',
              'checkedIn': newRecord['checked_in'] == true,
              'addOns': newRecord['add_ons'] is List ? newRecord['add_ons'] : [],
            };
            final updated = List<Map<String, dynamic>>.from(bookingsNotifier.value);
            updated.insert(0, formatted);
            bookingsNotifier.value = List.unmodifiable(updated);
          }
        },
        onUpdate: (updatedRecord) {
          final id = (updatedRecord['booking_id'] ?? updatedRecord['id'])?.toString();
          if (id != null) {
            final isCheckedIn = updatedRecord['checked_in'] == true;
            if (isCheckedIn) {
              TicketStore.instance.updateTicketStatus(id, 'checked_in');
              try {
                VenueOwnerStore.instance.checkIn(id);
              } catch (_) {}
            }
            final updated = List<Map<String, dynamic>>.from(bookingsNotifier.value);
            final idx = updated.indexWhere((b) => b['id'] == id || b['bookingId'] == id);
            if (idx != -1) {
              updated[idx] = {
                ...updated[idx],
                'checkedIn': isCheckedIn,
                'checkedInAt': updatedRecord['checked_in_at'],
                'paymentStatus': updatedRecord['payment_status'] ?? updated[idx]['paymentStatus'],
              };
              bookingsNotifier.value = List.unmodifiable(updated);
            }
          }
        },
      );
    }
  }

  /// Stops background polling
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (SupabaseService.instance.isConfigured) {
      SupabaseService.instance.dispose();
    }
  }

  /// Reset to clean initial state (court 1 of Tao Dan inactive as pre-configured)
  void reset() {
    stopPolling();
    inactiveCourtsNotifier.value = {
      'venue_01': [1],
      'venue_q1_04': [1],
    };
    venuesNotifier.value = List.of(SeedData.sampleVenues);
    bookingsNotifier.value = [];
    lastSyncTimeNotifier.value = null;
  }
}
