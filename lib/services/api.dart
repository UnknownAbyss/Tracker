import "dart:convert";

import "package:http/http.dart" as http;
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
}
