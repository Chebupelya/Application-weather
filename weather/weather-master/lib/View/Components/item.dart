import 'package:flutter/material.dart';
import 'package:weather/Model/weatherModel.dart';

// ignore: must_be_immutable
class Item extends StatelessWidget {
  Map<String, String> date;
  String? dayTemp;
  String? dayImg;
  Item({required this.date, required this.dayTemp, required this.dayImg});

  @override
  Widget build(BuildContext context) {
    double myHeight = MediaQuery.of(context).size.height;
    double myWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: myHeight * 0.015, horizontal: myWidth * 0.07),
      child: Container(
        height: myHeight * 0.11,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date["day"].toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                Text(
                  date["date"].toString(),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 17),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  dayTemp!.replaceAll("°C", "").toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 55),
                ),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '°C',
                      style: TextStyle(color: Colors.white, fontSize: 25),
                    ),
                    Text('')
                  ],
                ),
              ],
            ),
            Image.asset(
              dayImg.toString(),
              height: myHeight * 0.05,
              width: myWidth * 0.1,
            )
          ],
        ),
      ),
    );
  }
}
