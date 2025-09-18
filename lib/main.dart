import 'package:chat_room/pages/page0.dart';
import 'package:chat_room/pages/pageh.dart';
import 'package:chat_room/pages/pagec.dart';
import 'package:chat_room/pages/lobby.dart';
import 'package:chat_room/providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PageIndex()),
        ChangeNotifierProvider(create: (_) => General()),
        ChangeNotifierProvider(create: (_) => Host()),
      ],
      child: Mt(),
    ),
  );
}

class Mt extends StatelessWidget {
  const Mt({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Sc());
  }
}

class Sc extends StatelessWidget {
  const Sc({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<PageIndex>();
    return Scaffold(
      body: switch (nav.index) {
        0 => Page0(),
        1 => PageH(),
        2 => ServerList(),
        3 => PageC(),
        _ => GestureDetector(
          onTap: () {
            nav.changepage(0);
          },
        ),
      },
    );
  }
}
