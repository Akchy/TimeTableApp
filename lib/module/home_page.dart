import 'dart:convert';

import '../routes/Routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import 'export_page.dart';

class HomePage extends StatefulWidget {
  static const String routeName = '/home';
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {



   /*var links = {
     'DMDW': 'https://meet.google.com/vrr-ppbk-fqm',
     'ES': 'https://meet.google.com/dzu-gztb-dac',
     'Maths': 'https://meet.google.com/vsv-hgrm-dkg',
     'PIS': 'https://meet.google.com/jhj-vdps-orw',
   };
   var sessions = {'DMDW':'DMDW1','ES':'ES1','Maths':'Maths1','PIS':'PIS1','Free':'Free1'};
   var timeTable={
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
     'Thursday':[],
     'Friday':[],
     'Saturday':[],
     'Sunday':[]
   };*/

  var timeTable={};
  var sessions ={};
  var links = {};
   Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  var tempTT = {'Monday':[],'Tuesday':[],'Wednesday':[],'Thursday':[],'Friday':[],'Saturday':[],'Sunday':[]};
  var tempSession = {'Free':'Free'};
  var timingColor=[];
  var week = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  var classes,ttDay;
  List<Widget> tt = [];
  var day;
  var freeDay=0;
  String dropdownValue;
  var currDay;
  var breakTime=false;
  var ready=false;

  @override
  void initState() {
    super.initState();


    day = DateFormat('EEEE').format(DateTime.now());
    currDay = day;

    checkSharedPref();
  }

  Future<void>  checkSharedPref() async{
    final SharedPreferences prefs = await _prefs;
    //await prefs.clear();
   /* await prefs.clear();
    await prefs.setString('timetable', jsonEncode(timeTable));
    await prefs.setString('links', jsonEncode(links));
    await prefs.setString('sessions', jsonEncode(sessions));

*/
    var tt = prefs.getString('timetable')??'';
    var link = prefs.getString('links')??'';
    var sess = prefs.getString('sessions')??'';

    if(tt.length!=0) {
      setState(() {
        timeTable = jsonDecode(tt);
      });
    }
    else{
      tt = jsonEncode(tempTT);
      await prefs.setString('timetable', jsonEncode(tempTT));
    }
    if(link.length!=0)
      setState(() {
        links = jsonDecode(link);
      });
    if(sess.length!=0)
      setState(() {
        sessions = jsonDecode(sess);
      });
    else {
      sess = jsonEncode(tempSession);
      await prefs.setString('sessions', jsonEncode(tempSession));
    }
    setState(() {
      ready=true;
    });

    ttDay = timeTable[day];
    dropdownValue=day;
    if(ttDay==null || ttDay.length==0){
      setState(() {
        freeDay =1;
      });
      dropdownValue=day;
    }
    else {
      setState(() {
        freeDay =0;
      });
      initialTimeColor();
      timeColorAllot();
      Timer.periodic(Duration(seconds: 5), (Timer t) => timeColorAllot());  // Check every 5 sec for change in timetable

    }
  }
  int strToTime(var str){
    TimeOfDay _startTime = TimeOfDay(hour:int.parse(str.split(":")[0]),minute: int.parse(str.split(":")[1]));
    int strMin = _startTime.hour *60+ _startTime.minute;  //Converting to min
    return strMin;
  }

  void initialTimeColor(){
    for (var i=0;i<ttDay.length;i++)
      timingColor.insert(i, -1);
  }

  void timeColorAllot(){

    if(currDay==day && freeDay==0){
      TimeOfDay now = TimeOfDay.now();
      int currentTime = now.hour * 60 + now.minute; //Current Time in Min

      var sTimeToday=[],eTimeToday=[];
      for(var x in ttDay){
        sTimeToday.add(x['sTime']);
        eTimeToday.add(x['eTime']);
      }
      var dayEndTime = strToTime(eTimeToday[eTimeToday.length-1]);
      for (var start in sTimeToday ){
        var sessionTime = strToTime(start);
        var sessionIndex = sTimeToday.indexOf(start);
        var endTime = eTimeToday[sessionIndex];
        var sessionEndTime = strToTime(endTime);
        if(sessionTime <= currentTime && currentTime<= dayEndTime){
          if(sessionEndTime >= currentTime)
            setState(() {
              timingColor[sessionIndex] = 1;    //Current Hour
            });
          else
            setState(() {
              timingColor[sessionIndex] = 0;    //Past Hour
            });
        }
        else
          setState(() {
            timingColor[sessionIndex] = 2;    //Upcoming Hour
          });
      }
      var breakFound=1,sessionStarted=0;
      for(var x in timingColor){
        if(x==0) {
          sessionStarted = 1;
        }
        if(x==1) {
          breakFound = 0;
        }
      }
      if(sessionStarted==1 && breakFound==1 && currentTime<dayEndTime)
        setState(() {
          breakTime=true;
        });
      else
        setState(() {
          breakTime=false;
        });
    }
    else{
      setState(() {
        breakTime=false;
        if(freeDay==0)
        initialTimeColor();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Text('Class Time', style: TextStyle(color: Colors.white,fontSize: 20),),
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
              ),
              ListTile(
                  title: Text('Home',style: TextStyle(color: Colors.black),),
                  leading: Icon(Icons.home,color: Colors.black,),
                  onTap: ()=>Navigator.pop(context)
              ),
              ListTile(
                  title: Text('Sessions',style: TextStyle(color: Colors.black),),
                  leading: Icon(Icons.book_online,color: Colors.black,),
                  onTap: ()async{
                    Navigator.pop(context);
                    var flag =await Navigator.pushNamed(context, Routes.session)??false;
                    if(flag==true)
                      checkSharedPref();
                  }
              ),
              ListTile(
                  title: Text('Time Table',style: TextStyle(color: Colors.black),),
                  leading: Icon(Icons.edit_outlined,color: Colors.black,),
                  onTap: ()async{
                    Navigator.pop(context);
                    var flag =await Navigator.pushNamed(context, Routes.timetable)??false;
                    if(flag==true) {
                      checkSharedPref();
                    }
                  }
              ),

              ListTile(
                  title: Text('Export',style: TextStyle(color: Colors.black),),
                  leading: Icon(Icons.share_outlined,color: Colors.black,),
                  onTap: ()async{
                    Navigator.pop(context);
                    var flag =await
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ExportDB(path:'')))??false;
                    if(flag==true) {
                      checkSharedPref();
                    }
                  }
              ),
              Divider(),
              ListTile(
                title: Text('By Davish <3'),
              )
            ],
          ),
        ),
        appBar: AppBar(
          title: Text('Time Table'),
        ),
        body: (ready)?Container(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10,),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0,0,10,10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$day',
                          style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,),
                        ),
                        DropdownButton<String>(
                          value: dropdownValue,
                          icon: const Icon(Icons.arrow_downward),
                          iconSize: 24,
                          elevation: 16,
                          underline: Container(
                            height: 2,
                            color: Colors.black,
                          ),
                          onChanged: (String newValue) {
                            setState(() {
                              dropdownValue = newValue;
                              day=newValue;
                              ttDay = timeTable[newValue];
                              if(ttDay==null || ttDay.length==0){
                                freeDay=1;
                              }
                              else
                                freeDay=0;
                              timeColorAllot();
                            });
                          },
                          items: week
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8,right: 8),
                    child: (freeDay==0)?GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: weekManage(),
                      childAspectRatio: 1.7,
                    ):
                    freeDayWidget(),
                  ),
                  SizedBox(height: 10,),
                  if(breakTime==true)
                    Container(
                      width: MediaQuery.of(context).size.width,
                      margin: EdgeInsets.all(8),
                      padding: EdgeInsets.fromLTRB(00,20,0,20),
                      decoration: BoxDecoration(
                        color: Colors.black,
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
                            blurRadius: 7, // changes position of shadow
                          ),
                        ],
                      ),
                      child: Center(child: Text('Break Time',style: TextStyle(color: Colors.white),)),
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
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.blue),
                  backgroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 10.0),
              Text('Loading',style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w400,
                  fontSize: 18.0
              ),)
            ],
          ),
        )
    );
  }

  Widget freeDayWidget(){
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height/4,
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.fromLTRB(20,0,10,20),
      decoration: BoxDecoration(
        color: Colors.yellow[800],
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
            blurRadius: 7, // changes position of shadow
          ),
        ],
      ),
      child: Center(child: Text('Hola! A free Day.',style: TextStyle(fontSize: 30),)),
    );
  }

  List<Widget> weekManage(){
    tt=[];
    for (classes in ttDay) {
      tt.add(classContainer(classes,timingColor[ttDay.indexOf(classes)]));
    }
    return tt;
  }

  Widget classContainer(var currClass,var color){
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          color: (color==0)?Colors.red:(color==1)?Colors.green:Colors.blue,
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
              blurRadius: 7, // changes position of shadow
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top:8.0),
              child: Text(
                sessions[currClass['name']],
                style: TextStyle(fontSize: 18,color:Colors.white,),
                textAlign: TextAlign.justify,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom:8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${currClass['sTime']} - ${currClass['eTime']}',style: TextStyle(color: Colors.white),)
                ],
              ),
            ),
          ],
        ),
      ),
      onTap: ()async{
        var link = links[currClass['name']];
        if(link!=-1)
        await launch(link);
      },
    );
  }


}
