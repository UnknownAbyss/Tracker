import 'package:api_cache_manager/models/cache_db_model.dart';
import 'package:api_cache_manager/utils/cache_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:tracker_app/models/auth_model.dart';
import 'dart:convert';

class Shared {
  static Future<bool> isLogged() async {
    var key = await APICacheManager().isAPICacheKeyExist("login_details");

    return key;
  }

  static Future<LoginRes> getToken() async {
    var key = await APICacheManager().isAPICacheKeyExist("login_details");

    if (key) {
      var data = await APICacheManager().getCacheData("login_details");

      return LoginRes.fromJson(json.decode(data.syncData));
    }

    return LoginRes(mes: "Invalid", code: 2, token: "2");
  }

  static setToken(LoginRes model) async {
    APICacheDBModel cache = APICacheDBModel(
      key: "login_details",
      syncData: jsonEncode(model.toJson()),
    );

    await APICacheManager().addCacheData(cache);
  }

  static logout(BuildContext context) async {
    await APICacheManager().deleteCache("login_details");
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }
}
