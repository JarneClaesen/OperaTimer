// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:orchestra_timer/providers/timer_provider.dart';
import 'package:orchestra_timer/providers/brightness_provider.dart';
import 'package:orchestra_timer/screens/home_screen.dart';
import 'package:orchestra_timer/screens/timer_screen.dart';
import 'package:orchestra_timer/services/background_service.dart';
import 'package:orchestra_timer/services/notification_service.dart';
import 'package:orchestra_timer/widgets/screen_with_floating_timer.dart';
import 'package:provider/provider.dart';
import 'package:orchestra_timer/widgets/shake_detector.dart';
import 'package:orchestra_timer/widgets/floating_timer.dart';

import '../services/background_service.dart' as bg_service;
import '../services/background_timer_service.dart' as bg_timer_service;


import 'models/opera.dart';
import 'models/setlist.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(OperaAdapter());
  Hive.registerAdapter(SetlistAdapter());
  await Hive.openBox<Opera>('operas');

  // Initialize background service
  await bg_service.BackgroundNotificationService.initialize();
  await bg_timer_service.BackgroundTimerService.initialize();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TimerProvider()),
        ChangeNotifierProvider(create: (context) => BrightnessProvider()),
      ],
      child: Consumer<BrightnessProvider>(
        builder: (context, brightnessProvider, child) {
          return MaterialApp(
            title: 'Orchestra Timer',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
            ),
            darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                    seedColor: Color(0xFF800020), //Burgundy
                    brightness: Brightness.dark
                )
            ),
            themeMode: ThemeMode.dark,
            home: ScreenWithFloatingTimer(
              child: HomeScreen(),
            ),
            builder: (context, child) {
              return Stack(
                children: [
                  child!,
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Container(
                        color: Colors.black.withOpacity(1 - brightnessProvider.brightness),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
