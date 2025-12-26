// prediksi.dart
// Halaman Prediksi AI (NOW + FORECAST)
// UI konsisten: semua card mengikuti pola "Status Emosi Tanaman":
// Header -> Konten -> Divider -> "Terakhir diperbarui" di paling bawah
// Forecast TANPA grafik.
//
// ✅ FIX: Asset + warna + caption mengikuti homes.dart (dashboard)

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PrediksiPage extends StatelessWidget {
  final String devicePath;

  const PrediksiPage({
    super.key,
    required this.devicePath,
  });

  DatabaseReference get _nowRef =>
      FirebaseDatabase.instance.ref('$devicePath/ai/now');

  DatabaseReference get _forecastRef =>
      FirebaseDatabase.instance.ref('$devicePath/ai/forecast');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF46799D), Color(0xB30C202E)],
            stops: [0.36, 0.86],
          )
              : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF90B7C6), Color(0xFFD5DFC6), Color(0xFF8CA44D)],
            stops: [0.33, 0.61, 0.90],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== Header =====
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      tooltip: 'Kembali',
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Prediksi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ===================== NOW (Status Emosi + Keputusan Penyiraman) =====================
                StreamBuilder<DatabaseEvent>(
                  stream: _nowRef.onValue,
                  builder: (context, snap) {
                    final isLoading =
                        snap.connectionState == ConnectionState.waiting;

                    if (isLoading) {
                      return Column(
                        children: [
                          _AppCard(
                            isDark: isDark,
                            child: _LoadingState(isDark: isDark, height: 190),
                          ),
                          const SizedBox(height: 12),
                          _AppCard(
                            isDark: isDark,
                            child: _LoadingState(isDark: isDark, height: 130),
                          ),
                        ],
                      );
                    }

                    final map = _asMap(snap.data?.snapshot.value);
                    if (map == null) {
                      return Column(
                        children: [
                          _AppCard(
                            isDark: isDark,
                            child: _EmptyState(
                              isDark: isDark,
                              title: 'Belum ada data AI Now',
                              subtitle:
                              'Pastikan node ai/now sudah terisi di Realtime Database.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _AppCard(
                            isDark: isDark,
                            child: _EmptyState(
                              isDark: isDark,
                              title: 'Keputusan Penyiraman belum tersedia',
                              subtitle:
                              'Keputusan muncul setelah AI mengirim label & data tanah.',
                            ),
                          ),
                        ],
                      );
                    }

                    final now = AiNow.fromMap(map);

                    final rawLabel = now.label.trim();
                    final labelText = rawLabel.isEmpty ? 'MENUNGGU' : rawLabel;

                    // ✅ UI asset + warna + caption ikut mapping homes.dart
                    final ui = _PlantUi.fromLabel(labelText);

                    final decision =
                    _wateringDecisionFromLabel(labelText, now.soilPercent);

                    final updatedNow = _fmtUpdated(now.time);
                    final rightNow = _fmtDateTimeShort(now.time);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ===== Card 1: Status Emosi Tanaman (CENTER) =====
                        _AppCard(
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _CardHeader(
                                isDark: isDark,
                                icon: Icons.psychology,
                                title: 'Status Emosi Tanaman',
                                rightText: rightNow,
                              ),
                              const SizedBox(height: 14),

                              // Center content
                              LayoutBuilder(
                                builder: (context, c) {
                                  final maxW = c.maxWidth;
                                  final mascot =
                                  (maxW * 0.38).clamp(110.0, 150.0);

                                  return Column(
                                    children: [
                                      SizedBox(
                                        height: mascot,
                                        width: mascot,
                                        child: Image.asset(
                                          ui.assetPath,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              Image.asset(
                                                'assets/maskot3.png',
                                                fit: BoxFit.contain,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ui.accent.withOpacity(0.14),
                                          borderRadius:
                                          BorderRadius.circular(999),
                                          border: Border.all(
                                            color: ui.accent.withOpacity(0.28),
                                          ),
                                        ),
                                        child: Text(
                                          labelText,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: ui.accent,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        ui.caption,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: _subText(isDark),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 12),
                              Divider(height: 1, color: _divider(isDark)),
                              const SizedBox(height: 10),

                              // ✅ Updated di paling bawah
                              Text(
                                updatedNow,
                                style: TextStyle(
                                  color: _muted(isDark),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ===== Card 2: Keputusan Penyiraman (ikut pola yang sama) =====
                        _AppCard(
                          isDark: isDark,
                          tintColor: decision.color,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _CardHeader(
                                isDark: isDark,
                                icon: Icons.water_drop,
                                title: 'Keputusan Penyiraman',
                                rightText: rightNow,
                              ),
                              const SizedBox(height: 12),

                              _DecisionBox(
                                isDark: isDark,
                                icon: decision.icon,
                                title: decision.title,
                                subtitle: decision.subtitle,
                                color: decision.color,
                              ),

                              const SizedBox(height: 12),
                              Divider(height: 1, color: _divider(isDark)),
                              const SizedBox(height: 10),

                              // ✅ Updated di paling bawah
                              Text(
                                updatedNow,
                                style: TextStyle(
                                  color: _muted(isDark),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // ===================== FORECAST (tanpa grafik) =====================
                StreamBuilder<DatabaseEvent>(
                  stream: _forecastRef.onValue,
                  builder: (context, snap) {
                    final isLoading =
                        snap.connectionState == ConnectionState.waiting;

                    if (isLoading) {
                      return _AppCard(
                        isDark: isDark,
                        child: _LoadingState(isDark: isDark, height: 170),
                      );
                    }

                    final map = _asMap(snap.data?.snapshot.value);
                    if (map == null) {
                      return _AppCard(
                        isDark: isDark,
                        child: _EmptyState(
                          isDark: isDark,
                          title: 'Belum ada data Forecast',
                          subtitle:
                          'Pastikan node ai/forecast sudah terisi (soil_future, threshold, text).',
                        ),
                      );
                    }

                    final fc = AiForecast.fromMap(map);

                    final horizonMinutes = fc.soilFuture.isEmpty
                        ? 0
                        : (fc.soilFuture.length * fc.stepMinutes);

                    final forecastDecision =
                    _forecastDecision(fc.soilFuture, fc.threshold);

                    final rightFc = _fmtDateTimeShort(fc.time);
                    final updatedFc = _fmtUpdated(fc.time);

                    return _AppCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CardHeader(
                            isDark: isDark,
                            icon: Icons.auto_graph,
                            title: 'Forecast Kelembapan Tanah',
                            rightText: rightFc,
                          ),
                          const SizedBox(height: 12),

                          _DecisionBox(
                            isDark: isDark,
                            icon: forecastDecision.icon,
                            title: forecastDecision.title,
                            subtitle: horizonMinutes == 0
                                ? forecastDecision.subtitle
                                : '${forecastDecision.subtitle} (± ${_fmtHorizon(horizonMinutes)})',
                            color: forecastDecision.color,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Kesimpulan AI:',
                            style: TextStyle(
                              color: _title(isDark),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (fc.text.trim().isEmpty) ? '-' : fc.text.trim(),
                            style: TextStyle(
                              color: _subText(isDark),
                              fontSize: 12,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _InfoChip(
                                  isDark: isDark,
                                  icon: Icons.timer_outlined,
                                  label: 'Interval',
                                  value: '${fc.stepMinutes} menit/step',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _InfoChip(
                                  isDark: isDark,
                                  icon: Icons.flag_outlined,
                                  label: 'Ambang Batas',
                                  value: '${fc.threshold.toStringAsFixed(0)}%',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Divider(height: 1, color: _divider(isDark)),
                          const SizedBox(height: 10),

                          // ✅ Updated di paling bawah
                          Text(
                            updatedFc,
                            style: TextStyle(
                              color: _muted(isDark),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== helpers =====================

  static Map<dynamic, dynamic>? _asMap(dynamic v) {
    if (v is Map) return v as Map<dynamic, dynamic>;
    return null;
  }

  static String _fmtDateTimeShort(DateTime dt) {
    final d = dt.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yy $hh:$mi';
  }

  static String _fmtUpdated(DateTime dt) {
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    final d = dt.toLocal();
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return 'Terakhir diperbarui: ${d.day} ${bulan[d.month - 1]} ${d.year} · $hh:$mi';
  }

  static String _fmtHorizon(int minutes) {
    if (minutes <= 0) return '-';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h <= 0) return '$m menit';
    if (m == 0) return '$h jam';
    return '$h jam $m menit';
  }

  // ===================== keputusan siram =====================

  static _Decision _wateringDecisionFromLabel(String label, double soilPercent) {
    final u = label.trim().toUpperCase();

    if (u.contains('KERING') || u.contains('BUTUH AIR') || u.contains('KURANG')) {
      return const _Decision(
        title: 'Perlu disiram',
        subtitle:
        'AI mendeteksi tanah kekurangan air. Disarankan siram sekarang.',
        color: Color(0xFFF59E0B),
        icon: Icons.opacity,
      );
    }

    if (u.contains('BASAH') || u.contains('LEMBAP') || u.contains('TERLALU')) {
      return const _Decision(
        title: 'Jangan disiram dulu',
        subtitle: 'Kondisi terlalu lembap/basah. Tunda penyiraman.',
        color: Color(0xFF3B82F6),
        icon: Icons.water_drop_outlined,
      );
    }

    if (u.contains('AMAN') || u.contains('OPTIMAL') || u == 'OK') {
      return const _Decision(
        title: 'Tidak perlu disiram',
        subtitle: 'Kondisi aman. Cukup dipantau saja.',
        color: Color(0xFF22C55E),
        icon: Icons.check_circle_outline,
      );
    }

    if (soilPercent < 40) {
      return const _Decision(
        title: 'Kemungkinan perlu disiram',
        subtitle: 'Tanah cukup kering. Boleh siram sedikit dan pantau.',
        color: Color(0xFFF59E0B),
        icon: Icons.opacity_outlined,
      );
    }

    return const _Decision(
      title: 'Pantau kondisi',
      subtitle: 'Belum ada sinyal kuat. Pantau beberapa menit ke depan.',
      color: Color(0xFF94A3B8),
      icon: Icons.info_outline,
    );
  }

  static _Decision _forecastDecision(List<double> future, double threshold) {
    if (future.isEmpty) {
      return const _Decision(
        title: 'Belum ada prediksi',
        subtitle: 'Data prediksi belum tersedia.',
        color: Color(0xFF94A3B8),
        icon: Icons.hourglass_empty,
      );
    }

    final minV = future.reduce((a, b) => a < b ? a : b);

    if (minV < threshold) {
      return const _Decision(
        title: 'Berpotensi butuh siram',
        subtitle: 'Kelembapan tanah diprediksi bisa turun melewati ambang.',
        color: Color(0xFFF59E0B),
        icon: Icons.warning_amber_rounded,
      );
    }

    return const _Decision(
      title: 'Diprediksi aman',
      subtitle: 'Kelembapan tanah diperkirakan stabil di atas ambang.',
      color: Color(0xFF22C55E),
      icon: Icons.verified_outlined,
    );
  }
}

// ===================== UI =====================

class _AppCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color? tintColor;

  const _AppCard({
    required this.child,
    required this.isDark,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final base = isDark ? Colors.white.withOpacity(0.06) : Colors.white;

    final bg = (!isDark && tintColor != null)
        ? Color.alphaBlend(tintColor!.withOpacity(0.10), base)
        : base;

    final borderColor =
    isDark ? Colors.white.withOpacity(0.10) : const Color(0xFFE3E8F0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String rightText;

  const _CardHeader({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.rightText,
  });

  @override
  Widget build(BuildContext context) {
    final t = _title(isDark);
    final s = _muted(isDark);
    final ic = isDark ? Colors.white70 : const Color(0xFF475569);

    return Row(
      children: [
        Icon(icon, size: 18, color: ic),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: t,
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
            ),
          ),
        ),
        if (rightText.trim().isNotEmpty)
          Text(
            rightText,
            style: TextStyle(
              color: s,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _DecisionBox extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _DecisionBox({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = _title(isDark);
    final s = _subText(isDark);

    final bg = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF1F5F9);
    final bd =
    isDark ? Colors.white.withOpacity(0.10) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.28)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: t,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: s,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF1F5F9);
    final bd =
    isDark ? Colors.white.withOpacity(0.10) : const Color(0xFFE2E8F0);

    final lc = isDark ? Colors.white70 : const Color(0xFF64748B);
    final vc = isDark ? Colors.white : const Color(0xFF0F172A);
    final ic = isDark ? Colors.white70 : const Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bd),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ic),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: lc,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: vc,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final bool isDark;
  final double height;

  const _LoadingState({required this.isDark, required this.height});

  @override
  Widget build(BuildContext context) {
    final c = isDark ? Colors.white : const Color(0xFF2563EB);
    return SizedBox(
      height: height,
      child: Center(child: CircularProgressIndicator(color: c)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.isDark,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = _title(isDark);
    final s = _subText(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: t,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: s,
            fontSize: 12,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ===================== Theme helpers =====================

Color _title(bool isDark) =>
    isDark ? Colors.white : const Color(0xFF0F172A);

Color _subText(bool isDark) =>
    isDark ? Colors.white70 : const Color(0xFF475569);

Color _muted(bool isDark) =>
    isDark ? Colors.white54 : const Color(0xFF64748B);

Color _divider(bool isDark) =>
    isDark ? Colors.white.withOpacity(0.10) : const Color(0xFFE2E8F0);

// ===================== UI MAPPING (IKUT homes.dart) =====================

class _PlantUi {
  final String assetPath;
  final Color accent;
  final String caption;

  const _PlantUi({
    required this.assetPath,
    required this.accent,
    required this.caption,
  });

  static _PlantUi fromLabel(String label) {
    final u = label.trim().toUpperCase();

    // warna badge mengikuti homes.dart _levelColor
    final int level = _levelFromLabel(u);
    final Color accent = _levelColor(level);

    // asset mengikuti homes.dart _maskotAsset
    final String asset = _maskotAsset(u);

    // caption mengikuti homes.dart _pointForLabel
    final String caption = _pointForLabel(u);

    return _PlantUi(assetPath: asset, accent: accent, caption: caption);
  }

  static int _levelFromLabel(String u) {
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

  static String _maskotAsset(String u) {
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

  static String _pointForLabel(String u) {
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
    if (u.trim().isEmpty || u == 'MENUNGGU') return 'Menunggu data AI…';
    return 'Pantau kondisi';
  }
}

// ===================== MODELS =====================

class AiNow {
  final String label;
  final int ts;
  final DateTime time;

  final double tempC;
  final double humRH;
  final double soilPercent;
  final double lightPercent;
  final double uvUvi;

  AiNow({
    required this.label,
    required this.ts,
    required this.time,
    required this.tempC,
    required this.humRH,
    required this.soilPercent,
    required this.lightPercent,
    required this.uvUvi,
  });

  static AiNow fromMap(Map<dynamic, dynamic> m) {
    final iso = (m['iso'] ?? '').toString();
    final ts = _toInt(m['ts']);
    final time = _parseTime(iso, ts);

    final row = (m['row'] is Map) ? (m['row'] as Map) : <dynamic, dynamic>{};

    return AiNow(
      label: (m['label'] ?? '').toString(),
      ts: ts,
      time: time,
      tempC: _toDouble(row['tempC']),
      humRH: _toDouble(row['humRH']),
      soilPercent: _toDouble(row['soil_percent']),
      lightPercent: _toDouble(row['light_percent']),
      uvUvi: _toDouble(row['uv_uvi']),
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static DateTime _parseTime(String iso, int ts) {
    try {
      if (iso.isNotEmpty) return DateTime.parse(iso);
    } catch (_) {}
    if (ts > 0) return DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return DateTime.now();
  }
}

class AiForecast {
  final int ts;
  final DateTime time;
  final String text;
  final double threshold;
  final int stepMinutes;
  final List<double> soilFuture;

  AiForecast({
    required this.ts,
    required this.time,
    required this.text,
    required this.threshold,
    required this.stepMinutes,
    required this.soilFuture,
  });

  static AiForecast fromMap(Map<dynamic, dynamic> m) {
    final iso = (m['iso'] ?? '').toString();
    final ts = AiNow._toInt(m['ts']);
    final time = AiNow._parseTime(iso, ts);

    final step = AiNow._toInt(m['step_minutes']);
    final threshold = AiNow._toDouble(m['threshold']);
    final text = (m['text'] ?? '').toString();

    final list = _parseDoubleList(m['soil_future']);

    return AiForecast(
      ts: ts,
      time: time,
      text: text,
      threshold: threshold,
      stepMinutes: step == 0 ? 10 : step,
      soilFuture: list,
    );
  }

  static List<double> _parseDoubleList(dynamic raw) {
    final out = <double>[];

    if (raw is List) {
      for (final x in raw) {
        out.add(AiNow._toDouble(x));
      }
      return out;
    }

    if (raw is Map) {
      final entries = raw.entries.toList();
      entries.sort((a, b) {
        final ai = int.tryParse(a.key.toString()) ?? 0;
        final bi = int.tryParse(b.key.toString()) ?? 0;
        return ai.compareTo(bi);
      });
      for (final e in entries) {
        out.add(AiNow._toDouble(e.value));
      }
      return out;
    }

    return out;
  }
}

class _Decision {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _Decision({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}
