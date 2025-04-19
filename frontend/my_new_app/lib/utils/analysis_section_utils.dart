import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class AnalysisWidgets {
  static final _font = GoogleFonts.poppins;

  static Widget buildMultiSelect({
    required BuildContext context,
    required String label,
    required List<String> items,
    required List<String> initialValue,
    required void Function(List<String>) onConfirm,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _font(color: Colors.white70)),
        const SizedBox(height: 6),
        MultiSelectDialogField<String>(
          items: items.map((e) => MultiSelectItem<String>(e, e)).toList(),
          initialValue: initialValue,
          backgroundColor: const Color(0xFF2C2C2C),
          title: Text(label, style: _font(color: Colors.white)),
          selectedColor: Colors.greenAccent,
          searchable: false,
          
          itemsTextStyle: _font(color: Colors.white),
          selectedItemsTextStyle: _font(color: Colors.white),

          dialogHeight: MediaQuery.of(context).size.height * 0.5,
          buttonIcon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          buttonText: Text(
            initialValue.isEmpty
                ? "Select $label"
                : "${initialValue.length} ${label.split(" ").last.toLowerCase()} selected",
            style: _font(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),

          chipDisplay: MultiSelectChipDisplay.none(),
          onConfirm: onConfirm,
        ),
      ],
    );
  }

  static Widget buildDropdown({
    required String label,
    required List<String> items,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _font(color: Colors.white70)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String>(
            dropdownColor: const Color(0xFF2C2C2C),
            isExpanded: true,
            value: value,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            underline: const SizedBox(),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, style: TextStyle(color: Colors.white)),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  static Widget buildRadio({
    required String title,
    required String groupValue,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        Radio<String>(
          value: title,
          groupValue: groupValue,
          activeColor: Colors.greenAccent,
          onChanged: (val) => onChanged(val!),
        ),
        Text(title, style: _font(color: Colors.white70)),
      ],
    );
  }
}
