import 'package:flutter/material.dart';

class StateProvider extends ChangeNotifier {
  Map alData = {};
  Map animeDiscoveryData = {};
  Map mangaDiscoveryData = {};
  String? loginToken;
  void updateData(Map newData) {
    alData = newData;
    notifyListeners();
  }

  void updateDiscoveryData(Map newData) {
    animeDiscoveryData = newData;
    notifyListeners();
  }

  void updateMangaDiscoveryData(Map newData) {
    mangaDiscoveryData = newData;
    notifyListeners();
  }

  void updateAuthToken(String? token) {
    loginToken = token;
    notifyListeners();
  }
}
