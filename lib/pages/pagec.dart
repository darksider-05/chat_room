import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../providers.dart';

class PageC extends StatefulWidget {
  const PageC({super.key});

  @override
  State<PageC> createState() => _PagecState();
}

class _PagecState extends State<PageC> {
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    final host = context.read<Host>();
    final general = context.read<General>();
    final nav = context.read<PageIndex>();
    startclient(host, general, nav);
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  void startclient(Host host, General general, PageIndex nav) async {
    try {
      final ip = general.current["ip"];
      final port = general.current["port"];

      // 1. Connect using the 'ws://' URI scheme
      _channel = IOWebSocketChannel.connect('ws://$ip:$port');
      // 2. Listen for messages from the server
      _channel?.stream.listen(
              (message) {
            final decoded = json.decode(message);
            if (decoded["hint"] == "update") {
              final historyList = (decoded["content"] as List).cast<String>();
              host.sethistory(historyList);
            }
          },
          onDone: () {
            general.seterror("Host disconnected.");
            nav.changepage(2);
          },
          onError: (error) {
            general.seterror("Connection Error: ${error.toString()}");
            nav.changepage(2);
          }
      );

    } catch (e) {
      general.seterror("Failed to connect: ${e.toString()}");
      nav.changepage(2);
    }
  }

  void _sendMessage() {
    final general = context.read<General>();
    if (general.tec.text.isEmpty || _channel == null) return;

    // 3. Send a message - it's this simple!
    final message = jsonEncode({"hint": "submit", "content": general.tec.text});
    _channel?.sink.add(message);

    general.cleantec(); // Clear the text field
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
    final host = context.watch<Host>();


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
