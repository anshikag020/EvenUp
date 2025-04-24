import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildLabel(String text, Color color) => Align(
  alignment: Alignment.centerLeft,
  child: Text(
    text,
    style: GoogleFonts.poppins(color: color, fontSize: 14),
  ),
);

Widget buildInputField(TextEditingController controller, Color color) {
  return TextField(
    controller: controller,
    style: TextStyle(color: color),
    decoration: InputDecoration(
      fillColor: Colors.black26,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

Widget buildActionButton(String text,Gradient gradient, VoidCallback onPressed) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.zero,
      fixedSize: const Size(100, 38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    child: Ink(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
}

