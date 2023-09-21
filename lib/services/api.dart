import "dart:convert";

import "package:flutter/widgets.dart";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";
import "package:tracker_app/config.dart";
import "package:tracker_app/models/auth_model.dart";
import "package:tracker_app/services/shared.dart";

class ApiService {
  static var client = http.Client();

  static Future<Map<String, dynamic>> login(LoginReq req) async {
    Map<String, String> reqHead = {
      "Content-Type": "application/json",
    };

    var url = Uri.http(Config.apiUrl, Config.loginRoute);
    var res;

    try {
      res = await client.post(
        url,
        headers: reqHead,
        body: jsonEncode(req.toJson()),
      );
    } catch (e) {
      return <String, dynamic>{
        "msg": "Request failed. Check Internet",
        "val": false
      };
    }

    if (res.statusCode == 200) {
      LoginRes data = LoginRes.fromJson(json.decode(res.body));
      if (data.code == 0) {
        await Shared.setToken(data);
        return <String, dynamic>{"msg": "Success", "val": true};
      }
    }
    return <String, dynamic>{"msg": "Invalid Credentials", "val": false};
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

    print(tokenData.token);
    print(positions);
    print(start);
    print(end);
    print(tokenData.token);

    Map<String, dynamic> x = <String, dynamic>{
      "token": tokenData.token,
      "positions": positions,
      "start": start,
      "end": end,
      "date": start,
    };

    var res;

    try {
      res = await client.post(
        url,
        headers: reqHead,
        body: jsonEncode(x),
      );
    } catch (e) {
      return <String, dynamic>{
        "msg": "Couldn't submit. Check Internet and try again",
        "val": false
      };
    }

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
