class Venue {
  final String id;
  final String name;
  final List<String> sportTypes;
  final String address;
  final String district;
  final String? hotline;
  final int courtCount;
  final double hourlyRate;
  final double rating;
  final int reviewCount;
  final List<String> imageUrls;
  final List<String> amenities;

  const Venue({
    required this.id,
    required this.name,
    required this.sportTypes,
    required this.address,
    required this.district,
    this.hotline,
    required this.courtCount,
    required this.hourlyRate,
    required this.rating,
    required this.reviewCount,
    required this.imageUrls,
    required this.amenities,
  });
}
