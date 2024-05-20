import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:weather/Services/config.dart';
import 'package:weather/Services/getUserCitiesCount.dart';
import 'package:weather/Services/getUserIdByUsername.dart';
import 'package:weather/Services/getUserCities.dart';
import 'package:weather/Utils/staticFile.dart';
import '../../Model/weatherModel.dart';

class Search extends StatefulWidget {
  List<WeatherModel> weatherModel = [];
  String username;

  Search({required this.weatherModel, required this.username});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  int cityCount = 0;
  List<WeatherModel> _searchResults = [];
  List<WeatherModel> _cities = [];
  String _searchQuery = '';
  List<int> addedCityIds = [];
  List<dynamic> cities = [];
  OverlayEntry? _trashOverlayEntry;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initUserCities();
    _loadInitialCities();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialCities() async {
    final jsonString = await rootBundle.loadString('assets/myJson/cities.json');
    final List<dynamic> cities = json.decode(jsonString);
    setState(() {
      _cities = cities.map((city) => WeatherModel.fromJson(city)).toList();
      _searchResults = cities.map((city) {
        return WeatherModel.fromJson(city);
      }).toList();
    });
  }

  void searchCity(String query) async {
    final jsonString = await rootBundle.loadString('assets/myJson/cities.json');
    final List<dynamic> cities = json.decode(jsonString);
    setState(() {
      _searchResults = cities
          .where((city) {
            return city["name"].toLowerCase().contains(query.toLowerCase());
          })
          .map((city) => WeatherModel.fromJson(city))
          .toList();
    });
  }

  void initUserCities() async {
    try {
      String currentUser = widget.username;
      int userId = await getUserIdByUsername(currentUser);
      int count = await getUserCitiesCount(userId);
      cities = await getUserCities(userId);
      setState(() {
        cityCount = count;
      });
    } catch (error) {
      print('Failed to initialize cities data: $error');
    }
  }

