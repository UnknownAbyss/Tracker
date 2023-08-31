import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:snippet_coder_utils/hex_color.dart';
import 'package:tracker_app/config.dart';
import 'package:tracker_app/models/auth_model.dart';
import 'package:tracker_app/services/shared.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String title = "User:  ";
  bool marked = false;

  @override
  void initState() {
    super.initState();
    getUser(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _HomeUI(context),
        appBar: AppBar(
          backgroundColor: HexColor("#245D66"),
          toolbarHeight: kToolbarHeight * 1.5,
          title: Text(title),
          actions: [
            IconButton(
              onPressed: () {
                Shared.logout(context);
              },
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _HomeUI(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.only(top: 30, left: 30, right: 30, bottom: 30),
          child: Column(
            children: [
              SizedBox(
                height: 150,
                width: MediaQuery.of(context).size.width - 60,
                child: ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(marked
                          ? HexColor("#245D66").withOpacity(0.9)
                          : HexColor("#245D66")),
                      elevation: MaterialStatePropertyAll(5),
                      side: MaterialStatePropertyAll(
                        BorderSide(
                          width: 5,
                          color: marked ? Colors.red.shade300 : Colors.white54,
                        ),
                      )),
                  child: Text(marked ? "End Attendance" : "Start Attendance"),
                  onPressed: () async {
                    bool? x = true;
                    x = await showAlertBox(context);
                    if (x!) {
                      setState(() {
                        marked = !marked;
                      });
                    }
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: statusText(
                          context,
                          "Date:",
                          DateFormat('d/M/y').format(DateTime.now()),
                          HexColor("#245D66"),
                        ),
                      ),
                      statusText(
                        context,
                        "Marked Today",
                        marked ? "Yes" : "No",
                        marked ? Colors.green : Colors.red,
                      ),
                      statusText(
                        context,
                        "Start TIme",
                        marked ? "Yes" : "No",
                        marked ? Colors.green : Colors.red,
                      ),
                      statusText(
                        context,
                        "End Time",
                        marked ? "Yes" : "No",
                        marked ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> showAlertBox(BuildContext context) {
    Widget ok = TextButton(
      onPressed: () {
        Navigator.of(context).pop(true);
      },
      child: Text("Confirm"),
    );

    Widget back = TextButton(
      onPressed: () {
        Navigator.of(context).pop(false);
      },
      child: Text("Back"),
    );

    AlertDialog alert = AlertDialog(
      title: const Text(Config.appName),
      content: const Text("Do you wish to proceed?"),
      actions: [ok, back],
    );

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Widget statusText(
      BuildContext context, String title, String val, Color color) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              val,
              style: TextStyle(
                color: color,
                fontSize: 18,
              ),
            ),
          ),
        )
      ],
    );
  }

  void getUser(BuildContext context) async {
    LoginRes data = await Shared.getToken(context);
    Map<String, dynamic> decoded;
    try {
      decoded = JwtDecoder.decode(data.token);
      setState(() {
        title = "User: ${decoded['user']}";
      });
    } catch (e) {
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }
}
