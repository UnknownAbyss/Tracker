import "dart:convert";

import "package:flutter/widgets.dart";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";
import "package:tracker_app/config.dart";
import "package:tracker_app/models/auth_model.dart";
import "package:tracker_app/services/shared.dart";

class ApiService {
  static var client = http.Client();

  static Future<bool> login(LoginReq req) async {
    Map<String, String> reqHead = {
      "Content-Type": "application/json",
    };

    var url = Uri.http(Config.apiUrl, Config.loginRoute);

    var res = await client.post(
      url,
      headers: reqHead,
      body: jsonEncode(req.toJson()),
    );

    if (res.statusCode == 200) {
      LoginRes data = LoginRes.fromJson(json.decode(res.body));
      if (data.code == 0) {
        await Shared.setToken(data);
        return true;
      }
    }
    return false;
  }

  static Future<Map<String, dynamic>> sendData(BuildContext context) async {
    Map<String, String> reqHead = {
      "Content-Type": "application/json",
    };

    var url = Uri.http(Config.apiUrl, Config.submitRoute);
    var pref = await SharedPreferences.getInstance();
    var tokenData;
    pref.reload();

    if (context.mounted) {
      tokenData = await Shared.getToken(context);
    }
    var positions = pref.getStringList("position");
    var start = pref.getInt("start");
    var end = pref.getInt("end");

    if (tokenData.code != 0) {
      return <String, dynamic>{"msg": "Invalid login. Re-login", "val": false};
    }

    Map<String, dynamic> x = <String, dynamic>{
      "token": tokenData.token,
      "positions": positions,
      "start": start,
      "end": end,
      "date": start,
    };

    var res = await client.post(
      url,
      headers: reqHead,
      body: jsonEncode(x),
    );

    if (res.statusCode == 200) {
      Map<String, dynamic> data = json.decode(res.body);
      if (data["code"] == 0) {
        return <String, dynamic>{"msg": data["msg"], "val": true};
      } else {
        return <String, dynamic>{"msg": data["msg"], "val": false};
      }
    }
    return <String, dynamic>{"msg": "Request failed", "val": false};
  }
}
