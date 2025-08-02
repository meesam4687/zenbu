import 'package:flutter/material.dart';

class StateProvider extends ChangeNotifier {
  Map alData = {};

  void updateData(newData) {
    alData = newData;
    notifyListeners();
  }
}
