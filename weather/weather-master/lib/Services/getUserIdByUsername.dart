import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:weather/Services/config.dart';

Future<int> getUserIdByUsername(String username) async {
  try {
    final response = await http.get(
      Uri.parse('${Config.url}/getUserId?username=$username'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      int userId = json.decode(response.body)['userId'];
      return userId;
    } else {
      throw Exception('Failed to find user with username');
    }
  } catch (e) {
    print('Error: $e');
    return 0; // В случае ошибки возвращаем 0
  }
}
