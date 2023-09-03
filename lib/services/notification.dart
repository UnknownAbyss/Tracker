import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:snippet_coder_utils/hex_color.dart';
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
      1,
      title,
      text,
      notificationDetails,
      payload: 'item x',
    );
  }

  static killNotif() async {
    // cancel the notification with id value of zero
    List<ActiveNotification> x =
        await flutterLocalNotificationsPlugin!.getActiveNotifications();

    for (var i in x) {
      print("--------------");
      print(i.title);
      print(i.tag);
      print(i.payload);
      print(i.id);
      print(i.groupKey);
      print(i.channelId);
      print(i.body);
      print("--------------");
    }

    await flutterLocalNotificationsPlugin?.cancelAll();
    await flutterLocalNotificationsPlugin?.cancel(0);
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
}
