import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:weather/Services/config.dart';
import 'package:weather/View/Pages/AccountPage.dart';
import 'package:weather/View/Pages/HelpSupportPage.dart';
import 'package:weather/View/Pages/NotificationsPage.dart';
import 'package:weather/View/Pages/PrivacyPage.dart';
import 'package:http/http.dart' as http;
import 'package:weather/View/Pages/login_page.dart';

class Setting extends StatefulWidget {
  GoogleSignInAccount? user;
  String username;

  Setting({required this.user, required this.username});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  Future<void> _navigateToAccountPage() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.url}/getUserEmail?username=${widget.username}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final email = data['email'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountPage(null, widget.username, email),
          ),
        );
      } else {
        print('Failed to fetch email: ${response.body}');
      }
    } catch (error) {
      print('Failed to fetch email: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    double myHeight = MediaQuery.of(context).size.height;
    double myWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xff060720),
        body: Container(
          height: myHeight,
          width: myWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: myHeight * 0.05),
              Text(
                'Settings',
                style: TextStyle(fontSize: 30, color: Colors.white),
              ),
              SizedBox(height: myHeight * 0.05),
              ListTile(
                  leading: Icon(Icons.person, color: Colors.white),
                  title: Text('Account', style: TextStyle(color: Colors.white)),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onTap: _navigateToAccountPage),
              ListTile(
                leading: Icon(Icons.notifications, color: Colors.white),
                title: Text('Notifications',
                    style: TextStyle(color: Colors.white)),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NotificationsPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.lock, color: Colors.white),
                title: Text('Privacy', style: TextStyle(color: Colors.white)),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PrivacyPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.help, color: Colors.white),
                title: Text('Help & Support',
                    style: TextStyle(color: Colors.white)),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HelpSupportPage()),
                  );
                },
              ),
              SizedBox(height: myHeight * 0.37),
              SizedBox(
                width: 365,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LoginPage(weatherModel: [])),
                  ),
                  icon: Icon(Icons.exit_to_app, color: Colors.white),
                  label: Text('Logout', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
