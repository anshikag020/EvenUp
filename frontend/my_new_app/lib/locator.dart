import 'package:get_it/get_it.dart';
import 'package:my_new_app/services/api_services/api_groups_section_service.dart';
import 'package:my_new_app/services/api_services/api_transaction_history_service.dart';
import 'package:my_new_app/services/mock_services/mock_groups_section_service.dart';
import 'package:my_new_app/services/mock_services/mock_transactions_history_service.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/services/service%20interfaces/transaction_history_service_interface.dart';
final locator = GetIt.instance;


void setupLocator({bool useMock = true}) {
  locator.registerLazySingleton<TransactionService>(() =>
      useMock ? MockTransactionService() : ApiTransactionService(baseUrl: 'http://localhost:8080'));

  locator.registerLazySingleton<GroupService>(() =>
      useMock ? MockGroupService() : ApiGroupService(baseUrl: 'http://localhost:8080'));
}
