import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _applicationNumber = '';
  String _name = '';
  String _loginTime = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _applicationNumber = prefs.getString('application_number') ?? '';
      _name = prefs.getString('name') ?? '';
      _loginTime = prefs.getString('login_time') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Application Number: $_applicationNumber'),
            Text('Name: $_name'),
            Text('Login Time: $_loginTime'),
          ],
        ),
      ),
    );
  }
}
