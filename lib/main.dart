import 'package:flutter/material.dart';
import 'package:tracker_app/screens/auth/login.dart';
import 'package:tracker_app/screens/home/home.dart';
import 'package:tracker_app/services/background.dart';
import 'package:tracker_app/services/notification.dart';
import 'package:tracker_app/services/shared.dart';
import 'package:timezone/data/latest.dart' as tz;

Widget defaultpage = const Login();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (await Shared.isLogged()) {
    defaultpage = const Home();
  }

  NotifService.init();
  BackgroundService.init();
  NotifService.setupNotif();
  tz.initializeTimeZones();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracker',
      routes: {
        '/': (context) => defaultpage,
        '/home': (context) => const Home(),
        '/login': (context) => const Login(),
      },
    );
  }
}
