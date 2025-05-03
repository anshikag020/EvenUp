import 'package:get_it/get_it.dart';
import 'package:my_new_app/services/api_services/api_dashboard_section_service.dart';
import 'package:my_new_app/services/api_services/api_expenses_service.dart';
import 'package:my_new_app/services/api_services/api_friends_section.dart';
import 'package:my_new_app/services/api_services/api_groups_section_service.dart';
import 'package:my_new_app/services/api_services/api_login_section.dart';
import 'package:my_new_app/services/api_services/api_pinged_section_service.dart';
import 'package:my_new_app/services/api_services/api_transaction_history_service.dart';
import 'package:my_new_app/services/mock_services/mock_groups_section_service.dart';
import 'package:my_new_app/services/mock_services/mock_pinged_section_service.dart';
import 'package:my_new_app/services/mock_services/mock_transactions_history_service.dart';
import 'package:my_new_app/services/service%20interfaces/dashboard_section_service_interface.dart';
import 'package:my_new_app/services/service%20interfaces/expense_service_interface.dart';
import 'package:my_new_app/services/service%20interfaces/friends_section_api_interface_service.dart';
import 'package:my_new_app/services/service%20interfaces/groups_section_service_interface.dart';
import 'package:my_new_app/services/service%20interfaces/login_section_service_interface.dart';
import 'package:my_new_app/services/service%20interfaces/pinged_section_service_interface.dart';
import 'package:my_new_app/services/service%20interfaces/transaction_history_service_interface.dart';
final locator = GetIt.instance;
// final String backendUrl = 'http://localhost:8080'; 
final String backendUrl = 'http://172.21.130.87:8080'; 

void setupLocator({bool useMock = true}) {
  locator.registerLazySingleton<TransactionService>(() =>
      useMock ? MockTransactionService() : ApiTransactionService(baseUrl: backendUrl));

  locator.registerLazySingleton<GroupService>(() =>
      useMock ? MockGroupService() : ApiGroupService(baseUrl: backendUrl));
  
  locator.registerLazySingleton<GroupMemberService>(() =>
      useMock ? MockGroupMemberService() : ApiGroupMemberService(baseUrl: backendUrl));

  locator.registerLazySingleton<ExpenseService>(
    () => useMock ? MockExpenseService() : ApiExpenseService(baseUrl: backendUrl),
  );

  locator.registerLazySingleton<DetailedExpenseService>(
    () => useMock ? MockDetailedExpenseService() : ApiDetailedExpenseService(baseUrl: backendUrl),
  );

  locator.registerLazySingleton<BalanceService>(
    () => useMock
        ? MockBalanceService()
        : ApiBalanceService(baseUrl: backendUrl),
  );

  locator.registerLazySingleton<PingedSectionService>(() =>
      useMock ? MockPingedSectionService() : PingedSectionServiceImpl(baseUrl: backendUrl));



  locator.registerLazySingleton<AuthService>(
  () => ApiAuthService(baseUrl: backendUrl),
  );

  locator.registerLazySingleton<CreateGroupService>(
  () => CreateGroupServiceImpl(backendUrl),
  );
  
  locator.registerLazySingleton<CreatePrivateSplitService>(
  () => CreatePrivateSplitServiceImpl(backendUrl),
  );

  locator.registerLazySingleton<JoinGroupService>(
  () => JoinGroupImpl(backendUrl),
  );

  locator.registerLazySingleton<AddExpenseService>(
  () => AddExpenseServiceImpl(backendUrl),
  );
  
  locator.registerLazySingleton<SettleService>(
  () => BalanceSettleServiceImpl(backendUrl),
  );

  locator.registerLazySingleton<HandlePingedSectionService>(
  () => HandlePingedSectionImpl(baseUrl: backendUrl),
  );

  locator.registerLazySingleton<GroupUserPanelService>(
  () => GroupUserPanelImpl(baseUrl: backendUrl),
  );

  locator.registerLazySingleton<ConfirmOTS>(
  () => ConfirmOTSImpl(baseUrl: backendUrl),
  );

  locator.registerLazySingleton<ResetPasswordFlowService>(
  () => ResetPasswordFlowImpl(backendUrl),
  );

  locator.registerLazySingleton<FriendsService>(
  () => ApiFriendsService( baseUrl: backendUrl),
  );

  locator.registerLazySingleton<AnalysisService>(
  () => ApiAnalysisService( baseUrl: backendUrl),
  );

}
