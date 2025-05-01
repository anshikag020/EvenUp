
import 'package:get_it/get_it.dart';
import 'package:my_new_app/services/api_services/api_dashboard_section_service.dart';
import 'package:my_new_app/services/api_services/api_expenses_service.dart';
import 'package:my_new_app/services/api_services/api_groups_section_service.dart';
import 'package:my_new_app/services/api_services/api_login_section.dart';
import 'package:my_new_app/services/api_services/api_pinged_section_service.dart';
import 'package:my_new_app/services/api_services/api_transaction_history_service.dart';
import 'package:my_new_app/services/mock_services/mock_groups_section_service.dart';
import 'package:my_new_app/services/mock_services/mock_pinged_section_service.dart';
import 'package:my_new_app/services/mock_services/mock_transactions_history_service.dart';
import 'package:my_new_app/services/service%20interfaces/dashboard_section_service_interface.dart';
import 'package:my_new_app/services/service%20interfaces/expense_service_interface.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/services/service%20interfaces/login_section_service_interface.dart';
import 'package:my_new_app/services/service%20interfaces/pinged_section_service_interface.dart';
import 'package:my_new_app/services/service%20interfaces/transaction_history_service_interface.dart';
final locator = GetIt.instance;


void setupLocator({bool useMock = true}) {
  locator.registerLazySingleton<TransactionService>(() =>
      useMock ? MockTransactionService() : ApiTransactionService(baseUrl: 'http://localhost:8080'));

  locator.registerLazySingleton<GroupService>(() =>
      useMock ? MockGroupService() : ApiGroupService(baseUrl: 'http://localhost:8080'));
  
  locator.registerLazySingleton<GroupMemberService>(() =>
      useMock ? MockGroupMemberService() : ApiGroupMemberService(baseUrl: 'http://localhost:8080'));

  locator.registerLazySingleton<ExpenseService>(
    () => useMock ? MockExpenseService() : ApiExpenseService(baseUrl: 'http://localhost:8080'),
  );

  locator.registerLazySingleton<DetailedExpenseService>(
    () => useMock ? MockDetailedExpenseService() : ApiDetailedExpenseService(baseUrl: 'http://localhost:8080'),
  );

  locator.registerLazySingleton<BalanceService>(
    () => useMock
        ? MockBalanceService()
        : ApiBalanceService(baseUrl: 'http://localhost:8080'),
  );

  locator.registerLazySingleton<PingedSectionService>(() =>
      useMock ? MockPingedSectionService() : ApiPingedSectionService(baseUrl: 'http://localhost:8080'));

  locator.registerLazySingleton<AuthService>(
  () => ApiAuthService(baseUrl: 'http://localhost:8080'),
  );

  locator.registerLazySingleton<CreateGroupService>(
  () => CreateGroupServiceImpl('http://localhost:8080'),
  );
  
  locator.registerLazySingleton<CreatePrivateSplitService>(
  () => CreatePrivateSplitServiceImpl('http://localhost:8080'),
  );

  locator.registerLazySingleton<JoinGroupService>(
  () => JoinGroupImpl('http://localhost:8080'),
  );

  locator.registerLazySingleton<AddExpenseService>(
  () => AddExpenseServiceImpl('http://localhost:8080'),
  );

 
}
