import 'package:flutter/material.dart';

class StateProvider extends ChangeNotifier {
  Map alData = {};
  Map animeDiscoveryData = {};

  void updateData(newData) {
    alData = newData;
    notifyListeners();
  }

  void updateDiscoveryData(newData) {
    animeDiscoveryData = newData;
    notifyListeners();
  }
}
