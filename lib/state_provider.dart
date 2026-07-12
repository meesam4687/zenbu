import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenbu/services/update_service.dart';

class StateProvider extends ChangeNotifier {
  bool _isDownloadingUpdate = false;
  double _updateDownloadProgress = 0.0;
  UpdateInfo? _downloadingUpdateInfo;
  bool _isUpdateApkDownloaded = false;

  bool get isDownloadingUpdate => _isDownloadingUpdate;
  double get updateDownloadProgress => _updateDownloadProgress;
  UpdateInfo? get downloadingUpdateInfo => _downloadingUpdateInfo;
  bool get isUpdateApkDownloaded => _isUpdateApkDownloaded;

  Future<void> checkDownloadedApk(String remoteVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadedVersion = prefs.getString('downloaded_apk_version');
      if (downloadedVersion == remoteVersion) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/app-release.apk');
        if (await file.exists()) {
          _isUpdateApkDownloaded = true;
          notifyListeners();
          return;
        }
      }
    } catch (_) {}
    _isUpdateApkDownloaded = false;
    notifyListeners();
  }

  bool _isCancelledByUser = false;

  void cancelUpdateDownload() {
    _isCancelledByUser = true;
    UpdateService.cancelDownload();
    _isDownloadingUpdate = false;
    notifyListeners();
  }

  Future<void> startUpdateDownload(UpdateInfo info) async {
    if (_isDownloadingUpdate) return;
    _isDownloadingUpdate = true;
    _updateDownloadProgress = 0.0;
    _downloadingUpdateInfo = info;
    _isUpdateApkDownloaded = false;
    _isCancelledByUser = false;
    notifyListeners();

    int lastNotifiedProgress = -1;

    try {
      try {
        await const MethodChannel('zenbu/pip').invokeMethod('showDownloadingNotification', {'progress': 0});
      } catch (_) {}

      await UpdateService.downloadAndInstallApk(
        downloadUrl: info.downloadUrl,
        onProgress: (progress) {
          if (_isCancelledByUser) return;
          _updateDownloadProgress = progress;
          notifyListeners();
          
          final progressPercent = (progress * 100).toInt();
          if (progressPercent != lastNotifiedProgress) {
            lastNotifiedProgress = progressPercent;
            const MethodChannel('zenbu/pip').invokeMethod(
              'showDownloadingNotification',
              {'progress': progressPercent},
            );
          }
        },
      );

      if (_isCancelledByUser) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('downloaded_apk_version', info.remoteVersion);
      _isUpdateApkDownloaded = true;
    } catch (e) {
      if (!_isCancelledByUser) {
        rethrow;
      }
    } finally {
      _isDownloadingUpdate = false;
      notifyListeners();
      try {
        await const MethodChannel('zenbu/pip').invokeMethod('dismissDownloadingNotification');
      } catch (_) {}
    }
  }

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
  bool _displayAdultContent = false;
  String? _selectedCustomTheme;
  bool _showAnimeList = true;
  bool _showMangaList = true;
  bool _showRecommendationsList = true;
  List<String> _homeListOrder = ['anime', 'manga', 'recommendations'];

  List<dynamic> _recommendations = [];

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
    _displayAdultContent = prefs.getBool('setting_display_adult_content') ?? false;
    _selectedCustomTheme = prefs.getString('setting_custom_theme');
    _showAnimeList = prefs.getBool('setting_show_anime_list') ?? true;
    _showMangaList = prefs.getBool('setting_show_manga_list') ?? true;
    _showRecommendationsList = prefs.getBool('setting_show_recommendations_list') ?? true;
    
    final loadedOrder = prefs.getStringList('setting_home_list_order');
    if (loadedOrder != null && loadedOrder.isNotEmpty) {
      final validItems = ['anime', 'manga', 'recommendations'];
      _homeListOrder = loadedOrder.where((item) => validItems.contains(item)).toList();
      for (var item in validItems) {
        if (!_homeListOrder.contains(item)) {
          _homeListOrder.add(item);
        }
      }
    } else {
      _homeListOrder = ['anime', 'manga', 'recommendations'];
    }
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

  bool get showAnimeList => _showAnimeList;
  set showAnimeList(bool value) {
    _showAnimeList = value;
    _saveBool('setting_show_anime_list', value);
    notifyListeners();
  }

  bool get showMangaList => _showMangaList;
  set showMangaList(bool value) {
    _showMangaList = value;
    _saveBool('setting_show_manga_list', value);
    notifyListeners();
  }

  bool get showRecommendationsList => _showRecommendationsList;
  set showRecommendationsList(bool value) {
    _showRecommendationsList = value;
    _saveBool('setting_show_recommendations_list', value);
    notifyListeners();
  }

  List<String> get homeListOrder => _homeListOrder;
  set homeListOrder(List<String> value) {
    _homeListOrder = value;
    _saveStringList('setting_home_list_order', value);
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

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  Future<void> _saveOptionalInt(String key, int? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setInt(key, value);
    }
  }

  Future<void> _saveOptionalString(String key, String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }

  bool get displayAdultContent => _displayAdultContent;
  set displayAdultContent(bool value) {
    _displayAdultContent = value;
    if (_alData['data']?['Viewer']?['options'] != null) {
      _alData['data']['Viewer']['options']['displayAdultContent'] = value;
    }
    _saveBool('setting_display_adult_content', value);
    notifyListeners();
  }

  String? get selectedCustomTheme => _selectedCustomTheme;
  set selectedCustomTheme(String? value) {
    _selectedCustomTheme = value;
    _saveOptionalString('setting_custom_theme', value);
    notifyListeners();
  }

  bool get midnightTheme => _selectedCustomTheme == 'Midnight';

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

  List<dynamic> get recommendations => _recommendations;

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
    _loadRecommendations(newData);
    final lang =
        newData['data']?['Viewer']?['options']?['titleLanguage'] as String?;
    if (lang != null) {
      SharedPreferences.getInstance().then((prefs) {
        if (!prefs.containsKey('setting_title_language')) {
          titleLanguage = lang;
        }
      });
    }
    final adult =
        newData['data']?['Viewer']?['options']?['displayAdultContent'] as bool?;
    if (adult != null && adult != _displayAdultContent) {
      _displayAdultContent = adult;
      _saveBool('setting_display_adult_content', adult);
    }
    notifyListeners();
  }

  void _loadRecommendations(Map newData) {
    final List<dynamic> rawRecommendations = [];
    final Set<int> allActiveIds = {};
    final Set<int> seenRecIds = {};

    final animeLists = newData['data']?['animeList']?['lists'] as List?;
    if (animeLists != null) {
      for (var list in animeLists) {
        final entries = list['entries'] as List?;
        if (entries != null) {
          for (var entry in entries) {
            final media = entry['media'];
            if (media != null) {
              final int id = media['id'];
              allActiveIds.add(id);

              final recs = media['recommendations']?['nodes'] as List?;
              if (recs != null) {
                for (var rec in recs) {
                  final recMedia = rec['mediaRecommendation'];
                  if (recMedia != null) {
                    final int recId = recMedia['id'];
                    if (!seenRecIds.contains(recId)) {
                      seenRecIds.add(recId);
                      rawRecommendations.add({
                        'rating': rec['rating'] ?? 0,
                        'media': recMedia,
                      });
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    final mangaLists = newData['data']?['mangaList']?['lists'] as List?;
    if (mangaLists != null) {
      for (var list in mangaLists) {
        final entries = list['entries'] as List?;
        if (entries != null) {
          for (var entry in entries) {
            final media = entry['media'];
            if (media != null) {
              allActiveIds.add(media['id']);
            }
          }
        }
      }
    }

    final filtered = rawRecommendations.where((rec) {
      final media = rec['media'];
      if (media['mediaListEntry'] != null) {
        return false;
      }
      final int id = media['id'];
      return !allActiveIds.contains(id);
    }).toList();

    filtered.sort((a, b) => (b['rating'] as int).compareTo(a['rating'] as int));

    _recommendations = filtered;
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
