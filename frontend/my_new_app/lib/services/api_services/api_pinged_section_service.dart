import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_new_app/models/pinged_section_model.dart';
import 'package:my_new_app/services/service%20interfaces/pinged_section_service_interface.dart';


class ApiPingedSectionService implements PingedSectionService {
  final String baseUrl;

  ApiPingedSectionService({required this.baseUrl});

  @override
  Future<List<PingedSectionModel>> fetchTransactions() async {
    final response = await http.get(Uri.parse('$baseUrl/transactions'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) => PingedSectionModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch transactions');
    }
  }
}
