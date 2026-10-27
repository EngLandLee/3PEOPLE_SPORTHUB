import '../../domain/entities/venue.dart';

class VenueModel extends Venue {
  const VenueModel({
    required super.id,
    required super.name,
    required super.sportTypes,
    required super.address,
    required super.district,
    super.hotline,
    required super.courtCount,
    required super.hourlyRate,
    required super.rating,
    required super.reviewCount,
    required super.imageUrls,
    required super.amenities,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sportTypes': sportTypes,
      'address': address,
      'district': district,
      if (hotline != null) 'hotline': hotline,
      'courtCount': courtCount,
      'hourlyRate': hourlyRate,
      'rating': rating,
      'reviewCount': reviewCount,
      'imageUrls': imageUrls,
      'amenities': amenities,
    };
  }

  factory VenueModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return VenueModel(
      id: id ?? (map['id'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      sportTypes: List<String>.from(map['sportTypes'] as List? ?? []),
      address: map['address'] as String? ?? '',
      district: map['district'] as String? ?? '',
      hotline: map['hotline'] as String?,
      courtCount: (map['courtCount'] as num?)?.toInt() ?? 0,
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      imageUrls: List<String>.from(map['imageUrls'] as List? ?? []),
      amenities: List<String>.from(map['amenities'] as List? ?? []),
    );
  }
}
