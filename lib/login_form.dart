import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'captcha_widget.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  String _applicationNumber = '';
  String _captchaResponse = '';
  bool _isLoading = false;

  void _onCaptchaCompleted(String response) {
    setState(() {
      _captchaResponse = response;
    });
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      if (_captchaResponse.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please complete the CAPTCHA')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Backend verification
      final response = await http.post(
        Uri.parse('http://localhost:8080/verify_login'),
        body: json.encode({
          'application_number': _applicationNumber,
          'captcha_response': _captchaResponse,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      setState(() {
        _isLoading = false;
      });

      final responseBody = json.decode(response.body);
      if (responseBody['success']) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('application_number', _applicationNumber);
        prefs.setString('name', responseBody['name']);
        prefs.setString('login_time', responseBody['login_time']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseBody['message'])),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Form'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Application Number'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your application number';
                  }
                  return null;
                },
                onSaved: (value) {
                  _applicationNumber = value ?? '';
                },
              ),
              CaptchaWidget(onCaptchaCompleted: _onCaptchaCompleted),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Login'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
