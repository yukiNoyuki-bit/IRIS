import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'src/telemetry.dart';
import 'src/sensor.dart';

class RealtimeService {
  final DatabaseReference baseRef;

  RealtimeService({required String basePath})
      : baseRef = FirebaseDatabase.instance.ref(basePath);

  Stream<TelemetryData> streamState() {
    return baseRef.child('state').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) throw Exception('Data state kosong.');
      final map = Map<String, dynamic>.from(data as Map);
      return TelemetryData.fromMap(map);
    });
  }

  Stream<List<TelemetryData>> streamTelemetry({int limit = 200}) {
    return baseRef.child('telemetry').limitToLast(limit).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <TelemetryData>[];
      final raw = Map<String, dynamic>.from(data as Map);
      final list = raw.values.map((v) {
        final m = Map<String, dynamic>.from(v as Map);
        return TelemetryData.fromMap(m);
      }).toList()
        ..sort((a, b) => a.waktu.compareTo(b.waktu));
      return list;
    });
  }

  /// 🔹 Telemetry + titik terakhir dari state (agar ujung grafik = kartu)
  Stream<List<TelemetryData>> streamTelemetryWithStateTail({int limit = 200}) {
    final controller = StreamController<List<TelemetryData>>.broadcast();

    List<TelemetryData> _tel = const [];
    TelemetryData? _st;

    void _emit() {
      var out = List<TelemetryData>.from(_tel);
      if (_st != null) {
        out.removeWhere((e) => e.waktu.isAfter(_st!.waktu));
        out.add(_st!);
      }
      out.sort((a, b) => a.waktu.compareTo(b.waktu));
      if (out.length > limit) out = out.sublist(out.length - limit);
      controller.add(out);
    }

    final subTel = streamTelemetry(limit: limit).listen((l) {
      _tel = l;
      _emit();
    });
    final subSt = streamState().listen((s) {
      _st = s;
      _emit();
    }, onError: (_) {
      _st = null;
      _emit();
    });

    controller.onCancel = () {
      subTel.cancel();
      subSt.cancel();
    };
    return controller.stream;
  }

  /// 🟨 Riwayat 10 data terakhir untuk halaman RiwayatDataPage
  Stream<List<TelemetryData>> streamHistory({int limit = 10}) {
    final ref = baseRef.child('telemetry').limitToLast(limit);
    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <TelemetryData>[];

      final raw = Map<String, dynamic>.from(data as Map);
      final entries = raw.entries.toList()
        ..sort((a, b) => b.key.toString().compareTo(a.key.toString())); // urut terbaru

      final result = entries.take(limit).map((e) {
        final v = Map<String, dynamic>.from(e.value);
        return TelemetryData.fromMap(v);
      }).toList();

      return result;
    });
  }
}
