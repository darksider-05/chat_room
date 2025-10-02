import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';

import '../providers.dart';

class ServerList extends StatefulWidget {
  ServerList({super.key});

  @override
  State<ServerList> createState() => _ServerListState();
}

class _ServerListState extends State<ServerList> {
  RawDatagramSocket? _udpclient;

  void start(Host host) async {
    _udpclient = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _udpclient?.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = _udpclient?.receive();
        if (dg != null) {
          final msg = utf8.decode(dg.data);
          final lst = msg.split("|").toList();
          if (lst[0] == "pong") {
            final target = lst[1];
            host.discovered(target, 2021);
          }
        }
      }
    });
  }

  Future<void> scout(General general) async {
    general.busy = true;
    final selfip = await NetworkInfo().getWifiIP() ?? "0.0.0.0";
    var iplist = selfip.split(".").toList();
    iplist = iplist.sublist(0, 3);
    final subnet = iplist.join(".");

    await Future.forEach<int>(List.generate(254, (i) => i + 1), (sub) async {
      _udpclient?.send(
        utf8.encode("ping"),
        InternetAddress("$subnet.$sub"),
        2022,
      );
      await Future.delayed(Duration(milliseconds: 5));
    });
    general.busy = false;
  }

  @override
  void initState() {
    super.initState();
    final host = context.read<Host>();
    start(host);
  }

  @override
  Widget build(BuildContext context) {
    final general = context.watch<General>();
    final nav = context.watch<PageIndex>();
    final host = context.watch<Host>();

    var width = MediaQuery.of(context).size.shortestSide;
    var height = MediaQuery.of(context).size.longestSide;
    bool isver = MediaQuery.of(context).orientation == Orientation.portrait;
    var truewidth = isver ? width : height;
    var trueheight = isver ? height : width;

    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: trueheight * 0.09),
            Expanded(
              child: ListView.builder(
                itemCount: host.hosts.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: GestureDetector(
                      child: Container(
                        width: truewidth * 0.5,
                        height: trueheight * 0.1,
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              "${host.hosts[index]["ip"]}:${host.hosts[index]["port"]}",
                              style: TextStyle(fontSize: 17),
                            ),
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
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              height: trueheight * 0.1,
              width: truewidth * 0.5,
              child: FloatingActionButton.extended(
                onPressed:
                    !(general.busy)
                        ? () {
                          scout(general);
                        }
                        : null,
                label: Text("Refresh", style: TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),

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
