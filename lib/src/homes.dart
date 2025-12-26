// homes.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';

import '../realtime_service.dart';
import 'telemetry.dart';
import 'weather_service.dart';
import 'grafik_page.dart';
import 'data_page.dart';
import 'clock.dart';
import 'prediksi.dart';

class HomeScrollPage extends StatelessWidget {
  const HomeScrollPage({super.key});

  static const _devicePath = 'devices/esp32-iris-01';
  static const _routeSettings = '/settings';

  @override
  Widget build(BuildContext context) {
    final svc = RealtimeService(basePath: _devicePath);

    // 🔹 Cek tema saat ini
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        // 🔹 Gradien dibedakan antara terang & gelap
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF46799D),
              Color(0xB30C202E),
            ],
            stops: [0.36, 0.86],
          )
              : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF90B7C6),
              Color(0xFFD5DFC6),
              Color(0xFF8CA44D),
            ],
            stops: [0.33, 0.61, 0.90],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Row judul + tombol settings
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () =>
                          Navigator.pushNamed(context, _routeSettings),
                      tooltip: 'Pengaturan',
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const _HeaderCuaca(),
                const SizedBox(height: 16),

                // ===== Sensor cards (data TERBARU saja) =====
                StreamBuilder<TelemetryData>(
                  stream: svc.streamState(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Belum ada data sensor.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      );
                    }

                    final s = snap.data!;

                    final gaugeCards = [
                      // SUHU
                      SensorGaugeCard(
                        title: 'Suhu',
                        subtitle: _suhuKetTomatIndoor(s.suhu),
                        valueText: '${s.suhu.toStringAsFixed(1)}°C',
                        percent: _toPercent(s.suhu, min: 0, max: 50),
                        value: s.suhu,
                        icon: Icons.thermostat,
                        minLabel: '0°',
                        maxLabel: '50°',
                        colorForValue: _suhuColorTomatIndoor,
                      ),

                      // RH
                      SensorGaugeCard(
                        title: 'Kelembapan Udara',
                        subtitle: _rhKetTomatIndoor(s.kelembapan),
                        valueText: '${s.kelembapan.toStringAsFixed(0)}%',
                        percent: _toPercent(s.kelembapan, min: 0, max: 100),
                        value: s.kelembapan,
                        icon: Icons.water_drop,
                        minLabel: '0%',
                        maxLabel: '100%',
                        colorForValue: _rhColorTomatIndoor,
                      ),

                      // SOIL
                      SensorGaugeCard(
                        title: 'Kelembapan Tanah',
                        subtitle: _soilKetTomatIndoor(s.soil),
                        valueText: '${s.soil.toStringAsFixed(0)}%',
                        percent: _toPercent(s.soil, min: 0, max: 100),
                        value: s.soil,
                        icon: Icons.eco,
                        minLabel: '0%',
                        maxLabel: '100%',
                        colorForValue: _soilColorTomatIndoor,
                      ),

                      // LUX
                      SensorGaugeCard(
                        title: 'Penyinaran',
                        subtitle: _luxKet(s.cahaya),
                        valueText: '${s.cahaya.toStringAsFixed(0)} lx',
                        percent: _toPercent(s.cahaya, min: 0, max: 1200),
                        value: s.cahaya,
                        icon: Icons.wb_sunny_outlined,
                        minLabel: '0',
                        maxLabel: '1200',
                        colorForValue: _luxColor,
                      ),

                      // UV
                      SensorGaugeCard(
                        title: 'Sinar Matahari',
                        subtitle: _uvKet(s.uv),
                        valueText: s.uv.toStringAsFixed(1),
                        percent: _toPercent(s.uv, min: 0, max: 11),
                        value: s.uv,
                        icon: Icons.light_mode,
                        minLabel: '0',
                        maxLabel: '11+',
                        colorForValue: _uvColor,
                      ),

                      // ✅ PREDIKSI (DISAMAKAN DENGAN prediksi.dart)
                      PrediksiCard(
                        title: 'Prediksi',
                        devicePath: _devicePath,
                      ),
                    ];

                    final crossCount =
                    MediaQuery.of(context).size.width < 600 ? 2 : 3;

                    return GridView.count(
                      crossAxisCount: crossCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.05,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children: gaugeCards,
                    );
                  },
                ),

                const SizedBox(height: 16),

                _RiwayatGrafikTile(devicePath: _devicePath),
                const SizedBox(height: 12),

                _RiwayatDataTile(devicePath: _devicePath),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double _toPercent(double v, {required double min, required double max}) {
    if (max <= min) return 0;
    final p = (v - min) / (max - min);
    return p.isNaN ? 0 : p.clamp(0, 1);
  }

  // ==================== KETERANGAN + WARNA (INDEX) ====================

  // --- SUHU (Tomat Indoor) ---
  static String _suhuKetTomatIndoor(double t) {
    if (t.isNaN) return '-';
    if (t < 13) return 'Terlalu dingin';
    if (t < 18) return 'Dingin';
    if (t <= 27) return 'Optimal';
    if (t <= 30) return 'Hangat';
    if (t <= 33) return 'Panas';
    return 'Stres panas';
  }

  static Color _suhuColorTomatIndoor(double t) {
    if (t.isNaN) return const Color(0xFFE5E7EB);
    if (t < 13) return const Color(0xFF29B6F6);
    if (t < 18) return const Color(0xFF4FC3F7);
    if (t <= 27) return const Color(0xFF66BB6A);
    if (t <= 30) return const Color(0xFFFFD54F);
    if (t <= 33) return const Color(0xFFFFA726);
    return const Color(0xFFFF5252);
  }

  // --- RH (Tomat Indoor) ---
  static String _rhKetTomatIndoor(double rh) {
    if (rh.isNaN) return '-';
    if (rh < 40) return 'Terlalu kering';
    if (rh < 55) return 'Agak kering';
    if (rh <= 75) return 'Optimal';
    if (rh <= 85) return 'Terlalu lembap';
    return 'Sangat lembap';
  }

  static Color _rhColorTomatIndoor(double rh) {
    if (rh.isNaN) return const Color(0xFFE5E7EB);
    if (rh < 40) return const Color(0xFFFF5252);
    if (rh < 55) return const Color(0xFFFFA726);
    if (rh <= 75) return const Color(0xFF66BB6A);
    if (rh <= 85) return const Color(0xFFFFD54F);
    return const Color(0xFFFF5252);
  }

  // --- SOIL (Tomat Indoor) ---
  static String _soilKetTomatIndoor(double sm) {
    if (sm.isNaN) return '-';
    if (sm < 30) return 'Kering';
    if (sm < 40) return 'Agak kering';
    if (sm <= 70) return 'Optimal';
    if (sm <= 85) return 'Basah';
    return 'Terlalu basah';
  }

  static Color _soilColorTomatIndoor(double sm) {
    if (sm.isNaN) return const Color(0xFFE5E7EB);
    if (sm < 30) return const Color(0xFFFF5252);
    if (sm < 40) return const Color(0xFFFFA726);
    if (sm <= 70) return const Color(0xFF66BB6A);
    if (sm <= 85) return const Color(0xFFFFD54F);
    return const Color(0xFFFF5252);
  }

  // --- LUX (0–1200 skala sensor Anda) ---
  static String _luxKet(double lux) {
    if (lux.isNaN) return '-';
    if (lux < 200) return 'Rendah';
    if (lux < 600) return 'Sedang';
    if (lux < 900) return 'Tinggi';
    return 'Sangat tinggi';
  }

  static Color _luxColor(double lux) {
    if (lux.isNaN) return const Color(0xFFE5E7EB);
    if (lux < 200) return const Color(0xFF29B6F6);
    if (lux < 600) return const Color(0xFF66BB6A);
    if (lux < 900) return const Color(0xFFFFD54F);
    return const Color(0xFFFFA726);
  }

  // --- UV ---
  static String _uvKet(double uv) {
    if (uv.isNaN) return '-';
    if (uv <= 2) return 'Rendah';
    if (uv <= 5) return 'Sedang';
    if (uv <= 7) return 'Tinggi';
    if (uv <= 10) return 'Sangat tinggi';
    return 'Ekstrem';
  }

  static Color _uvColor(double uv) {
    if (uv.isNaN) return const Color(0xFFE5E7EB);
    if (uv <= 2) return const Color(0xFF66BB6A);
    if (uv <= 5) return const Color(0xFFFFD54F);
    if (uv <= 7) return const Color(0xFFFFA726);
    if (uv <= 10) return const Color(0xFFFF5252);
    return const Color(0xFFBA68C8);
  }
}

