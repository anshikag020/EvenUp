import 'package:flutter/material.dart';
import 'package:my_new_app/theme/app_colors.dart';

class ConfirmationDialog extends StatelessWidget {
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  ConfirmationDialog({
    required this.message,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width; 
    return Dialog(
      // backgroundColor: const Color(0xFF1B1B1B),
      backgroundColor:   Theme.of(context).brightness ==  Brightness.dark ? Color(0XFF1B1B1B) : AppColors.box2Light,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  
                  ElevatedButton(
                    onPressed: () {
                                    Navigator.of(context).pop(); // Close dialog
                                    onConfirm();
                                  },
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
                                    gradient:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.greenButtondarktheme : AppColors.greenButtonwhitetheme,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Confirm",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     Navigator.of(context).pop(); // Close dialog
                  //     onCancel();
                  //   },
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.grey[400],
                  //   ),
                  //   child: const Text('Cancel'),
                  // ),
                  ElevatedButton(
                    onPressed: () {
                                    Navigator.of(context).pop(); // Close dialog
                                    onCancel();
                                  },
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
                        gradient:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.redbuttondarktheme : AppColors.redbuttonwhitetheme,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Cancel",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
