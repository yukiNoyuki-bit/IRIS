import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;

/// Representasi data cuaca sederhana (+ waktu lokal kota Parepare / Asia/Makassar)
class WeatherData {
  final String cityName;
  final double temperature;
  final String description;
  final DateTime localTime; // waktu lokal Parepare (Asia/Makassar)

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.localTime,
  });
}

/// Service untuk mengambil data cuaca dari OpenWeatherMap.
/// KITA PAKSA label kota jadi "Parepare, Sulawesi Selatan, Indonesia",
/// supaya tidak berubah-ubah (Harapankarya, dlsb) meski koordinat sama.
class WeatherService {
  // Ganti dengan key-mu kalau perlu
  static const String _fallbackKey = '71004de02113db92b574f611674684eb';

  // Koordinat Parepare
  static const double _parepareLat = -4.0167;
  static const double _parepareLon = 119.6333;

  // Label kota yang akan SELALU ditampilkan
  static const String _parepareLabel =
      'Parepare, Sulawesi Selatan, Indonesia';

  final String apiKey;

  WeatherService([String? key])
      : apiKey = key ??
      const String.fromEnvironment(
        'OWM_KEY',
        defaultValue: _fallbackKey,
      );

  /// Ambil cuaca. Jika [lat]/[lon] tidak diisi, otomatis pakai Parepare.
  Future<WeatherData> fetchWeather({double? lat, double? lon}) async {
    if (apiKey.trim().isEmpty) {
      throw Exception(
        '❌ OWM_KEY kosong. Jalankan: flutter run --dart-define=OWM_KEY=YOUR_KEY',
      );
    }

    final useLat = lat ?? _parepareLat;
    final useLon = lon ?? _parepareLon;

    final uri = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
          '?lat=$useLat&lon=$useLon&appid=$apiKey&units=metric&lang=id',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final j = jsonDecode(response.body) as Map<String, dynamic>;

      final temp = (j['main']['temp'] as num).toDouble();
      final descRaw = (j['weather'][0]['description'] as String);
      final desc = _sentenceCase(descRaw);

      // ===== WAKTU LOKAL PAREPARE (Asia/Makassar) DENGAN TIMEZONE =====
      //
      // dt dari OWM = UNIX UTC (detik)
      final dtUtc = DateTime.fromMillisecondsSinceEpoch(
        (j['dt'] as int) * 1000,
        isUtc: true,
      );

      // Kita pakai zona waktu tetap "Asia/Makassar" (UTC+8)
      // Pastikan di main() sudah ada: tzdata.initializeTimeZones();
      final location = tz.getLocation('Asia/Makassar');
      final tzLocal = tz.TZDateTime.from(dtUtc, location);

      // PAKAI LABEL KITA (bukan j['name'])
      return WeatherData(
        cityName: _parepareLabel,
        temperature: temp,
        description: desc,
        localTime: tzLocal, // TZDateTime turunan DateTime
      );
    } else if (response.statusCode == 401) {
      throw Exception('❌ API key salah / belum aktif (401).');
    } else if (response.statusCode == 404) {
      throw Exception('❌ Lokasi tidak ditemukan (404).');
    } else {
      throw Exception(
        '❌ Gagal mengambil data cuaca (kode: ${response.statusCode})\n${response.body}',
      );
    }
  }

  static String _sentenceCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
