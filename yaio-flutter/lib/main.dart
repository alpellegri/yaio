import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'drawer.dart';
import 'login.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yaio',
      theme: new ThemeData(
        // fontFamily: 'Open_Sans',
        primarySwatch: Colors.indigo,
        ),
      home: new Login(title: 'Yaio'),
      routes: menuRoutes,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print('app start');
  DateTime now = new DateTime.now();
  Duration off = now.timeZoneOffset;
  print('$now');
  print('${off.inHours}');
  runApp(new MyApp());
}
