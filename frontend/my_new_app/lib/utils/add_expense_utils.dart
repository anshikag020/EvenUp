import 'package:flutter/material.dart';
import 'package:my_new_app/models/groups_section_model.dart';

class PaidByDialog extends StatefulWidget {
  final List<GroupMemberModel> members;

  PaidByDialog({required this.members});

  @override
  _PaidByDialogState createState() => _PaidByDialogState();
}

class _PaidByDialogState extends State<PaidByDialog> {
  Map<String, TextEditingController> controllers = {};
  List<GroupMemberModel> filteredMembers = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredMembers = widget.members;
    for (var member in widget.members) {
      controllers[member.name] = TextEditingController();
    }
    searchController.addListener(_filterMembers);
  }

  void _filterMembers() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredMembers =
          widget.members
              .where((member) => member.name.toLowerCase().contains(query))
              .toList();
    });
  }

  void _confirmSelection() {
    Map<String, double> result = {};
    controllers.forEach((key, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        final amount = double.tryParse(text);
        if (amount != null && amount > 0) {
          result[key] = amount;
        }
      }
    });
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width; 

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Members Who Paid',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelStyle: TextStyle(color: const Color.fromARGB(255, 144, 144, 144)),
                labelText: 'Search Members',
                prefixIcon: Icon(Icons.search, color: const Color.fromARGB(255, 144, 144, 144),),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: filteredMembers.length,
                itemBuilder: (context, index) {
                  final member = filteredMembers[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          height: 40,
                          child: TextField(
                            controller: controllers[member.name],
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Amount',
                              hintStyle: TextStyle(color: Colors.white38),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    fixedSize: Size(width*0.25, width*0.1),
                    // fixedSize: Size(100, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: _confirmSelection,
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
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Confirm',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    fixedSize: Size(width*0.25, width*0.1),
                    // fixedSize: Size(100, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
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
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Cancel',
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
    );
  }
}









class SplitBetweenDialog extends StatefulWidget {
  final List<GroupMemberModel> members;
  final List<String> selectedMembers;

  SplitBetweenDialog({required this.members, required this.selectedMembers});

  @override
  _SplitBetweenDialogState createState() => _SplitBetweenDialogState();
}

class _SplitBetweenDialogState extends State<SplitBetweenDialog> {
  late List<String> selected;
  late List<GroupMemberModel> filteredMembers;
  TextEditingController searchController = TextEditingController();
  late ScrollController _scrollController; 

  @override
  void initState() {
    super.initState();
    selected = List.from(widget.selectedMembers);
    filteredMembers = widget.members;
    searchController.addListener(_filterMembers);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  void _filterMembers() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredMembers = widget.members
          .where((member) => member.name.toLowerCase().contains(query))
          .toList();
    });
  }

  void _confirmSelection() {
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Members to Split Between',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search Members',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                radius: Radius.circular(10),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
                    return CheckboxListTile(
                      title: Text(
                        member.name,
                        style: TextStyle(color: Colors.white),
                      ),
                      activeColor: Colors.green,
                      checkColor: Colors.black,
                      value: selected.contains(member.name),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selected.add(member.name);
                          } else {
                            selected.remove(member.name);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    fixedSize: Size(width * 0.25, width * 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
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
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Cancel',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    fixedSize: Size(width * 0.25, width * 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: _confirmSelection,
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
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Confirm',
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
    );
  }
}






class SplitTypeDialog extends StatefulWidget {
  final List<GroupMemberModel> members;
  final List<String> selectedMembers;
  final double totalAmount;
  final String? initialSplitType;
  final Map<String, double>? initialSplitDetails;
  
  SplitTypeDialog({
  required this.members,
  required this.selectedMembers,
  required this.totalAmount,
  this.initialSplitType,
  this.initialSplitDetails,
});

  @override
  _SplitTypeDialogState createState() => _SplitTypeDialogState();
}

class _SplitTypeDialogState extends State<SplitTypeDialog> {
  String splitType = 'Evenly';
  Map<String, TextEditingController> controllers = {};
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    splitType = widget.initialSplitType ?? 'Evenly';

    for (var name in widget.selectedMembers) {
      controllers[name] = TextEditingController();
      if (widget.initialSplitDetails != null && widget.initialSplitDetails!.containsKey(name)) {
        controllers[name]!.text = widget.initialSplitType == 'By Percentage'
            ? widget.initialSplitDetails![name]!.toStringAsFixed(0)
            : widget.initialSplitDetails![name]!.toStringAsFixed(2);
      }
    }

    if (splitType == 'Evenly' && widget.initialSplitDetails == null) {
      _setEvenSplit();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setEvenSplit() {
    double perPerson = widget.totalAmount / widget.selectedMembers.length;
    for (var controller in controllers.values) {
      controller.text = perPerson.toStringAsFixed(2);
    }
  }

  void _clearControllers() {
    for (var controller in controllers.values) {
      controller.text = '';
    }
  }

  void _onTypeChange(String? value) {
    if (value == null) return;
    setState(() {
      splitType = value;
      if (splitType == 'Evenly') {
        _setEvenSplit();
      } else {
        _clearControllers();
      }
    });
  }

  void _confirmSplit() {
    Map<String, double> result = {};
    double total = 0.0;

    for (var entry in controllers.entries) {
      String text = entry.value.text.trim();
      if (text.isEmpty) {
        _showError('Please enter value for ${entry.key}');
        return;
      }

      double? value = double.tryParse(text);
      if (value == null || value < 0) {
        _showError('Invalid value for ${entry.key}');
        return;
      }

      result[entry.key] = value;
      total += value;
    }

    if (splitType == 'Evenly' || splitType == 'Unevenly') {
      if ((total - widget.totalAmount).abs() > 0.01) {
        _showError('The split total does not match the expense amount.');
        return;
      }
    } else if (splitType == 'By Percentage') {
      if ((total - 100).abs() > 0.01) {
        _showError('Total percentage must equal 100%.');
        return;
      }
      // Convert percentage to amounts
      result = result.map(
        (k, v) => MapEntry(
          k,
          double.parse(((v / 100) * widget.totalAmount).toStringAsFixed(2)),
        ),
      );
    }

    Navigator.of(context).pop({'type': splitType, 'details': result});
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Split Type',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: splitType,
              dropdownColor: Colors.black87,
              items: [
                DropdownMenuItem(value: 'Evenly', child: Text('Split Evenly')),
                DropdownMenuItem(value: 'Unevenly', child: Text('Split Unevenly')),
                DropdownMenuItem(value: 'By Percentage', child: Text('Split by Percentage')),
              ],
              onChanged: _onTypeChange,
              decoration: InputDecoration(
                labelText: 'Split Type',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: widget.selectedMembers.length,
                  itemBuilder: (context, index) {
                    final name = widget.selectedMembers[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: controllers[name],
                              enabled: splitType != 'Evenly',
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: splitType == 'By Percentage' ? '%' : '₹',
                                hintStyle: TextStyle(color: Colors.white38),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    fixedSize: Size(width*0.25, width*0.1),
                    // fixedSize: Size(100, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: _confirmSplit,
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
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Confirm',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    fixedSize: Size(width*0.25, width*0.1),
                    // fixedSize: Size(100, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
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
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Cancel',
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
    );
  }
}
