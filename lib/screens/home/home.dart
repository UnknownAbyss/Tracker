import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snippet_coder_utils/hex_color.dart';
import 'package:tracker_app/config.dart';
import 'package:tracker_app/models/auth_model.dart';
import 'package:tracker_app/services/api.dart';
import 'package:tracker_app/services/background.dart';
import 'package:tracker_app/services/notification.dart';
import 'package:tracker_app/services/shared.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String title = "User:  ";
  bool marked = false;
  bool markedtdy = false;
  bool submittdy = false;
  DateTime? starttime;
  DateTime? endtime;
  double distance = 0.0;
  List<Position> position = [];
  String curloc = "";
  Timer? timer;

  @override
  void initState() {
    super.initState();
    getUser(context);
    print("Doing updates");
    updateStates();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _HomeUI(context),
        appBar: AppBar(
          backgroundColor: HexColor(Config.appColor),
          toolbarHeight: kToolbarHeight * 1.5,
          title: Text(title),
          actions: [
            IconButton(
              onPressed: () async {
                bool? x = await showAlertBox(context, "Sync");
                if (x! && context.mounted) {
                  resetDay();
                }
              },
              icon: const Icon(
                Icons.sync,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () async {
                bool? x = await showAlertBox(context, "Sync");
                if (x! && context.mounted) {
                  refresh();
                }
              },
              icon: const Icon(
                Icons.refresh_sharp,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () async {
                bool? x = await showAlertBox(context, "Logout");
                if (x! && context.mounted) {
                  Shared.logout(context);
                }
              },
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
            ),
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
                  onPressed: markedtdy ? null : attendButton,
                  style: ButtonStyle(
                    elevation: MaterialStatePropertyAll(5),
                    backgroundColor: MaterialStatePropertyAll(
                      marked
                          ? HexColor(Config.appColor).withOpacity(0.9)
                          : HexColor(Config.appColor),
                    ),
                    side: MaterialStatePropertyAll(
                      BorderSide(
                        width: 5,
                        color: marked ? Colors.red.shade300 : Colors.white54,
                      ),
                    ),
                  ),
                  child: Text(
                    marked ? "End Attendance" : "Start Attendance",
                    style: TextStyle(
                      color: markedtdy ? Colors.grey : Colors.white,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 8, right: 8, top: 20, bottom: 30),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: statusText(
                          context,
                          "",
                          DateFormat('d/M/y').format(DateTime.now()),
                          HexColor(Config.appColor),
                        ),
                      ),
                      statusText(
                        context,
                        "Marked Today:",
                        markedtdy ? "Yes" : "No",
                        markedtdy ? Colors.green : Colors.red,
                      ),
                      statusText(
                        context,
                        "Start Time:",
                        starttime != null
                            ? DateFormat('h:mm a').format(starttime!)
                            : "-",
                        Colors.black,
                      ),
                      statusText(
                        context,
                        "End Time:",
                        endtime != null
                            ? DateFormat('h:mm a').format(endtime!)
                            : "-",
                        Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  const Text(
                    "Distance",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                  ),
                  Text("${distance.toStringAsFixed(3)} km"),
                  const SizedBox(height: 20),
                  const Text(
                    "Current Location",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                  ),
                  Text(curloc),
                ],
              ),
              _Submitter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _Submitter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          const Text(
            "Submitted to Server",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                color: submittdy ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 5),
              Text(submittdy ? "Submitted" : "Not Submitted"),
            ],
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor:
                  MaterialStatePropertyAll(HexColor(Config.appColor)),
            ),
            onPressed: markedtdy && !submittdy ? submitbttn : null,
            child: Text("Submit to server"),
          ),
        ],
      ),
    );
  }

  Future<bool?> showAlertBox(BuildContext context, String title,
      [String text = "Do you wish to proceed?", bool confirm = true]) {
    Widget ok = TextButton(
      onPressed: () {
        Navigator.of(context).pop(true);
      },
      child: const Text(
        "Confirm",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );

    Widget back = TextButton(
      onPressed: () {
        Navigator.of(context).pop(false);
      },
      child: const Text(
        "Back",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );

    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: confirm ? [back, ok] : [ok],
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
      print(data.token);
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

  void attendButton() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    if (markedtdy) {
      return;
    }

    if (!await Shared.locperm()) {
      return;
    }

    bool? x;
    x = await showAlertBox(context, "Attendance");

    if (x!) {
      if (marked) {
        DateTime temp = DateTime.now();
        setState(() {
          marked = !marked;
          markedtdy = !markedtdy;
          endtime = temp;
          timer?.cancel();
          refresh();
        });
        await pref.setInt("end", temp.millisecondsSinceEpoch);
        await pref.setBool("ongoing", false);
        await pref.setBool("markedtdy", true);
        print("Ending notif");
        BackgroundService.destroy();
      } else {
        DateTime temp = DateTime.now();
        setState(() {
          marked = !marked;
          starttime = temp;
          timer = Timer.periodic(const Duration(seconds: Config.updateFreq),
              (timer) {
            refresh();
          });
        });
        print("Spawning Isolate");
        BackgroundService.spawnLocIsolate(temp.millisecondsSinceEpoch);
      }
    }
  }

  void refresh() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    print("Refreshn");
    String loc = "No location found";
    double dist = 0;
    await pref.reload();
    if (pref.containsKey("latest_loc")) {
      loc = pref.getString("latest_loc")!;
    }
    if (pref.containsKey("dist")) {
      dist = pref.getDouble("dist")!;
    }
    setState(() {
      curloc = loc;
      distance = dist / 1000;
    });
  }

  updateStates() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    if (!pref.containsKey("markedtdy")) {
      await pref.setBool("markedtdy", false);
    }
    if (!pref.containsKey("ongoing")) {
      await pref.setBool("ongoing", false);
    }
    if (!pref.containsKey("submitted")) {
      await pref.setBool("submitted", false);
    }

    setState(() {
      if (!pref.containsKey("start")) {
        starttime = null;
      } else {
        starttime = DateTime.fromMillisecondsSinceEpoch(pref.getInt("start")!);
      }
      if (!pref.containsKey("end")) {
        endtime = null;
      } else {
        endtime = DateTime.fromMillisecondsSinceEpoch(pref.getInt("end")!);
      }
      markedtdy = pref.getBool("markedtdy")!;
      submittdy = pref.getBool("submitted")!;
      marked = pref.getBool("ongoing")!;
      if (pref.getBool("ongoing")!) {
        timer =
            Timer.periodic(const Duration(seconds: Config.updateFreq), (timer) {
          refresh();
        });
      }
    });
    refresh();
  }

  resetDay() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setBool("markedtdy", false);
    await pref.setBool("ongoing", false);
    await pref.setBool("submitted", false);
    await pref.remove("start");
    await pref.remove("end");
    await pref.remove("latest_loc");
    await pref.remove("dist");
    await pref.remove("position");
    updateStates();
    NotifService.displayNotif(
      "Day Reset",
      "Cache cleared",
      false,
    );
  }

  submitbttn() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    Map<String, dynamic> res = <String, dynamic>{
      "msg": "Client error occurred",
      "val": false
    };

    if (!markedtdy || submittdy) {
      return;
    }

    if (await showAlertBox(context, "Submit Attendance") == false) {
      return;
    }

    if (context.mounted) {
      res = await ApiService.sendData(context);
    }

    if (context.mounted) {
      showAlertBox(
        context,
        "Submission",
        res["msg"],
        false,
      );
    }

    if (res["val"]) {
      await pref.setBool("submitted", true);
      updateStates();
    }
  }
}
