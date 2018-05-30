import 'package:flutter/material.dart';
import 'drawer.dart';
import 'device.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Yaio',
      theme: new ThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.amber[200],
        // buttonColor: Colors.amber[200],
        buttonTheme: const ButtonThemeData(
          textTheme: ButtonTextTheme.accent
        ),
      ),
      home: new Device(title: 'Device'),
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
