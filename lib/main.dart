import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'src/homes.dart';
import 'placeholder_page.dart';
import 'src/setting_page.dart';
import 'src/open.dart'; // Halaman Open/Onboarding (class Iris)

// 👉 Tambahan untuk timezone
import 'package:timezone/data/latest.dart' as tzdata;

// Path device kamu (samakan dengan di SettingsPage)
const String kDevicePath = 'devices/esp32-iris-01';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inisialisasi database timezone sekali di awal app
  tzdata.initializeTimeZones();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // (Opsional) Pastikan node settings/theme ada; jika hilang → buat "light"
  await ensureSettingsDefault(kDevicePath);

  // === Reset onboarding via --dart-define (untuk testing dari Android Studio) ===
  // Jalankan dengan: flutter run --dart-define=RESET_ONBOARDING=true
  const bool kResetFromDartDefine =
  bool.fromEnvironment('RESET_ONBOARDING', defaultValue: false);
  if (kResetFromDartDefine) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('iris.onboarded');
  }

  // Cek apakah onboarding sudah pernah dilihat
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('iris.onboarded') ?? false;

  runApp(IrisApp(hasSeenOnboarding: hasSeenOnboarding));
}

/// Membuat kembali /devices/<id>/settings/theme bila terhapus.
/// Nilai default: "light" (karena kita tidak pakai "system" lagi).
Future<void> ensureSettingsDefault(String devicePath) async {
  try {
    final themeRef =
    FirebaseDatabase.instance.ref('$devicePath/settings/theme');
    final snap = await themeRef.get();
    if (!snap.exists) {
      await themeRef.set('light');
    }
  } catch (_) {
    // Abaikan error kecil agar app tetap jalan.
  }
}

class IrisApp extends StatelessWidget {
  const IrisApp({super.key, required this.hasSeenOnboarding});
  final bool hasSeenOnboarding;

  // ==== Named routes ====
  static const String routeHome = '/';
  static const String routeOpen = '/open';
  static const String routeSuhu = '/suhu';
  static const String routeHumidity = '/humidity';
  static const String routeSoil = '/soil';
  static const String routeLux = '/lux';
  static const String routeUV = '/uv';
  static const String routePrediksi = '/prediksi';
  static const String routeRiwayat = '/riwayat';
  static const String routeSettings = '/settings';

  @override
  Widget build(BuildContext context) {
    // 🔹 Streaming nilai tema dari Firebase: "light" / "dark"
    final themeRef =
    FirebaseDatabase.instance.ref('$kDevicePath/settings/theme');

    return StreamBuilder<DatabaseEvent>(
      stream: themeRef.onValue,
      builder: (context, snapshot) {
        String raw = (snapshot.data?.snapshot.value as String?) ?? 'light';
        raw = raw.toLowerCase();

        // Fallback kalau ada value aneh / sisa lama
        final ThemeMode mode =
        raw == 'dark' ? ThemeMode.dark : ThemeMode.light;

        return MaterialApp(
          debugShowCheckedModeBanner: false,

          // 🔥 Mode tema global (light/dark) dikontrol dari SettingsPage
          themeMode: mode,

          // Tema terang
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'Poppins',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF46799D),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),

          // Tema gelap
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Poppins',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF26445E),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),

          // Jika belum pernah lihat onboarding → buka /open, selain itu langsung /
          initialRoute: hasSeenOnboarding ? routeHome : routeOpen,

          onGenerateRoute: (settings) {
            late final Widget page;

            switch (settings.name) {
              case routeOpen:
                page = const Iris(); // layar Open/Onboarding
                break;

              case routeHome:
                page = const HomeScrollPage();
                break;

              case routeSuhu:
                page = const PlaceholderPage(title: 'Detail Suhu');
                break;

              case routeHumidity:
                page = const PlaceholderPage(title: 'Detail Humidity');
                break;

              case routeSoil:
                page = const PlaceholderPage(title: 'Detail Soil Moisture');
                break;

              case routeLux:
                page = const PlaceholderPage(title: 'Detail Lux');
                break;

              case routeUV:
                page = const PlaceholderPage(title: 'Detail Ultraviolet');
                break;

              case routePrediksi:
                page = const PlaceholderPage(title: 'Prediksi');
                break;

              case routeRiwayat:
                page = const PlaceholderPage(title: 'Riwayat Penuh');
                break;

              case routeSettings:
                page = const SettingsPage(
                  devicePath: kDevicePath,
                );
                break;

              default:
                page = const Scaffold(
                  body: Center(child: Text('Halaman tidak ditemukan')),
                );
            }

            return MaterialPageRoute(builder: (_) => page, settings: settings);
          },
        );
      },
    );
  }
}
