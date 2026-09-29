import '../../core/utils/sport_image_catalog.dart';

class TicketModel {
  final String id;
  final String bookingId;
  final String venueName;
  final String sportType;
  final int courtNumber;
  final String matchDate;
  final String startTime;
  final String endTime;
  final double totalPrice;
  final String qrCodeData;
  final String status;
  final String createdAt;
  final String district;

  TicketModel({
    required this.id,
    required this.bookingId,
    required this.venueName,
    required this.sportType,
    required this.courtNumber,
    required this.matchDate,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.qrCodeData,
    required this.status,
    required this.createdAt,
    this.district = 'Bình Thạnh',
  });

  String get timeSlot => '$startTime - $endTime';
  String get venueImage => SportImageCatalog.getDefaultImageForSport(sportType);
  bool get isValid => status != 'cancelled';
  bool get isExpired => status == 'completed' || status == 'expired';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'venue_name': venueName,
      'sport_type': sportType,
      'court_number': courtNumber,
      'match_date': matchDate,
      'start_time': startTime,
      'end_time': endTime,
      'total_price': totalPrice,
      'qr_code_data': qrCodeData,
      'status': status,
      'created_at': createdAt,
      'district': district,
    };
  }

  factory TicketModel.fromMap(Map<String, dynamic> map) {
    return TicketModel(
      id: map['id'] as String,
      bookingId: map['booking_id'] as String,
      venueName: map['venue_name'] as String,
      sportType: map['sport_type'] as String,
      courtNumber: map['court_number'] as int,
      matchDate: map['match_date'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      totalPrice: (map['total_price'] as num).toDouble(),
      qrCodeData: map['qr_code_data'] as String,
      status: map['status'] as String,
      createdAt: map['created_at'] as String,
      district: (map['district'] as String?) ?? 'Bình Thạnh',
    );
  }
}
