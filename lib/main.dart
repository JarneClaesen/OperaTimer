// lib/main.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:orchestra_timer/providers/theme_provider.dart';
import 'package:orchestra_timer/providers/timer_provider.dart';
import 'package:orchestra_timer/providers/brightness_provider.dart';
import 'package:orchestra_timer/screens/home_screen.dart';
import 'package:orchestra_timer/services/foreground_timer_service.dart';
import 'package:orchestra_timer/services/notification_service.dart';
import 'package:orchestra_timer/widgets/screen_with_floating_timer.dart';
import 'package:provider/provider.dart';

import 'models/opera.dart';
import 'models/setlist.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  await Hive.initFlutter();
  Hive.registerAdapter(OperaAdapter());
  Hive.registerAdapter(SetlistAdapter());
  await Hive.openBox<Opera>('operas');

  // Initialize foreground service
  await ForegroundTimerService.initialize();

  await ForegroundTimerService.requestPermissions();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MyApp());

  Timer.periodic(Duration(seconds: 1), (timer) {
    final timerProvider = Provider.of<TimerProvider>(navigatorKey.currentContext!, listen: false);
    timerProvider.updateTimer();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TimerProvider()),
        ChangeNotifierProvider(create: (context) => BrightnessProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer2<BrightnessProvider, ThemeProvider>(
        builder: (context, brightnessProvider, themeProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Orchestra Timer',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: themeProvider.currentColor),
            ),
            darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                    seedColor: themeProvider.currentColor, //Burgundy
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
