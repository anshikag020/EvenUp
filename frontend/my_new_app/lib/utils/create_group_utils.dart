import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/theme/app_colors.dart';

Widget buildLabel(String text, BuildContext context) => Align(
  alignment: Alignment.centerLeft,
  child: Text(
    text,
    style: GoogleFonts.poppins(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight, fontSize: 14),
  ),
);

Widget buildInputField(TextEditingController controller, BuildContext context) {
  return TextField(
    controller: controller,
    style: TextStyle(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
    decoration: InputDecoration(
      fillColor: Colors.black26,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

Widget buildDescriptionField(TextEditingController controller, BuildContext context) {
  return TextField(
    controller: controller,
    maxLines: 4,
    style: TextStyle(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
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
  required BuildContext context
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
      activeColor: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight,
      title: Text(value, style: GoogleFonts.poppins(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight,)),
    ),
  );
}

Widget buildActionButton( double width, String text, Gradient gradient, VoidCallback onPressed) {
  
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.zero,
      fixedSize: Size(width*0.25, width*0.1),
      // fixedSize: Size(100, 38),
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
