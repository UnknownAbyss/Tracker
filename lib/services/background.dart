import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracker_app/config.dart';
import 'package:tracker_app/services/location.dart';

class BackgroundService {
  static late FlutterBackgroundService service;

  static void init() async {
    service = FlutterBackgroundService();

    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: LocationService.init,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: LocationService.init,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: Config.notificationChannelId,
        foregroundServiceNotificationId: Config.notificationId,
        initialNotificationTitle: "Location Service",
      ),
    );
  }

  static Future<bool> spawnLocIsolate(int starttime) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setInt("start", starttime);
    await pref.setBool("ongoing", true);
    await pref.remove("latest_loc");
    await pref.setDouble("dist", 0);
    await pref.setStringList("position", []);
    print("Started service");
    var res = await service.startService();
    print("Post Started service");

    return res;
  }

  static void destroy() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    print(pref.getStringList("position"));
    service.invoke("stop");
  }
}
