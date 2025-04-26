import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/models/groups_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/theme/app_colors.dart';
import 'package:my_new_app/utils/groups_utils.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final TextEditingController _searchController = TextEditingController();

  late final GroupService _groupService;
  List<GroupModel> allGroups = [];
  List<GroupModel> filteredGroups = [];

  @override
  void initState() {
    super.initState();
    _groupService = locator<GroupService>();
    _loadGroups();
    _searchController.addListener(_filterGroups);
  }

  Future<void> _loadGroups() async {
    final groups = await _groupService.fetchGroups(context);
    setState(() {
      allGroups = groups;
      filteredGroups = groups;
    });
  }

  void _filterGroups() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredGroups = allGroups
          .where((group) => group.name.toLowerCase().contains(query))
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
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "Groups",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.textDark: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight),
                decoration: InputDecoration(
                  hintText: 'Search groups...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  // fillColor: const Color(0xFF1E1E1E),
                  fillColor: Theme.of(context).brightness ==  Brightness.dark ? AppColors.searchBoxDark : const Color.fromARGB(255, 179, 179, 179),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: filteredGroups.isEmpty
                  ? Center(
                      child: Text(
                        "No groups found.",
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredGroups.length + 1,
                      itemBuilder: (context, index) {
                        if (index < filteredGroups.length) {
                          final group = filteredGroups[index];
                          return GroupTile(
                            groupID: group.groupID,
                            name: group.name,
                            size: group.size,
                            description: group.description,
                            inviteCode: group.inviteCode,
                            groupType: group.groupType,
                            gradient: Theme.of(context).brightness ==  Brightness.dark ? AppColors.groupBoxDark : AppColors.groupBoxLight,
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 20),
                            child: Center(
                              child: Text(
                                "You don’t have any more groups.",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
