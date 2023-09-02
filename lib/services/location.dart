import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracker_app/config.dart';

class LocationService {
  static late Timer locTimer;
  static final Geolocator geolocator = Geolocator();

  @pragma('vm:entry-point')
  static void init(ServiceInstance service) async {
    print("method called");
    DartPluginRegistrant.ensureInitialized();
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.remove("latest_loc");
    await pref.setDouble("dist", 0);
    Position temp = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    locTimer = Timer.periodic(
      const Duration(seconds: Config.distPeriod),
      (timer) async {
        Position event = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        double dist = Geolocator.distanceBetween(
          temp.latitude,
          temp.longitude,
          event.latitude,
          event.longitude,
        );

        temp = event;

        List<Placemark> p = await placemarkFromCoordinates(
          event.latitude,
          event.longitude,
        );

        await pref.setString(
          "latest_loc",
          "${p[0].name} | ${p[0].locality} | ${p[0].administrativeArea}",
        );
        await pref.setDouble("dist", dist + pref.getDouble("dist")!);
        print(pref.getString("latest_loc"));
        print(pref.getDouble("dist"));
      },
    );

    service.on("stop").listen((event) {
      locTimer.cancel();
      service.stopSelf();
    });
  }
}
