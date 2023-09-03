class Config {
  static const String appName = "Tracker";
  static const String appIcon = "@mipmap/ic_launcher";
  static const String appColor = "#333333";
  // static const String appColor = "#ed1c24";
  static const String apiUrl = "20.212.201.208:3000";

  static const String loginRoute = "/auth/login";
  static const String userRoute = "/auth/user";

  // Distance checking frequency
  static const int distPeriod = 5;
  static const double distFilter = 0;

  // Update frequency of Values
  static const int updateFreq = 10;
  static const notificationId = 888;
  static const notificationChannelId = 'my_foreground';
  static const notificationChannelName = 'location_foreground';
  static const notificationChannelIdAlert = 'simple_alerts';
  static const notificationChannelNameAlert = 'simple_alerts';
}
