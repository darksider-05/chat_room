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

  @override
  void dispose() {
    // Gracefully disconnect when leaving the page
    try {
      final terminateMessage = jsonEncode({"hint": "terminate"}) + '\n';
      clsocket?.write(terminateMessage);
      clsocket?.flush();
      clsocket?.destroy();
    } catch (e) {
      print("Error on dispose: $e");
    }
    super.dispose();
  }

  void startclient(Server host, General general, PageIndex nav) async {
    try {
      clsocket = await Socket.connect(general.current["ip"], general.current["port"], timeout: Duration(seconds: 5));

      // ✨ Use LineSplitter to correctly handle incoming messages
      utf8.decoder.bind(clsocket!).transform(const LineSplitter()).listen((line) {
        try {
          final decoded = json.decode(line);
          if (decoded["hint"] == "update") {
            // ✨ FIX: Cast the incoming list to the correct type
            final historyList = (decoded["content"] as List).cast<String>();
            host.sethistory(historyList);
          }
        } catch (e) {
          // This can happen if a malformed JSON is received
          print("Error decoding server message: $e");
        }
      }, onDone: () {
        general.seterror("Host disconnected.");
        nav.changepage(2);
      }, onError: (error) {
        general.seterror("Connection Error: ${error.toString()}");
        nav.changepage(2);
      });

    } catch (e) {
      // ✨ Use your error provider to show errors to the user
      general.seterror("Connection Failed: ${e.toString()}");
      nav.changepage(2); // Go back if connection fails
    }
  }

  void _sendMessage() {
    final general = context.read<General>();
    if (general.tec.text.isEmpty || clsocket == null) return;

    try {
      // Add a newline character for data framing
      final message = jsonEncode({"hint": "submit", "content": general.tec.text}) + '\n';
      clsocket?.write(message);
      clsocket?.flush(); // Ensure data is sent immediately
      general.update(""); // Clear the text field
    } catch (e) {
      general.seterror("Failed to send message: ${e.toString()}");
    }
  }





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
                        controller: general.tec,
                        onChanged: general.update,
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
                          _sendMessage();
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
              clsocket?.write(utf8.encode(jsonEncode({"hint":"terminate"}) + "\n"));
              clsocket?.flush();
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


          general.error != ""?Container(
          color: Colors.grey,
    width: MediaQuery.of(context).size.width,
    height: MediaQuery.of(context).size.height,
    child: Center(
    child: Text(general.error),
    ),
    ):Container()
      ],
    );
  }
}
