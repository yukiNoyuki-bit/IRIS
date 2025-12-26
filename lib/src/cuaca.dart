import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;

class WeatherBundle {
  final WeatherNow now;
  final List<WeatherHour> hours;

  WeatherBundle({required this.now, required this.hours});
}

class WeatherNow {
  final String locationName;
  final double temp;
  final String condition;
  final IconData icon;

  WeatherNow({
    required this.locationName,
    required this.temp,
    required this.condition,
    required this.icon,
  });
}

class WeatherHour {
  final DateTime time;
  final double temp;
  final IconData icon;

  WeatherHour({
    required this.time,
    required this.temp,
    required this.icon,
  });
}

class WeatherService {
  static const String _fallbackKey = '71004de02113db92b574f611674684eb';

  final String apiKey;

  WeatherService([String? key])
      : apiKey = key ??
      const String.fromEnvironment(
        'OWM_KEY',
        defaultValue: _fallbackKey,
      );

  static const _base = 'https://api.openweathermap.org/data/2.5';

  Future<WeatherBundle> fetchFor(double lat, double lon) async {
    if (apiKey.trim().isEmpty) {
      throw Exception(
        '❌ Belum ada API key.\n'
            'Tambahkan dengan perintah:\n'
            'flutter run --dart-define=OWM_KEY=YOUR_KEY_HERE',
      );
    }

    final nowUrl = Uri.parse(
      '$_base/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=id',
    );
    final fcUrl = Uri.parse(
      '$_base/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric&cnt=6&units=metric&lang=id',
    );

    debugPrint('🌦 Fetching weather from: $nowUrl');
    debugPrint('🌤 Forecast from: $fcUrl');

    final nowRes = await http.get(nowUrl);
    debugPrint('Now Response (${nowRes.statusCode}): ${nowRes.body}');
    if (nowRes.statusCode != 200) {
      throw Exception('Gagal memuat cuaca: ${nowRes.statusCode}\n${nowRes.body}');
    }

    final nowJson = json.decode(nowRes.body);
    final now = WeatherNow(
      locationName: nowJson['name'] ?? 'Lokasi tidak dikenal',
      temp: (nowJson['main']['temp'] as num).toDouble(),
      condition: (nowJson['weather'][0]['description'] as String).toUpperCase(),
      icon: _mapIcon(nowJson['weather'][0]['icon']),
    );

    final fcRes = await http.get(fcUrl);
    debugPrint('Forecast Response (${fcRes.statusCode}): ${fcRes.body}');
    if (fcRes.statusCode != 200) {
      throw Exception('Gagal memuat prakiraan: ${fcRes.statusCode}\n${fcRes.body}');
    }

    final fcJson = json.decode(fcRes.body);
    final List list = fcJson['list'];

    final location = tz.getLocation('Asia/Makassar');

    final hours = list.map((item) {
      final dtUtc = DateTime.fromMillisecondsSinceEpoch(
        (item['dt'] as int) * 1000,
        isUtc: true,
      );
      final tzLocal = tz.TZDateTime.from(dtUtc, location);

      final temp = (item['main']['temp'] as num).toDouble();
      final icon = _mapIcon(item['weather'][0]['icon']);

      return WeatherHour(time: tzLocal, temp: temp, icon: icon);
    }).toList();

    return WeatherBundle(now: now, hours: hours);
  }

  static IconData _mapIcon(String code) {
    switch (code) {
      case '01d':
        return Icons.wb_sunny;
      case '01n':
        return Icons.nightlight_round;
      case '02d':
      case '02n':
        return Icons.cloud;
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        return Icons.cloud_queue;
      case '09d':
      case '09n':
      case '10d':
      case '10n':
        return Icons.grain;
      case '11d':
      case '11n':
        return Icons.flash_on;
      case '13d':
      case '13n':
        return Icons.ac_unit;
      case '50d':
      case '50n':
        return Icons.blur_on;
      default:
        return Icons.wb_cloudy;
    }
  }
}
