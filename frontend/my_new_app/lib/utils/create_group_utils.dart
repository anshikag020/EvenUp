import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildLabel(String text) => Align(
  alignment: Alignment.centerLeft,
  child: Text(
    text,
    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
  ),
);

Widget buildInputField(TextEditingController controller) {
  return TextField(
    controller: controller,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      fillColor: Colors.black26,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

Widget buildDescriptionField(TextEditingController controller) {
  return TextField(
    controller: controller,
    maxLines: 4,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      fillColor: Colors.black26,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

Widget buildRadio({
  required String value,
  required String groupValue,
  required void Function(String) onChanged,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black26,
      borderRadius: BorderRadius.circular(12),
    ),
    child: RadioListTile<String>(
      value: value,
      groupValue: groupValue,
      onChanged: (val) => onChanged(val!),
      activeColor: Colors.white,
      title: Text(value, style: GoogleFonts.poppins(color: Colors.white)),
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
