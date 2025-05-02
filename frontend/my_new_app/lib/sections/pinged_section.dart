import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/models/pinged_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/pinged_section_service_interface.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/pinged_section_utils.dart';

class PingedScreen extends StatefulWidget {
  const PingedScreen({super.key});

  @override
  State<PingedScreen> createState() => _PingedScreenState();
}

class _PingedScreenState extends State<PingedScreen> {
  late final PingedSectionService _pingedservice;
  final TextEditingController _searchController = TextEditingController();

  List<PingedSectionModel> _allPings = [];
  List<PingedSectionModel> _filteredPings = [];

  @override
  void initState() {
    super.initState();
    _pingedservice = locator<PingedSectionService>();
    _fetchTransactions();
    _searchController.addListener(_filterPings);
  }

  Future<void> _fetchTransactions() async {
    final data = await _pingedservice.fetchTransactions();
    setState(() {
      _allPings = data;
      _filteredPings = data;
    });
  }

  void _filterPings() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPings = _allPings
          .where((ping) => ping.otherMember.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness ==  Brightness.dark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 20),
          child: Text(
            'Pinged',
            style: GoogleFonts.poppins(
              color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight,
              fontSize: 35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: TextStyle(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
              decoration: InputDecoration(
                hintText: 'Search by username...',
                hintStyle: TextStyle(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark2 : AppColors.textLight),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark2 : AppColors.textLight),
                filled: true,
                fillColor: Theme.of(context).brightness ==  Brightness.dark ? AppColors.searchBoxDark : AppColors.searchBoxLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredPings.isNotEmpty
                  ? ListView.builder(
                      itemCount: _filteredPings.length + 1,
                      itemBuilder: (context, index) {
                        if (index < _filteredPings.length) {
                          final ping = _filteredPings[index];
                          return PingCard(
                            transacID: ping.transacID,
                            otherMember: ping.otherMember,
                            amount: ping.amount,
                            isSender: ping.isSender,
                            groupName: ping.groupName,
                            onAccept: () async {
                              // handle accept
                              final HandlePingedSectionService service = locator<HandlePingedSectionService>(); 
                              final success = await service.acceptPingedTransaction(ping.transacID);
                              if( !success )
                              {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Transaction acceptance failed'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              else
                              {
                                _fetchTransactions(); 
                              }

                            },
                            onReject: () async {
                              // handle reject

                              final HandlePingedSectionService service = locator<HandlePingedSectionService>(); 
                              final success = await service.rejectPingedTransaction(ping.transacID);
                              if( !success )
                              {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Transaction rejection failed'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              else
                              {
                                _fetchTransactions(); 
                              }
                            },
                          );
                        } else {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Text(
                                'No more pinged transactions',
                                style: TextStyle(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark2 : AppColors.textLight),
                              ),
                            ),
                          );
                        }
                      },
                    )
                  : Center(
                      child: Text(
                        "No matching results",
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark2 : AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
