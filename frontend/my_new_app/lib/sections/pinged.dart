import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/utils/pinged_section_utils.dart';

class PingedScreen extends StatefulWidget {
  @override
  State<PingedScreen> createState() => _PingedScreenState();
}

class _PingedScreenState extends State<PingedScreen> {
  final List<Map<String, dynamic>> pings = [
    {"name": "Yash", "amount": 1000},
    {"name": "Anshika", "amount": 500},
    {"name": "Anirudh", "amount": 750},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
        elevation: 0,
        centerTitle: true,
        title: Padding(
          padding: EdgeInsets.only(top: 40, bottom: 20) , 
          child: Text(
                    'Pinged',
                    style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 35,
                                    fontWeight: FontWeight.w600,
                                  ),
                  ),
        )
      ),
      body: ListView.builder(
        itemCount: pings.length + 1, // +1 for the footer
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, index) {
          if (index < pings.length) {
            final ping = pings[index];
            return PingCard(
              name: ping['name'],
              amount: ping['amount'],
              groupName: 'Team Meet',
              onAccept: () {
                // handle accept
              },
              onReject: () {
                // handle reject
              },
            );
          } else {
            // Last item: footer message
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No more pinged transactions',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
