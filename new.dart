import 'dart:math' as math;
import 'package:flutter/material.dart';

const kIrisBlue = Color(0xFF1A3B66);
const kBg = Color(0xFFF3F6F4);
const kCard = Colors.white;
const kSubtle = Color(0xFFE8EEF0);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _navIndex = 0;

  // Data ini tidak digunakan secara langsung di build, bisa dihapus jika tidak diperlukan di tempat lain.
  // final List<double> baseTemp   = [25, 24, 23, 24, 26, 28, 30, 31, 30, 29, 27, 26];
  // final List<double> baseHumAir = [55, 56, 60, 62, 65, 63, 58, 57, 59, 61, 60, 58];

  Widget _buildBody() {
    switch (_navIndex) {
      case 0:
        return const _HomeContent();
      case 1:
        return const _DummyChartsView();
      case 2:
        return const Center(child: Text('Halaman Prediksi (placeholder).'));
      case 3:
        return const Center(child: Text('Halaman Riwayat (placeholder).'));
      default:
        return const _HomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          _navIndex == 0 ? 'Dashboard'
              : _navIndex == 1 ? 'Grafik'
              : _navIndex == 2 ? 'Prediksi' : 'Riwayat',
          style: const TextStyle(color: kIrisBlue, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: _buildBody(), // Menggunakan helper method untuk body
      bottomNavigationBar: NavigationBar(
        height: 64,
        elevation: 8,
        indicatorColor: kIrisBlue.withOpacity(0.08),
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.show_chart),
              label: 'Grafik'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'Prediksi'),
          NavigationDestination(icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Riwayat'), // Menggunakan icon yang sesuai
        ],
      ),
    );
  }
}

class _DummyChartsView extends StatelessWidget {
  const _DummyChartsView();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Halaman Grafik (placeholder).'));
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final List<double> temps = [25, 24, 23, 24, 26, 28, 30, 31, 30, 29, 27, 26];
    final List<double> hums = [55, 56, 60, 62, 65, 63, 58, 57, 59, 61, 60, 58];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const _WeatherHeader(),
        // Widget _WeatherHeader belum ada, asumsikan sudah didefinisikan di file lain
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _QuickCard(
                items: const [
                  _QuickItem(icon: Icons.opacity, label: 'Air', on: true),
                  _QuickItem(icon: Icons.waves, label: 'Pompa', on: false),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const _MiniStatCard(),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Suhu & Kelembapan - History 24h',
          trailing: Text('Titik: ${temps.length}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          child: SizedBox(
            height: 180,
            child: _LineChart(
              series: [
                ChartSeries(
                    values: temps, color: kIrisBlue, label: 'Suhu (°C)'),
                ChartSeries(values: hums,
                    color: const Color(0xFF55BFA5),
                    label: 'Kelembapan (%)'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Asisten Tanamanmu',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 74,
                height: 90,
                decoration: BoxDecoration(
                  color: kSubtle,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3))
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/maskot1.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.pets, color: kIrisBlue, size: 36),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tanamanmu tidak tumbuh optimal.\nButuh pupuk, beri irisan de\n(ini contoh teks, ganti dengan AI rekomendasi).',
                  style: TextStyle(color: kIrisBlue,
                      fontWeight: FontWeight.w600,
                      height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _SectionCard(
          title: 'Status Terakhir',
          child: Column(
            children: [
              _StatusPill(
                  text: 'Berisi informasi tanggal-jam-suhu-kelembapan tanah',
                  color: Color(0xFFDDEBFF)),
              _StatusPill(
                  text: 'Berisi informasi tanggal-jam-suhu-kelembapan tanah',
                  color: Color(0xFFFFE1E6)),
              _StatusPill(
                  text: 'Berisi informasi tanggal-jam-suhu-kelembapan tanah',
                  color: Color(0xFFFFE0F5)),
              _StatusPill(
                  text: 'Berisi informasi tanggal-jam-suhu-kelembapan tanah',
                  color: Color(0xFFE0F7E9)),
            ],
          ),
        ),
      ],
    );
  }
}

/// ===== Chart ringkas

class ChartSeries {
  ChartSeries({required this.values, required this.color, required this.label});

  final List<double> values;
  final Color color;
  final String label;
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.series});

  final List<ChartSeries> series;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(series),
      child: const SizedBox.expand(),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.series);

  final List<ChartSeries> series;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.any((s) => s.values.isEmpty)) {
      // Tidak menggambar chart jika ada data yang kosong untuk menghindari error
      return;
    }

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(.15)
      ..strokeWidth = 1;

    const rows = 4;
    for (int i = 0; i <= rows; i++) {
      final y = size.height * i / rows;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    double minV = double.infinity,
        maxV = -double.infinity;
    for (final s in series) {
      minV = math.min(minV, s.values.reduce(math.min));
      maxV = math.max(maxV, s.values.reduce(math.max));
    }
    if (minV == maxV) {
      maxV += 1;
      minV -= 1;
    }

    for (final s in series) {
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      final path = Path();
      // Handle kasus jika hanya ada satu titik data
      if (s.values.length == 1) {
        final norm = (s.values[0] - minV) / (maxV - minV);
        final y = size.height * (1 - norm);
        canvas.drawCircle(Offset(size.width / 2, y), 2.5, paint);
        continue; // Lanjut ke series berikutnya
      }

      for (int i = 0; i < s.values.length; i++) {
        final x = size.width * i / (s.values.length - 1);
        final norm = (s.values[i] - minV) / (maxV - minV);
        final y = size.height * (1 - norm);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);

      for (int i = 0; i < s.values.length; i++) {
        final x = size.width * i / (s.values.length - 1);
        final norm = (s.values[i] - minV) / (maxV - minV);
        final y = size.height * (1 - norm);
        canvas.drawCircle(Offset(x, y), 2.5, paint..style = PaintingStyle.fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}

// Asumsi widget-widget ini sudah ada di file lain atau di bawahnya.
// Jika belum, Anda perlu membuatnya.
final _cardDeco = BoxDecoration(
  color: kCard,
  borderRadius: BorderRadius.circular(18),
  boxShadow: const [
    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
  ],
);

// --- Placeholder untuk Widget yang hilang ---
class _WeatherHeader extends StatelessWidget {
  const _WeatherHeader();

  @override
  Widget build(BuildContext context) =>
      const Card(child: ListTile(title: Text("Weather Header Placeholder")));
}

class _QuickCard extends StatelessWidget {
  final List<_QuickItem> items;

  const _QuickCard({required this.items});

  @override
  Widget build(BuildContext context) =>
      Card(child: ListTile(title: Text("QuickCard Placeholder")));
}

class _QuickItem {
  final IconData icon;
  final String label;
  final bool on;

  const _QuickItem({required this.icon, required this.label, required this.on});
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard();

  @override
  Widget build(BuildContext context) =>
      const Card(child: ListTile(title: Text("MiniStatCard Placeholder")));
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) =>
      Card(child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme
                    .of(context)
                    .textTheme
                    .titleMedium),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ));
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text(text)),
      );
}

