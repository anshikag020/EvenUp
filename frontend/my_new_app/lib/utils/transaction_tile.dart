import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/theme/app_colors.dart';

class FancyTransactionTile extends StatelessWidget {
  final String groupName;
  final String name;
  final double amount;
  final bool type; 
  final String timestamp; 

  const FancyTransactionTile({
    super.key,
    required this.groupName,
    required this.name,
    required this.amount,
    required this.type, 
    required this.timestamp
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: Theme.of(context).brightness ==  Brightness.dark ? AppColors.tileGradDark : AppColors.tileGradLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Group: ",
                  style: GoogleFonts.poppins(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight, fontSize: 16),
                ),
                Text(
                  groupName,
                  style: GoogleFonts.poppins(
                    color:  Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Top Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (type == false) ?  
                  "Paid by:": "Paid to:" , 
                  style: GoogleFonts.poppins(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight, fontSize: 16),
                ),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: (type == false) ? Color(0xFFCBFF41) : const Color.fromARGB(255, 239, 99, 89),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(
            height: 1,
            color: Colors.white24,
            thickness: 1,
            indent: 12,
            endIndent: 12,
          ),

          // Bottom Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Amount:",
                  style: GoogleFonts.poppins(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight, fontSize: 16),
                ),
                Text(
                  "₹ $amount",
                  style: GoogleFonts.poppins(
                    color: (type == false ) ? Color(0xFFCBFF41) : const Color.fromARGB(255, 239, 99, 89),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Timestamp:",
                  style: GoogleFonts.poppins(color: Theme.of(context).brightness ==  Brightness.dark ? const Color.fromARGB(173, 255, 255, 255) : AppColors.textLight, fontSize: 16),
                ),
                Text(
                  timestamp,
                   style: GoogleFonts.poppins(color: Theme.of(context).brightness ==  Brightness.dark ? const Color.fromARGB(173, 255, 255, 255) : AppColors.textLight, fontSize: 16),
                  ),
                
              ],
            ),
          ),
          
        ],
      ),
    );
  }
}
