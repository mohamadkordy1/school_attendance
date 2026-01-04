import 'package:flutter/material.dart';
import 'LoginPage.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'weak 6',
      debugShowCheckedModeBanner: false,
      home: LoginPage(),

    );
  }
}
