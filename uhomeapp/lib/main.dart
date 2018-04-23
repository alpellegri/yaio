import 'package:flutter/material.dart';
import 'drawer.dart';
import 'device.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'uHome',
      theme: new ThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.amber[200],
      ),
      home: new Device(title: 'Device'),
      routes: menuRoutes,
    );
  }
}

void main() {
  runApp(new MyApp());
}
