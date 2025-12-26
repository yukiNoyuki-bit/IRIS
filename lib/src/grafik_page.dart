import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../realtime_service.dart';
import 'telemetry.dart';

class RiwayatGrafikPage extends StatelessWidget {
  const RiwayatGrafikPage({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = RealtimeService(basePath: 'devices/esp32-iris-01');

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgGradient = isDark
        ? const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF46799D),
        Color(0xFF0C202E),
      ],
      stops: [0.36, 0.86],
    )
        : const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF90B7C6), // 33%
        Color(0xFFD5DFC6), // 61%
        Color(0xFF8CA44D), // 90%
      ],
      stops: [0.33, 0.61, 0.90],
    );

    final appBarColor =
    isDark ? const Color(0xFF2F4A5A) : const Color(0xFF90B7C6);
    final appBarFg =
    isDark ? Colors.white : const Color(0xFF24324B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Grafik (10 Terakhir)'),
        backgroundColor: appBarColor,
        foregroundColor: appBarFg,
        elevation: 0,
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: StreamBuilder<List<TelemetryData>>(
            stream: svc.streamHistory(limit: 10),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                      color: isDark ? Colors.white : const Color(0xFF24324B),
                    ),
                  ),
                );
              }

              final list = snapshot.data!;
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    'Belum ada riwayat.',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                    ),
                  ),
                );
              }

              final data = list.reversed.toList();

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: data.length,
                itemBuilder: (context, i) =>
                    _RecordDonutCard(d: data[i], isDark: isDark),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecordDonutCard extends StatelessWidget {
  const _RecordDonutCard({
    required this.d,
    required this.isDark,
  });

  final TelemetryData d;
  final bool isDark;

  static const double _tMax = 50; // suhu °C
  static const double _rhMax = 100; // kelembapan %
  static const double _soilMax = 100; // soil %
  static const double _luxMax = 1200; // lux (atur sesuai range)
  static const double _uvMax = 11; // UV index (0..11+)

  double _norm(double v, double max) {
    if (max <= 0) return 0;
    final p = (v / max) * 100.0;
    return p.isNaN ? 0 : p.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final waktu = d.waktu;

    // Nilai normalisasi untuk pie (0..100)
    final nT = _norm(d.suhu, _tMax);
    final nRH = _norm(d.kelembapan, _rhMax);
    final nSoil = _norm(d.soil, _soilMax);
    final nLux = _norm(d.cahaya, _luxMax);
    final nUV = _norm(d.uv, _uvMax);

    // Warna konsisten per variabel
    const cT = Color(0xFFFFA726); // Suhu
    const cRH = Color(0xFF29B6F6); // RH
    const cSoil = Color(0xFF66BB6A); // Soil
    const cLux = Color(0xFFFFEE58); // Lux
    const cUV = Color(0xFFBA68C8); // UV

    final cardBg = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE0E5EF);
    final headerIconColor =
    isDark ? Colors.white70 : const Color(0xFF4A5568);
    final headerTextColor =
    isDark ? Colors.white70 : const Color(0xFF4A5568);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          if (!isDark)
            const BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header waktu
          Row(
            children: [
              Icon(Icons.schedule, color: headerIconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                '${waktu.day}/${waktu.month}/${waktu.year} '
                    '${waktu.hour}:${waktu.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: headerTextColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: nT,
                    color: cT,
                    title: 'T',
                    radius: 48,
                    titleStyle: _titleStyle,
                  ),
                  PieChartSectionData(
                    value: nRH,
                    color: cRH,
                    title: 'RH',
                    radius: 48,
                    titleStyle: _titleStyle,
                  ),
                  PieChartSectionData(
                    value: nSoil,
                    color: cSoil,
                    title: 'Soil',
                    radius: 48,
                    titleStyle: _titleStyle,
                  ),
                  PieChartSectionData(
                    value: nLux,
                    color: cLux,
                    title: 'Lux',
                    radius: 48,
                    titleStyle: _titleStyle,
                  ),
                  PieChartSectionData(
                    value: nUV,
                    color: cUV,
                    title: 'UV',
                    radius: 48,
                    titleStyle: _titleStyle,
                  ),
                ],
                centerSpaceRadius: 52,
                sectionsSpace: 2,
                startDegreeOffset: -90,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _legendItem(
                color: cT,
                label: 'Suhu: T',
                value: '${d.suhu.toStringAsFixed(1)}°C',
                isDark: isDark,
              ),
              _legendItem(
                color: cRH,
                label: 'Kelembapan Udara: RH',
                value: '${d.kelembapan.toStringAsFixed(0)}%',
                isDark: isDark,
              ),
              _legendItem(
                color: cSoil,
                label: 'Kelembapan Tanah: Soil',
                value: '${d.soil.toStringAsFixed(0)}%',
                isDark: isDark,
              ),
              _legendItem(
                color: cLux,
                label: 'Penyinaran: Lux',
                value: '${d.cahaya.toStringAsFixed(0)} lx',
                isDark: isDark,
              ),
              _legendItem(
                color: cUV,
                label: 'Cahaya Matahari:UV',
                value: d.uv.toStringAsFixed(1),
                isDark: isDark,
              ),
              _legendItem(
                color: d.pump ? Colors.greenAccent : Colors.redAccent,
                label: 'Pompa',
                value: d.pump ? 'ON' : 'OFF',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _titleStyle = TextStyle(
    color: Colors.black87,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  Widget _legendItem({
    required Color color,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final chipBg = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final chipBorder = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE0E5EF);
    final labelColor =
    isDark ? Colors.white70 : const Color(0xFF4A5568);
    final valueColor =
    isDark ? Colors.white : const Color(0xFF1A202C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
            BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: labelColor, fontSize: 12),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
