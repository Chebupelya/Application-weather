import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:weather/Services/config.dart';

Future<int> getUserCitiesCount(int userId) async {
  try {
    final response = await http.get(
      Uri.parse('${Config.url}/userCities?userId=$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> cities = json.decode(response.body)['data'];
      return cities.length; // Возвращаем количество городов
    } else {
      throw Exception('Failed to load user cities');
    }
  } catch (e) {
    print('Error: $e');
    return 0; // В случае ошибки возвращаем 0
  }
}
