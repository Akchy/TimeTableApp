
import 'dart:convert';

import '../../module/timeTablePage/day_time_table.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimeTablePage extends StatefulWidget {
  static const String routeName = '/edit';
  @override
  _TimeTablePageState createState() => _TimeTablePageState();
}

class _TimeTablePageState extends State<TimeTablePage> {

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  var ready =true;
  var timeTable = {};
  var sessionNames ={};// {'ES':'ES1','Maths':'Maths1','PIS':'PIS1'};

  @override
  void initState() {
    super.initState();
    checkSharedPref();
  }

  Future<void>  checkSharedPref() async{
    final SharedPreferences prefs = await _prefs;

    var tt = prefs.getString('timetable')??'';
    var sess = prefs.getString('sessions')??'';
    if(tt.length!=0)
      setState(() {
        timeTable = jsonDecode(tt);
      });
    if(sess.length!=0)
      setState(() {
        sessionNames = jsonDecode(sess);
      });
    setState(() {
      ready=true;
    });
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async{
        Navigator.pop(context,true);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Edit Time Table"),
        ),
        body: (ready)?SingleChildScrollView(
          child: Container(
            child: Column(
              children:editClassDayWise(),
            ),
          ),
        ):
            Container(
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
            )
      ),
    );
  }

  List<Widget> editClassDayWise(){
    List<Widget> widgetDayWise =[];

    timeTable.forEach((day,ttList) {
      widgetDayWise.add(editWidget(day,ttList));
    });
    return widgetDayWise;
  }

  Widget editWidget(day,ttList){
    return Container(
      margin: EdgeInsets.all(9),
      padding: EdgeInsets.symmetric(vertical: 8),
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
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 4,
            offset: Offset(1, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12,8,12,8),
            child: Row(
              mainAxisAlignment: (ttList.length==0)?MainAxisAlignment.start:MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(day,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                    (ttList.length==0)?
                    InkWell(
                      onTap: ()async{
                        var flag =await Navigator.push(context,
                          MaterialPageRoute(builder: (context) => DayTimeTable(day: day,add:false)),)??false;
                        if(flag==true)
                          checkSharedPref();
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add_box_outlined,)),
                    ):
                    InkWell(
                      onTap: ()async{
                        var flag =await Navigator.push(context,
                          MaterialPageRoute(builder: (context) => DayTimeTable(day: day,add:true)),)??false;
                        if(flag==true)
                          checkSharedPref();
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit_outlined)),
                    ) ,
                  ],
                ),
                if (ttList.length!=0) InkWell(
                  child: InkWell(
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete_outline,color: Theme.of(context).errorColor,)
                    ),
                  ),
                  onTap: ()=>deleteDialog(day),
                )
                else SizedBox(width: 0,)
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8,right: 8,bottom: 8),
            child: IgnorePointer(
              child: (ttList.length!=0)?GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: weekManage(ttList),
                childAspectRatio: 1.8,
              ):
              freeDayWidget(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> weekManage(list){
    List<Widget> tt=[];

    for (var classes in list) {
      tt.add(classContainer(classes));
    }
    return tt;
  }

  Widget classContainer(var currClass){
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10)
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(top:8.0),
            child: Text(
              sessionNames[currClass['name']],
              style: TextStyle(fontSize: 18,color:Colors.white,),
              textAlign: TextAlign.justify,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom:8.0,left: 3,right: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${currClass['sTime']} - ${currClass['eTime']}',style: TextStyle(color: Colors.white),)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget freeDayWidget(){
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 100,
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10)
        ),
      ),
      child: Center(child: Text('Hola! A free Day.',style: TextStyle(fontSize: 20),)),
    );
  }

  void deleteDialog(day){
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
                          child: Text('Delete $day',
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
                            setState(() {
                              timeTable[day]=[];
                            });
                            Navigator.pop(context);
                            final SharedPreferences prefs = await _prefs;
                            await prefs.setString('timetable', jsonEncode(timeTable));
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
}
