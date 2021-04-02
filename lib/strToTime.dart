import 'package:flutter/material.dart';

class StrToTime {

  int convert(var str){
    TimeOfDay _startTime = TimeOfDay(hour:int.parse(str.split(":")[0]),minute: int.parse(str.split(":")[1]));
    int strMin = _startTime.hour *60+ _startTime.minute;  //Converting to min
    return strMin;
  }
}