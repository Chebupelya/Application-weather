import 'dart:convert';
import 'dart:ffi';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:weather/Model/weatherModel.dart';
import 'package:weather/Services/config.dart';
import 'package:weather/Services/getUserIdByUsername.dart';
import 'package:weather/Utils/staticFile.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:weather/View/Pages/forecast.dart';

class Home extends StatefulWidget {
  List<WeatherModel> weatherModel = [];
  String username;

  Home(
      {required this.weatherModel,
      required this.username,
      GoogleSignInAccount? user});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<WeatherModel> weatherModel = [];
  bool isKeyboardVisible = false;
  bool isLoading = true;
  bool isForecastSelected = true;

  String city_name = "Minsk";
  String main_img = "assets/img/04n.png";
  String temp = "10°С";
  String wind = "10 km/h";
  String humidity = "10%";
  List<dynamic> hour_img = List.filled(24, "assets/img/04n.png");
  List<dynamic> hour_temp = List.filled(24, "10°С");
  List<dynamic> hour_time = [];
  int userId = -1;

  @override
  void initState() {
    initHourList();
    fetchWeatherData();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await scrollToIndex();
    });
    //find_hour_index();
  }

  Future<void> initHourList() async {
    DateTime now = DateTime.now();
    int currentHour = now.hour;

    hour_time = List.generate(24, (index) {
      int hour = (currentHour + index) % 24;
      return "${hour.toString().padLeft(2, '0')}:00";
    });
  }

  Future<void> fetchWeatherData() async {
    try {
      userId = await getUserIdByUsername(widget.username);
      final response =
          await http.get(Uri.parse('${Config.url}/weather?userId=$userId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          weatherModel = (data as List)
              .map((item) => WeatherModel.fromJson(item))
              .toList();
          isLoading = false;
          city_name = data[0]["name"];
          main_img = data[0]["weekly_weather"][0]["main_img"];
          temp = data[0]["weekly_weather"][0]["main_temp"];
          wind = data[0]["weekly_weather"][0]["main_wind"];
          humidity = data[0]["weekly_weather"][0]["main_humidity"];
          hour_img = data[0]["weekly_weather"][0]["all_time"]["img"];
          hour_temp = data[0]["weekly_weather"][0]["all_time"]["temps"];
          hour_time = data[0]["weekly_weather"][0]["all_time"]["hour"];
          find_hour_index();
        });
      } else {
        print('Ошибка при запросе данных: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка при запросе данных: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  DateTime time = DateTime.now();
  int hour_index = 0;
  bool complete1 = false;
  bool complete2 = false;

  find_hour_index() {
    String my_time;
    my_time = time.hour.toString();
    if (my_time.length == 1) {
      my_time = '0$my_time';
    }
    for (var i = 0; i < hour_time.length; i++) {
      if (hour_time[i].substring(0, 2).toString() == my_time) {
        setState(() {
          hour_index = i;
          complete2 = true;
        });
        break;
      }
    }
  }

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  scrollToIndex() async {
    itemScrollController.scrollTo(
        index: hour_index,
        duration: Duration(seconds: 1),
        curve: Curves.easeInOutCubic);
  }

  void _showWeatherChart(BuildContext context, int userId) async {
  // Initialize empty lists for FlSpot data and labels for x-axis
  List<FlSpot> _temperatureData = [];
  List<FlSpot> _humidityData = [];
  List<FlSpot> _windSpeedData = [];
  List<FlSpot> _cloudinessData = [];
  List<FlSpot> _pressureData = [];
  List<String> _xLabels = [];

  try {
    // Fetch the weather data from the endpoint
    final response = await http.get(
      Uri.parse('${Config.url}/weatherChart?userId=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Parse the JSON response
      final data = json.decode(response.body);
      final List<dynamic> dailyData = data['daily'];

      for (var i = 0; i < dailyData.length; i++) {
        final dayData = dailyData[i];
        final date = DateTime.parse(dayData['date']);
        final dayLabel = DateFormat.E().format(date); // Day of the week (e.g., Mon, Tue)

        _xLabels.add(dayLabel);

        _temperatureData.add(FlSpot(i.toDouble(), dayData['temperature']['day']));
        _humidityData.add(FlSpot(i.toDouble(), dayData['humidity'].toDouble()));
        _windSpeedData.add(FlSpot(i.toDouble(), dayData['windSpeed']));
        _cloudinessData.add(FlSpot(i.toDouble(), dayData['cloudiness'].toDouble()));
        _pressureData.add(FlSpot(i.toDouble(), dayData['pressure'].toDouble()));
      }

      // Show the modal bottom sheet with the charts
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.grey[900],
        isScrollControlled: true,
        builder: (BuildContext bc) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Weather Chart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildChart('Temperature', _temperatureData, _xLabels),
                        _buildChart('Humidity', _humidityData, _xLabels),
                        _buildChart('Wind Speed', _windSpeedData, _xLabels),
                        _buildChart('Cloudiness', _cloudinessData, _xLabels),
                        _buildChart('Pressure', _pressureData, _xLabels),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      throw Exception('Failed to load weather data');
    }
  } catch (error) {
    print('Error fetching weather data: $error');
    // Handle the error, e.g., show a dialog or a snack bar
  }
}

// Helper method to build the charts
Widget _buildChart(String title, List<FlSpot> data, List<String> xLabels) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 10),
      Container(
        height: 200,
        padding: EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: data,
                isCurved: true,
                colors: [Colors.blue],
                barWidth: 4, // Set the thickness of the line
                belowBarData: BarAreaData(
                  show: true,
                  colors: [Colors.blue.withOpacity(0.3)],
                ),
              ),
            ],
            titlesData: FlTitlesData(
              rightTitles: SideTitles(showTitles: false),
              topTitles: SideTitles(showTitles: false),
              leftTitles: SideTitles(
                showTitles: true,
                getTextStyles: (context, value) => const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                margin: 16, // Set the distance of the values from the left axis
              ),
              bottomTitles: SideTitles(
                showTitles: true,
                getTextStyles: (context, value) => const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                margin: 16, // Set the distance of the values from the bottom axis
                getTitles: (value) {
                  if (value.toInt() >= 0 && value.toInt() < xLabels.length) {
                    return xLabels[value.toInt()];
                  }
                  return '';
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.white.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
          ),
        ),
      ),
      SizedBox(height: 20),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    double myHeight = MediaQuery.of(context).size.height;
    double myWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
                  city_name,
                  style: TextStyle(fontSize: 40, color: Colors.white),
                ),
                SizedBox(
                  height: myHeight * 0.01,
                ),
                Text(
                  DateFormat('dd MMMM yyyy, EEEEE').format(time),
                  style: TextStyle(
                      fontSize: 20, color: Colors.white.withOpacity(0.5)),
                ),
                SizedBox(
                  height: myHeight * 0.05,
                ),
                Container(
                  height: myHeight * 0.05,
                  width: myWidth * 0.6,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isForecastSelected = true;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: isForecastSelected
                                  ? BorderRadius.circular(10)
                                  : BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomLeft: Radius.circular(10)),
                              gradient: isForecastSelected
                                  ? LinearGradient(colors: [
                                      Color.fromARGB(255, 21, 85, 169),
                                      Color.fromARGB(255, 44, 162, 246),
                                    ])
                                  : null,
                              color: isForecastSelected
                                  ? null
                                  : Colors.white.withOpacity(0.05),
                            ),
                            child: Center(
                              child: Text(
                                'Forecast',
                                style: TextStyle(
                                  color: isForecastSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isForecastSelected = false;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: isForecastSelected
                                  ? BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      bottomRight: Radius.circular(10))
                                  : BorderRadius.circular(10),
                              gradient: isForecastSelected
                                  ? null
                                  : LinearGradient(colors: [
                                      Color.fromARGB(255, 21, 85, 169),
                                      Color.fromARGB(255, 44, 162, 246),
                                    ]),
                              color: isForecastSelected
                                  ? Colors.white.withOpacity(0.05)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Air quality',
                                style: TextStyle(
                                  color: isForecastSelected
                                      ? Colors.white.withOpacity(0.5)
                                      : Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: myHeight * 0.05,
                ),
                Container(
                  //color: Colors.amber,
                  child: Image.asset(
                    main_img,
                    height: myHeight * 0.17,
                    width: myWidth * 0.36,
                    fit: BoxFit.fill,
                  ),
                ),
                SizedBox(
                  height: myHeight * 0.07,
                ),
                Container(
                  height: myHeight * 0.09,
                  child: Row(
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
                              Text(
                                temp,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20),
                              ),
                            ],
                          )),
                      Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Text(
                                'Wind',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 20),
                              ),
                              Text(
                                wind,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20),
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
                              Text(
                                humidity,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20),
                              ),
                            ],
                          )),
                    ],
                  ),
                ),
                SizedBox(
                  height: myHeight * 0.04 - 30,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: myWidth * 0.06),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today',
                        style: TextStyle(color: Colors.white, fontSize: 28),
                      ),
                      InkWell(
                        onTap: () => _showWeatherChart(context, userId),
                        child: Text(
                          'View full report',
                          style: TextStyle(color: Colors.blue, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: myHeight * 0.02,
                ),
                Expanded(
                    child: Padding(
                  padding: EdgeInsets.only(
                      left: myWidth * 0.03, bottom: myHeight * 0.03),
                  child: ScrollablePositionedList.builder(
                    itemScrollController: itemScrollController,
                    itemPositionsListener: itemPositionsListener,
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: 24,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: myWidth * 0.02,
                            vertical: myHeight * 0.03),
                        child: Container(
                          width: myWidth * 0.35,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: hour_index == index
                                  ? null
                                  : Colors.white.withOpacity(0.05),
                              gradient: hour_index == index
                                  ? LinearGradient(colors: [
                                      Color.fromARGB(255, 21, 85, 169),
                                      Color.fromARGB(255, 44, 162, 246),
                                    ])
                                  : null),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: myWidth * 0.01,
                                ),
                                Container(
                                  width: 65,
                                  height: 65,
                                  child: Image.asset(
                                    hour_img[index],
                                    height: myHeight * 0.03,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                SizedBox(
                                  width: myWidth * 0.01,
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      hour_time[index],
                                      style: TextStyle(
                                          fontSize: 20, color: Colors.white),
                                    ),
                                    Text(
                                      hour_temp[index],
                                      style: TextStyle(
                                          fontSize: 25, color: Colors.white),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ))
              ],
            )),
      ),
    );
  }
}
