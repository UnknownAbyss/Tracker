import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:snippet_coder_utils/FormHelper.dart";
import "package:snippet_coder_utils/ProgressHUD.dart";
import "package:snippet_coder_utils/hex_color.dart";
import "package:tracker_app/config.dart";
import "package:tracker_app/models/auth_model.dart";
import "package:tracker_app/services/api.dart";

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
        backgroundColor: HexColor("#245D66"),
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
                bottomLeft: Radius.circular(100),
                bottomRight: Radius.circular(100),
              ),
            ),
            child: Column(
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
                Icons.person,
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
                    text: "Forgot password..?",
                    style: const TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        print("Forget");
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
              () {
                if (validateSave()) {
                  setState(() {
                    loading = true;
                  });

                  LoginReq req = LoginReq(user: user!, pass: pass!);
                  ApiService.login(req).then((res) {
                    setState(() {
                      loading = false;
                    });
                    if (res) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    } else {
                      FormHelper.showSimpleAlertDialog(
                        context,
                        Config.appName,
                        "Invalid Credentials",
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
              txtColor: HexColor("#245D66"),
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
