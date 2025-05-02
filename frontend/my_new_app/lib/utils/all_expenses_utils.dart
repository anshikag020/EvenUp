import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/theme/app_colors.dart';

class ExpenseTile extends StatelessWidget {
  final String description;
  final double amount;
  final VoidCallback onTap;

  const ExpenseTile({
    super.key,
    required this.description,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(context).brightness ==  Brightness.dark ? AppColors.tileGradDark : AppColors.tileGradLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Expense Description:",
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).brightness ==  Brightness.dark ? Colors.white70 : AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Divider(
                color: Theme.of(context).brightness ==  Brightness.dark ? Colors.white24 : Colors.white,
                height: 1,
                thickness: 1,
                indent: 12,
                endIndent: 12,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Amount:",
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "₹ $amount",
                      style: GoogleFonts.poppins(
                        color: Color(0xFFCBFF41),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
