import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class RealTimeParepareClock extends StatelessWidget {
  final String pattern;
  final TextStyle? style;

  const RealTimeParepareClock({
    super.key,
    this.pattern = 'hh:mm a', // contoh: 12:35 PM
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final location = tz.getLocation('Asia/Makassar');

    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
            (_) => DateTime.now().toUtc(),
      ),
      builder: (context, snapshot) {
        final utcNow = snapshot.data ?? DateTime.now().toUtc();
        final cityNow = tz.TZDateTime.from(utcNow, location);

        final formatted = DateFormat(pattern).format(cityNow);
        return Text(
          formatted,
          style: style ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
        );
      },
    );
  }
}
