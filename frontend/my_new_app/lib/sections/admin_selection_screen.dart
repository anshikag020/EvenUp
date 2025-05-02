import 'package:flutter/material.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/models/exit_group_models.dart';
import 'package:my_new_app/sections/main_page.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';


class AdminSelectionScreen extends StatelessWidget {
  final List<Member> members;
  final String groupId;

  const AdminSelectionScreen({
    super.key,
    required this.members,
    required this.groupId,
  });

  void _handleAdminSelection(BuildContext context, String newAdmin) async {
    final GroupUserPanelService service = locator<GroupUserPanelService>();

    try {
      final response = await service.selectAnotherAdmin(groupId, newAdmin);

      if (response.status) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainPage(initialIndex: 1,),
          ),
        );

        // Navigator.popUntil(context, (route) => route.isFirst); // Exit all
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        primaryColor: Colors.tealAccent,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.grey[800],
          contentTextStyle: const TextStyle(color: Colors.white),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select New Admin'),
          backgroundColor: Colors.grey[900],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  member.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  member.username,
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: ElevatedButton(
                  onPressed: () => _handleAdminSelection(context, member.username),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent[700],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Make Admin"),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
