import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'main.dart';

class NotificationClass{

  Future<void> setNotification({id,dayInt, hour,min,sessionName}) async {


    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    final SharedPreferences prefs = await _prefs;
    var tempMinusMin = prefs.getInt('notifTime')??5;

    var tempHour =hour ;
    var tempMin = min;
    var tempDay = dayInt;
    if((tempMin - tempMinusMin) < 0){
      if(tempHour ==0){
        if(tempDay==1){
          tempDay=7;
        }
        else
          tempDay--;
        tempHour=23;
      }
      else{
        tempHour--;
      }
      tempMin = 60 + tempMin - tempMinusMin;
    }
    else{
      tempMin -= tempMinusMin;
    }
    await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        '$sessionName Session in 5 min',
        'Open Session Now',
        //tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
        _nextInstanceOfMondayTenAM(dayInt: tempDay,hour: tempHour,min: tempMin),
        const NotificationDetails(
            android: AndroidNotificationDetails(
                '3174',
                'FullScreen',
                'FullScreenDesc',
                priority: Priority.high,
                importance: Importance.high,
                ticker: 'ticker')),
        payload: sessionName,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);

  }


  tz.TZDateTime _nextInstanceOfTenAM({hour,min}) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour,min);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }


  tz.TZDateTime _nextInstanceOfMondayTenAM({dayInt,hour,min}) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTenAM(hour: hour,min:min);
    while (scheduledDate.weekday != dayInt) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }


  Future<void> cancelAllNotification() async{
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(id) async{
    await flutterLocalNotificationsPlugin.cancel(id);
  }

}