import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  static String get _apiKey => dotenv.env['DEEPSEEK_API_KEY'] ?? '';

  static const String _baseUrl =
      'https://api.deepseek.com/v1/chat/completions';

  static Future<String> getAirQualityAdvice({
    required double aqi,
    required double pm25,
    required double pm10,
    required double o3,
    required double no2,
    required String location,
    bool isChinese = false,
  }) async {
    // 如果 apikey.env 没有配置 key，就不要请求 API
    if (_apiKey.isEmpty) {
      return _fallbackAdvice(
        aqi: aqi,
        pm25: pm25,
        pm10: pm10,
        isChinese: isChinese,
      );
    }

    final prompt = isChinese
        ? '空气质量数据：AQI=$aqi，PM2.5=${pm25}μg/m³，PM10=${pm10}μg/m³，臭氧=${o3}μg/m³，二氧化氮=${no2}μg/m³，位置=$location。\n请根据以上数据，给出简洁实用的健康建议（100字以内），包括是否适合外出、运动、开窗等。'
        : 'Air quality data: AQI=$aqi, PM2.5=${pm25}μg/m³, PM10=${pm10}μg/m³, Ozone=${o3}μg/m³, NO₂=${no2}μg/m³, location=$location.\nBased on the above data, provide concise and practical health advice within 100 words, including whether it is suitable to go outside, exercise, or open windows.';

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'deepseek-chat',
              'messages': [
                {
                  'role': 'user',
                  'content': prompt,
                }
              ],
              'max_tokens': 200,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        final advice = data['choices']?[0]?['message']?['content']
            ?.toString()
            .trim();

        if (advice != null && advice.isNotEmpty) {
          return advice;
        }
      }

      return _fallbackAdvice(
        aqi: aqi,
        pm25: pm25,
        pm10: pm10,
        isChinese: isChinese,
      );
    } catch (_) {
      return _fallbackAdvice(
        aqi: aqi,
        pm25: pm25,
        pm10: pm10,
        isChinese: isChinese,
      );
    }
  }

  static String _fallbackAdvice({
    required double aqi,
    required double pm25,
    required double pm10,
    required bool isChinese,
  }) {
    if (isChinese) {
      if (aqi <= 50) {
        return '空气质量较好，适合外出、通风和一般户外活动。敏感人群仍可关注PM2.5变化。';
      } else if (aqi <= 100) {
        return '空气质量一般，可以短时间外出，但建议减少高强度户外运动，并根据PM2.5水平决定是否开窗。';
      } else if (aqi <= 150) {
        return '空气质量对敏感人群不太友好。建议减少长时间户外活动，老人、儿童和呼吸道敏感人群应更加谨慎。';
      } else {
        return '空气质量较差，建议减少外出和户外运动，尽量关闭窗户，必要时佩戴口罩。';
      }
    } else {
      if (aqi <= 50) {
        return 'Air quality is good. Outdoor activity and ventilation are generally suitable. Sensitive users should still monitor PM2.5 changes.';
      } else if (aqi <= 100) {
        return 'Air quality is moderate. Short outdoor activity is acceptable, but intense outdoor exercise should be reduced.';
      } else if (aqi <= 150) {
        return 'Air quality may be unhealthy for sensitive groups. Reduce long outdoor exposure, especially for children, older adults, and people with respiratory issues.';
      } else {
        return 'Air quality is poor. Reduce outdoor activity, avoid intense exercise, keep windows closed, and consider wearing a mask if going outside.';
      }
    }
  }
}