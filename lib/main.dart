
import 'dart:async';

import 'package:class_time/module/notification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'module/export_page.dart';
import 'module/home_page.dart';
import 'module/session_page.dart';
import 'module/timeTablePage/time_table_page.dart';
import 'routes/Routes.dart';


import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Streams are created so that app can respond to notification-related events
/// since the plugin is initialised in the `main` function
final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
BehaviorSubject<ReceivedNotification>();

final BehaviorSubject<String> selectNotificationSubject =
BehaviorSubject<String>();

const MethodChannel platform =
MethodChannel('app.davish.me/methodChannel');

class ReceivedNotification {
  ReceivedNotification({
    this.id,
    this.title,
    this.body,
    this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String payload;
}

String selectedNotificationPayload;

/// IMPORTANT: running the following code on its own won't work as there is
/// setup required for each platform head project.
///
/// Please download the complete example app from the GitHub repository where
/// all the setup has been done


NotificationAppLaunchDetails notificationAppLaunchDetails;

Future<void> main() async {
  // needed if you intend to initialize in the `main` function
  WidgetsFlutterBinding.ensureInitialized();

  await _configureLocalTimeZone();

  notificationAppLaunchDetails =
  await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();


  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('app_icon');

  /// Note: permissions aren't requested here just to demonstrate that can be
  /// done later
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
        if (payload != null) {
          debugPrint('notification payload: $payload');
        }
        selectedNotificationPayload = payload;
        selectNotificationSubject.add(payload);
      });
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(new MyApp());
  });
}


Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final String timeZoneName =
  await platform.invokeMethod<String>('getTimeZoneName');
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}


class MyApp extends StatefulWidget {

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var theme = ThemeMode.system;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkSharedPref();
  }

  void checkSharedPref() async{

    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    final SharedPreferences prefs = await _prefs;
    var dark = prefs.getBool('darkTheme')??false;
    setState(() {
      if(dark)
        theme = ThemeMode.dark;
      else
        theme = ThemeMode.light;
    });
  }
  @override
  Widget build(BuildContext context) {
    checkSharedPref();
    return MaterialApp(
      title: 'Time Table',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        primaryColorLight: Colors.blue,
        iconTheme: IconThemeData(
          color: Colors.blue
        ),
        highlightColor: Colors.blue[400],

        /* light theme settings */
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.cyanAccent
        ),
        errorColor: Colors.redAccent,


        /* dark theme settings */
      ),
      themeMode: theme,
      /* ThemeMode.system to follow system theme,
         ThemeMode.light for light theme,
         ThemeMode.dark for dark theme
      */
      debugShowCheckedModeBanner: false,
      home: MainPage(),
      routes: {
        Routes.home: (context) => HomePage(),
        Routes.timetable: (context) => TimeTablePage(),
        Routes.session: (context) => SessionPage(),
        Routes.export: (context) => ExportDB(),
        Routes.notification: (context) => NotificationPage(),
      },
    );
  }
}


class MainPage extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  StreamSubscription _intentDataStreamSubscription;
  List<SharedMediaFile> _sharedFiles =[];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) async{
          setState(() {
            _sharedFiles = value;
            if(_sharedFiles.length!=0)
              Navigator.push(context, MaterialPageRoute(builder: (context) => ExportDB(path:_sharedFiles[0].path)));
          });
        }, onError: (err) {
        });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) async{
      setState(() {
        _sharedFiles = value;
        if(_sharedFiles.length!=0)
          Navigator.push(context, MaterialPageRoute(builder: (context) => ExportDB(path:_sharedFiles[0].path)));
      });
    });

    /*if (notificationAppLaunchDetails.didNotificationLaunchApp ?? false) {
      selectedNotificationPayload = notificationAppLaunchDetails.payload;
      Navigator.push(context, MaterialPageRoute(builder: (context) => SessionPage()));
    }*/

  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomePage();
  }
}
