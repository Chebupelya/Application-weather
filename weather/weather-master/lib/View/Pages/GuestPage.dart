import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:weather/Services/config.dart';
import 'package:weather/View/Pages/login_page.dart';

class GuestPage extends StatefulWidget {
  @override
  _GuestPageState createState() => _GuestPageState();
}

class _GuestPageState extends State<GuestPage> {
  bool _isCityAdded = false;
  Map<String, dynamic>? _weatherData;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  List<dynamic> _cities = [];

  Future<void> _addCity(String cityName) async {
    final response = await http.get(
      Uri.parse('${Config.url}/guestWeather?city=$cityName'),
      headers: <String, String>{'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _weatherData = json.decode(response.body);
        _isCityAdded = true;
      });
    } else {
      print('Failed to fetch weather data: ${response.body}');
    }
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(
          weatherModel: [],
        ),
      ),
    );
  }

  void _openSearchModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (BuildContext bc) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search for a city',
                      suffixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(color: Colors.white),
                    onChanged: _filterCities,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final city = _searchResults[index];
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          border: Border.all(color: Colors.grey[700]!),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ListTile(
                          title: Text(
                            city['name'],
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Lat: ${city['lat']}, Lon: ${city['lon']}',
                            style:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                          trailing: Icon(Icons.location_pin),
                          onTap: () {
                            _addCity(city['name']);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    _onModalClosed();
  }

  void _onModalClosed() {
    _loadInitialCities();
  }

  void _loadInitialCities() async {
    final jsonString = await rootBundle.loadString('assets/myJson/cities.json');
    final List<dynamic> cities = json.decode(jsonString);
    setState(() {
      _cities = cities;
      _searchResults = cities;
    });
  }

  void _filterCities(String query) {
    final filteredCities = _cities.where((city) {
      return city['name'].toLowerCase().contains(query.toLowerCase());
    }).toList();
    setState(() {
      _searchResults = filteredCities;
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy, EEEEE').format(date);
  }

  @override
  void initState() {
    super.initState();
    _loadInitialCities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Guest Page', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff060720),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (_isCityAdded)
              Container()
            else
              ElevatedButton(
                onPressed: () => _openSearchModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 71, 55, 217),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                child: Text(
                  'Select city',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            SizedBox(height: 20),
            if (_weatherData != null) ...[
              Text(
                _weatherData!['name'],
                style: TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                _formatDate(DateTime.now()),
                style: TextStyle(
                    fontSize: 20, color: Colors.white.withOpacity(0.7)),
              ),
              SizedBox(height: 40),
              Image.asset(
                'assets/img/${_weatherData!['weather']['icon']}.png',
                width: 100,
                height: 100,
              ),
              SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Text(
                            'Temp',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 20),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "${_weatherData!['main']['temp']}°C",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ],
                      )),
                  Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Text(
                            'Wind',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 20),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "${_weatherData!['wind']['speed']}m/s",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ],
                      )),
                  Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Text(
                            'Humidity',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 20),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "${_weatherData!['main']['humidity']}%",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ],
                      )),
                ],
              ),
              SizedBox(height: 50),
              Text(
                "Want to see more information and add more cities?",
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(vertical: 20.0),
                child: TextButton(
                  onPressed: () => _navigateToRegister(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 94, 138, 216),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      backgroundColor: Color(0xff060720),
    );
  }
}
