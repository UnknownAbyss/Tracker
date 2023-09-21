import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:snippet_coder_utils/FormHelper.dart";
import "package:snippet_coder_utils/ProgressHUD.dart";
import "package:snippet_coder_utils/hex_color.dart";
import "package:tracker_app/config.dart";
import "package:tracker_app/models/auth_model.dart";
import "package:tracker_app/services/api.dart";
import "package:tracker_app/services/notification.dart";

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool loading = false;
  bool hidePass = true;
  GlobalKey<FormState> globalFormKey = GlobalKey<FormState>();
  String? user, pass;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: HexColor(Config.appColor),
        body: ProgressHUD(
          inAsyncCall: loading,
          opacity: 0.3,
          key: UniqueKey(),
          child: Form(
            key: globalFormKey,
            child: _loginUI(context),
          ),
        ),
      ),
    );
  }

  Widget _loginUI(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width / 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white,
                  ]),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.elliptical(200, 50),
                bottomRight: Radius.elliptical(200, 50),
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Tracker",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 50,
                  ),
                )
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Text(
              "Login",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: Colors.white,
              ),
            ),
          ),
          FormHelper.inputFieldWidget(
            context,
            "user",
            "Username",
            (onValidate) {
              if (onValidate.isEmpty) {
                return "Username can't be empty";
              }
              return null;
            },
            (onSaved) {
              user = onSaved;
            },
            borderFocusColor: Colors.white,
            borderColor: Colors.white,
            showPrefixIcon: true,
            prefixIcon: const Icon(
              Icons.person,
              color: Colors.white,
            ),
            textColor: Colors.white,
            hintColor: Colors.white.withOpacity(0.7),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: FormHelper.inputFieldWidget(
              context,
              "pass",
              "Password",
              (onValidate) {
                if (onValidate.isEmpty) {
                  return "Password can't be empty";
                }
                return null;
              },
              (onSaved) {
                pass = onSaved;
              },
              obscureText: hidePass,
              borderFocusColor: Colors.white,
              borderColor: Colors.white,
              showPrefixIcon: true,
              prefixIcon: const Icon(
                Icons.lock,
                color: Colors.white,
              ),
              textColor: Colors.white,
              hintColor: Colors.white.withOpacity(0.7),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    hidePass = !hidePass;
                  });
                },
                color: Colors.white.withOpacity(0.7),
                icon: Icon(
                  hidePass ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 30),
              child: RichText(
                text: TextSpan(
                    text: "Request Notification Permission...?",
                    style: const TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        print("Tapped");
                        bool granted = await NotifService.requestNotifPerm();
                        print(granted);
                        if (context.mounted) {
                          if (!granted) {
                            print("Get");
                            FormHelper.showSimpleAlertDialog(
                              context,
                              Config.appName,
                              "App needs notification permissions",
                              "Ok",
                              () {
                                Navigator.pop(context);
                              },
                            );
                          } else {
                            print("Have");
                            FormHelper.showSimpleAlertDialog(
                              context,
                              Config.appName,
                              "App already has notification permissions",
                              "Ok",
                              () {
                                Navigator.pop(context);
                              },
                            );
                          }
                        }
                      }),
              ),
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          Center(
            child: FormHelper.submitButton(
              "Login",
              () async {
                if (validateSave()) {
                  setState(() {
                    loading = true;
                  });

                  var perm = await NotifService.requestNotifPerm();
                  if (!perm) {
                    if (context.mounted) {
                      FormHelper.showSimpleAlertDialog(
                        context,
                        Config.appName,
                        "Need notification permissions",
                        "Ok",
                        () {
                          Navigator.pop(context);
                        },
                      );
                    }
                    setState(() {
                      loading = false;
                    });
                    return;
                  }

                  LoginReq req = LoginReq(user: user!, pass: pass!);
                  ApiService.login(req).then((res) {
                    setState(() {
                      loading = false;
                    });
                    if (res['val']) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    } else {
                      FormHelper.showSimpleAlertDialog(
                        context,
                        Config.appName,
                        res['msg'],
                        "Ok",
                        () {
                          Navigator.pop(context);
                        },
                      );
                    }
                  });
                }
              },
              btnColor: HexColor("#EEEEEE"),
              txtColor: HexColor(Config.appColor),
              borderColor: HexColor("#537A80"),
            ),
          ),
        ],
      ),
    );
  }

  bool validateSave() {
    final form = globalFormKey.currentState;

    if (form!.validate()) {
      form.save();
      return true;
    } else {
      return false;
    }
  }
}
