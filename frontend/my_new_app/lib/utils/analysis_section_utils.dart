import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:my_new_app/theme/app_colors.dart';

class AnalysisWidgets {
  static final _font = GoogleFonts.poppins;

  static Widget buildMultiSelect({
    required BuildContext context,
    required String label,
    required List<String> items,
    required List<String> initialValue,
    required void Function(List<String>) onConfirm,
  }) {
    Color textcolor = Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _font(color: textcolor)),
        const SizedBox(height: 6),
        MultiSelectDialogField<String>(
          items: items.map((e) => MultiSelectItem<String>(e, e)).toList(),
          initialValue: initialValue,
          backgroundColor:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.box2Dark : AppColors.box2Light,
          title: Text(label, style: _font(color: textcolor)),
          selectedColor:   Theme.of(context).brightness ==  Brightness.dark ? Colors.greenAccent : Color.fromARGB(255, 47, 160, 76),
          searchable: false,
          
          itemsTextStyle: _font(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
          selectedItemsTextStyle: _font(color:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight,),

          dialogHeight: MediaQuery.of(context).size.height * 0.5,
          buttonIcon: Icon(Icons.arrow_drop_down, color:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark: AppColors.textLight),
          buttonText: Text(
            initialValue.isEmpty
                ? "Select $label"
                : "${initialValue.length} ${label.split(" ").last.toLowerCase()} selected",
            style: _font(color:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark: AppColors.textLight),
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
    required BuildContext context
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _font(color:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.appBarColorDark : const Color.fromARGB(255, 161, 160, 160),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String>(
            dropdownColor:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.appBarColorDark : AppColors.appBarColorLight,
            isExpanded: true,
            value: value,
            icon: Icon(Icons.arrow_drop_down, color:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
            underline: const SizedBox(),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, style: TextStyle(color:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight)),
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
    required Color selectColor,
    required Color textcolor,    
  }) {
    return Row(
      children: [
        Radio<String>(
          value: title,
          groupValue: groupValue,
          // activeColor: Colors.greenAccent,
          activeColor: selectColor, 
          onChanged: (val) => onChanged(val!),
        ),
        Text(title, style: _font(color: textcolor)),
      ],
    );
  }
}
