import 'package:firebase_database/firebase_database.dart';

Future<void> clearTelemetry() async {
  final ref = FirebaseDatabase.instance.ref('telemetry');
  await ref.set({});
}
