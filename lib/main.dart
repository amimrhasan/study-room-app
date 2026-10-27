import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/app_config.dart';
import 'screens/study_room_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Style the system status bar & navigation bar to match Study Room theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppConfig.primaryGreen,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppConfig.darkBg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const StudyRoomApp());
}

class StudyRoomApp extends StatelessWidget {
  const StudyRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppConfig.primaryGreen,
        scaffoldBackgroundColor: AppConfig.lightBg,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: AppConfig.primaryGreen,
        scaffoldBackgroundColor: AppConfig.darkBg,
      ),
      home: const StudyRoomScreen(),
    );
  }
}
