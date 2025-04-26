import 'package:flutter/material.dart';
import 'package:my_new_app/splash_screen.dart';
import 'package:my_new_app/theme/theme.dart';
import 'package:my_new_app/theme/theme_service.dart';
import 'package:provider/provider.dart';
import 'locator.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator(useMock: true);

  final themeService = ThemeService();
  await themeService.loadTheme();

  runApp(
    ChangeNotifierProvider.value(
      value: themeService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AnimatedSplashScreenWidget(),
    );
  }
}
