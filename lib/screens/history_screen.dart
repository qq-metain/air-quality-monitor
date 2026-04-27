import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/air_quality_record.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/l10n.dart';

class HistoryScreen extends StatefulWidget {
  final int userId;

  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AirQualityRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    locale.addListener(_onLocaleChange);
    _load();
  }

  @override
  void dispose() {
    locale.removeListener(_onLocaleChange);
    super.dispose();
  }

  void _onLocaleChange() => setState(() {});

  Future<void> _load() async {
    final records = await DatabaseService.getRecords(widget.userId);
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _delete(AirQualityRecord record) async {
    await DatabaseService.deleteRecord(record.id!);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.t('Deleted', '已删除'))));
  }

  void _showDetail(AirQualityRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.aqiColor(record.aqi), borderRadius: BorderRadius.circular(20)),
                    child: Text('AQI ${record.aqi.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Text(record.aqiLevel(locale.isChinese), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 12),
              Text(DateFormat('yyyy-MM-dd HH:mm').format(record.recordTime), style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              _detailRow('PM2.5', '${record.pm25.toStringAsFixed(1)} μg/m³'),
              _detailRow('PM10', '${record.pm10.toStringAsFixed(1)} μg/m³'),
              _detailRow(locale.t('Ozone O₃', '臭氧 O₃'), '${record.o3.toStringAsFixed(1)} μg/m³'),
              _detailRow(locale.t('Nitrogen Dioxide NO₂', '二氧化氮 NO₂'), '${record.no2.toStringAsFixed(1)} μg/m³'),
              _detailRow(locale.t('Sulfur Dioxide SO₂', '二氧化硫 SO₂'), '${record.so2.toStringAsFixed(1)} μg/m³'),
              _detailRow(locale.t('Carbon Monoxide CO', '一氧化碳 CO'), '${record.co.toStringAsFixed(1)} μg/m³'),
              const Divider(height: 32),
              Text(locale.t('AI Advice', 'AI 建议'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Text(record.aiAdvice, style: const TextStyle(fontSize: 14, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(locale.t('History', '历史记录'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 60, color: AppTheme.textSecondary),
                      const SizedBox(height: 12),
                      Text(locale.t('No history records', '暂无历史记录'), style: const TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final r = _records[i];
                      final color = AppTheme.aqiColor(r.aqi);
                      return Dismissible(
                        key: Key(r.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (_) => _delete(r),
                        child: Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            onTap: () => _showDetail(r),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                              child: Center(
                                child: Text(r.aqi.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            title: Text(r.aqiLevel(locale.isChinese), style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PM2.5: ${r.pm25.toStringAsFixed(1)}  PM10: ${r.pm10.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12)),
                                Text(DateFormat('yyyy-MM-dd HH:mm').format(r.recordTime), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
