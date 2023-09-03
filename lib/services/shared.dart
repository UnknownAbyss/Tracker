import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracker_app/models/auth_model.dart';
import 'package:tracker_app/services/notification.dart';

class Shared {
  static Future<bool> isLogged() async {
    var pref = await SharedPreferences.getInstance();
    var key = pref.containsKey("token");
    return key;
  }

  static Future<LoginRes> getToken(BuildContext context) async {
    var pref = await SharedPreferences.getInstance();
    var key = pref.containsKey("token");

    if (key) {
      var data = pref.getString("token");
      return LoginRes(mes: "None", code: 0, token: data!);
    }

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
    return LoginRes(mes: "Invalid", code: 2, token: "2");
  }

  static setToken(LoginRes model) async {
    var pref = await SharedPreferences.getInstance();
    await pref.setString("token", model.token);
  }

  static logout(BuildContext context) async {
    var pref = await SharedPreferences.getInstance();
    await pref.remove("token");
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  static Future<bool> locperm() async {
    LocationPermission perm;
    if (!await Geolocator.isLocationServiceEnabled()) {
      print("1");
      NotifService.displayNotif(
        "Location",
        "Enable Location permissions first",
        false,
      );
      return false;
    }
    perm = await Geolocator.checkPermission();

    if (perm != LocationPermission.always) {
      NotifService.displayNotif(
        "Location",
        "Grant permission: allow always",
        false,
      );
      print(2);
      perm = await Geolocator.requestPermission();
      if (perm != LocationPermission.always) {
        NotifService.displayNotif(
          "Location",
          "Grant permission: allow always",
          false,
        );
        perm = await Geolocator.requestPermission();
        if (perm != LocationPermission.always) {
          print("Don't have perms");
          NotifService.displayNotif(
            "Location",
            "Denied: Acquire Location Permissions",
            false,
          );
          return false;
        }
      }
    }

    return true;
  }

  static void locenabled(BuildContext context) async {
    bool enabled;
    enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (context.mounted) {
        logout(context);
      }
    }
  }
}
