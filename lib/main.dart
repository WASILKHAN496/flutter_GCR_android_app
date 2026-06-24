import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:best_flutter_ui_templates/splash_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const StudentClassroomApp());
}

class StudentClassroomApp extends StatelessWidget {
  const StudentClassroomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (BuildContext context, ThemeMode currentThemeMode, Widget? child) {
        final bool isDarkMode = currentThemeMode == ThemeMode.dark;

        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
            statusBarBrightness:
            isDarkMode ? Brightness.dark : Brightness.light,
            systemNavigationBarColor:
            isDarkMode ? AppTheme.nearlyBlack : Colors.white,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
          ),
        );

        return MaterialApp(
          title: 'Student Classroom App',
          debugShowCheckedModeBanner: false,
          themeMode: currentThemeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: AppTheme.white,
            textTheme: AppTheme.textTheme,
            platform: TargetPlatform.iOS,
            dividerTheme: const DividerThemeData(
              color: Color(0xFFE0E0E0),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: AppTheme.nearlyBlack,
            textTheme: AppTheme.textTheme,
            platform: TargetPlatform.iOS,
            dividerTheme: DividerThemeData(
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          home: SplashScreen(),
        );
      },
    );
  }
}
class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return int.parse(hexColor, radix: 16);
  }
}