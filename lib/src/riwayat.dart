import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final String description;
  final String cityName;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.cityName,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      cityName: json['name'],
    );
  }
}

class WeatherService {
  final String apiKey;
  final String city;

  WeatherService(this.apiKey, {this.city = 'Parepare'});

  Future<WeatherData> fetchWeather() async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=id';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal mengambil data cuaca (${response.statusCode})');
    }
  }
}
