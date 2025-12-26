import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/main.dart';

void main() {
  testWidgets('Open (onboarding) renders on first launch',
          (WidgetTester tester) async {
        // IrisApp butuh argumen hasSeenOnboarding.
        // false -> aplikasi membuka layar Open (aman untuk test, tanpa Firebase).
        await tester.pumpWidget(const IrisApp(hasSeenOnboarding: false));

        // Aplikasi terpasang dengan MaterialApp.
        expect(find.byType(MaterialApp), findsOneWidget);

        // Teks utama di layar Open harus tampil.
        expect(find.text('Kelola Irigasi Lebih Cerdas'), findsOneWidget);
      });
}
