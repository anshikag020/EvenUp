import 'package:flutter/material.dart';
import 'package:my_new_app/sections/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void redirectToLoginPage(BuildContext context) {
  // First, show the SnackBar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Session expired. Please login again.'),
      duration: Duration(seconds: 2), // Show for 2 seconds
    ),
  );

  // Then, after a small delay (so the user can see the message), navigate to login
  Future.delayed(Duration(seconds: 1), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwtToken');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(),
        ),
      );
  });
}