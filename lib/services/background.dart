import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
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
    await service.startService();
    print("Post Started service");
    bool res = false;
    service.on("complete").listen((event) {
      print("Response from background!!");
      res = true;
    });
    var count = 0;
    var t = Timer.periodic(const Duration(seconds: 1), (timer) {
      print("Waiting $count");
      count++;
      if (count > 15 || res) {
        timer.cancel();
      }
    });
    while (t.isActive) {
      await Future.delayed(const Duration(seconds: 2));
      print("Waiting for timer");
    }
    return res;
  }

  static void destroy() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    print(pref.getStringList("position"));
    var temp;
    if (await Geolocator.checkPermission() != LocationPermission.always) {
      temp = await Geolocator.getLastKnownPosition();
    } else {
      temp = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    }

    if (pref.containsKey("position")) {
      await pref.setStringList(
        "position",
        pref.getStringList("position")! +
            ["${temp?.latitude}", "${temp?.longitude}"],
      );
    }

    service.invoke("stop");
  }
}
