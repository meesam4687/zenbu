import 'package:flutter/material.dart';

class StateProvider extends ChangeNotifier {
  Map _alData = {};
  Map _animeDiscoveryData = {};
  Map _mangaDiscoveryData = {};
  Map _currentAnimeFilters = _defaultAnimeFilters();
  Map _currentMangaFilters = _defaultMangaFilters();
  String _animeSearchQuery = "";
  String _mangaSearchQuery = "";

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

  String get animeSearchQuery => _animeSearchQuery;
  set animeSearchQuery(String value) {
    _animeSearchQuery = value;
    notifyListeners();
  }

  String get mangaSearchQuery => _mangaSearchQuery;
  set mangaSearchQuery(String value) {
    _mangaSearchQuery = value;
    notifyListeners();
  }

  bool get isAnimeFilterActive {
    final filters = _currentAnimeFilters;
    return (filters["selectedGenres"] as Set).isNotEmpty ||
        (filters["selectedTags"] as Set).isNotEmpty ||
        (filters["excludedGenres"] as Set).isNotEmpty ||
        (filters["excludedTags"] as Set).isNotEmpty ||
        filters["releaseYear"] != null ||
        filters["countryOfOrigin"] != "" ||
        filters["season"] != "" ||
        filters["format"] != "" ||
        filters["airingStatus"] != "" ||
        filters["sourceMaterial"] != "" ||
        (filters["sortBy"] != null && filters["sortBy"] != "POPULARITY_DESC");
  }

  bool get isMangaFilterActive {
    final filters = _currentMangaFilters;
    return (filters["selectedGenres"] as Set).isNotEmpty ||
        (filters["selectedTags"] as Set).isNotEmpty ||
        (filters["excludedGenres"] as Set).isNotEmpty ||
        (filters["excludedTags"] as Set).isNotEmpty ||
        filters["releaseYear"] != null ||
        filters["countryOfOrigin"] != "" ||
        filters["format"] != "" ||
        filters["airingStatus"] != "" ||
        filters["sourceMaterial"] != "" ||
        (filters["sortBy"] != null && filters["sortBy"] != "POPULARITY_DESC");
  }

  static Map _defaultAnimeFilters() => {
        "selectedGenres": <String>{},
        "selectedTags": <String>{},
        "excludedGenres": <String>{},
        "excludedTags": <String>{},
        "releaseYear": null,
        "countryOfOrigin": "",
        "season": "",
        "format": "",
        "airingStatus": "",
        "sourceMaterial": "",
        "sortBy": "POPULARITY_DESC",
      };

  static Map _defaultMangaFilters() => {
        "selectedGenres": <String>{},
        "selectedTags": <String>{},
        "excludedGenres": <String>{},
        "excludedTags": <String>{},
        "releaseYear": null,
        "countryOfOrigin": "",
        "format": "",
        "airingStatus": "",
        "sourceMaterial": "",
        "sortBy": "POPULARITY_DESC",
      };

  void updateData(Map newData) {
    _alData = newData;
    notifyListeners();
  }

  void clearAnimeFilters() {
    _currentAnimeFilters = _defaultAnimeFilters();
    _animeSearchQuery = "";
    notifyListeners();
  }

  void clearMangaFilters() {
    _currentMangaFilters = _defaultMangaFilters();
    _mangaSearchQuery = "";
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
