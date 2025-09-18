

import 'dart:io';

import 'package:flutter/material.dart';


class PageIndex extends ChangeNotifier{
int _page_index = 0;
int get index => _page_index;

void changepage(int target){
  _page_index = target;
  notifyListeners();
}
}


class Server extends ChangeNotifier{
  List<String> history = [];
  List<Socket> clients = [];
  List<Map> hosts = [];


  void discovered(String ip, int port){
    hosts.add(
        {
          "ip" : ip,
          "port": port
        }
    );
    notifyListeners();
  }

  void add(String msg){
    history.add(msg);
    notifyListeners();
  }

  void sethistory(List<String> newh){
    history = newh;
    notifyListeners();
  }
}

class General extends ChangeNotifier{
  TextEditingController tec = TextEditingController();
  bool busy = false;
  Map current = {};
  String error = "";

  void seterror(String e){
    error = e;
    notifyListeners();
  }
  void update(String newText) {
    notifyListeners();
  }

  void setbusy (bool tobe){
    busy = tobe;
    notifyListeners();
  }

  void getserver (String ip, int port) {
    current = {"ip":ip, "port":port};
    notifyListeners();
  }

  bool get isEmpty => tec.text.isEmpty;
}


