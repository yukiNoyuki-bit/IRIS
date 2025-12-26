import 'package:flutter/material.dart';

class PlantExpressionUi {
  final String assetPath;
  final Color accent;
  final String displayLabel;
  final String caption;

  const PlantExpressionUi({
    required this.assetPath,
    required this.accent,
    required this.displayLabel,
    required this.caption,
  });

  static const Color ok = Color(0xFF22C55E);
  static const Color warn = Color(0xFFF59E0B);
  static const Color bad = Color(0xFFEF4444);
  static const Color neutral = Color(0xFF94A3B8);

  static String _pretty(String s) =>
      s.trim().isEmpty ? 'BELUM ADA' : s.trim().replaceAll('_', ' ');

  static PlantExpressionUi fromAiLabel(String rawLabel) {
    final u = rawLabel.trim().toUpperCase();
    final display = _pretty(u);

    if (u.isEmpty) {
      return const PlantExpressionUi(
        assetPath: 'assets/expresi/sit_calm.png',
        accent: neutral,
        displayLabel: 'BELUM ADA',
        caption: 'Menunggu data AI…',
      );
    }

    if (u.contains('AMAN') || u.contains('OPTIMAL') || u == 'OK') {
      return PlantExpressionUi(
        assetPath: 'assets/expresi/happy_thumbs.png',
        accent: ok,
        displayLabel: display,
        caption: 'Pertahankan kondisi',
      );
    }

    // label Anda sekarang
    if (u.contains('STRES_PANAS') || u.contains('PANAS')) {
      return PlantExpressionUi(
        assetPath: 'assets/expresi/tired.png',
        accent: bad,
        displayLabel: display,
        caption: 'Tambah ventilasi/kipas',
      );
    }

    if (u.contains('STRES_DINGIN') || u.contains('DINGIN')) {
      return PlantExpressionUi(
        assetPath: 'assets/expresi/sad_cry.png',
        accent: warn,
        displayLabel: display,
        caption: 'Stabilkan suhu ruang',
      );
    }

    if (u.contains('KERING') || u.contains('KURANG_AIR')) {
      return PlantExpressionUi(
        assetPath: 'assets/expresi/water_splash.png',
        accent: bad,
        displayLabel: display,
        caption: 'Cek pompa/penyiraman',
      );
    }

    if (u.contains('LEMBAP') || u.contains('BASAH')) {
      return PlantExpressionUi(
        assetPath: 'assets/expresi/dizzy_upside.png',
        accent: warn,
        displayLabel: display,
        caption: 'Kurangi air & tambah airflow',
      );
    }

    if (u.contains('CAHAYA_KURANG') || u.contains('KURANG_CAHAYA')) {
      return PlantExpressionUi(
        assetPath: 'assets/expresi/confused.png',
        accent: warn,
        displayLabel: display,
        caption: 'Tambah intensitas lampu',
      );
    }

    if (u.contains('CAHAYA_BERLEBIH') || u.contains('UV_TINGGI')) {
      return PlantExpressionUi(
        assetPath: 'assets/expresi/angry.png',
        accent: warn,
        displayLabel: display,
        caption: 'Kurangi intensitas lampu',
      );
    }

    return PlantExpressionUi(
      assetPath: 'assets/expresi/sit_calm.png',
      accent: warn,
      displayLabel: display,
      caption: 'Pantau kondisi',
    );
  }
}
