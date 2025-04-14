import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 


Widget buildActionBox({
  required String label,
  required IconData icon,
  required LinearGradient gradient,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        height: 200,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white, fontSize: 23), ),
          ],
        ),
      ),
    ),
  );
}
