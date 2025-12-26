// import 'package:flutter/material.dart';
// import '../realtime_service.dart';
// import 'telemetry.dart';
//
// class RiwayatDataPage extends StatelessWidget {
//   const RiwayatDataPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final realtime = RealtimeService(basePath: "smartfarm");
//
//     return Scaffold(
//       appBar: AppBar(title: const Text("Riwayat - Data")),
//       backgroundColor: Colors.black,
//       body: StreamBuilder<List<TelemetryData>>(
//         stream: realtime.streamTelemetry(limit: 10),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(
//               child: CircularProgressIndicator(color: Colors.white),
//             );
//           }
//
//           final list = snapshot.data!;
//           if (list.isEmpty) {
//             return const Center(
//               child: Text("Belum ada data riwayat.",
//                   style: TextStyle(color: Colors.white70)),
//             );
//           }
//
//           return ListView.builder(
//             itemCount: list.length,
//             itemBuilder: (context, index) {
//               final d = list[index];
//               return Card(
//                 color: Colors.grey[850],
//                 margin: const EdgeInsets.all(8),
//                 child: ListTile(
//                   title: Text(
//                     "${d.waktu.hour}:${d.waktu.minute.toString().padLeft(2, '0')} - ${d.waktu.day}/${d.waktu.month}/${d.waktu.year}",
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                   subtitle: Text(
//                     "Suhu: ${d.suhu.toStringAsFixed(1)}°C | Kelembapan: ${d.kelembapan.toStringAsFixed(1)}% | Soil: ${d.soil.toStringAsFixed(1)}% | UV: ${d.uv.toStringAsFixed(1)}",
//                     style: const TextStyle(color: Colors.white70),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
