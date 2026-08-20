import 'package:flutter/material.dart';
import 'screens/HomeScreen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = ThemeController();
  await themeController.load();
  runApp(MyApp(themeController: themeController));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: themeController,
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Attendance',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.mode,
            themeAnimationDuration: const Duration(milliseconds: 320),
            themeAnimationCurve: Curves.easeInOutCubic,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
