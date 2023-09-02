import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:tracker_app/services/location.dart';

class NotificationService {
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
      ),
    );
  }

  static void spawnLocIsolate() async {
    service.startService();
  }

  static void destroy() {
    service.invoke("stop");
  }
}
