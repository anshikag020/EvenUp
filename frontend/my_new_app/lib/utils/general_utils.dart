import 'package:flutter/material.dart';

void showCustomSnackBar(BuildContext context , String message, {Color backgroundColor = Colors.blue}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: backgroundColor),
  );
}
