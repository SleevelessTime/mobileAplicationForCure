//import 'package:flutter/material.dart';
//import 'LoginSelectionPage.dart'; // LoginSelectionPage'i içe aktar
//
//void main() {
//  runApp(MyApp());
//}
//
//class MyApp extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      title: 'Login Selection',
//      theme: ThemeData(
//        primarySwatch: Colors.teal,
//        textTheme: TextTheme(
//          headlineSmall: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
//          bodyMedium: TextStyle(fontSize: 18),
//        ),
//      ),
//      home: LoginSelectionPage(),
//    );
//  }
//}



import 'package:flutter/material.dart';
import 'LoginPage.dart'; // Import the LoginPage

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginPage(), // Set LoginPage as the initial route
    );
  }
}
