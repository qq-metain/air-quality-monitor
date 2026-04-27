import 'package:flutter/material.dart';
import '../models/air_quality_record.dart';
import '../services/location_service.dart';
import '../services/air_quality_service.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../utils/auth_utils.dart';
import '../utils/app_theme.dart';
import '../utils/l10n.dart';
import 'login_screen.dart';
import 'history_screen.dart';
import 'chart_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final String username;

  const HomeScreen({super.key, required this.userId, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = false;
  AirQualityRecord? _current;
  String? _error;

  @override
  void initState() {
    super.initState();
    locale.addListener(_onLocaleChange);
  }

  @override
  void dispose() {
    locale.removeListener(_onLocaleChange);
    super.dispose();
  }

  void _onLocaleChange() => setState(() {});

  Future<void> _fetchAirQuality() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final position = await LocationService.getCurrentPosition();
    if (position == null) {
      setState(() {
        _loading = false;
        _error = locale.t('Unable to get location. Please check location permissions.', '无法获取位置，请检查定位权限');
      });
      return;
    }

    final data = await AirQualityService.fetchAirQuality(position.latitude, position.longitude);
    if (data == null) {
      setState(() {
        _loading = false;
        _error = locale.t('Unable to get air quality data. Please check your network.', '无法获取空气质量数据，请检查网络');
      });
      return;
    }

    final locationName = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

    final advice = await AiService.getAirQualityAdvice(
      aqi: data['aqi']!,
      pm25: data['pm25']!,
      pm10: data['pm10']!,
      o3: data['o3']!,
      no2: data['no2']!,
      location: locationName,
      isChinese: locale.isChinese,
    );

    final record = AirQualityRecord(
      userId: widget.userId,
      latitude: position.latitude,
      longitude: position.longitude,
      locationName: locationName,
      aqi: data['aqi']!,
      pm25: data['pm25']!,
      pm10: data['pm10']!,
      o3: data['o3']!,
      no2: data['no2']!,
      so2: data['so2']!,
      co: data['co']!,
      aiAdvice: advice,
      recordTime: DateTime.now(),
    );

    await DatabaseService.insertRecord(record);

    setState(() {
      _current = record;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await AuthUtils.clearSession();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _toggleLanguage() {
    locale.toggle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(locale.t('Hello, ${widget.username}', '你好，${widget.username}')),
        actions: [
          TextButton(
            onPressed: _toggleLanguage,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(locale.isChinese ? 'EN' : '中文', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(userId: widget.userId))),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen(userId: widget.userId))),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                ]),
              ),
            if (_current != null) ...[
              _buildAqiCard(),
              const SizedBox(height: 16),
              _buildPollutantsCard(),
              const SizedBox(height: 16),
              _buildAdviceCard(),
            ],
            if (_current == null && !_loading && _error == null)
              Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_queue, size: 80, color: AppTheme.accent),
                    const SizedBox(height: 16),
                    Text(
                      locale.t('Tap the button below to get current air quality', '点击下方按钮获取当前位置空气质量'),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _fetchAirQuality,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.my_location),
        label: Text(_loading ? locale.t('Fetching...', '获取中...') : locale.t('Get Air Quality', '获取空气质量')),
      ),
    );
  }

  Widget _buildAqiCard() {
    final record = _current!;
    final color = AppTheme.aqiColor(record.aqi);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(locale.t('Air Quality Index', '空气质量指数'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                Text(record.aqiLevel(locale.isChinese), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Text(record.aqi.toStringAsFixed(0),
                style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(record.locationName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollutantsCard() {
    final record = _current!;
    final items = [
      {'label': 'PM2.5', 'value': '${record.pm25.toStringAsFixed(1)} μg/m³'},
      {'label': 'PM10', 'value': '${record.pm10.toStringAsFixed(1)} μg/m³'},
      {'label': locale.t('Ozone O₃', '臭氧 O₃'), 'value': '${record.o3.toStringAsFixed(1)} μg/m³'},
      {'label': locale.t('Nitrogen Dioxide NO₂', '二氧化氮 NO₂'), 'value': '${record.no2.toStringAsFixed(1)} μg/m³'},
      {'label': locale.t('Sulfur Dioxide SO₂', '二氧化硫 SO₂'), 'value': '${record.so2.toStringAsFixed(1)} μg/m³'},
      {'label': locale.t('Carbon Monoxide CO', '一氧化碳 CO'), 'value': '${record.co.toStringAsFixed(1)} μg/m³'},
    ];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.t('Pollutant Details', '污染物详情'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(items[i]['label']!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(items[i]['value']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.smart_toy_outlined, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Text(locale.t('AI Health Advice', 'AI 健康建议'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 14),
            Text(_current!.aiAdvice, style: const TextStyle(fontSize: 14, height: 1.6, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }
}
