import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionPage extends StatefulWidget {
  static const String routeName = '/session';
  @override
  _SessionPageState createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {

  var _nameController = TextEditingController();
  var _linkController = TextEditingController();
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  var update=false;
  var uSession ;
  var ready=false;

  var sessions = {};//{'DMDW':'DMDW1','ES':'ES1','Maths':'Maths1','PIS':'PIS1'};
  var links = {};/*{
    'DMDW': 'https://meet.google.com/vrr-ppbk-fqm',
    'ES': 'https://meet.google.com/dzu-gztb-dac',
    'Maths': 'https://meet.google.com/vsv-hgrm-dkg',
    'PIS': 'https://meet.google.com/jhj-vdps-orw',
  };*/

  var timeTable ={};
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkSharedPref();
  }

  Future<void>  checkSharedPref() async{
    final SharedPreferences prefs = await _prefs;

    var link = prefs.getString('links')??'';
    var sess = prefs.getString('sessions')??'';
    var tt = prefs.getString('timetable')??'';
    //print('Initial Session --$link \n==$sess \n++$tt');
    if(link.length!=0)
      setState(() {
        links = jsonDecode(link);
      });
    if(sess.length!=0)
      setState(() {
        sessions = jsonDecode(sess);
      });
    if(tt.length!=0)
      setState(() {
        timeTable = jsonDecode(tt);
      });
    setState(() {
      ready=true;
    });
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
          title: Text('Sessions'),
        ),
          body: (ready)?Container(
            //padding: EdgeInsets.fromLTRB(8, 10, 8, 10),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom:70.0),
                child: Column(
                  children: sessionListWidget(),
                ),
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
          ),
          floatingActionButton: Visibility(
            visible: !keyboardIsOpen,
            child: FloatingActionButton.extended(
              label: const Text('Session'),
              icon: Icon(Icons.add_box_outlined,size: 35,),
              onPressed:()=> sessionAddWidget(),
            ),
          ),

          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        ),
    );
    }

    List<Widget> sessionListWidget(){
      List<Widget> list = [];
      sortSession();

      links.forEach((key, value) {
        list.add(sessionWidget(key, value));
      });
      return list;
    }

    Widget sessionWidget(sessionName, sessionLink){
      Widget widget = (update==true && uSession==sessionName)?
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
                    TextFormField(
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: new InputDecoration(
                        labelText: "Session Name",
                        fillColor: Colors.white,
                        isDense: true,
                        border: new OutlineInputBorder(
                          borderRadius: new BorderRadius.circular(25.0),
                          borderSide: new BorderSide(
                          ),
                        ),
                        //fillColor: Colors.green
                      ),
                      validator: (val) {
                        if(val.length==0) {
                          return "Name cannot be empty";
                        }else{
                          return null;
                        }
                      },
                      controller: _nameController,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 20,),
                    TextFormField(
                      decoration: new InputDecoration(
                        labelText: "Session Link",
                        fillColor: Colors.white,
                        isDense: true,
                        border: new OutlineInputBorder(
                          borderRadius: new BorderRadius.circular(25.0),
                          borderSide: new BorderSide(
                          ),
                        ),
                        //fillColor: Colors.green
                      ),
                      validator: (val) {
                        if(val.length==0) {
                          return "Link cannot be empty";
                        }else{
                          return null;
                        }
                      },
                      controller: _linkController,
                      keyboardType: TextInputType.url,
                    ),

                  ],
                ),
              ),
            ),
            Column(
              children: [
                InkWell(
                  onTap:() {
                    if(update==true)
                      setState((){
                        saveSession(sessionName);
                        update=false;
                      });
                  },
                  child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.save_outlined,)
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
                      child: Icon(Icons.cancel_outlined,color: Theme.of(context).errorColor,)
                  ),
                ),
              ],
            ),
          ],
        ),
      ):
      GestureDetector(
        onLongPress: (){

          Clipboard.setData(new ClipboardData(text: sessionLink)).then((result){
            final snackBar = SnackBar(
              behavior: SnackBarBehavior.floating,elevation: 6,
              margin: EdgeInsets.all(10),
              content: Center(heightFactor: 1,child: Text('${sessions[sessionName]} Link Copied')),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          });
        },
        child: Container(
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
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 3*MediaQuery.of(context).size.width/4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessions[sessionName],
                      style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 5,),
                    Text(
                      sessionLink,
                      style: TextStyle(fontSize: 18),
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
                          _nameController=TextEditingController(text: sessions[sessionName]);
                          _linkController=TextEditingController(text: sessionLink);
                          uSession=sessionName;
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
                    onTap:() => deleteDialog(sessionName),
                    child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delete_outline,color: Theme.of(context).errorColor,)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      return widget;
    }
    dynamic sessionAddWidget(){
      if(update==false) {
        setState(() {
          update = false;
          _nameController = TextEditingController(text: '');
          _linkController = TextEditingController(text: '');
        });
        _displayTextInputDialog(context);
      }
      else{
        final snackBar = SnackBar(
          behavior: SnackBarBehavior.floating,elevation: 6,
          margin: EdgeInsets.all(10),
          content: Center(heightFactor: 1,child: Text('Save the current Session Details')),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }

    void saveSession(var session) async{
      final SharedPreferences prefs = await _prefs;
      var newName = _nameController.text.toString().trim();
      if(newName == sessions[session]) {
        setState(()  {
          links[session] = _linkController.text.toString().trim();
          sortSession();
        });
        await prefs.setString('links', jsonEncode(links));
      }
      else{
        setState(() {
          links[session]= _linkController.text.toString().trim();
          sessions[session]=newName;
          sortSession();
        });
        await prefs.setString('links', jsonEncode(links));
        await prefs.setString('sessions', jsonEncode(sessions));
      }
    }

    void sortSession(){
      links=SplayTreeMap.from(
          links, (key1, key2) => key1.compareTo(key2));
      sessions=SplayTreeMap.from(
          sessions, (key1, key2) => key1.compareTo(key2));
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
                            child: Text('Delete $session',
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
                                links.remove(session);
                                sessions.remove(session);
                                timeTable.forEach((day, classList) {
                                  for(int i=0;i<classList.length;i++)
                                    if(classList[i]['name']==session)
                                      timeTable[day][i]['name']='Free';
                                });

                              });
                              final SharedPreferences prefs = await _prefs;
                              await prefs.setString('links', jsonEncode(links));
                              await prefs.setString('sessions', jsonEncode(sessions));
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


    Future<void> _displayTextInputDialog(BuildContext context) async {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.fromLTRB(30, 20, 30, 20),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Add Session',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                            textAlign: TextAlign.center,),
                          SizedBox(height: 30,),
                          TextFormField(
                            //autofocus: true,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: new InputDecoration(
                              labelText: "Session Name",
                              fillColor: Colors.white,
                              isDense: true,
                              border: new OutlineInputBorder(
                                borderRadius: new BorderRadius.circular(25.0),
                                borderSide: new BorderSide(
                                ),
                              ),
                              //fillColor: Colors.green
                            ),
                            validator: (val) {
                              if(val.length==0) {
                                return "Name cannot be empty";
                              }else{
                                return null;
                              }
                            },
                            controller: _nameController,
                            keyboardType: TextInputType.text,
                          ),
                          SizedBox(height: 20,),
                          TextFormField(
                            decoration: new InputDecoration(
                              labelText: "Session Link",
                              fillColor: Colors.white,
                              isDense: true,
                              border: new OutlineInputBorder(
                                borderRadius: new BorderRadius.circular(25.0),
                                borderSide: new BorderSide(
                                ),
                              ),
                              //fillColor: Colors.green
                            ),
                            validator: (val) {
                              if(val.length==0) {
                                return "Link cannot be empty";
                              }else{
                                return null;
                              }
                            },
                            controller: _linkController,
                            keyboardType: TextInputType.url,
                          ),

                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          MaterialButton(
                            onPressed: ()=>Navigator.pop(context),
                            splashColor: Colors.red[100],
                            child: Text('Cancel',style: TextStyle(color: Colors.red[400],fontSize: 17),),
                          ),
                          MaterialButton(
                            onPressed: ()async{
                              var newName=_nameController.text.toString().trim();
                              var newLink=_linkController.text.toString().trim();
                              if(newName.length!=0 && newLink.length!=0) {
                                setState(() {
                                  if(links[newName]==null) {
                                    if(sessions[newName]!=newName) {
                                      links[newName] = newLink;
                                      sessions[newName]=newName;
                                      sortSession();
                                    }
                                    else{
                                      final snackBar = SnackBar(
                                        behavior: SnackBarBehavior.floating,elevation: 6,
                                        margin: EdgeInsets.all(10),
                                        content: Center(heightFactor: 1,child: Text('Session Name Already Present')),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                    }
                                  }
                                  else{
                                    final snackBar = SnackBar(
                                      behavior: SnackBarBehavior.floating,elevation: 6,
                                      margin: EdgeInsets.all(10),
                                      content: Center(heightFactor: 1,child: Text('${sessions[newName]} has the same ID')),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                  }
                                });
                                print(links);
                                final SharedPreferences prefs = await _prefs;
                                await prefs.setString('links', jsonEncode(links));
                                await prefs.setString('sessions', jsonEncode(sessions));
                                Navigator.pop(context);
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
            );
          });
    }

  }
