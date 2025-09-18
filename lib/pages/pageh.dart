import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';

import '../providers.dart';





class PageH extends StatefulWidget {
  PageH({super.key});

  @override
  State<PageH> createState() => _PageHState();
}

class _PageHState extends State<PageH> {


  @override
  void initState() {
    super.initState();
    final host = context.read<Server>();

    starthost(host);
  }



  @override
  void dispose() {
    final host = context.read<Server>();
    for (Socket c in host.clients){
      c.destroy();
    }
    host.clients.clear();

    _server?.close();
    _udpserver?.close();
    _broadcastudp?.cancel();


    super.dispose();
  }


  ServerSocket? _server;
  RawDatagramSocket? _udpserver;
  StreamSubscription? _broadcastudp;


  void starthost(Server host) async {
    var selfip = await NetworkInfo().getWifiIP() ?? "0.0.0.0";
    try{
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 2021);
    _server!.listen((client) {
      host.clients.add(client);

      client.write(json.encode({"hint":"update", "content":host.history}));

      client.listen((data) {
        var message = utf8.decode(data);
        var decoded = jsonDecode(message);
        if (decoded["hint"] == "submit") {
          host.history.add(decoded["content"]);
          for (Socket c in host.clients) {
            c.write(json.encode({"hint": "update", "content": host.history}));
          }
        } else if (decoded["hint"] == "terminate") {
          host.clients.remove(client);
          client.close();
        }
      });
    });

    _udpserver = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
    );
    _udpserver!.broadcastEnabled = true;
    final broadcastaddress = InternetAddress("255.255.255.255");

    _broadcastudp = Stream.periodic(Duration(seconds: 2)).listen((_) {
      final announcement = jsonEncode({
        "hint": "discovery",
        "ip": selfip,
        "port": _server!.port,
      });

      _udpserver!.send(utf8.encode(announcement), broadcastaddress, 2120);
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
                                  borderRadius: BorderRadius.circular(40),
                                  color: Colors.teal,
                                ),
                                child: Align(
                                  alignment: Alignment.center,

                                  child: Text(
                                    host.history[host.history.length -
                                        index -
                                        1],
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
                          host.add(general.tec.text);
                          for (Socket c in host.clients) {
                            c.write(json.encode({"hint": "update", "content": host.history}));
                          }
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
              nav.changepage(0);
              general.update("");
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
