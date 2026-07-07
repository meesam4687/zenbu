import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StateProvider extends ChangeNotifier {
  Map _alData = {};
  Map _animeDiscoveryData = {};
  Map _mangaDiscoveryData = {};
  Map _currentAnimeFilters = _defaultAnimeFilters();
  Map _currentMangaFilters = _defaultMangaFilters();
  String _animeSearchQuery = "";
  String _mangaSearchQuery = "";

  String _titleLanguage = 'ROMAJI';
  ThemeMode _themeMode = ThemeMode.system;

  Color? _seedColor;

  StateProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _titleLanguage = prefs.getString('setting_title_language') ?? 'ROMAJI';
    final tm = prefs.getString('setting_theme_mode') ?? 'system';
    _themeMode = tm == 'light'
        ? ThemeMode.light
        : tm == 'dark'
        ? ThemeMode.dark
        : ThemeMode.system;
    final seedColorValue = prefs.getInt('setting_seed_color');
    _seedColor = seedColorValue != null ? Color(seedColorValue) : null;
    notifyListeners();
  }

  String get titleLanguage => _titleLanguage;
  set titleLanguage(String value) {
    _titleLanguage = value;
    _saveString('setting_title_language', value);
    notifyListeners();
  }

  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode value) {
    _themeMode = value;
    final str = value == ThemeMode.light
        ? 'light'
        : value == ThemeMode.dark
        ? 'dark'
        : 'system';
    _saveString('setting_theme_mode', str);
    notifyListeners();
  }

  Color? get seedColor => _seedColor;
  set seedColor(Color? value) {
    _seedColor = value;
    _saveOptionalInt('setting_seed_color', value?.toARGB32());
    notifyListeners();
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveOptionalInt(String key, int? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setInt(key, value);
    }
  }

  String resolveTitle(Map? titleMap, {String fallback = ''}) {
    if (titleMap == null) return fallback;
    switch (_titleLanguage) {
      case 'ENGLISH':
        return (titleMap['english'] as String?)?.isNotEmpty == true
            ? titleMap['english'] as String
            : (titleMap['romaji'] as String?) ?? fallback;
      case 'NATIVE':
        return (titleMap['native'] as String?)?.isNotEmpty == true
            ? titleMap['native'] as String
            : (titleMap['romaji'] as String?) ?? fallback;
      case 'ROMAJI':
      default:
        return (titleMap['romaji'] as String?) ?? fallback;
    }
  }

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
    final lang =
        newData['data']?['Viewer']?['options']?['titleLanguage'] as String?;
    if (lang != null) {
      SharedPreferences.getInstance().then((prefs) {
        if (!prefs.containsKey('setting_title_language')) {
          titleLanguage = lang;
        }
      });
    }
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
