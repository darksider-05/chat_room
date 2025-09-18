import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers.dart';


class PageC extends StatefulWidget {
  const PageC({super.key});

  @override
  State<PageC> createState() => _PagecState();
}

class _PagecState extends State<PageC> {
  Socket? clsocket;

  @override
  void initState() {
    super.initState();
    final host = context.read<Server>();
    final general = context.read<General>();
    final nav = context.read<PageIndex>();
    startclient(host, general, nav);
  }

  void startclient(Server host, General general, PageIndex nav) async{
    try{
    clsocket = await Socket.connect(general.current["ip"], general.current["port"]);
    clsocket?.listen((data){
      final message = utf8.decode(data);
      final decoded = json.decode(message);
      if (decoded["hint"] == "update"){
        host.sethistory(decoded["content"]);
      }
    }, onDone: (){
      clsocket?.close();
      general.current.clear();
      nav.changepage(2);
    });
  }catch(e){}}


  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.shortestSide;
    var height = MediaQuery.of(context).size.longestSide;
    bool isver = MediaQuery.of(context).orientation == Orientation.portrait;

    var truewidth = isver ? width : height;
    var trueheight = isver ? height : width;
    final general = context.watch<General>();
    final nav = context.watch<PageIndex>();
    final host = context.watch<Server>();


    return Stack(
      children: [


        // main part
        Container(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: trueheight*0.09,),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: host.history.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.teal,
                                ),
                                child: Align(
                                  alignment: Alignment.center,

                                  child: Text(
                                    host.history[host.history.length - index - 1],
                                    style: TextStyle(
                                      fontSize:
                                      truewidth > 1500
                                          ? 30
                                          : truewidth > 1000
                                          ? 25
                                          : truewidth > 800
                                          ? 22
                                          : 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: trueheight * 0.028),
                        ],
                      );
                    },
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 150),
                      width:
                      general.isEmpty
                          ? truewidth * 85 / 100
                          : truewidth * 75 / 100,
                      child: TextField(
                        onChanged: general.update,
                        controller: general.tec,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 5),

                    AnimatedContainer(
                      duration:
                      general.isEmpty
                          ? Duration(milliseconds: 100)
                          : Duration(milliseconds: 235),
                      child: GestureDetector(
                        child:
                        !general.isEmpty
                            ? Container(
                          width: truewidth * 0.045,
                          height: trueheight * 0.045,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.send,
                            color: Colors.black38,
                          ),
                        )
                            : Container(),
                        onTap: (){
                          clsocket?.write(utf8.encode(jsonEncode({"hint":"submit", "content":general.tec.text})));
                        },
                      ),
                    ),
                    SizedBox(height: truewidth * 0.05),
                  ],
                ),
              ],
            ),
          ),
        ),
        // back button
        Positioned(
          top: trueheight * 7 / 100 + 10,
          left: 15,
          child: GestureDetector(
            onTap: () {
              nav.changepage(2);
              clsocket?.write(utf8.encode(jsonEncode({"hint":"terminate"})));
            },
            child: Container(
              width: min(width, height) / 10,
              height: min(width, height) / 10,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black12
              ),
              child: Center(
                child: Icon(Icons.arrow_back_outlined, color: Colors.black45),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
