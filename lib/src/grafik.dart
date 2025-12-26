import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../realtime_service.dart';
import 'telemetry.dart';

class GrafikRealtime extends StatelessWidget {
  final RealtimeService realtime;
  const GrafikRealtime({super.key, required this.realtime});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TelemetryData>>(
      stream: realtime.streamTelemetryWithStateTail(limit: 10),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final list = snapshot.data!;
        if (list.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada data grafik.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final spots = list.map((d) {
          final t = d.waktu.millisecondsSinceEpoch.toDouble();
          return FlSpot(t, d.suhu);
        }).toList();

        return SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              backgroundColor: Colors.transparent,
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.cyanAccent,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
