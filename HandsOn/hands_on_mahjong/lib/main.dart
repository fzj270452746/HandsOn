import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_menu_screen.dart';
import 'services/save_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await SaveService.instance.load();
  runApp(const HandsOnMahjongApp());
}

class HandsOnMahjongApp extends StatelessWidget {
  const HandsOnMahjongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hands On Mahjong',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.targetHint,
          surface: AppColors.tableTop,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}
