import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracker_app/config.dart';

class LocationService {
  @pragma('vm:entry-point')
  static void init(ServiceInstance service) async {
    Timer? locTimer;
    DartPluginRegistrant.ensureInitialized();
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.reload();
    print("Inside service");

    service.on("stop").listen(
      (ondata) async {
        print("Stop called");
        if (locTimer!.isActive) {
          locTimer.cancel();
        }
        await service.stopSelf();
      },
      onError: (obj, str) {
        print(obj);
        print(str);
        print("Error occured!");
      },
      onDone: () {
        print("Service done!");
      },
    );

    Position? temp;
    const notifDetails = AndroidNotificationDetails(
      Config.notificationChannelId,
      Config.notificationChannelName,
      ongoing: true,
      importance: Importance.min,
      playSound: false,
      enableLights: false,
      enableVibration: false,
    );
    final FlutterLocalNotificationsPlugin notifPlug =
        FlutterLocalNotificationsPlugin();

    print("method called");

    if (pref.getBool("markedtdy")!) {
      locTimer?.cancel();
      notifPlug.cancel(Config.notificationId);
      await service.stopSelf();
    }

    if (await Geolocator.checkPermission() != LocationPermission.always) {
      temp = await Geolocator.getLastKnownPosition();
    } else {
      temp = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    }
    await pref.setStringList(
      "position",
      pref.getStringList("position")! +
          ["${temp?.latitude}", "${temp?.longitude}"],
    );

    List<Placemark> p = await placemarkFromCoordinates(
      temp!.latitude,
      temp.longitude,
    );

    await pref.setString(
      "latest_loc",
      "${p[0].name} | ${p[0].locality} | ${p[0].administrativeArea}",
    );

    await notifPlug.show(
      Config.notificationId,
      'Distance | Location',
      '0.000 km | -',
      const NotificationDetails(
        android: notifDetails,
      ),
    );

    locTimer = Timer.periodic(
      const Duration(seconds: Config.distPeriod),
      (timer) async {
        print("Timer Called");
        var perm1 = await Geolocator.checkPermission();
        var perm2 = await Geolocator.isLocationServiceEnabled();

        if (perm1 != LocationPermission.always) {
          print("Not enabled");
          return;
        }
        if (!perm2) {
          print("No permission");
          return;
        }
        Position event = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        double dist = Geolocator.distanceBetween(
          temp!.latitude,
          temp!.longitude,
          event.latitude,
          event.longitude,
        );

        if (dist < Config.distFilter || event.speed < Config.spdFilter) {
          return;
        }

        temp = event;

        List<Placemark> p = await placemarkFromCoordinates(
          event.latitude,
          event.longitude,
        );

        await pref.setStringList(
          "position",
          pref.getStringList("position")! +
              ["${event.latitude}", "${event.longitude}"],
        );

        await pref.setString(
          "latest_loc",
          "${p[0].name} | ${p[0].locality} | ${p[0].administrativeArea}",
        );

        await pref.setDouble("dist", dist + pref.getDouble("dist")!);
        print(pref.getString("latest_loc"));
        print(pref.getDouble("dist"));

        notifPlug.show(
          Config.notificationId,
          'Distance | Location',
          '${(pref.getDouble("dist")! / 1000).toStringAsFixed(3)} km | ${p[0].name}, ${p[0].locality}',
          const NotificationDetails(
            android: notifDetails,
          ),
        );
      },
    );

    service.invoke("complete");
  }
}
