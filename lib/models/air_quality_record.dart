class AirQualityRecord {
  final int? id;
  final int userId;
  final double latitude;
  final double longitude;
  final String locationName;
  final double aqi;
  final double pm25;
  final double pm10;
  final double o3;
  final double no2;
  final double so2;
  final double co;
  final String aiAdvice;
  final DateTime recordTime;

  AirQualityRecord({
    this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.o3,
    required this.no2,
    required this.so2,
    required this.co,
    required this.aiAdvice,
    required this.recordTime,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'location_name': locationName,
        'aqi': aqi,
        'pm25': pm25,
        'pm10': pm10,
        'o3': o3,
        'no2': no2,
        'so2': so2,
        'co': co,
        'ai_advice': aiAdvice,
        'record_time': recordTime.toIso8601String(),
      };

  factory AirQualityRecord.fromMap(Map<String, dynamic> map) => AirQualityRecord(
        id: map['id'],
        userId: map['user_id'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        locationName: map['location_name'],
        aqi: map['aqi'],
        pm25: map['pm25'],
        pm10: map['pm10'],
        o3: map['o3'],
        no2: map['no2'],
        so2: map['so2'],
        co: map['co'],
        aiAdvice: map['ai_advice'],
        recordTime: DateTime.parse(map['record_time']),
      );

  String aqiLevel(bool isChinese) {
    if (isChinese) {
      if (aqi <= 50) return '优';
      if (aqi <= 100) return '良';
      if (aqi <= 150) return '轻度污染';
      if (aqi <= 200) return '中度污染';
      if (aqi <= 300) return '重度污染';
      return '严重污染';
    } else {
      if (aqi <= 50) return 'Good';
      if (aqi <= 100) return 'Moderate';
      if (aqi <= 150) return 'Unhealthy for Sensitive';
      if (aqi <= 200) return 'Unhealthy';
      if (aqi <= 300) return 'Very Unhealthy';
      return 'Hazardous';
    }
  }
}
