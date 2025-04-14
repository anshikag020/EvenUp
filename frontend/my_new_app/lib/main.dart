import 'package:flutter/material.dart';
import 'package:my_new_app/sections/main_page.dart';
import 'locator.dart';

void main() {
  setupLocator(useMock: true); // Flip to false when switching to live API
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainPage(),
    );
  }
}
