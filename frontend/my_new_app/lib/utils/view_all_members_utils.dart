import 'package:flutter/material.dart';
import 'package:my_new_app/locator.dart';
import 'package:my_new_app/models/groups_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/theme/app_colors.dart';
// import 'package:my_new_app/services/service_interfaces/groups_section_service_interface.dart';

class GroupUtils {
  static void showGroupMembersDialog({
    required BuildContext context,
    required String groupId,
  }) async {
    final memberService = locator<GroupMemberService>();
    final List<GroupMemberModel> members = await memberService.fetchMembersForGroup(groupId);

    final ScrollController scrollController = ScrollController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.searchBoxDark : AppColors.searchBoxLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 400, // 👈 bounds the height properly
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "All Group Members",
                  style: TextStyle(
                    fontSize: 20,
                    color:  Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Divider(
                  color:   Theme.of(context).brightness ==  Brightness.dark ? Colors.white24 : AppColors.textLight,
                  thickness: 1,
                  height: 20,
                ),
                Flexible( // 👈 Use Flexible to allow ListView to take available space
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: scrollController,
                    trackVisibility: true,
                    radius: const Radius.circular(10),
                    thickness: 4,
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: members.length,
                      itemBuilder: (_, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Row(
                            children: [
                              Icon(Icons.circle_outlined,
                                  color:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight , size: 16),
                              const SizedBox(width: 8),
                              Text(
                                members[index].name,
                                style: TextStyle(
                                  color:   Theme.of(context).brightness ==  Brightness.dark ? AppColors.textDark : AppColors.textLight,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
