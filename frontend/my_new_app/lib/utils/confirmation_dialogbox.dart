import 'package:flutter/material.dart';

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
      backgroundColor: const Color.fromARGB(255, 27, 27, 27),
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
                style: TextStyle(fontSize: 18, color: Colors.white),
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
                                    gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color.fromRGBO(208, 227, 64, 1), Color.fromRGBO(28, 54, 6, 1)],
                                  ),
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
                        gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color.fromRGBO(255, 71, 139, 1), Color.fromRGBO(58, 11, 30, 1)],
                                      ),
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
