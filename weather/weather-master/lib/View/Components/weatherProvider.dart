import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weather/Model/weatherModel.dart';
import 'package:weather/Services/config.dart';

class WeatherProvider with ChangeNotifier {
  List<WeatherModel> _cities = [];
  int _cityCount = 0;
  Timer? _timer;

  List<WeatherModel> get cities => _cities;
  int get cityCount => _cityCount;

  WeatherProvider() {
    loadInitialCities();
    _startPeriodicUpdate();
  }

  Future<void> loadInitialCities() async {
    final jsonString = await rootBundle.loadString('assets/myJson/cities.json');
    final List<dynamic> cities = json.decode(jsonString);
    _cities = cities.map((city) => WeatherModel.fromJson(city)).toList();
    _cityCount = _cities.length;
    notifyListeners();
  }

  void _startPeriodicUpdate() {
    _timer = Timer.periodic(Duration(minutes: 5), (timer) {
      loadInitialCities();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