// ==================== CUACA CARD (besar + background) ====================
class _HeaderCuaca extends StatefulWidget {
  const _HeaderCuaca();

  @override
  State<_HeaderCuaca> createState() => _HeaderCuacaState();
}

class _HeaderCuacaState extends State<_HeaderCuaca> {
  late Future<WeatherData> _futureWeather;

  @override
  void initState() {
    super.initState();
    _futureWeather = WeatherService().fetchWeather(lat: -4.0167, lon: 119.6333);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerAsset = isDark ? 'assets/cuaca(1).png' : 'assets/cuacacerah.png';

    return FutureBuilder<WeatherData>(
      future: _futureWeather,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final has = snapshot.hasData;

        final d = has ? snapshot.data! : null;
        final t = has ? d!.localTime : DateTime.now();

        return Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  headerAsset,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.25),
                  colorBlendMode: BlendMode.darken,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.20),
                        Colors.black.withOpacity(0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: loading
                      ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                      : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d!.cityName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.wb_cloudy_outlined,
                                    color: Colors.white, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  '${d.temperature.toStringAsFixed(1)}°C',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              d.description[0].toUpperCase() +
                                  d.description.substring(1),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _fmtDate(t),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          const RealTimeParepareClock(
                            pattern: 'hh:mm a',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtDate(DateTime t) {
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${t.day} ${bulan[t.month - 1]} ${t.year}';
  }
}

// ==================== SENSOR CARD ====================
class SensorGaugeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String valueText;
  final double percent;
  final double value;
  final IconData icon;
  final String minLabel;
  final String maxLabel;
  final Color Function(double value)? colorForValue;

  const SensorGaugeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.valueText,
    required this.percent,
    required this.value,
    required this.icon,
    required this.minLabel,
    required this.maxLabel,
    this.colorForValue,
  });

  Color _defaultColorForPercent(double p) {
    final v = p.isNaN ? 0.0 : p.clamp(0.0, 1.0);
    if (v < 0.33) return const Color(0xFF29B6F6);
    if (v < 0.66) return const Color(0xFFFFD54F);
    return const Color(0xFFFF5252);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE0E4EC);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final scaleLabelColor = isDark ? Colors.white54 : const Color(0xFF9CA3AF);
    final valueColor = isDark ? Colors.white : const Color(0xFF111827);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF4B5563);

    final gaugeColor =
        colorForValue?.call(value) ?? _defaultColorForPercent(percent);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent),
              duration: const Duration(milliseconds: 800),
              builder: (context, val, _) {
                return CustomPaint(
                  painter: _SemiGaugePainter(
                    percent: val,
                    color: gaugeColor,
                    isDark: isDark,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          valueText,
                          style: TextStyle(
                            color: valueColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minLabel,
                  style: TextStyle(color: scaleLabelColor, fontSize: 10)),
              Text(maxLabel,
                  style: TextStyle(color: scaleLabelColor, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== PREDIKSI CARD (DISAMAKAN DENGAN prediksi.dart) ====================
class PrediksiCard extends StatelessWidget {
  final String title;
  final String devicePath;

  const PrediksiCard({
    super.key,
    required this.title,
    required this.devicePath,
  });

  DatabaseReference get _nowRef =>
      FirebaseDatabase.instance.ref('$devicePath/ai/now');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE0E4EC);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF4B5563);
    final chevronColor = isDark ? Colors.white54 : const Color(0xFF9CA3AF);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrediksiPage(devicePath: devicePath),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: StreamBuilder<DatabaseEvent>(
          stream: _nowRef.onValue,
          builder: (context, snap) {
            final map = _mapOf(snap.data?.snapshot.value);

            final rawLabel = (map?['label'] ?? '').toString().trim();
            final label = rawLabel.isEmpty ? 'MENUNGGU' : rawLabel;

            final bool empty = rawLabel.isEmpty;

            // warna badge + poin + asset mengikuti prediksi.dart
            final Color badgeColor = empty
                ? const Color(0xFF94A3B8) // netral untuk menunggu
                : _levelColor(_levelFromLabel(label));

            final String point =
            empty ? 'Menunggu data AI…' : _pointForLabel(label);

            final String asset =
            empty ? 'assets/maskot3.png' : _maskotAsset(label);

            return LayoutBuilder(
              builder: (context, c) {
                final maxH = c.maxHeight;
                final maskotH = (maxH * 0.26).clamp(40.0, 56.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: iconColor, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: chevronColor),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: maskotH,
                            child: Image.asset(
                              asset,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/maskot3.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(999),
                              border:
                              Border.all(color: badgeColor.withOpacity(0.35)),
                            ),
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: badgeColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            point,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subColor,
                              fontSize: 11,
                              height: 1.15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  static Map<dynamic, dynamic>? _mapOf(dynamic value) {
    if (value is Map) return value as Map<dynamic, dynamic>;
    return null;
  }

  // ===== Helper logic: sama seperti prediksi.dart =====
  static int _levelFromLabel(String label) {
    final u = label.toUpperCase();
    if (u.contains('AMAN') || u.contains('OPTIMAL') || u == 'OK') return 0;
    if (u.contains('WASPADA') || u.contains('HANGAT')) return 1;
    if (u.contains('STRES') || u.contains('BAHAYA')) return 2;
    return 1;
  }

  static Color _levelColor(int level) {
    if (level == 0) return const Color(0xFF66BB6A);
    if (level == 1) return const Color(0xFFFFA726);
    return const Color(0xFFFF5252);
  }

  static String _pointForLabel(String label) {
    final u = label.toUpperCase();
    if (u.contains('STRES_PANAS')) return 'Tambah ventilasi/kipas';
    if (u.contains('STRES_DINGIN')) return 'Stabilkan suhu ruang';
    if (u.contains('KERING') || u.contains('STRES_KERING')) {
      return 'Cek pompa/penyiraman';
    }
    if (u.contains('LEMBAP') || u.contains('STRES_LEMBAP')) {
      return 'Kurangi air & tambah airflow';
    }
    if (u.contains('CAHAYA_KURANG')) return 'Tambah intensitas growlight';
    if (u.contains('CAHAYA_BERLEBIH')) return 'Kurangi intensitas growlight';
    if (u.contains('AMAN') || u.contains('OPTIMAL') || u == 'OK') {
      return 'Pertahankan kondisi';
    }
    return 'Pantau kondisi';
  }

  static String _maskotAsset(String label) {
    final u = label.toUpperCase();
    if (u.contains('AMAN') || u.contains('OPTIMAL') || u == 'OK') {
      return 'assets/maskot_aman.png';
    }
    if (u.contains('WASPADA') || u.contains('HANGAT')) {
      return 'assets/maskot_waspada.png';
    }
    if (u.contains('STRES') || u.contains('BAHAYA')) {
      return 'assets/maskot_bahaya.png';
    }
    return 'assets/maskot3.png';
  }
}

// ==================== GAUGE PAINTER ====================
class _SemiGaugePainter extends CustomPainter {
  final double percent;
  final Color color;
  final bool isDark;

  _SemiGaugePainter({
    required this.percent,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.35;

    final bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.12)
          : const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.7), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const startAngle = math.pi;
    final sweepAngle = math.pi * percent;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SemiGaugePainter old) =>
      old.percent != percent || old.color != color || old.isDark != isDark;
}

// ==================== TILE: RIWAYAT - GRAFIK ====================
class _RiwayatGrafikTile extends StatelessWidget {
  const _RiwayatGrafikTile({required this.devicePath, super.key});
  final String devicePath;

  @override
  Widget build(BuildContext context) {
    final svc = RealtimeService(basePath: devicePath);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE0E4EC);
    final headerColor = isDark ? Colors.white : const Color(0xFF111827);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF4B5563);
    final chevronColor = isDark ? Colors.white54 : const Color(0xFF9CA3AF);
    final loadingColor = isDark ? Colors.white : const Color(0xFF2563EB);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RiwayatGrafikPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: StreamBuilder<List<TelemetryData>>(
          stream: svc.streamHistory(limit: 1),
          builder: (context, snapshot) {
            final header = Row(
              children: [
                Icon(Icons.show_chart, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Riwayat - Grafik (Tap untuk lihat)',
                    style: TextStyle(
                      color: headerColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: chevronColor),
              ],
            );

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(color: loadingColor),
                    ),
                  ),
                ],
              );
            }

            final d = snapshot.data!.first;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 12),
                SizedBox(height: 160, child: _MiniDonutChart(d: d)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ==================== TILE: RIWAYAT - DATA ====================
class _RiwayatDataTile extends StatelessWidget {
  const _RiwayatDataTile({required this.devicePath, super.key});
  final String devicePath;

  @override
  Widget build(BuildContext context) {
    final svc = RealtimeService(basePath: devicePath);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE0E4EC);
    final headerColor = isDark ? Colors.white : const Color(0xFF111827);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF4B5563);
    final chevronColor = isDark ? Colors.white54 : const Color(0xFF9CA3AF);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final timeColor = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final valueColor = isDark ? Colors.white : const Color(0xFF111827);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RiwayatDataPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: StreamBuilder<List<TelemetryData>>(
          stream: svc.streamHistory(limit: 1),
          builder: (context, snapshot) {
            final header = Row(
              children: [
                Icon(Icons.table_chart, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Riwayat - Data (Tap untuk lihat)',
                    style: TextStyle(
                      color: headerColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: chevronColor),
              ],
            );

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Memuat data terbaru...',
                      style: TextStyle(color: subTextColor),
                    ),
                  ),
                ],
              );
            }

            final d = snapshot.data!.first;
            final waktu = d.waktu;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 8),
                Text(
                  '${waktu.day}/${waktu.month}/${waktu.year} '
                      '${waktu.hour}:${waktu.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: timeColor, fontSize: 12),
                ),
                const SizedBox(height: 8),
                _row('Suhu', '${d.suhu.toStringAsFixed(1)} °C',
                    labelColor: subTextColor, valueColor: valueColor),
                _row('Kelembapan', '${d.kelembapan.toStringAsFixed(0)} %',
                    labelColor: subTextColor, valueColor: valueColor),
                _row('Soil Moisture', '${d.soil.toStringAsFixed(0)} %',
                    labelColor: subTextColor, valueColor: valueColor),
                _row('Cahaya', '${d.cahaya.toStringAsFixed(0)} lx',
                    labelColor: subTextColor, valueColor: valueColor),
                _row('UV Index', d.uv.toStringAsFixed(1),
                    labelColor: subTextColor, valueColor: valueColor),
                _row(
                  'Pompa',
                  d.pump ? 'ON' : 'OFF',
                  labelColor: subTextColor,
                  valueColor: d.pump ? Colors.greenAccent : Colors.redAccent,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(
      String a,
      String b, {
        required Color labelColor,
        required Color valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a, style: TextStyle(color: labelColor, fontSize: 13)),
          Text(
            b,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MINI DONUT CHART ====================
class _MiniDonutChart extends StatelessWidget {
  const _MiniDonutChart({required this.d});
  final TelemetryData d;

  static const double _tMax = 50;
  static const double _rhMax = 100;
  static const double _soilMax = 100;
  static const double _luxMax = 1200;
  static const double _uvMax = 11;

  double _norm(double v, double max) {
    if (max <= 0) return 0;
    final p = (v / max) * 100.0;
    return p.isNaN ? 0 : p.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final nT = _norm(d.suhu, _tMax);
    final nRH = _norm(d.kelembapan, _rhMax);
    final nSoil = _norm(d.soil, _soilMax);
    final nLux = _norm(d.cahaya, _luxMax);
    final nUV = _norm(d.uv, _uvMax);

    const cT = Color(0xFFFFA726);
    const cRH = Color(0xFF29B6F6);
    const cSoil = Color(0xFF66BB6A);
    const cLux = Color(0xFFFFEE58);
    const cUV = Color(0xFFBA68C8);

    final sections = <PieChartSectionData>[
      PieChartSectionData(
          value: nT, color: cT, title: 'T', radius: 38, titleStyle: _miniTitle),
      PieChartSectionData(
          value: nRH,
          color: cRH,
          title: 'RH',
          radius: 38,
          titleStyle: _miniTitle),
      PieChartSectionData(
          value: nSoil,
          color: cSoil,
          title: 'Soil',
          radius: 38,
          titleStyle: _miniTitle),
      PieChartSectionData(
          value: nLux,
          color: cLux,
          title: 'Lux',
          radius: 38,
          titleStyle: _miniTitle),
      PieChartSectionData(
          value: nUV,
          color: cUV,
          title: 'UV',
          radius: 38,
          titleStyle: _miniTitle),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final legendTextColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 36,
              sectionsSpace: 2,
              startDegreeOffset: -90,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            _dot('T', cT, legendTextColor),
            _dot('RH', cRH, legendTextColor),
            _dot('Soil', cSoil, legendTextColor),
            _dot('Lux', cLux, legendTextColor),
            _dot('UV', cUV, legendTextColor),
          ],
        ),
      ],
    );
  }

  static const _miniTitle = TextStyle(
      color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w700);

  Widget _dot(String text, Color c, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: textColor, fontSize: 11)),
      ],
    );
  }
}
