import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'main.dart';

class NotificationClass{

  Future<void> setNotification({id,dayInt, hour,min,sessionName}) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        '$sessionName Session in 5 min',
        'Open Session Now',
        //tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
        _nextInstanceOfMondayTenAM(dayInt: dayInt,hour: hour,min: min),
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
    print(scheduledDate);
    return scheduledDate;
  }


  Future<void> cancelAllNotification() async{
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(id) async{
    await flutterLocalNotificationsPlugin.cancel(id);
  }

}