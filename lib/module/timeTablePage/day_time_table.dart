import 'dart:convert';

import 'package:class_time/strToTime.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:class_time/notification.dart';

class DayTimeTable extends StatefulWidget {

  final String day;
  final bool add;
  const DayTimeTable({Key key, this.day,this.add}) : super(key: key);

  @override
  _DayTimeTableState createState() => _DayTimeTableState();
}

class _DayTimeTableState extends State<DayTimeTable> {


  var links = {};/*{
    'DMDW': 'https://meet.google.com/vrr-ppbk-fqm',
    'ES': 'https://meet.google.com/dzu-gztb-dac',
    'Maths': 'https://meet.google.com/vsv-hgrm-dkg',
    'PIS': 'https://meet.google.com/jhj-vdps-orw',
  };*/

  var sessions = {};//{'ES':'ES1','Maths':'Maths1','PIS':'PIS1','Free':'Free1'};
  var timeTable = {};/*{
    'Monday':[
      {
        'name':'DMDW',
        'sTime':'8:30',
        'eTime':'9:20'
      },
      {
        'name':'ES',
        'sTime':'9:30',
        'eTime':'10:20'
      },
      {
        'name':'PIS',
        'sTime':'10:30',
        'eTime':'11:20'
      },
      {
        'name':'Maths',
        'sTime':'11:40',
        'eTime':'12:30'
      },
      {
        'name':'Free',
        'sTime':'12:40',
        'eTime':'13:30'
      },
    ],
    'Tuesday':[
      {
        'name':'ES',
        'sTime':'8:30',
        'eTime':'9:20'
      },
      {
        'name':'DMDW',
        'sTime':'9:30',
        'eTime':'10:20'
      },
      {
        'name':'Free',
        'sTime':'10:30',
        'eTime':'11:20'
      },
      {
        'name':'Maths',
        'sTime':'11:40',
        'eTime':'12:30'
      },
      {
        'name':'PIS',
        'sTime':'12:40',
        'eTime':'13:30'
      },
    ],
    'Wednesday':[
      {
        'name':'Free',
        'sTime':'8:30',
        'eTime':'9:20'
      },
      {
        'name':'PIS',
        'sTime':'9:30',
        'eTime':'10:20'
      },
      {
        'name':'DMDW',
        'sTime':'10:30',
        'eTime':'11:20'
      },
      {
        'name':'Maths',
        'sTime':'11:40',
        'eTime':'12:30'
      },
      {
        'name':'ES',
        'sTime':'12:40',
        'eTime':'13:30'
      },
    ],
  };*/

  var week = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  var newStartTime, newEndTime;

  var update=false;
  var uTimeIndex ;
  var day;
  var sTime=[],eTime=[],sessionList=<String>[];
  var dropdownValue;
  var ttClass=[];
  var uIndex;
  var addSession=false;
  var sessionNames = <String>[];
  var ready=false;

  @override
  void initState() {
    super.initState();
    day = widget.day;
    checkSharedPref();
    setState(() {
      addSession=widget.add;
    });
    if(addSession)
      sessionAddFunction();

  }

  Future<void>  checkSharedPref() async{
    final SharedPreferences prefs = await _prefs;

    var tt = prefs.getString('timetable')??'';
    var link = prefs.getString('links')??'';
    var sess = prefs.getString('sessions')??'';
    if(tt.length!=0)
      setState(() {
        timeTable = jsonDecode(tt);
      });
    if(link.length!=0)
      setState(() {
        links = jsonDecode(link);
      });
    if(sess.length!=0)
      setState(() {
        sessions = jsonDecode(sess);
      });
    setState(() {
      ready=true;
    });
    ttClass = timeTable[day];

    sessions.forEach((key, value) {sessionNames.add(key);});
  }

