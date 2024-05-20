import 'package:flutter/material.dart';

Widget CardWidget(Map city) {
  return Card(
    elevation: 10,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18.0),
    ),
    child: Container(
      decoration: BoxDecoration(
        gradient: city['isSelected'] == 1
            ? LinearGradient(colors: [Color.fromARGB(255, 21, 85, 169), Color.fromARGB(255, 44, 162, 246)])
            : LinearGradient(colors: [Color.fromARGB(255, 20, 20, 43), Color.fromARGB(255, 20, 20, 43)]),
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Содержимое карточки
          ],
        ),
      ),
    ),
  );
}
