import 'package:flutter/material.dart';

class StateProvider extends ChangeNotifier {
  Map _alData = {};
  Map _animeDiscoveryData = {};
  Map _mangaDiscoveryData = {};
  Map _currentAnimeFilters = _defaultAnimeFilters();
  Map _currentMangaFilters = _defaultMangaFilters();

  Map get alData => _alData;
  set alData(Map value) {
    _alData = value;
    notifyListeners();
  }

  Map get animeDiscoveryData => _animeDiscoveryData;
  set animeDiscoveryData(Map value) {
    _animeDiscoveryData = value;
    notifyListeners();
  }

  Map get mangaDiscoveryData => _mangaDiscoveryData;
  set mangaDiscoveryData(Map value) {
    _mangaDiscoveryData = value;
    notifyListeners();
  }

  Map get currentAnimeFilters => _currentAnimeFilters;
  set currentAnimeFilters(Map value) {
    _currentAnimeFilters = value;
    notifyListeners();
  }

  Map get currentMangaFilters => _currentMangaFilters;
  set currentMangaFilters(Map value) {
    _currentMangaFilters = value;
    notifyListeners();
  }

  static Map _defaultAnimeFilters() => {
        "selectedGenres": <String>{},
        "selectedTags": <String>{},
        "releaseYear": null,
        "countryOfOrigin": "",
        "season": "",
        "format": "",
        "airingStatus": "",
        "sourceMaterial": "",
      };

  static Map _defaultMangaFilters() => {
        "selectedGenres": <String>{},
        "selectedTags": <String>{},
        "releaseYear": null,
        "countryOfOrigin": "",
        "format": "",
        "airingStatus": "",
        "sourceMaterial": "",
      };

  void updateData(Map newData) {
    _alData = newData;
    notifyListeners();
  }

  void clearAnimeFilters() {
    _currentAnimeFilters = _defaultAnimeFilters();
    notifyListeners();
  }

  void clearMangaFilters() {
    _currentMangaFilters = _defaultMangaFilters();
    notifyListeners();
  }

  void updateDiscoveryData(Map newData) {
    _animeDiscoveryData = newData;
    notifyListeners();
  }

  void updateMangaDiscoveryData(Map newData) {
    _mangaDiscoveryData = newData;
    notifyListeners();
  }

  void clearNotifications() {
    final viewer = (_alData["data"] is Map) ? _alData["data"]["Viewer"] : null;
    if (viewer is Map && viewer.containsKey("unreadNotificationCount")) {
      viewer["unreadNotificationCount"] = 0;
      notifyListeners();
    }
  }
}
