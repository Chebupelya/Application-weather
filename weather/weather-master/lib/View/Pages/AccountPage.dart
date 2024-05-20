import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:weather/Services/config.dart';
import 'package:weather/View/Pages/login_page.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();

  GoogleSignInAccount? user;
  String username;
  String email;

  AccountPage(this.user, this.username, this.email);
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isChanged = false;

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _repeatNewPasswordController =
      TextEditingController();

  String? _errorMessage;

  String _originalName = "";
  String _originalEmail = "";

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user?.displayName ?? widget.username;
    _emailController.text = widget.user?.email ?? widget.email;
    _originalName = _nameController.text;
    _originalEmail = _emailController.text;
    _nameController.addListener(_checkIfChanged);
    _emailController.addListener(_checkIfChanged);
  }

  void _checkIfChanged() {
    setState(() {
      _isChanged = _nameController.text != _originalName ||
          _emailController.text != _originalEmail;
    });
  }

  void _saveChanges() async {
    var url = Uri.parse(
        '${Config.url}/updateUser'); // Замените на адрес вашего сервера
    var response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': _nameController.text,
        'email': _emailController.text,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _isChanged = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Changes saved successfully')));
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(weatherModel: [],),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save changes')));
    }
  }

  void _discardChanges() {
    setState(() {
      _nameController.text = _originalName;
      _emailController.text = _originalEmail;
      _isChanged = false;
    });
  }

  Future<void> _changePassword() async {
    String oldPassword = _oldPasswordController.text;
    String newPassword = _newPasswordController.text;
    String repeatNewPassword = _repeatNewPasswordController.text;

    if (newPassword != repeatNewPassword) {
      setState(() {
        _errorMessage = 'New password and Repeat new password do not match';
      });
      return;
    }

    if (newPassword.length < 4) {
      setState(() {
        _errorMessage = 'New password must be at least 4 characters long';
      });
      return;
    }

    var response = await http.get(
        Uri.parse(
            '${Config.url}/checkPassword?username=${widget.username}&password=$oldPassword'),
        headers: <String, String>{'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      print(data["message"]);
      if (data['message'] != "success") {
        setState(() {
          _errorMessage = 'Old password is incorrect';
        });
        return;
      }
    } else {
      setState(() {
        _errorMessage = 'Error verifying old password';
      });
      return;
    }
    response = await http.post(
      Uri.parse('${Config.url}/changePassword'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: json.encode({
        'username': widget.username,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _errorMessage = 'Error changing password';
      });
    }
  }

  void _showChangePasswordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xff060720),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _oldPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Old Password',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _repeatNewPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Repeat New Password',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Change Password',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      setState(() {
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _repeatNewPasswordController.clear();
        _errorMessage = null;
      });
    });
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
        title: Text('Account', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff060720),
      ),
      backgroundColor: const Color(0xff060720),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlueAccent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlueAccent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isChanged ? _saveChanges : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button color
                  foregroundColor: Colors.white, // Text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
                child: Text('Save Changes'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isChanged ? _discardChanges : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey, // Button color
                  foregroundColor: Colors.white, // Text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
                child: Text('Cancel'),
              ),
              SizedBox(height: 30),
              InkWell(
                onTap: () {},
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                      color: Colors.grey, decoration: TextDecoration.underline),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: _showChangePasswordDialog,
                child: Text(
                  'Change Password',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
