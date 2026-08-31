class LocationCoords {
  final double latitude;
  final double longitude;
  final double accuracy;

  LocationCoords({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      };
}
