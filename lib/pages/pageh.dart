import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../providers.dart';

class PageH extends StatefulWidget {
  PageH({super.key});

  @override
  State<PageH> createState() => _PageHState();
}

class _PageHState extends State<PageH> {
  HttpServer? _httpserver;
  RawDatagramSocket? _udpserver;
  StreamSubscription? _broadcastudp;

  final List<WebSocketChannel> _clients = [];


  @override
  void dispose() {
    for (final client in _clients) {
      client.sink.close();
    }


    _httpserver?.close(force: true);
    _udpserver?.close();
    _broadcastudp?.cancel();
    super.dispose();
  }





  @override
  void initState() {
    super.initState();
    final host = context.read<Host>();
    final general = context.read<General>();
    starthost(host, general);
  }







  void _broadcastHistory(Host host) {

    final message =
        json.encode({"hint": "update", "content": host.history});
    for (final client in _clients) {

        client.sink.add(message);

    }
  }

  void starthost(Host host, General general) async {
    try {
      var selfip = await NetworkInfo().getWifiIP() ?? "0.0.0.0";
      // 1. Define the handler for WebSocket connections
      final handler = webSocketHandler((WebSocketChannel channel, _) {
        // A new client has connected!
        setState(() {
          _clients.add(channel);
        });

        // Send the current chat history to the new client
        final initialMessage = json.encode({"hint": "update", "content": host.history});
        channel.sink.add(initialMessage);

        channel.stream.listen(
                (message) {
              final decoded = jsonDecode(message);
              if (decoded["hint"] == "submit") {
                host.add(decoded["content"]);
                _broadcastHistory(host); // Broadcast the new history to all
              }
            },

            // 3. Handle the client disconnecting
            onDone: () {
              setState(() {
                _clients.remove(channel);
              });
              host.add("one left");
              _broadcastHistory(host);
            },
            onError: (error) {
              // Handle errors and remove the client
              setState(() {
                _clients.remove(channel);
              });
            }
        );
      });
      // 4. Create a pipeline and start the server
      final pipeline = const Pipeline().addHandler(handler);
      _httpserver = await shelf_io.serve(pipeline, InternetAddress.anyIPv4, 2021);

          _udpserver = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _udpserver!.broadcastEnabled = true;
      final broadcastaddress = InternetAddress("255.255.255.255");

      _broadcastudp = Stream.periodic(Duration(seconds: 2)).listen((_) {
        final announcement = jsonEncode({
          "hint": "discovery",
          "ip": selfip,
          "port": _httpserver!.port,
        });
        _udpserver!.send(utf8.encode(announcement), broadcastaddress, 2120);
      });
    } catch (e) {
      // ✨ Use your error provider to show errors to the user
      general.seterror("Host Error: ${e.toString()}");
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
    final host = context.watch<Host>();

    return Stack(
      children: [
        // Main Part
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: host.history.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.teal.shade100,
                        ),
                        child: Text(
                          host.history[host.history.length - 1 - index],
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: general.tec,
                        onChanged: general.update,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    if (!general.isEmpty)
                      FloatingActionButton(
                        mini: true,
                        child: Icon(Icons.send),
                        onPressed: () {
                          if (general.tec.text.isNotEmpty) {
                            host.add(general.tec.text);
                            _broadcastHistory(host); // Broadcast the update
                            general.cleantec(); // Clear the text field
                          }
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Back button and Error display... (UI code unchanged)
        // back button
        Positioned(
          top: trueheight * 7 / 100 + 10,
          left: 15,
          child: GestureDetector(
            onTap: () {
              nav.changepage(0);
            },
            child: Container(
              width: min(width, height) / 10,
              height: min(width, height) / 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black12,
              ),
              child: Center(
                child: Icon(Icons.arrow_back_outlined, color: Colors.black45),
              ),
            ),
          ),
        ),
        // ...
        general.error != ""
            ? Container(
              color: Colors.grey,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Center(child: Text(general.error)),
            )
            : Container(),
      ],
    );
  }
}
