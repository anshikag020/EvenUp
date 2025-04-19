import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/utils/confirmation_dialogbox.dart';

class PingCard extends StatelessWidget {
  final String transacID;
  final String name;
  final int amount;
  final String groupName;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const PingCard({
    Key? key,
    required this.transacID, 
    required this.name,
    required this.amount,
    required this.groupName,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
        // padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                'Group: $groupName',
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(255, 151, 151, 151),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  amount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: width * 0.25,
                  height: width * 0.1,
                  child: Material(
                    borderRadius: BorderRadius.circular(30),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromRGBO(208, 227, 64, 1),
                            Color.fromRGBO(28, 54, 6, 1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => ConfirmationDialog(
                                  message:
                                      'Are you sure you want to accept this transaction?',
                                  onConfirm: () {
                                    // Navigator.pop(context); // Close the dialog
                                    // ✅ Place your group creation logic here
                                    onAccept();
                                  },
                                  onCancel: () {
                                    // Just close the dialog
                                  },
                                ),
                          );
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Center(
                          child: Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.038,
                              // fontSize: 18
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: width * 0.25,
                  height: width * 0.1,
                  child: Material(
                    borderRadius: BorderRadius.circular(30),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromRGBO(255, 71, 139, 1),
                            Color.fromRGBO(58, 11, 30, 1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => ConfirmationDialog(
                                  message:
                                      'Are you sure you want to reject this transaction?',
                                  onConfirm: () {
                                    onReject;
                                  },
                                  onCancel: () {
                                    // handle this
                                  },
                                ),
                          );
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Center(
                          child: Text(
                            'Reject',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.038,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
