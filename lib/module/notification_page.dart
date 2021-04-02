import 'dart:convert';

import 'package:class_time/notification.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../main.dart';

class NotificationPage extends StatefulWidget {
  static const String routeName = '/notification';
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  var week = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  bool notification = false;
  var notifMap =
    {'1 min':1,
    '2 mins':2,
    '5 mins':5,
    '10 mins':10};
  var notifList = ['1 min','2 mins','5 mins','10 mins'];
  var dropdownValue='5 mins';
  var changed =false;
  var ready=false;
  var timetable={};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkSharedPref();
  }

  void checkSharedPref() async{
    final SharedPreferences prefs = await _prefs;

    var notif = prefs.getBool('notification')??false;
    var notifBefore = prefs.getInt('notifTime')??5;
    var tt = prefs.getString('timetable')??'';

    if(tt.length!=0)
      setState(() {
        timetable=jsonDecode(tt);
      });

    setState(() {
      notification=notif;
      ready=true;
      dropdownValue = notifMap.keys.firstWhere((key) => notifMap[key] == notifBefore);
    });

  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        Navigator.pop(context,changed);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Notifications'),
        ),
        body: (ready)?Container(
          padding: EdgeInsets.symmetric(vertical: 8,horizontal: 12),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).bottomAppBarColor,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4)
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.4),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: Offset(1, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Notification',style: TextStyle(fontSize: 17),),
                      Switch(
                        onChanged: (value) async{
                          setState(() {
                            notification=value;
                            if(notification)
                              setNotification();
                            else
                              NotificationClass().cancelAllNotification();
                          });
                          final SharedPreferences prefs = await _prefs;
                          prefs.setBool('notification',value);
                        },
                        value: notification,
                      )
                    ],
                  ),
                ),
                SizedBox(height: 20,),
                if(notification)Container(
                  width: double.maxFinite,
                  padding: EdgeInsets.symmetric(horizontal: 20,vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).bottomAppBarColor,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4)
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.4),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: Offset(1, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notifications_active_outlined),
                          SizedBox(width: 15,),
                          Text('Notify Before'),
                        ],
                      ),DropdownButton<String>(
                        value: dropdownValue,
                        icon: const Icon(Icons.arrow_drop_down),
                        elevation: 16,

                        underline: Container(
                          height: 2,
                          color: Colors.transparent,
                        ),
                        onChanged: (String newValue) async{
                          setState(() {
                            dropdownValue=newValue;
                            changed=true;
                          });
                          setNotification();
                          final SharedPreferences prefs = await _prefs;
                          prefs.setInt('notifTime',notifMap[newValue]);

                          final snackBar = SnackBar(
                            behavior: SnackBarBehavior.floating,elevation: 6,
                            margin: EdgeInsets.all(10),
                            duration: Duration(seconds: 1),
                            content: Center(heightFactor: 1,child: Text('Time Updated')),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        },
                        items: notifList
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value,style: TextStyle(fontSize: 14),),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ):Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColorLight),
                  backgroundColor: Colors.transparent,
                ),
              ),
              SizedBox(height: 10.0),
              Text('Loading',style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 18.0
              ),)
            ],
          ),
        ),
      ),
    );
  }

  void setNotification() {
    timetable.forEach((key, value) {
      if(value.length!=0) {
        for (var session in value) {
          var time = session['sTime'];
          var dayInt = week.indexOf(key) + 1;
          var hour = time.split(":")[0];
          var min = time.split(":")[1];
          var id = (dayInt*100)+value.indexOf(session);
          NotificationClass().setNotification(id:id,sessionName: session['name'], hour: int.parse(hour),min: int.parse(min),dayInt: dayInt);
        }
      }
    });
  }

}
