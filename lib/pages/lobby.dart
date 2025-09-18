import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers.dart';

class ServerList extends StatelessWidget {
  const ServerList({super.key});

  void scout(Server host, General general) async {
    general.setbusy(true);
    host.hosts.clear();
    try{
    RawDatagramSocket udplistener = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      2120,
      reuseAddress: true,
      reusePort: true,
    );
    udplistener.broadcastEnabled = true;

    udplistener.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = udplistener.receive();
        if (datagram != null) {
          final message = utf8.decode(datagram.data);
          final decoded = jsonDecode(message);
          if (decoded["hint"] == "discovery") {
            host.discovered(decoded["ip"], decoded["port"]);
          }
        }
      }
    });

    Future.delayed(Duration(milliseconds: 1500), () {
      udplistener.close();
      general.setbusy(false);
    });
  }catch(e){}}

  @override
  Widget build(BuildContext context) {
    final general = context.watch<General>();
    final nav = context.watch<PageIndex>();
    final host = context.watch<Server>();

    var width = MediaQuery.of(context).size.shortestSide;
    var height = MediaQuery.of(context).size.longestSide;
    bool isver = MediaQuery.of(context).orientation == Orientation.portrait;
    var truewidth = isver ? width : height;
    var trueheight = isver ? height : width;

    return Stack(
      children: [
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
                color:Colors.black12,
              ),
              child: Center(
                child: Icon(Icons.arrow_back_outlined, color: Colors.black45),
              ),
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: trueheight * 0.09),
            Expanded(
              child: ListView.builder(
                itemCount: host.hosts.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    child: Container(
                      width: truewidth * 0.6,
                      height: trueheight * 0.15,
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "${host.hosts[index]["ip"]}:${host.hosts[index]["port"]}",
                        ),
                      ),
                    ),

                    onTap: () {
                      general.getserver(
                        host.hosts[index]["ip"],
                        host.hosts[index]["port"],
                      );
                      host.hosts.clear();
                      nav.changepage(3);
                    },
                  );
                },
              ),
            ),

            SizedBox(
              height: trueheight * 0.1,
              width: truewidth * 0.5,
              child: FittedBox(
                child: FloatingActionButton(
                  onPressed:
                      !(general.busy)
                          ? () {
                            scout(host, general);
                          }
                          : null,
                  child: Text("Refresh", style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
