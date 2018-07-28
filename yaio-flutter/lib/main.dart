import 'package:flutter/material.dart';
import 'drawer.dart';
import 'login.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Yaio',
      theme: new ThemeData(
        fontFamily: 'Raleway',
        primaryColor: Colors.blue[800],
        // brightness: Brightness.dark,
        accentColor: Colors.blueAccent[600],
        //toggleableActiveColor: Colors.deepPurple[200],
        // buttonColor: Colors.amber[200],
        buttonTheme: const ButtonThemeData(
          // textTheme: ButtonTextTheme.accent,
        ),
      ),
      home: new Login(title: 'Login'),
      routes: menuRoutes,
    );
  }
}

void main() {
  print('app start');
  DateTime now = new DateTime.now();
  Duration off = now.timeZoneOffset;
  print('$now');
  print('${off.inHours}');
  runApp(new MyApp());
}
