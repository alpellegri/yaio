import 'package:flutter/material.dart';
import 'drawer.dart';
import 'home.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'uHome',
      theme: new ThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.amber[200],
      ),
      home: new MyHomePage(title: 'uHome'),
      routes: menuRoutes,
    );
  }
}

void main() {
  runApp(new MyApp());
}
