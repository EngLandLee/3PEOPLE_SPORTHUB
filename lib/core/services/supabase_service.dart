import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase service providing PostgreSQL persistence,
/// anti-double-booking transactions, and Realtime WebSocket updates for SportHub.
class SupabaseService {
  SupabaseService._internal();

  static final SupabaseService instance = SupabaseService._internal();

  SupabaseClient? _client;
  bool _isInitialized = false;
  String? _currentUrl;
  RealtimeChannel? _bookingsChannel;

  /// Default configuration from environment variables or overrides
  static const String envUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://avlizwimxvgnzqdmxily.supabase.co',
  );
  static const String envAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2bGl6d2lteHZnbnpxZG14aWx5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMxMTQ5NjAsImV4cCI6MjEwODY5MDk2MH0.JtNJ3joPBjnGYNKLQkJ9gHQqxOA5udAImiHkSklOrRg',
  );

  /// Returns true only if Supabase has been properly configured with a live project URL and Key.
  bool get isConfigured =>
      _isInitialized &&
      _client != null &&
      _currentUrl != null &&
      !_currentUrl!.contains('YOUR_PROJECT_REF');

  SupabaseClient? get client => _client;

  /// Initializes Supabase client.
  /// If credentials are empty or placeholders, it remains unconfigured and falls back safely to local sync.
  Future<bool> initialize({
    String? url,
    String? anonKey,
  }) async {
    final targetUrl = (url ?? envUrl).trim();
    final targetKey = (anonKey ?? envAnonKey).trim();

    if (targetUrl.isEmpty ||
        targetKey.isEmpty ||
        targetUrl.contains('YOUR_PROJECT_REF') ||
        targetKey.contains('YOUR_ANON_KEY')) {
      debugPrint('ℹ️ [SupabaseService] No credentials provided. Running in local sync / fallback mode.');
      _isInitialized = false;
      _currentUrl = null;
      return false;
    }

    try {
      await Supabase.initialize(
        url: targetUrl,
        // ignore: deprecated_member_use
        anonKey: targetKey,
        debug: kDebugMode,
      );
      _client = Supabase.instance.client;
      _currentUrl = targetUrl;
      _isInitialized = true;
      debugPrint('✅ [SupabaseService] Successfully connected to Supabase: $targetUrl');
      return true;
    } catch (e) {
      debugPrint('⚠️ [SupabaseService] Initialization failed ($e). Falling back to local store.');
      _isInitialized = false;
      _currentUrl = null;
      return false;
    }
  }

  // ===========================================================================
  // 1. VENUES & COURTS
  // ===========================================================================

  Future<List<Map<String, dynamic>>> fetchVenues() async {
    if (!isConfigured) return [];
    try {
      final data = await _client!
          .from('venues')
          .select()
          .eq('is_active', true)
          .order('name');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('⚠️ [SupabaseService] Error fetching venues: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchCourts(String venueId) async {
    if (!isConfigured) return [];
    try {
      final data = await _client!
          .from('courts')
          .select()
          .eq('venue_id', venueId)
          .eq('is_active', true)
          .order('court_number');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('⚠️ [SupabaseService] Error fetching courts: $e');
      return [];
    }
  }

  // ===========================================================================
  // 2. BOOKINGS & CONCURRENCY CONTROLS
  // ===========================================================================

  Future<List<Map<String, dynamic>>> fetchBookings({String? venueId}) async {
    if (!isConfigured) return [];
    try {
      var query = _client!.from('bookings').select();
      if (venueId != null && venueId.isNotEmpty) {
        query = query.eq('venue_id', venueId);
      }
      final data = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('⚠️ [SupabaseService] Error fetching bookings: $e');
      return [];
    }
  }

  /// Safe booking creation using PostgreSQL anti-double-booking function
  Future<Map<String, dynamic>> createBookingSafely({
    required String bookingId,
    required String venueId,
    String? venueName,
    required int courtNumber,
    required String courtName,
    required String sport,
    required String date,
    required String startTime,
    required String endTime,
    required String customerName,
    required String customerPhone,
    required double price,
    String paymentMethod = 'vietqr',
    List<Map<String, dynamic>>? addOns,
  }) async {
    if (!isConfigured) {
      return {'success': false, 'message': 'Supabase is not configured'};
    }

    try {
      // 1. Try invoking PostgreSQL atomic transaction function
      final response = await _client!.rpc(
        'fn_book_court_slot',
        params: {
          'p_booking_id': bookingId,
          'p_venue_id': venueId,
          'p_court_number': courtNumber,
          'p_court_name': courtName,
          'p_sport': sport,
          'p_date': date,
          'p_start_time': startTime,
          'p_end_time': endTime,
          'p_customer_name': customerName,
          'p_customer_phone': customerPhone,
          'p_price': price,
          'p_payment_method': paymentMethod,
          'p_add_ons': addOns ?? [],
        },
      );

      if (venueName != null && venueName.trim().isNotEmpty) {
        try {
          await _client!
              .from('bookings')
              .update({'venue_name': venueName.trim()})
              .eq('id', bookingId);
        } catch (_) {}
      }

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'success': true, 'booking_id': bookingId};
    } catch (e) {
      debugPrint('❌ [SupabaseService] RPC fn_book_court_slot error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Check-in ticket on Supabase PostgreSQL
  Future<bool> checkInTicket(String ticketId) async {
    if (!isConfigured) return false;
    final cleanId = ticketId.trim().toUpperCase();

    try {
      // Try atomic stored procedure
      final res = await _client!.rpc(
        'fn_checkin_booking',
        params: {'p_ticket_id': cleanId},
      );
      if (res is Map && res['success'] == true) {
        return true;
      }
    } catch (_) {}

    try {
      await _client!
          .from('bookings')
          .update({
            'checked_in': true,
            'checked_in_at': DateTime.now().toIso8601String(),
          })
          .or('id.ilike.$cleanId,booking_id.ilike.$cleanId');
      return true;
    } catch (e) {
      debugPrint('⚠️ [SupabaseService] checkInTicket failed: $e');
      return false;
    }
  }

  // ===========================================================================
  // 3. REALTIME SUBSCRIPTIONS (WebSocket)
  // ===========================================================================

  void subscribeToLiveBookings({
    required void Function(Map<String, dynamic> newRecord) onInsert,
    required void Function(Map<String, dynamic> updatedRecord) onUpdate,
  }) {
    if (!isConfigured) return;

    _bookingsChannel?.unsubscribe();
    _bookingsChannel = _client!
        .channel('public:bookings')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bookings',
          callback: (payload) {
            debugPrint('🔔 [Supabase Realtime] New booking inserted: ${payload.newRecord}');
            onInsert(Map<String, dynamic>.from(payload.newRecord));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          callback: (payload) {
            debugPrint('🔔 [Supabase Realtime] Booking updated: ${payload.newRecord}');
            onUpdate(Map<String, dynamic>.from(payload.newRecord));
          },
        )
        .subscribe();
  }

  // ===========================================================================
  // 4. USER PROFILES
  // ===========================================================================

  static String toUuid(String id) {
    if (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(id)) {
      return id;
    }
    final rawDigits = id.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    final padded = rawDigits.padRight(32, '0').substring(0, 32);
    return '${padded.substring(0, 8)}-${padded.substring(8, 12)}-4${padded.substring(13, 16)}-8${padded.substring(17, 20)}-${padded.substring(20, 32)}';
  }

  Future<bool> syncUserProfile({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    String role = 'player',
    String preferredSport = 'pickleball',
    String skillLevel = 'Beginner',
    String? district,
  }) async {
    if (!isConfigured) return false;
    try {
      final uuid = toUuid(userId);
      await _client!.from('user_profiles').upsert({
        'id': uuid,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ [SupabaseService] Synced profile for $email to Supabase');
      return true;
    } catch (e) {
      debugPrint('⚠️ [SupabaseService] syncUserProfile failed: $e');
      return false;
    }
  }

  void dispose() {
    _bookingsChannel?.unsubscribe();
  }
}
