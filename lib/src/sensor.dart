class SensorData {
  final double suhu;
  final double kelembapan;
  final double soil;
  final double cahaya;
  final double uv;
  final bool pompa;
  final DateTime waktu;

  SensorData({
    required this.suhu,
    required this.kelembapan,
    required this.soil,
    required this.cahaya,
    required this.uv,
    required this.pompa,
    required this.waktu,
  });

  static double _asDouble(dynamic x) {
    if (x == null) return 0.0;
    if (x is num) return x.toDouble();
    if (x is String) return double.tryParse(x) ?? 0.0;
    if (x is Map) {
      for (final k in [
        'v','value','val','percent','lux','raw','adc','moisture','index','uvi','temperature','humidity','temp','hum'
      ]) {
        final v = x[k];
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v) ?? 0.0;
      }
    }
    return 0.0;
  }

  static bool _asBool(dynamic x) {
    if (x is bool) return x;
    if (x is num) return x != 0;
    if (x is String) {
      final s = x.toLowerCase();
      return s == 'on' || s == 'true' || s == '1';
    }
    if (x is Map) return _asBool(x['on'] ?? x['value'] ?? x['state']);
    return false;
  }

  factory SensorData.fromMap(Map<String, dynamic> map) {
    final env     = map['env']   is Map ? Map<String, dynamic>.from(map['env'])   : const {};
    final soilMap = map['soil']  is Map ? Map<String, dynamic>.from(map['soil'])  : const {};
    final light   = map['light'] is Map ? Map<String, dynamic>.from(map['light']) : const {};
    final uvMap   = map['uv']    is Map ? Map<String, dynamic>.from(map['uv'])    : map['uv'];
    final pump    = map['pump'];

    final ts = map['ts'];
    final tMillis = ts is int
        ? ts
        : (ts is num ? ts.toInt() : int.tryParse(ts?.toString() ?? '0') ?? 0);

    return SensorData(
      suhu:        _asDouble(env['tempC'] ?? env['temperature'] ?? env['temp']),
      kelembapan:  _asDouble(env['humRH'] ?? env['humidity']   ?? env['hum']),
      soil:        _asDouble(soilMap['percent'] ?? soilMap['moisture'] ?? soilMap),
      cahaya:      _asDouble(light['percent'] ?? light['lux'] ?? light),
      uv:          _asDouble(uvMap),
      pompa:       _asBool(pump),
      waktu:       DateTime.fromMillisecondsSinceEpoch(tMillis),
    );
  }
}
