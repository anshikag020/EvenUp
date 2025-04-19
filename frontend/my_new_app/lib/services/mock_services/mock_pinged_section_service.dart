import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:my_new_app/models/pinged_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/pinged_section_service_interface.dart';


class MockPingedSectionService implements PingedSectionService {
  @override
  Future<List<PingedSectionModel>> fetchTransactions() async {
    final String response = await rootBundle.loadString('lib/data/pinged_section_data.json');
    final List<dynamic> data = jsonDecode(response);

    return data.map((json) => PingedSectionModel.fromJson(json)).toList();
  }
}
