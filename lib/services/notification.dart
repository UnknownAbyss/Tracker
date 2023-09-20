import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:snippet_coder_utils/hex_color.dart';
import 'package:timezone/timezone.dart';
import 'package:tracker_app/config.dart';

class NotifService {
  static FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  static init() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await requestNotifPerm();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(Config.appIcon);
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    // onDidReceiveLocalNotification: onDidReceiveLocalNotification,

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin?.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  static onDidReceiveNotificationResponse(NotificationResponse notifResp) {
    String? payload = notifResp.payload;

    if (payload == null) {
      print("Error WIth Notification: $payload");
    }

    print(payload);
  }

  static displayNotif(String title, String text, bool ongo) async {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      Config.notificationChannelIdAlert,
      Config.notificationChannelNameAlert,
      channelDescription: 'Alert Notifications',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      ongoing: ongo,
      color: HexColor(Config.appColor),
    );

    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin?.show(
      0,
      title,
      text,
      notificationDetails,
      payload: 'item x',
    );
  }

  static schedNotif() async {
    flutterLocalNotificationsPlugin?.cancel(1);
    flutterLocalNotificationsPlugin?.cancel(2);

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      Config.notificationChannelIdAlert,
      Config.notificationChannelNameAlert,
      channelDescription: 'Alert Notifications',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      ongoing: false,
      color: HexColor(Config.appColor),
    );

    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin?.zonedSchedule(
      1,
      "Reminder",
      "Start your attendance!",
      nextInstanceOf9AM(),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'Test Payload',
    );
    await flutterLocalNotificationsPlugin?.zonedSchedule(
      2,
      "Reminder",
      "Submit your attendance!",
      nextInstanceOf7PM(),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'Test Payload',
    );
  }

  static killNotif(int id) async {
    await flutterLocalNotificationsPlugin?.cancel(id);
  }

  static Future<void> setupNotif() async {
    AndroidNotificationChannel androidNotificationChannel =
        const AndroidNotificationChannel(
      Config.notificationChannelId,
      Config.notificationChannelName,
      description: 'Foreground notification for Location Tracker',
      showBadge: true,
      importance: Importance.low,
      playSound: false,
      enableLights: false,
      enableVibration: false,
    );

    await flutterLocalNotificationsPlugin
        ?.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  static Future<bool> requestNotifPerm() async {
    bool? x = await flutterLocalNotificationsPlugin
        ?.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
    if (x != null) {
      return x;
    }
    print("Android Done");

    bool? y = await flutterLocalNotificationsPlugin
        ?.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    if (y != null) {
      return y;
    }
    print("IOS Done");

    return false;
  }

  static TZDateTime nextInstanceOf9AM() {
    var loc = getLocation('Asia/Kolkata');
    print("got 9AM day");
    final TZDateTime now = TZDateTime.now(loc);
    TZDateTime scheduledDate =
        TZDateTime(loc, now.year, now.month, now.day, 9, 0);
    if (scheduledDate.isBefore(now)) {
      print("Next day");
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static TZDateTime nextInstanceOf7PM() {
    var loc = getLocation('Asia/Kolkata');
    print("got 7PM day");
    final TZDateTime now = TZDateTime.now(loc);
    TZDateTime scheduledDate =
        TZDateTime(loc, now.year, now.month, now.day, 19, 0);
    if (scheduledDate.isBefore(now)) {
      print("Next day");
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
