import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Channel identity is shared by show/schedule and the explicit channel
  // creation below so they always refer to the same Android channel.
  static const String _alertChannelId = 'opera_timer_alert_channel';
  static const String _alertChannelName = 'Opera Timer Notifications';
  // Reserved id for the throwaway priming notification (see primeAlertChannel).
  static const int _primeNotificationId = 987654;

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('ic_stat_opera');
    final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        // Handle notification tapped logic here
      },
    );

    // Create the alert channel up front. If we let Android create it lazily on
    // the first show(), that first notification both creates the channel and
    // posts in one go, and its importance isn't applied in time: the first
    // alert only buzzes faintly, never reaches the drawer, and isn't bridged to
    // paired wearables. Pre-creating the channel with max importance fixes that.
    const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
      _alertChannelId,
      _alertChannelName,
      importance: Importance.max,
    );
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alertChannel);
  }

  Future<void> showNotification(String title, String body, {int id = 0}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      _alertChannelId,
      _alertChannelName,
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_stat_opera',
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledDate) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannelId,
          _alertChannelName,
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_opera',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Warms up the alert channel's alerting for the current isolate.
  ///
  /// On many Android builds the FIRST notification a freshly-started process or
  /// isolate posts to a channel is delivered without alerting (no vibration, no
  /// heads-up, no wearable buzz), and only subsequent ones vibrate. Because the
  /// foreground-service isolate is recreated every time the timer starts, the
  /// first warning/play-time alert of each run was the casualty.
  ///
  /// Posting one `silent` notification (which suppresses vibration/sound for
  /// that single post regardless of the channel) and immediately cancelling it
  /// makes that throwaway the isolate's first post, so the first *real* alert is
  /// no longer first and alerts normally.
  Future<void> primeAlertChannel() async {
    const AndroidNotificationDetails android = AndroidNotificationDetails(
      _alertChannelId,
      _alertChannelName,
      importance: Importance.min,
      priority: Priority.min,
      silent: true,
      icon: 'ic_stat_opera',
    );
    const NotificationDetails details = NotificationDetails(android: android);
    await _flutterLocalNotificationsPlugin.show(
      id: _primeNotificationId,
      title: null,
      body: null,
      notificationDetails: details,
    );
    await _flutterLocalNotificationsPlugin.cancel(id: _primeNotificationId);
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
