import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:weather/Model/GoogleSignInApi.dart';
import 'package:weather/Services/config.dart';
import 'package:weather/Model/weatherModel.dart';
import 'package:weather/View/Pages/AccountPage.dart';
import 'package:weather/View/Pages/AdminPanel.dart';
import 'package:weather/View/Pages/GuestPage.dart';
import 'package:weather/View/Pages/bottomNavigationBar.dart';
import 'package:weather/View/Pages/setting.dart';

class LoginPage extends StatefulWidget {
  final List<WeatherModel> weatherModel;
  bool isRegisterMode = false;

  LoginPage({required this.weatherModel});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isRegisterMode = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    var url = '${Config.url}/login';
    var response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'username': _usernameController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      print('Login successful: ${data["data"]}');
      await Future.delayed(Duration(seconds: 2));

      if (data["data"]["role"] == "Admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminPanel(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NavBar(
                weatherModel: widget.weatherModel,
                username: data["data"]["username"]),
          ),
        );
      }
    } else {
      _showErrorDialog();
      print('Failed to login: ${response.body}');
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xff060720),
          title: Text(
            'Error',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Invalid username or password.',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _repeatPasswordController.text) {
      print('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    var url = '${Config.url}/register';
    print(url);
    var response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'username': _usernameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'role': 'User',
      }),
    );

    if (response.statusCode == 200) {
      print('Registration successful');
      await Future.delayed(Duration(seconds: 2));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NavBar(
              weatherModel: widget.weatherModel,
              username: _usernameController.text),
        ),
      );
    } else {
      print('Failed to register: ${response.body}');
    }
    setState(() {
      _isLoading = false;
    });
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (RegExp(r'[!@#\$&*~]').hasMatch(value)) {
      return 'Username cannot contain special characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 4) {
      return 'Password must be at least 4 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff060720),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          _isRegisterMode ? 'Register' : 'Login',
                          style: TextStyle(fontSize: 32.0, color: Colors.white),
                        ),
                        SizedBox(height: 20.0),
                        Container(
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Color(0xff1e1e2e),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: <Widget>[
                              TextFormField(
                                controller: _usernameController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  prefixIcon:
                                      Icon(Icons.person, color: Colors.white),
                                  labelText: 'Username',
                                  labelStyle: TextStyle(color: Colors.white),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.blue),
                                  ),
                                ),
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter a username'
                                    : null,
                              ),
                              SizedBox(height: 10.0),
                              if (_isRegisterMode)
                                TextFormField(
                                  controller: _emailController,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    prefixIcon:
                                        Icon(Icons.email, color: Colors.white),
                                    labelText: 'Email',
                                    labelStyle: TextStyle(color: Colors.white),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.blue),
                                    ),
                                  ),
                                  validator: (value) => value!.isEmpty
                                      ? 'Please enter an email'
                                      : null,
                                ),
                              SizedBox(height: 10.0),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  prefixIcon:
                                      Icon(Icons.lock, color: Colors.white),
                                  labelText: 'Password',
                                  labelStyle: TextStyle(color: Colors.white),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.blue),
                                  ),
                                ),
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter a password'
                                    : null,
                              ),
                              SizedBox(height: 10.0),
                              if (_isRegisterMode)
                                TextFormField(
                                  controller: _repeatPasswordController,
                                  obscureText: true,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.lock_outline,
                                        color: Colors.white),
                                    labelText: 'Repeat Password',
                                    labelStyle: TextStyle(color: Colors.white),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.blue),
                                    ),
                                  ),
                                  validator: (value) =>
                                      value != _passwordController.text
                                          ? 'Passwords do not match'
                                          : null,
                                ),
                              SizedBox(height: 20.0),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      _isRegisterMode ? _register : _login,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    backgroundColor: Colors.blue,
                                  ),
                                  child: Text(
                                    _isRegisterMode ? 'Register' : 'Login',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isRegisterMode = !_isRegisterMode;
                                  });
                                },
                                child: Text(
                                  _isRegisterMode
                                      ? 'Already have an account? Login'
                                      : 'Don’t have an account? Register',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ),
                              SizedBox(height: 10.0),
                              Text('or',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                              SizedBox(
                                height: 10,
                              ),
                              SizedBox(height: 10.0),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: signIn,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    backgroundColor:
                                        Color.fromARGB(255, 87, 87, 97),
                                    foregroundColor:
                                        Color.fromARGB(255, 236, 225, 225),
                                  ),
                                  icon: Image.asset(
                                    'assets/icons/google_logo.png',
                                    height: 24.0,
                                  ),
                                  label: Text('Sign in with Google'),
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => GuestPage()),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    backgroundColor:
                                        Color.fromARGB(255, 87, 87, 97),
                                    foregroundColor:
                                        Color.fromARGB(255, 236, 225, 225),
                                  ),
                                  icon: Image.asset(
                                    'assets/icons/guest_logo.png',
                                    height: 24.0,
                                  ),
                                  label: Text('Continue as guest'),
                                ),
                              ),
                              SizedBox(height: 20.0),
                              Text("Minsk 2024",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              Text("Privacy Policy",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future signIn() async {
    final user = await GoogleSignInApi.login();
    print(user);
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Sign in failed")));
    } else {
      var response = await http.post(
        Uri.parse('${Config.url}/googleSignIn'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String?>{
          'email': user.email,
          'username': user.displayName,
          'sub': user.id
        }),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => NavBar(
                weatherModel: widget.weatherModel,
                username: user.displayName)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Sign in failed: ${response.body}")));
      }
    }
  }
}