  @override
  Widget build(BuildContext context) {
    bool keyboardIsOpen = MediaQuery.of(context).viewInsets.bottom != 0;
    return WillPopScope(
      onWillPop: () async{
        Navigator.pop(context,true);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("$day's Time Table"),
        ),
        body:(ready)?Container(
          //padding: EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Align(
            alignment:  (addSession)?Alignment.center:Alignment.topCenter,
            child: Stack(
              children: [
                if(!addSession)(ttClass.length!=0)?SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom:70.0),
                    child: Column(
                      children: ttListWidget(),
                    ),
                  ),
                ):
                Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width*3/4,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Add your Time Table, I'm Empty", style: TextStyle(fontSize: 15),),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: Divider(thickness: 2,),
                        ),
                        SizedBox(height: 8,),
                        Text("Don't forget to add your session in Sessions Tab")
                      ],
                    ),
                  ),
                )
                else addNewSession()
              ],
            ),
          ),
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
        floatingActionButton: (!addSession)?Visibility(
          visible: (!keyboardIsOpen||addSession),
          child: FloatingActionButton.extended(
            label: const Text('Session'),
            icon: Icon(Icons.add_box_outlined,size: 35,),
            onPressed:()=>sessionAddFunction(),
          ),
        ):null,

        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  List<Widget> ttListWidget(){
    List<Widget> ttWidget = [];

    for(var tt in ttClass){
      ttWidget.add(sessionWidget(tt,ttClass.indexOf(tt)));
    }
    return ttWidget;
  }

  Widget sessionWidget(session,index){
    Widget widget = (update==true && uIndex==index)?
    Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.fromLTRB(20,10,10,25),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomAppBarColor,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10)
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
      child:Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right:8.0,top: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    children: [
                      Text('Name: ',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                      SizedBox(width: 15,),
                      DropdownButton<String>(
                        value: dropdownValue,
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                        elevation: 16,
                        underline: Container(
                          height: 2,
                          color: Theme.of(context).primaryColorDark,
                        ),
                        onChanged: (String newValue) {
                          setState(() {
                            dropdownValue=newValue;
                          });
                        },
                        items: sessionNames
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  SizedBox(height: 15,),
                  Row(
                    children: [
                      Expanded(
                          child: MaterialButton(
                            onPressed: () async {
                              var tempTime = newStartTime;
                              TimeOfDay time = TimeOfDay(hour:int.parse(tempTime.split(":")[0]),minute: int.parse(tempTime.split(":")[1]));
                              FocusScope.of(context).requestFocus(new FocusNode());

                              TimeOfDay picked =
                              await showTimePicker(context: context, initialTime: time);
                              if (picked != null) {
                                newStartTime = '${picked.hour}:${picked.minute}';
                              }
                            },
                            child: Text(newStartTime,style: TextStyle(color: Colors.white),),
                            color: Theme.of(context).highlightColor,
                          ),
                      ),
                      SizedBox(width: 20,),
                      Expanded(
                        child:MaterialButton(
                          onPressed: () async {
                            var tempTime = newEndTime;
                            TimeOfDay time = TimeOfDay(hour:int.parse(tempTime.split(":")[0]),minute: int.parse(tempTime.split(":")[1]));
                            FocusScope.of(context).requestFocus(new FocusNode());

                            TimeOfDay picked =
                            await showTimePicker(context: context, initialTime: time);
                            if (picked != null) {
                              newEndTime= '${picked.hour}:${picked.minute}';
                            }
                          },
                          child: Text(newEndTime,style: TextStyle(color: Colors.white),),
                          color: Theme.of(context).highlightColor,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              InkWell(
                onTap:() {
                  var sTemp = StrToTime().convert(newStartTime);
                  var eTemp = StrToTime().convert(newEndTime);    // Checking if end time is greater than less time
                  if (sTemp<eTemp) {
                    if(update==true)
                      setState((){
                        saveSession(session);
                        update=false;
                      });
                  }
                  else{
                    final snackBar = SnackBar(
                      behavior: SnackBarBehavior.floating,elevation: 6,
                      margin: EdgeInsets.all(10),
                      duration: Duration(seconds: 5),
                      content: Center(heightFactor: 1,child: Text('End Time Should Be Greater Than Start Time')),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                },
                child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.save_outlined)
                ),
              ),
              GestureDetector(
                onTap:() {
                  if(update==true)
                    setState((){
                      update=false;
                    });
                },
                child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.cancel_outlined,color: Theme.of(context).errorColor)
                ),
              ),
            ],
          ),
        ],
      ),
    ):
    Container(
      //width: double.infinity,
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.fromLTRB(20,10,10,10),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomAppBarColor,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10)
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
      child:Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 3*MediaQuery.of(context).size.width/4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sessions[session['name']],
                      style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(width: 10,),
                    Text(
                      '[ ${session['sTime']} - ',
                      style: TextStyle(fontSize: 18,),
                      textAlign: TextAlign.justify,
                    ),
                    Text(
                      '${session['eTime']} ]',
                      style: TextStyle(fontSize: 18,),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
                SizedBox(height: 5,),
                Text(
                  links[session['name']]??'',
                  style: TextStyle(fontSize: 18,),
                  textAlign: TextAlign.justify,
                )
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap:() {
                  if(update==false)
                    setState(() {
                      update=true;
                      dropdownValue=session['name'];
                      newStartTime= session['sTime'];
                      newEndTime=session['eTime'];
                      uIndex=index;
                    });
                  else{
                    final snackBar = SnackBar(
                      behavior: SnackBarBehavior.floating,elevation: 6,
                      margin: EdgeInsets.all(10),
                      duration: Duration(seconds: 5),
                      content: Center(heightFactor: 1,child: Text('Save the current Session Details')),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                },
                child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit_outlined,)),
              ),
              GestureDetector(
                onTap:() => deleteDialog(session),
                child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_outline,color: Theme.of(context).errorColor)),
              ),
            ],
          ),
        ],
      ),
    );
    return widget;
  }

  void saveSession(var session)  async{
    var sessionIndex = timeTable[day].indexOf(session);
    var newSession = session;
    newSession['name']=dropdownValue;
    newSession['sTime']=newStartTime;
    newSession['eTime']=newEndTime;
    setState(() {
      timeTable[day][sessionIndex]=newSession;
    });

    timeTable[day].sort((a,b){
      var aNum = StrToTime().convert(a['sTime']);
      var bNum = StrToTime().convert(b['sTime']);
      if(aNum>bNum)
        return 1;
      else
        return 0;

    });
    await NotificationClass().cancelAllNotification();
    timeTable.forEach((key, value) async{
      if(value.length!=0) {
        for (var session in value) {
          if(session['name']!='Free') {
            var time = session['sTime'];
            var dayInt = week.indexOf(key) + 1;
            var hour = time.split(":")[0];
            var min = time.split(":")[1];
            var id = (dayInt * 100) + value.indexOf(session);
            await NotificationClass().setNotification(id: id,
                sessionName: session['name'],
                hour: int.parse(hour),
                min: int.parse(min),
                dayInt: dayInt);
          }
        }
      }
    });
    final SharedPreferences prefs = await _prefs;
    await prefs.setString('timetable', jsonEncode(timeTable));

  }

  void deleteDialog(session){
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: Colors.grey[800],
              ),
              height: 170,
              child: Column(
                children: [
                  Container(
                    height: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 30,right: 30),
                          child: Text("Delete ${sessions[session['name']]}'s Hour",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 30,right: 25,top: 15),
                          child: Text(
                            'Once deleted, can not be retrieved. Are you sure you want to delete?',
                            style: TextStyle(color: Colors.white60),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey,thickness: 0,height: 0,),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        MaterialButton(
                          onPressed: ()=>Navigator.pop(context),
                          splashColor: Colors.blue[100],
                          child: Text('Cancel',style: TextStyle(color: Colors.lightBlue[400],fontSize: 17),),
                        ),
                        MaterialButton(
                          onPressed: ()async{
                            var index = timeTable[day].indexOf(session);
                            setState(() {
                              update=false;
                              timeTable[day].remove(session);
                            });
                            var id = 100*(week.indexOf(day)+1) + index;
                            await NotificationClass().cancelNotification(id);
                            final SharedPreferences prefs = await _prefs;
                            await prefs.setString('timetable', jsonEncode(timeTable));
                            Navigator.pop(context);
                          },
                          splashColor: Colors.red[100],
                          child: Text('Delete',style: TextStyle(color: Colors.red[400],fontSize: 17),),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  dynamic sessionAddFunction()async{


    if(update==false) {
      setState(() {
        addSession = true;
        dropdownValue = links[0];
        var time = TimeOfDay.now();
        newStartTime = '${time.hour}:${time.minute}';
        newEndTime = '${time.hour}:${time.minute}';
      });

      final SharedPreferences prefs = await _prefs;
      await prefs.setString('timetable', jsonEncode(timeTable));
    }
    else{
      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,elevation: 6,
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 5),
        content: Center(heightFactor: 1,child: Text('Save the current Session Details')),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Widget addNewSession(){
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Container(
            padding: EdgeInsets.fromLTRB(30, 20, 30, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              color: Theme.of(context).bottomAppBarColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        children: [
                          Text('Name: ',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                          SizedBox(width: 15,),
                          DropdownButton<String>(
                            value: dropdownValue,
                            icon: const Icon(Icons.arrow_drop_down),
                            iconSize: 24,
                            elevation: 16,
                            underline: Container(
                              height: 2,
                              color: Colors.black,
                            ),
                            onChanged: (String newValue) {
                              setState(() {
                                dropdownValue=newValue;
                              });
                            },
                            items: sessionNames
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(sessions[value]),
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                      SizedBox(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Note to add new Session: \nGoto Sessions in Menu > Create Session', style: TextStyle(fontSize: 13),textAlign: TextAlign.center,),
                        ],
                      ),
                      SizedBox(height: 10,),
                      Row(
                        children: [
                          Expanded(
                            child: MaterialButton(
                              onPressed: () async {
                                TimeOfDay time =TimeOfDay.now();
                                FocusScope.of(context).requestFocus(new FocusNode());

                                TimeOfDay picked =
                                await showTimePicker(context: context, initialTime: time);
                                if (picked != null) {
                                  newStartTime = '${picked.hour}:${picked.minute}';
                                }
                              },
                              child: Text(newStartTime,style: TextStyle(color: Colors.white),),
                              color: Theme.of(context).highlightColor,
                            ),
                          ),
                          SizedBox(width: 10,),
                          Text('-',style: TextStyle(fontSize: 15),),
                          SizedBox(width: 10,),
                          Expanded(
                            child:MaterialButton(
                              onPressed: () async {
                                TimeOfDay time =TimeOfDay.now();
                                FocusScope.of(context).requestFocus(new FocusNode());

                                TimeOfDay picked =
                                await showTimePicker(context: context, initialTime: time);
                                if (picked != null) {
                                  newEndTime = '${picked.hour}:${picked.minute}';
                                }
                              },
                              child: Text(newEndTime,style: TextStyle(color: Colors.white),),
                              color: Theme.of(context).highlightColor,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20,),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      MaterialButton(
                        onPressed: (){
                          setState(() {
                            addSession=false;
                          });
                        },
                        splashColor: Colors.red[100],
                        child: Text('Cancel',style: TextStyle(color: Colors.red[400],fontSize: 17),),
                      ),
                      MaterialButton(
                        onPressed: ()async{
                          var sTemp = StrToTime().convert(newStartTime);
                          var eTemp = StrToTime().convert(newEndTime);  // Checking if end time is greater than less time
                          if (sTemp<eTemp && dropdownValue!=null) {
                            Map<String,String> newSession={};
                            newSession['name']=dropdownValue;
                            newSession['sTime']=newStartTime;
                            newSession['eTime']=newEndTime;
                            setState(() {
                              timeTable[day].add(newSession);
                              timeTable[day].sort((a,b){
                                var aNum = StrToTime().convert(a['sTime']);
                                var bNum = StrToTime().convert(b['sTime']);
                                if(aNum>bNum)
                                  return 1;
                                else
                                  return 0;

                              });
                              addSession=false;
                            });
                            await NotificationClass().cancelAllNotification();
                            timeTable.forEach((key, value) async{
                              if(value.length!=0) {
                                for (var session in value) {
                                  if(session['name']!='Free') {
                                    var time = session['sTime'];
                                    var dayInt = week.indexOf(key) + 1;
                                    var hour = time.split(":")[0];
                                    var min = time.split(":")[1];
                                    var id = (dayInt * 100) + value.indexOf(session);
                                    await NotificationClass().setNotification(id: id,
                                        sessionName: session['name'],
                                        hour: int.parse(hour),
                                        min: int.parse(min),
                                        dayInt: dayInt);
                                  }
                                }
                              }
                            });
                            final SharedPreferences prefs = await _prefs;
                            await prefs.setString('timetable', jsonEncode(timeTable));
                          }
                          else if(dropdownValue==null){

                            final snackBar = SnackBar(
                              behavior: SnackBarBehavior.floating,elevation: 6,
                              margin: EdgeInsets.all(10),
                              duration: Duration(seconds: 5),
                              content: Center(heightFactor: 1,child: Text('Select a Session')),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(snackBar);
                          }
                          else{
                            final snackBar = SnackBar(
                              behavior: SnackBarBehavior.floating,elevation: 6,
                              margin: EdgeInsets.all(10),
                              duration: Duration(seconds: 5),
                              content: Center(heightFactor: 1,child: Text('End Time Should Be Greater Than Start Time')),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(snackBar);
                          }


                        },
                        splashColor: Colors.blue[100],
                        child: Text('Add',style: TextStyle(color: Colors.lightBlue[400],fontSize: 17),),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  
}
