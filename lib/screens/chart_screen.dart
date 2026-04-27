import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/air_quality_record.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/l10n.dart';

class ChartScreen extends StatefulWidget {
  final int userId;

  const ChartScreen({super.key, required this.userId});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<AirQualityRecord> _records = [];
  bool _loading = true;
  String _selected = 'AQI';
  final List<String> _metrics = ['AQI', 'PM2.5', 'PM10', 'O₃', 'NO₂'];

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
    final records = await DatabaseService.getWeekRecords(widget.userId);
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  List<FlSpot> _getSpots() {
    return List.generate(_records.length, (i) {
      final r = _records[i];
      double y = switch (_selected) {
        'AQI' => r.aqi,
        'PM2.5' => r.pm25,
        'PM10' => r.pm10,
        'O₃' => r.o3,
        'NO₂' => r.no2,
        _ => r.aqi,
      };
      return FlSpot(i.toDouble(), y);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(locale.t('Weekly Trend', '一周趋势图'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.show_chart, size: 60, color: AppTheme.textSecondary),
                      const SizedBox(height: 12),
                      Text(locale.t('No data in the past 7 days', '近7天暂无数据'), style: const TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _metrics.map((m) {
                            final selected = m == _selected;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(m),
                                selected: selected,
                                onSelected: (_) => setState(() => _selected = m),
                                selectedColor: AppTheme.primary,
                                labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            height: 280,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 50,
                                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (v, _) {
                                        final i = v.toInt();
                                        if (i < 0 || i >= _records.length) return const SizedBox();
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(DateFormat('MM/dd').format(_records[i].recordTime), style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _getSpots(),
                                    isCurved: true,
                                    color: AppTheme.primary,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                                        radius: 4,
                                        color: Colors.white,
                                        strokeWidth: 2,
                                        strokeColor: AppTheme.primary,
                                      ),
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [AppTheme.primary.withOpacity(0.3), AppTheme.primary.withOpacity(0.0)],
                                      ),
                                    ),
                                  ),
                                ],
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipItems: (spots) => spots.map((s) {
                                      final i = s.spotIndex;
                                      final time = i < _records.length ? DateFormat('MM-dd HH:mm').format(_records[i].recordTime) : '';
                                      return LineTooltipItem('$_selected: ${s.y.toStringAsFixed(1)}\n$time', const TextStyle(color: Colors.white, fontSize: 12));
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(locale.t('Statistics Summary', '统计摘要'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _statItem(locale.t('Records', '记录次数'), '${_records.length}${locale.t('', '次')}'),
                                  _statItem(locale.t('Avg AQI', '平均AQI'), _records.isEmpty ? '-' : (_records.map((r) => r.aqi).reduce((a, b) => a + b) / _records.length).toStringAsFixed(1)),
                                  _statItem(locale.t('Max AQI', '最高AQI'), _records.isEmpty ? '-' : _records.map((r) => r.aqi).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)),
                                  _statItem(locale.t('Min AQI', '最低AQI'), _records.isEmpty ? '-' : _records.map((r) => r.aqi).reduce((a, b) => a < b ? a : b).toStringAsFixed(0)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _statItem(String label, String value) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      );
}
