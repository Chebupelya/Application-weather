// ignore_for_file: file_names, must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:weather/Model/weatherModel.dart';
import 'package:weather/View/Pages/forecast.dart';
import 'package:weather/View/Pages/home.dart';
import 'package:weather/View/Pages/search.dart';
import 'package:weather/View/Pages/setting.dart';

class NavBar extends StatefulWidget {
  List<WeatherModel> weatherModel = [];
  final dynamic username;
  GoogleSignInAccount? user;

  NavBar({required this.weatherModel, this.username, this.user});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _currentIndex = 0;
  late List<Widget> pages;
  List<WeatherModel> weatherList = [];

  @override
  void initState() {
    pages = [
      Home(weatherModel: widget.weatherModel, username: widget.username),
      Search(weatherModel: widget.weatherModel, username: widget.username),
      Forecast(weatherModel: widget.weatherModel, username: widget.username),
      Setting(user: widget.user, username: widget.username),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double myHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xff060720),
        body: pages.elementAt(_currentIndex),
        bottomNavigationBar: BottomNavigationBar(
            backgroundColor: const Color(0xff060720),
            currentIndex: _currentIndex,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            onTap: (value) {
              setState(() {
                _currentIndex = value;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/icons/1.2.png',
                  height: myHeight * 0.03,
                  color: Colors.grey.withOpacity(0.5),
                ),
                label: '',
                activeIcon: Image.asset(
                  'assets/icons/1.1.png',
                  height: myHeight * 0.03,
                  color: Colors.white,
                ),
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/icons/2.2.png',
                  height: myHeight * 0.03,
                  color: Colors.grey.withOpacity(0.5),
                ),
                label: '',
                activeIcon: Image.asset(
                  'assets/icons/2.1.png',
                  height: myHeight * 0.03,
                  color: Colors.white,
                ),
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/icons/3.2.png',
                  height: myHeight * 0.03,
                  color: Colors.grey.withOpacity(0.5),
                ),
                label: '',
                activeIcon: Image.asset(
                  'assets/icons/3.1.png',
                  height: myHeight * 0.03,
                  color: Colors.white,
                ),
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/icons/4.2.png',
                  height: myHeight * 0.03,
                  color: Colors.grey.withOpacity(0.5),
                ),
                label: '',
                activeIcon: Image.asset(
                  'assets/icons/4.1.png',
                  height: myHeight * 0.03,
                  color: Colors.white,
                ),
              ),
            ]),
      ),
    );
  }
}
