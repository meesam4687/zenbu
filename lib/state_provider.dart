import 'package:flutter/material.dart';

class StateProvider extends ChangeNotifier {
  Map alData = {};
  Map animeDiscoveryData = {};
  Map mangaDiscoveryData = {};
  void updateData(newData) {
    alData = newData;
    notifyListeners();
  }

  void updateDiscoveryData(newData) {
    animeDiscoveryData = newData;
    notifyListeners();
  }

  void updateMangaDiscoveryData(newData) {
    mangaDiscoveryData = newData;
    notifyListeners();
  }
}
