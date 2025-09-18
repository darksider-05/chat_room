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
    final general = context.read<General>();
    starthost(host, general);
  }

  @override
  void dispose() {
    final host = context.read<Server>();
    for (Socket c in host.clients) {
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

  // ✨ Helper function to broadcast updates to all clients
  void _broadcastHistory(Server host) {
    // Add a newline character for data framing
    final message =
        json.encode({"hint": "update", "content": host.history}) + '\n';
    for (Socket c in host.clients) {
      try {
        c.write(message);
        c.flush(); // Ensure data is sent immediately
      } catch (e) {
        // Handle error if a client socket is dead
        print("Error writing to client: $e");
      }
    }
  }

  void starthost(Server host, General general) async {
    try {
      var selfip = await NetworkInfo().getWifiIP() ?? "0.0.0.0";
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, 2021);

      _server!.listen((client) {
        host.clients.add(client);

        // Send initial history to the new client
        final initialMessage =
            json.encode({"hint": "update", "content": host.history}) + '\n';
        client.write(initialMessage);
        client.flush();

        // ✨ Use LineSplitter to handle incoming data correctly
        utf8.decoder
            .bind(client)
            .transform(const LineSplitter())
            .listen(
              (line) {
                try {
                  var decoded = jsonDecode(line);
                  if (decoded["hint"] == "submit") {
                    host.history.add(decoded["content"]);
                    _broadcastHistory(host); // Broadcast the new history to all
                  }
                } catch (e) {
                  print("Error decoding client message: $e");
                }
              },
              onDone: () {
                host.clients.remove(client);
                host.history.add("one left");
                _broadcastHistory(host);
              },
              onError: (error) {
                host.clients.remove(client);
              },
            );
      });

      _udpserver = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
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
    final host = context.watch<Server>();

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
                            general.update(""); // Clear the text field
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
              general.update("");
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
