import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/venue.dart';
import '../state/venue_owner_store.dart';
import '../utils/seed_data.dart';

/// Service for synchronizing venue court availability and status
/// between the SportHub Admin/Partner Web Portal and the Flutter Mobile App.
class VenueSyncService {
  VenueSyncService._internal();

  static final VenueSyncService instance = VenueSyncService._internal();

  String serverBaseUrl = 'http://localhost:5173';
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
    try {
      if (Uri.base.scheme == 'http' || Uri.base.scheme == 'https') {
        final host = Uri.base.host;
        if (host.isNotEmpty) {
          urls.add('${Uri.base.scheme}://$host:5173');
        }
      }
    } catch (_) {}
    if (!urls.contains(serverBaseUrl)) urls.add(serverBaseUrl);
    if (!urls.contains('http://127.0.0.1:5173')) urls.add('http://127.0.0.1:5173');
    if (!urls.contains('http://localhost:5173')) urls.add('http://localhost:5173');
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
    final isTaoDan = (venueName != null &&
            venueName.toLowerCase().contains('tao đàn')) ||
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
    final isTaoDan = (venueName != null &&
            venueName.toLowerCase().contains('tao đàn')) ||
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
        if (bDate.isNotEmpty && date.isNotEmpty && !_isMatchingDate(bDate, date)) {
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
        final bookingStartMin = _parseTimeToMinutes(
            bStartTime.isNotEmpty ? bStartTime : bTimeSlot.split('-').first.trim());
        final bookingEndMin = _parseTimeToMinutes(bookingEndTime);

        if (slotStartMin != null && bookingStartMin != null && bookingEndMin != null) {
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
      'paymentStatus': 'paid',
      'paymentMethod': paymentMethod,
      'checkedIn': false,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Immediately update local in-memory bookings for snappy UI
    final current = List<Map<String, dynamic>>.from(bookingsNotifier.value);
    current.removeWhere((b) => b['id'] == bookingId);
    current.insert(0, newBooking);
    bookingsNotifier.value = List.unmodifiable(current);

    // Synchronize to mobile owner store if Tao Dan
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
        return response.statusCode == 200 || response.statusCode == 201;
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
        client: client,
      );

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
                    address: address,
                    district: district,
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

        // Parse bookings array if returned by server
        final rawBookings = data['bookings'] as List<dynamic>?;
        if (rawBookings != null) {
          final List<Map<String, dynamic>> parsedBookings = [];
          for (final rb in rawBookings) {
            if (rb is Map<String, dynamic>) {
              parsedBookings.add(Map<String, dynamic>.from(rb));
            }
          }
          bookingsNotifier.value = List.unmodifiable(parsedBookings);
        }

        lastSyncTimeNotifier.value = DateTime.now();
        return true;
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

  /// Starts polling the admin web server every [interval]
  void startPolling({Duration interval = const Duration(seconds: 2)}) {
    if (!isSyncEnabled || isTestEnvironment) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) {
      syncWithServer();
    });
    // Immediately trigger initial sync
    syncWithServer();
  }

  /// Stops background polling
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
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
