import 'package:flutter/material.dart';

void showCustomSnackBar(BuildContext context , String message, {Color backgroundColor = Colors.blue}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message, style: TextStyle(color: Colors.white),), backgroundColor: backgroundColor),
  );
}

void showOverlayNotification(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromARGB(255, 195, 56, 56).withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            message,
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}
