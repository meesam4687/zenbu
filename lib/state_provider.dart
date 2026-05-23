import 'package:flutter/material.dart';

class StateProvider extends ChangeNotifier {
  Map alData = {};
  Map animeDiscoveryData = {};
  Map mangaDiscoveryData = {};
  Map currentAnimeFilters = {
    "selectedGenres": <String>{},
    "selectedTags": <String>{},
    "releaseYear": null,
    "countryOfOrigin": "",
    "season": "",
    "format": "",
    "airingStatus": "",
    "sourceMaterial": "",
  };
  Map currentMangaFilters = {
    "selectedGenres": <String>{},
    "selectedTags": <String>{},
    "releaseYear": null,
    "countryOfOrigin": "",
    "format": "",
    "airingStatus": "",
    "sourceMaterial": "",
  };
  void updateData(Map newData) {
    alData = newData;
    notifyListeners();
  }

  void clearAnimeFilters() {
    currentAnimeFilters = {
      "selectedGenres": <String>{},
      "selectedTags": <String>{},
      "releaseYear": null,
      "countryOfOrigin": "",
      "season": "",
      "format": "",
      "airingStatus": "",
      "sourceMaterial": "",
    };
    notifyListeners();
  }

  void clearMangaFilters() {
    currentMangaFilters = {
      "selectedGenres": <String>{},
      "selectedTags": <String>{},
      "releaseYear": null,
      "countryOfOrigin": "",
      "format": "",
      "airingStatus": "",
      "sourceMaterial": "",
    };
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

  void clearNotifications() {
    final viewer = (alData["data"] is Map) ? alData["data"]["Viewer"] : null;
    if (viewer is Map && viewer.containsKey("unreadNotificationCount")) {
      viewer["unreadNotificationCount"] = 0;
      notifyListeners();
    }
  }
}
