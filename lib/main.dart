
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'module/export_page.dart';
import 'module/home_page.dart';
import 'module/session_page.dart';
import 'module/timeTablePage/time_table_page.dart';
import 'routes/Routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(new MyApp());
  });
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
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
        cardColor: Colors.yellow[800]

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
      themeMode: ThemeMode.system,
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
