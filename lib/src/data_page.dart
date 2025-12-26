import 'package:flutter/material.dart';
import '../realtime_service.dart';
import 'telemetry.dart';

class RiwayatDataPage extends StatelessWidget {
  const RiwayatDataPage({super.key});

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
    isDark ? const Color(0xFF26445E) : const Color(0xFF90B7C6);
    final appBarFg =
    isDark ? Colors.white : const Color(0xFF24324B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Data (10 Terakhir)'),
        backgroundColor: appBarColor,
        foregroundColor: appBarFg,
        elevation: 0,
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<TelemetryData>>(
          stream: svc.streamHistory(limit: 10),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: isDark ? Colors.white : const Color(0xFF24324B),
                ),
              );
            }

            final list = snapshot.data!;
            if (list.isEmpty) {
              return Center(
                child: Text(
                  'Belum ada data riwayat.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF4A5568),
                  ),
                ),
              );
            }

            final data = list.reversed.toList();

            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, i) {
                final d = data[i];
                final waktu = d.waktu;

                final cardBg =
                isDark ? Colors.white.withOpacity(0.06) : Colors.white;
                final cardBorder = isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE0E5EF);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
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
                      Text(
                        '${waktu.day}/${waktu.month}/${waktu.year}  '
                            '${waktu.hour}:${waktu.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF4A5568),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _dataRow(
                        'Suhu',
                        '${d.suhu.toStringAsFixed(1)} °C',
                        isDark: isDark,
                      ),
                      _dataRow(
                        'Kelembapan',
                        '${d.kelembapan.toStringAsFixed(0)} %',
                        isDark: isDark,
                      ),
                      _dataRow(
                        'Soil Moisture',
                        '${d.soil.toStringAsFixed(0)} %',
                        isDark: isDark,
                      ),
                      _dataRow(
                        'Cahaya',
                        '${d.cahaya.toStringAsFixed(0)} lx',
                        isDark: isDark,
                      ),
                      _dataRow(
                        'UV Index',
                        d.uv.toStringAsFixed(1),
                        isDark: isDark,
                      ),
                      _dataRow(
                        'Pompa',
                        d.pump ? 'ON' : 'OFF',
                        isDark: isDark,
                        valueColor:
                        d.pump ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _dataRow(
      String label,
      String value, {
        required bool isDark,
        Color? valueColor,
      }) {
    final labelColor =
    isDark ? Colors.white70 : const Color(0xFF4A5568);
    final effectiveValueColor =
        valueColor ?? (isDark ? Colors.white : const Color(0xFF1A202C));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: labelColor, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: effectiveValueColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
