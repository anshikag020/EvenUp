import 'package:my_new_app/models/pinged_section_model.dart';

abstract class PingedSectionService {
  Future<List<PingedSectionModel>> fetchTransactions();
}
