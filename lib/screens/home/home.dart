import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
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

class _HomeState extends State<Home> with WidgetsBindingObserver {
  String title = "Tracker:  ";
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
    NotifService.schedNotif();
    print("Doing updates");
    updateStates();
    checkReset();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) checkReset();
    if (markedtdy && !submittdy) submitbttn(false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: HexColor(Config.appColor),
        body: _HomeUI(context),
        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: kToolbarHeight * 2,
          title: Text(
            "TRACKER",
            style: TextStyle(
              color: HexColor(Config.appColor),
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.elliptical(200, 30),
              bottomRight: Radius.elliptical(200, 30),
            ),
          ),
          actions: [
            IconButton(
              iconSize: 30,
              onPressed: () async {
                bool? x = await showAlertBox(context, "Sync");
                if (x! && context.mounted) {
                  resetDay();
                }
              },
              icon: Icon(
                Icons.sync,
                color: HexColor(Config.appColor),
              ),
            ),
            IconButton(
              iconSize: 30,
              tooltip: "Logout",
              onPressed: () async {
                bool? x = await showAlertBox(context, "Logout");
                if (x! && context.mounted) {
                  Shared.logout(context);
                }
              },
              icon: Icon(
                Icons.logout,
                color: HexColor(Config.appColor),
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
              statusText(
                context,
                title,
                "${DateFormat('d/M/y').format(DateTime.now().subtract(const Duration(hours: Config.cycle)))} ${20 < DateTime.now().hour || DateTime.now().hour < Config.cycle ? '🌙' : '☀️'}",
                Colors.white,
              ),
              const SizedBox(
                height: 30,
              ),
              _Submitter(context),
              const SizedBox(
                height: 15,
              ),
              _CurStatus(context),
              const SizedBox(
                height: 15,
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 8, right: 8, top: 20, bottom: 30),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          statusText(
                            context,
                            "START 🕘",
                            starttime != null
                                ? DateFormat('h:mm a').format(starttime!)
                                : "-",
                            !marked && !markedtdy
                                ? Colors.orange.shade300
                                : Colors.green.shade300,
                          ),
                          statusText(
                            context,
                            "END 🕖",
                            endtime != null
                                ? DateFormat('h:mm a').format(endtime!)
                                : "-",
                            markedtdy
                                ? Colors.green.shade300
                                : Colors.orange.shade300,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          statusText(
                            context,
                            "Distance 🗺️",
                            "${distance.toStringAsFixed(3)} km",
                            marked || markedtdy
                                ? Colors.green.shade300
                                : Colors.orange.shade300,
                          ),
                          statusText(
                            context,
                            "Location📍",
                            curloc.split(" | ")[0],
                            marked || markedtdy
                                ? Colors.green.shade300
                                : Colors.orange.shade300,
                          ),
                        ],
                      )
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

  Widget _CurStatus(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Status:  ",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            submittdy
                ? 'Complete! ✅'
                : marked
                    ? 'Ongoing'
                    : markedtdy
                        ? 'Pending Submit ⏳'
                        : 'Not started',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: submittdy
                    ? Colors.green
                    : marked
                        ? Colors.red.shade300
                        : markedtdy
                            ? Colors.orange.shade200
                            : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _Submitter(BuildContext context) {
    var dim = MediaQuery.of(context).size.width - 200;
    return SizedBox(
      height: dim,
      width: dim,
      child: ElevatedButton(
        onPressed: markedtdy
            ? submittdy
                ? () {}
                : () => submitbttn(true)
            : attendButton,
        style: ButtonStyle(
          shape: const MaterialStatePropertyAll(CircleBorder()),
          elevation: const MaterialStatePropertyAll(5),
          backgroundColor: MaterialStatePropertyAll(
            submittdy
                ? Colors.green
                : marked
                    ? Colors.red.shade300
                    : markedtdy
                        ? Colors.orange.shade200
                        : Colors.white,
          ),
        ),
        child: Text(
          submittdy
              ? "Done!"
              : marked
                  ? "End"
                  : markedtdy
                      ? "Submit"
                      : "Start",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: !marked && !markedtdy && !submittdy
                ? HexColor(Config.appColor)
                : Colors.white,
          ),
        ),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(
          height: 7,
        ),
        Container(
          width: 130,
          child: Center(
            child: Text(
              val,
              overflow: TextOverflow.fade,
              softWrap: false,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 18,
              ),
            ),
          ),
        ),
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
        title = "${decoded['user']}";
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

    if (context.mounted) {
      x = await showAlertBox(
          context,
          "Attendance",
          marked
              ? "Do you wish to end your attendance"
              : "Do you wish to start your attendance?");
    }

    var running = await FlutterBackgroundService().isRunning();

    print("STATUS");
    print(marked);
    print(running);
    if (x!) {
      if (marked && running) {
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
        Future.delayed(const Duration(seconds: 3), () {
          if (markedtdy && !submittdy) submitbttn(false);
        });
      } else if (!marked && !running) {
        DateTime temp = DateTime.now();
        print("Spawning Isolate");

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const Dialog(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      Text("Loading"),
                    ],
                  ),
                ),
              );
            },
          );
        }

        var res = await BackgroundService.spawnLocIsolate(
          temp.millisecondsSinceEpoch,
        );
        if (mounted) {
          Navigator.pop(context);
        }

        if (res) {
          setState(() {
            marked = !marked;
            starttime = temp;
            timer = Timer.periodic(const Duration(seconds: Config.updateFreq),
                (timer) {
              refresh();
            });
          });
        } else {
          if (context.mounted) {
            showAlertBox(context, "Attendance", "Something went wrong", false);
          }
        }
      } else {
        if (context.mounted) {
          showAlertBox(context, "Attendance", "Wait for a few seconds", false);
          BackgroundService.destroy();
        }
      }
    }
  }

  void refresh() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    print("Refreshn");
    String loc = "Unknown";
    double dist = 0;
    await pref.reload();

    if (pref.containsKey("latest_loc")) {
      loc = pref.getString("latest_loc")!;
    }
    if (pref.containsKey("position")) {
      var pos = pref.getStringList("position");
      var dpos = pos!.map(double.parse).toList();
      for (int i = 1; i < dpos.length / 2; i++) {
        dist += Geolocator.distanceBetween(
            dpos[i * 2 - 2], dpos[i * 2 - 1], dpos[i * 2], dpos[i * 2 + 1]);
      }
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
    print(pref.getStringList("position"));

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
    FlutterBackgroundService().invoke("stop");
    updateStates();
    NotifService.displayNotif(
      "Good morning",
      "Day reset",
      false,
    );
  }

  checkReset() async {
    print("Called reset");
    SharedPreferences pref = await SharedPreferences.getInstance();
    if (!pref.containsKey("prev")) {
      pref.setInt("prev", DateTime.now().millisecondsSinceEpoch);
      BackgroundService.destroy();
      resetDay();
      return;
    }
    var prev = pref.getInt("prev");
    var startday = DateTime.fromMillisecondsSinceEpoch(prev!)
        .subtract(const Duration(hours: Config.cycle))
        .day;
    var endday =
        DateTime.now().subtract(const Duration(hours: Config.cycle)).day;

    if (startday != endday) {
      pref.setInt("prev", DateTime.now().millisecondsSinceEpoch);
      BackgroundService.destroy();
      resetDay();
      return;
    }
  }

  submitbttn(bool ask) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    Map<String, dynamic> res = <String, dynamic>{
      "msg": "Client error occurred",
      "val": false,
      "dist": 0.0,
    };

    if (!markedtdy || submittdy) {
      return;
    }
    if (ask) {
      if (await showAlertBox(context, "Submit Attendance") == false) {
        return;
      }
    }

    if (context.mounted) {
      res = await ApiService.sendData(context);
    }

    if (res["dist"] != -1) {
      setState(() {
        distance = res["dist"];
      });
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