  void addCityToUser(WeatherModel city) async {
    final userId = await getUserIdByUsername(widget.username);
    final response = await http.post(
      Uri.parse('${Config.url}/addCityToUser'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: json
          .encode({'userId': userId, 'cityId': city.id, 'cityName': city.name}),
    );

    if (response.statusCode == 200) {
      final userId = await getUserIdByUsername(widget.username);
      final newCities = await getUserCities(userId);

      setState(() {
        cityCount += 1;
        cities = newCities;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text('City was added'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('City is already added or another error occurred.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> selectCity(int userId, int cityId) async {
    final response = await http.post(
      Uri.parse('${Config.url}/setSelectedCity'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: json.encode({'userId': userId, 'cityId': cityId}),
    );

    if (response.statusCode == 200) {
      print('Selection updated successfully');
      var newCities = await getUserCities(userId);
      setState(() {
        cities = newCities;
      });
    } else {
      throw Exception('Failed to update city selection');
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchResults = _cities.where((city) {
        return city.name.toLowerCase().contains(query);
      }).toList();
    });
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
                            city.name,
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Lat: ${city.lat}, Lon: ${city.lon}',
                            style:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                          trailing: Icon(Icons.location_pin),
                          onTap: () {
                            addCityToUser(city);
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

  Future<void> _deleteCityFromUser(int userId, int cityId) async {
    final response = await http.delete(
      Uri.parse('${Config.url}/deleteCityFromUser'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: json.encode({'userId': userId, 'cityId': cityId}),
    );

    if (response.statusCode == 200) {
      final newCities = await getUserCities(userId);

      setState(() {
        cityCount -= 1;
        cities = newCities;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text('City was removed'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to remove the city.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double myHeight = MediaQuery.of(context).size.height;
    double myWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xff060720),
        body: Container(
          height: myHeight,
          width: myWidth,
          child: Column(
            children: [
              SizedBox(
                height: myHeight * 0.03,
              ),
              Text(
                'Pick location',
                style: TextStyle(fontSize: 30, color: Colors.white),
              ),
              SizedBox(
                height: myHeight * 0.03,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: myWidth * 0.05),
                child: Column(
                  children: [
                    Text(
                      'Find the area or city that you want to know',
                      style: TextStyle(
                          fontSize: 18, color: Colors.white.withOpacity(0.5)),
                    ),
                    Text(
                      'the detailed weather info at this time',
                      style: TextStyle(
                          fontSize: 18, color: Colors.white.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: myHeight * 0.05,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: myWidth * 0.04),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: ElevatedButton(
                        onPressed: () => _openSearchModal(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.05),
                          foregroundColor: Colors.white.withOpacity(0.5),
                          padding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/icons/2.2.png',
                              height: myHeight * 0.025,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Search',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: myWidth * 0.03,
                    ),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.05),
                          foregroundColor: Colors.white,
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding:
                              EdgeInsets.symmetric(vertical: myHeight * 0.015),
                        ),
                        child: Image.asset(
                          'assets/icons/6.png',
                          height: myHeight * 0.03,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: myHeight * 0.04,
              ),
              Expanded(
                child: Stack(
                  children: [
                    GridView.builder(
                      padding:
                          EdgeInsets.symmetric(horizontal: myWidth * 0.036),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 13,
                        crossAxisSpacing: 6,
                        childAspectRatio: 3 / 2.2,
                      ),
                      itemCount: cityCount,
                      itemBuilder: (context, index) {
                        final city = cities[index];
                        return GestureDetector(
                          onTap: () async {
                            int userId =
                                await getUserIdByUsername(widget.username);
                            selectCity(userId, city['cityId']);
                          },
                          child: LongPressDraggable<Map<String, dynamic>>(
                            data: city,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Card(
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: city['isSelected'] == "1"
                                        ? const LinearGradient(
                                            colors: [
                                              Color.fromARGB(255, 21, 85, 169),
                                              Color.fromARGB(255, 44, 162, 246),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : const LinearGradient(
                                            colors: [
                                              Color.fromARGB(255, 20, 20, 43),
                                              Color.fromARGB(255, 20, 20, 43),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    borderRadius: BorderRadius.circular(18.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Stack(
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width: 80,
                                                      height: 33,
                                                      child: Text(
                                                        "${city["weather"]["temperature"].round()}°C",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 28),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: 20,
                                                    ),
                                                    Text(
                                                      "${city["weather"]["description"]}",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white
                                                            .withOpacity(0.5),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  "${city["cityName"]}",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          top: -15,
                                          right: -10,
                                          child: Container(
                                            child: Image.asset(
                                              'assets/img/${city["weather"]["icon"]}.png',
                                              width: 70,
                                              height: 70,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            onDragStarted: () {
                              // Show trash icon
                              _trashOverlayEntry = _buildTrashIcon(context);
                              Overlay.of(context)?.insert(_trashOverlayEntry!);
                            },
                            onDragEnd: (details) {
                              // Remove trash icon
                              _removeTrashIcon();
                            },
                            child: GestureDetector(
                              onTap: () async {
                                int userId =
                                    await getUserIdByUsername(widget.username);
                                selectCity(userId, city['cityId']);
                              },
                              child: Card(
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                  side: BorderSide(
                                    color: Color.fromARGB(255, 20, 20, 43),
                                    width: 0,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: city['isSelected'] == "1"
                                        ? const LinearGradient(
                                            colors: [
                                              Color.fromARGB(255, 21, 85, 169),
                                              Color.fromARGB(255, 44, 162, 246),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : const LinearGradient(
                                            colors: [
                                              Color.fromARGB(255, 20, 20, 43),
                                              Color.fromARGB(255, 20, 20, 43),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    borderRadius: BorderRadius.circular(18.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Stack(
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width: 80,
                                                      height: 33,
                                                      child: Text(
                                                        "${city["weather"]["temperature"].round()}°C",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 28),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: 20,
                                                    ),
                                                    Text(
                                                      "${city["weather"]["description"]}",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white
                                                            .withOpacity(0.5),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  "${city["cityName"]}",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          top: -15,
                                          right: -10,
                                          child: Container(
                                            child: Image.asset(
                                              'assets/img/${city["weather"]["icon"]}.png',
                                              width: 70,
                                              height: 70,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_trashOverlayEntry != null)
                      Positioned(
                        right: 20,
                        top: 40,
                        child: DragTarget<Map<String, dynamic>>(
                          builder: (context, candidateData, rejectedData) {
                            return Icon(
                              Icons.delete,
                              color: candidateData.isNotEmpty
                                  ? Colors.red
                                  : Colors.white,
                              size: 40,
                            );
                          },
                          onWillAccept: (data) {
                            return true;
                          },
                          onAccept: (data) async {
                            int userId =
                                await getUserIdByUsername(widget.username);
                            _deleteCityFromUser(userId, data['cityId']);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeTrashIcon() {
    _trashOverlayEntry?.remove();
    _trashOverlayEntry = null;
  }

  OverlayEntry _buildTrashIcon(BuildContext context) {
    return OverlayEntry(
      builder: (context) => Positioned(
        right: 20,
        top: 40,
        child: DragTarget<Map<String, dynamic>>(
          builder: (context, candidateData, rejectedData) {
            return Icon(
              Icons.delete,
              color: candidateData.isNotEmpty ? Colors.red : Colors.white,
              size: 40,
            );
          },
          onWillAccept: (data) {
            return true;
          },
          onAccept: (data) async {
            int userId = await getUserIdByUsername(widget.username);
            _deleteCityFromUser(userId, data['cityId']);
          },
        ),
      ),
    );
  }
}
