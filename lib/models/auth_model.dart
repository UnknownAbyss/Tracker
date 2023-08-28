class LoginReq {
  LoginReq({
    required this.user,
    required this.pass,
  });

  late final String user;
  late final String pass;

  LoginReq.fromJson(Map<String, dynamic> json) {
    user = json['user'];
    pass = json['pass'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['user'] = user;
    data['pass'] = pass;
    return data;
  }
}

class LoginRes {
  LoginRes({
    required this.mes,
    required this.code,
    required this.token,
  });

  late final String mes;
  late final int code;
  late final String token;

  LoginRes.fromJson(Map<String, dynamic> json) {
    mes = json['msg'];
    code = json['code'];
    token = json['token'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['msg'] = mes;
    data['code'] = code;
    data['token'] = token;
    return data;
  }
}
