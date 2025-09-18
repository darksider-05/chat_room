import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers.dart';

class Page0 extends StatelessWidget {
  const Page0({super.key});

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.shortestSide;
    var height = MediaQuery.of(context).size.longestSide;
    bool isver = MediaQuery.of(context).orientation == Orientation.portrait;
    final nav = context.watch<PageIndex>();
    return Row(
      spacing: 0,
      children: [

        GestureDetector(
          child: Container(
            color: Colors.red,
            padding: EdgeInsets.all(10),
            width: isver? width/2: height/2,
            height: isver ? height:width,
            child: Column(
              spacing: 0,
              mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [SizedBox(width: isver? width: height), Text("Join", style: TextStyle(fontSize: 40),)]),
          ),


          onTap: (){
            nav.changepage(2);
          },
        ),
        GestureDetector(
          child: Container(
            color: Colors.blue,
            padding: EdgeInsets.all(10),
            width: isver? width/2: height/2,
            height: isver ? height:width,
            child: Column(
              spacing: 0,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [SizedBox(width: isver? width: height), Text("Host", style: TextStyle(fontSize: 40),)],
            ),
          ),


          onTap: (){
            nav.changepage(1);
          },
        ),
        //Container(height: height,)
      ],
    );
  }
}
