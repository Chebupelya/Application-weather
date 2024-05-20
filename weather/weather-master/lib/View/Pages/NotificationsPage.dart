import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Notifications', style: TextStyle(color: Colors.white),),
        backgroundColor: const Color(0xff060720),
      ),
      backgroundColor: const Color(0xff060720),
      body: Center(
        child: Text('Notifications Page'),
      ),
    );
  }
}