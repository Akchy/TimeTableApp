import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:save_in_gallery/save_in_gallery.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExportDB extends StatefulWidget {
  static const String routeName = '/export';
  final String path;
  const ExportDB({Key key, this.path}) : super(key: key);
  @override
  _ExportDBState createState() => _ExportDBState();
}

class _ExportDBState extends State<ExportDB> {

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final _imageSaver =  ImageSaver();

  GlobalKey globalKey = new GlobalKey();
  String _dataString = 'Class Time';
  var import = false;
  var path='';
  var _data;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(widget.path.length!=0) {
      setState(() {
        import=true;
        path = widget.path;
        decode(path);
      });

    }
    else{
      getSharedPref();
    }
  }

  void getSharedPref()async{
    final SharedPreferences prefs = await _prefs;

    var tt = prefs.getString('timetable')??'';
    var link = prefs.getString('links')??'';
    var sess = prefs.getString('sessions')??'';
    setState(() {
      _dataString = jsonEncode({'timetable':tt,'links':link,'sessions':sess});
    });
  }

  Future decode(String file) async {
    try {
      String tempData = await QrCodeToolsPlugin.decodeFrom(file);
      setState(() {
        _data = tempData;
        _data = jsonDecode(_data);
      });
    }
    catch(e){
      setState(() {
        path='';
      });
    }
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
          title: (!import)?Text('Export'):Text('Import'),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20,),
              Padding(
                padding: const EdgeInsets.only(left:20.0),
                child: Text((!import)?'Export Time Table':'Import Time Table',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 25),),
              ),
              SizedBox(height: 10,),
              Container(
                height: MediaQuery.of(context).size.width,
                margin: EdgeInsets.all(10),
                color: Colors.black,
                child: (!import)? RepaintBoundary(
                  key: globalKey,
                  child: QrImage(
                    gapless: true,
                    backgroundColor: Colors.white,
                    data: _dataString,
                    size: MediaQuery.of(context).size.width,
                  ),
                ):
                (path.length!=0)?Container(
                  alignment: Alignment.center,
                  height: MediaQuery.of(context).size.width,
                  child: Column(
                    children: [
                      Image.file(File(path)),
                    ],
                  ),
                ):Center(child: Text('Not a Valid QR',style: TextStyle(color: Colors.white,fontSize: 25),))
                ,
              ),

              SizedBox(height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if(!import)button('Share'),
                  if(!import)button('Download'),
                  if(import)button('Import'),
                ],
              ),

              SizedBox(height: 20,),

              if(!import)Container(
                margin: EdgeInsets.all(8),
                padding: EdgeInsets.fromLTRB(20,10,10,25),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                  children: [
                    Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 30,right: 30,bottom: 15,top: 10),
                            child: Text('Import',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),),
                          ),
                          Divider(color: Colors.grey,thickness: 1,height: 0,),
                          Padding(
                            padding: const EdgeInsets.only(left: 30,right: 25,top: 15),
                            child: Text(
                              '-> Select QR from Gallery (Any App)\n'
                                  '-> Share the QR\n'
                                  '-> Select Class Time App\n'
                                  '-> Press Import',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20,)

            ],
          ),
        ),
      ),
    );
  }

  Widget button(text){
    return GestureDetector(
      onTap: (){
        if(text=='Share')
          shareQR();
        else if(text=='Download')
          downloadQR();
        else if(text=='Import' && path.length!=0)
          importDB();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 5,horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2.0),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(.6),
                spreadRadius: 1,
                blurRadius: 1, // changes position of shadow
                offset: Offset(0,1)
            ),
          ],
          color: Colors.blue,
        ),
        child: Row(
          children: [
            Text(text,style: TextStyle(color: Colors.white),),
            SizedBox(width: 15,),
            if(text=='Share')Icon(Icons.share_outlined,color: Colors.white,),
            if(text=='Download')Icon(Icons.download_outlined,color: Colors.white,),
            if(text=='Import')Icon(Icons.add_to_queue,color: Colors.white,),
          ],
        ),
      ),
    );
  }


  Future<void> shareQR() async {
    try {
      RenderRepaintBoundary boundary = globalKey.currentContext.findRenderObject();
      var image = await boundary.toImage(pixelRatio: 2.0);
      ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await new File('${tempDir.path}/image.png').create();
      await file.writeAsBytes(pngBytes);

      final RenderBox box = context.findRenderObject();
      Share.shareFile(File('${tempDir.path}/image.png'),
          subject: 'Share Time Table',
          text: "Here's My Class Time Table",
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size
      );
    }
    catch(e) {
    }
  }

  Future<void> downloadQR()async{
    RenderRepaintBoundary boundary = globalKey.currentContext.findRenderObject();
    var image = await boundary.toImage(pixelRatio: 2.0);
    ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    List<Uint8List> bytesList = [];
    bytesList.add(pngBytes);

    await _imageSaver.saveImages(
        imageBytes: bytesList,
        directoryName: 'Time Table'
    );

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,elevation: 6,
      margin: EdgeInsets.all(10),
      duration: Duration(seconds: 5),
      content: Center(heightFactor: 1,child: Text('Time Table Downloaded')),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }


  void importDB() async{

    await deleteDialog();

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,elevation: 6,
      margin: EdgeInsets.all(10),
      duration: Duration(seconds: 5),
      content: Center(heightFactor: 1,child: Text('Time Table Imported')),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    Navigator.pop(context);
  }

  Future<void> deleteDialog(){
    return showDialog(
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
                          child: Text('Import New Time Table',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 30,right: 25,top: 15),
                          child: Text(
                            'Once imported, old time table and sessions will be lost!',
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
                          splashColor: Colors.red[100],
                          child: Text('Cancel',style: TextStyle(color: Colors.red[400],fontSize: 17),),
                        ),
                        MaterialButton(
                          onPressed: ()async{
                            var tempTT = _data['timetable'];
                            var tempSession = _data['sessions'];
                            var tempLink = _data['links'];

                            final SharedPreferences prefs = await _prefs;
                            await prefs.clear();
                            await prefs.setString('timetable', tempTT);
                            await prefs.setString('links', tempLink);
                            await prefs.setString('sessions',tempSession);
                            Navigator.pop(context);
                          },
                          splashColor: Colors.blue[100],
                          child: Text('Import',style: TextStyle(color: Colors.lightBlue[400],fontSize: 17),),
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
