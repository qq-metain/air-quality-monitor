import 'dart:convert';
import 'package:http/http.dart' as http;

class AirQualityService {
  static Future<Map<String, double>?> fetchAirQuality(double lat, double lon) async {
    final url = Uri.parse(
      'https://air-quality-api.open-meteo.com/v1/air-quality'
      '?latitude=$lat&longitude=$lon'
      '&current=pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,european_aqi',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final current = data['current'];

      double pm25 = (current['pm2_5'] ?? 0).toDouble();
      double pm10 = (current['pm10'] ?? 0).toDouble();
      double co = (current['carbon_monoxide'] ?? 0).toDouble();
      double no2 = (current['nitrogen_dioxide'] ?? 0).toDouble();
      double so2 = (current['sulphur_dioxide'] ?? 0).toDouble();
      double o3 = (current['ozone'] ?? 0).toDouble();
      double aqi = (current['european_aqi'] ?? 0).toDouble();

      return {
        'aqi': aqi,
        'pm25': pm25,
        'pm10': pm10,
        'co': co,
        'no2': no2,
        'so2': so2,
        'o3': o3,
      };
    } catch (_) {
      return null;
    }
  }

  static String getAqiLevel(double aqi, {bool isChinese = false}) {
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
