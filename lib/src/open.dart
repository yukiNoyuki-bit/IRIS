import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kIrisBlue = Color(0xFF1A3B66);
const kPrimaryBtnColor = Color(0xFF143B6E);

const double kContentMaxWidth = 340;
const double kGapAfterMascot = 18.0;
const double kFooterButtonHeight = 52;

class Iris extends StatelessWidget {
  const Iris({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: _OnboardingShell(),
    );
  }
}

class _OnboardingShell extends StatefulWidget {
  const _OnboardingShell({super.key});
  @override
  State<_OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends State<_OnboardingShell> {
  final _pc = PageController();
  Timer? _timer;
  int _index = 0;
  static const _length = 3;

  @override
  void initState() {
    super.initState();
    // Auto-slide pelan (boleh dihapus kalau mau full manual)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted) return;
        final next = (_index + 1) % _length;
        _pc.animateToPage(
          next,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOut,
        );
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  Future<void> _finishAndGoToDashboard() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('iris.onboarded', true); // tandai sudah lihat Open
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/'); // routeHome
  }

  void _goNext() {
    if (_index < _length - 1) {
      _timer?.cancel();
      _pc.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOut,
      );
      return;
    }
    _finishAndGoToDashboard(); // selesai onboarding
  }

  ButtonStyle get _primaryBtnStyle => ElevatedButton.styleFrom(
    backgroundColor: kPrimaryBtnColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    elevation: 6,
    shadowColor: Colors.black26,
  );

  @override
  Widget build(BuildContext context) {
    // Background statis, hanya konten di tengah yang bergerak
    return _DecoratedBackground(
      child: SafeArea(
        child: Column(
          children: [
            // Jarak dari atas ke konten
            const SizedBox(height: 32),

            // ===== AREA KONTEN YANG BERGESER =====
            Expanded(
              child: PageView(
                controller: _pc,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: const [
                  _LogoPageContent(),
                  _MascotPageContent(asset: 'assets/maskot.png'),
                  _MascotPageContent(asset: 'assets/maskott.png', isLast: true),
                ],
              ),
            ),

            // Jarak yang sama dari konten ke footer
            const SizedBox(height: 32),

            // ===== FOOTER (DOT + BUTTON) TETAP DI BAWAH =====
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PageDots(current: _index, length: _length),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: kFooterButtonHeight,
                    width: double.infinity,
                    child: _index < _length - 1
                        ? ElevatedButton.icon(
                      style: _primaryBtnStyle,
                      onPressed: _goNext,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Selanjutnya'),
                    )
                        : ElevatedButton(
                      style: _primaryBtnStyle,
                      onPressed: _goNext,
                      child: const Text('Ayo Mulai'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===== Konten halaman

class _LogoPageContent extends StatelessWidget {
  const _LogoPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final textScale = MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.2);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: textScale),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/logo(1).png',
                    height: h * 0.18,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kelola Irigasi Lebih Cerdas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kIrisBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ubah cara Anda merawat pertanian dan tanaman dengan IRIS. '
                      'Pantau kondisi tanah secara real-time dan dapatkan kontrol penuh atas penyiraman '
                      'lebih efisien, hemat air, dan tepat sasaran.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: kIrisBlue.withOpacity(0.85),
                    letterSpacing: 0.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MascotPageContent extends StatelessWidget {
  const _MascotPageContent({
    super.key,
    required this.asset,
    this.isLast = false,
  });

  final String asset;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                asset,
                height: h * (isLast ? 0.26 : 0.28),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.eco_outlined,
                  size: 96,
                  color: kIrisBlue,
                ),
              ),
              const SizedBox(height: kGapAfterMascot),
              Text(
                isLast ? 'Otomatis & Hemat Air' : 'Pantau Tanah Secara Real-Time',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kIrisBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'IRIS menganalisis data sensor untuk merekomendasikan waktu dan durasi penyiraman '
                    'yang tepat. Tanaman tercukupi, air tidak terbuang.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: kIrisBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dekorasi background sudut (statis, tidak berpindah saat page berubah)
class _DecoratedBackground extends StatelessWidget {
  const _DecoratedBackground({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -20,
          left: -20,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.9,
              child: Image.asset(
                'assets/shape.png',
                width: w * 0.45,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        Positioned(
          right: -18,
          bottom: -18,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.9,
              child: Image.asset(
                'assets/shape0.png',
                width: w * 0.50,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.current, required this.length, super.key});
  final int current;
  final int length;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    final base = maxWidth < 360 ? 7.0 : 8.0;
    final selectedW = maxWidth < 360 ? 18.0 : 22.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final selected = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: base,
          width: selected ? selectedW : base,
          decoration: BoxDecoration(
            color: selected
                ? kPrimaryBtnColor
                : kPrimaryBtnColor.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
