import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenbu/services/mangayomi/models/extensions_models.dart';
import 'package:zenbu/services/progress_service.dart';

class DownloadItem {
  final String url;
  final String name;
  final String localPath;

  DownloadItem({
    required this.url,
    required this.name,
    required this.localPath,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'name': name,
    'localPath': localPath,
  };

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      url: json['url'] ?? '',
      name: json['name'] ?? '',
      localPath: json['localPath'] ?? '',
    );
  }
}

class DownloadedMedia {
  final int mediaId;
  final int? malId;
  final String mediaTitle;
  final String coverImage;
  final bool isManga;
  final List<DownloadItem> items;

  DownloadedMedia({
    required this.mediaId,
    this.malId,
    required this.mediaTitle,
    required this.coverImage,
    required this.isManga,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'mediaId': mediaId,
    'malId': malId,
    'mediaTitle': mediaTitle,
    'coverImage': coverImage,
    'isManga': isManga,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory DownloadedMedia.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return DownloadedMedia(
      mediaId: json['mediaId'] ?? 0,
      malId: json['malId'] as int?,
      mediaTitle: json['mediaTitle'] ?? '',
      coverImage: json['coverImage'] ?? '',
      isManga: json['isManga'] ?? false,
      items: rawItems
          .map((e) => DownloadItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class _ByteRecord {
  final DateTime time;
  final int bytes;
  _ByteRecord(this.time, this.bytes);
}

class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal() {
    _loadRegistries();
  }

  static const MethodChannel _channel = MethodChannel('zenbu/pip');

  void _updateNotificationProgress(String url, String title, double progress) {
    try {
      final id = url.hashCode;
      final percent = (progress * 100).toInt();
      _channel.invokeMethod('showDownloadingNotification', {
        'id': id,
        'title': title,
        'progress': percent,
      });
    } catch (_) {}
  }

  void _dismissNotification(String url) {
    try {
      final id = url.hashCode;
      _channel.invokeMethod('dismissDownloadingNotification', {'id': id});
    } catch (_) {}
  }

  static const Duration _downloadTimeout = Duration(seconds: 90);

  final Map<String, double> _activeDownloads = {};
  final Map<String, StreamSubscription> _activeSubscriptions = {};
  final Map<String, Completer<void>> _activeCompleters = {};
  final Map<String, http.Client> _activeClients = {};

  final Map<String, int> _downloadedBytes = {};
  final Map<String, List<_ByteRecord>> _speedHistories = {};
  final Map<String, String> _downloadSpeeds = {};
  Timer? _speedTimer;

  final Map<String, bool> _activeTypes = {};
  final Map<String, String> _activeNames = {};
  final Map<String, String> _activeMediaTitles = {};

  final Set<String> _manuallyCancelled = {};
  final Set<String> _pausedDownloads = {};

  final Map<String, int> _activeMediaIds = {};
  final Map<String, int?> _activeMalIds = {};
  final Map<String, String> _activeCoverImages = {};
  final Map<String, String> _activeRootPaths = {};
  final Map<String, String> _activeVideoStreamUrls = {};
  final Map<String, Map<String, String>> _activeHeaders = {};
  final Map<String, List<dynamic>> _activeSubtitles = {};
  final Map<String, List<dynamic>> _activePages = {};

  bool isPaused(String url) => _pausedDownloads.contains(url);

  List<DownloadedMedia> _animeRegistry = [];
  List<DownloadedMedia> _mangaRegistry = [];

  Map<String, double> get activeDownloads => _activeDownloads;
  Map<String, bool> get activeTypes => _activeTypes;
  Map<String, String> get activeNames => _activeNames;
  Map<String, String> get activeMediaTitles => _activeMediaTitles;
  List<DownloadedMedia> get animeRegistry => _animeRegistry;
  List<DownloadedMedia> get mangaRegistry => _mangaRegistry;

  double? getDownloadProgress(String url) => _activeDownloads[url];
  bool isDownloading(String url) => _activeDownloads.containsKey(url);
  bool wasManuallyCancelled(String url) => _manuallyCancelled.contains(url);
  void clearManualCancel(String url) => _manuallyCancelled.remove(url);
  String getDownloadSpeed(String url) => _downloadSpeeds[url] ?? '0 KB/s';

  void _startSpeedTimer() {
    if (_speedTimer != null) return;
    _speedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeDownloads.isEmpty) {
        timer.cancel();
        _speedTimer = null;
        _downloadSpeeds.clear();
        _downloadedBytes.clear();
        _speedHistories.clear();
        notifyListeners();
        return;
      }
      for (final url in _activeDownloads.keys) {
        if (_pausedDownloads.contains(url)) {
          _downloadSpeeds[url] = 'Paused';
          continue;
        }
        final currentBytes = _downloadedBytes[url] ?? 0;
        final now = DateTime.now();

        final history = _speedHistories.putIfAbsent(url, () => []);
        history.add(_ByteRecord(now, currentBytes));

        if (history.length > 6) {
          history.removeAt(0);
        }

        double bytesPerSec = 0.0;
        if (history.length > 1) {
          final first = history.first;
          final last = history.last;
          final elapsedSeconds =
              last.time.difference(first.time).inMilliseconds / 1000.0;
          if (elapsedSeconds > 0.1) {
            bytesPerSec = (last.bytes - first.bytes) / elapsedSeconds;
          }
        }

        if (bytesPerSec <= 10.0) {
          _downloadSpeeds[url] = '0 KB/s';
        } else if (bytesPerSec < 1024 * 1024) {
          _downloadSpeeds[url] =
              '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
        } else {
          _downloadSpeeds[url] =
              '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
        }
      }
      notifyListeners();
    });
  }

  void setDownloadingInitialState(
    String url,
    bool isManga,
    String name,
    String mediaTitle,
  ) {
    _activeDownloads[url] = 0.0;
    _activeTypes[url] = isManga;
    _activeNames[url] = name;
    _activeMediaTitles[url] = mediaTitle;
    _downloadedBytes[url] = 0;
    _speedHistories[url] = [_ByteRecord(DateTime.now(), 0)];
    _downloadSpeeds[url] = '0 KB/s';
    _startSpeedTimer();
    _updateNotificationProgress(url, '$mediaTitle - $name', 0.0);
    notifyListeners();
  }

  Future<void> _saveRegistryState() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> stateMap = {};
    for (final url in _activeDownloads.keys) {
      final isManga = _activeTypes[url] ?? false;
      stateMap[url] = {
        'url': url,
        'isManga': isManga,
        'progress': _activeDownloads[url],
        'isPaused': _pausedDownloads.contains(url),
        'name': _activeNames[url],
        'mediaTitle': _activeMediaTitles[url],
        'mediaId': _activeMediaIds[url],
        'malId': _activeMalIds[url],
        'coverImage': _activeCoverImages[url],
        'rootPath': _activeRootPaths[url],
        'videoStreamUrl': _activeVideoStreamUrls[url],
        'headers': _activeHeaders[url],
        'subtitles': _activeSubtitles[url],
        'pages': _activePages[url],
      };
    }
    await prefs.setString('active_downloads_state_v1', json.encode(stateMap));
  }

  void saveDownloadMetadata({
    required String url,
    required bool isManga,
    required String name,
    required String mediaTitle,
    required int mediaId,
    int? malId,
    required String coverImage,
    required String rootPath,
    String? videoStreamUrl,
    Map<String, String>? headers,
    List<dynamic>? subtitles,
    List<dynamic>? pages,
  }) {
    _activeDownloads[url] = 0.0;
    _activeTypes[url] = isManga;
    _activeNames[url] = name;
    _activeMediaTitles[url] = mediaTitle;
    _activeMediaIds[url] = mediaId;
    _activeMalIds[url] = malId;
    _activeCoverImages[url] = coverImage;
    _activeRootPaths[url] = rootPath;
    if (videoStreamUrl != null) _activeVideoStreamUrls[url] = videoStreamUrl;
    if (headers != null) _activeHeaders[url] = headers;
    if (subtitles != null) {
      _activeSubtitles[url] = subtitles.map((e) => {'file': e.file, 'label': e.label}).toList();
    }
    if (pages != null) _activePages[url] = pages;
    _saveRegistryState();
    notifyListeners();
  }

  void pauseDownload(String url) {
    if (!_activeDownloads.containsKey(url)) return;
    _pausedDownloads.add(url);
    _downloadSpeeds[url] = 'Paused';

    final isManga = _activeTypes[url] ?? false;
    if (!isManga) {
      final sub = _activeSubscriptions[url];
      if (sub != null) {
        sub.pause();
      }
    }
    _saveRegistryState();
    notifyListeners();
  }

  void resumeDownload(String url) {
    if (!_activeDownloads.containsKey(url)) return;
    _pausedDownloads.remove(url);

    final isManga = _activeTypes[url] ?? false;
    final isAlreadyRunning = isManga 
        ? _activeClients.containsKey(url)
        : (_activeClients.containsKey(url) || _activeSubscriptions.containsKey(url));

    if (!isAlreadyRunning) {
      if (isManga) {
        final pagesList = _activePages[url]
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ?? [];
        startMangaDownload(
          mediaId: _activeMediaIds[url] ?? 0,
          mediaTitle: _activeMediaTitles[url] ?? '',
          coverImage: _activeCoverImages[url] ?? '',
          chapterUrl: url,
          chapterName: _activeNames[url] ?? '',
          pages: pagesList,
          rootPath: _activeRootPaths[url] ?? '',
        );
      } else {
        final subsList = _activeSubtitles[url]
            ?.map((e) => ExtSubtitle(file: e['file'] ?? '', label: e['label'] ?? ''))
            .toList();
        startAnimeDownload(
          mediaId: _activeMediaIds[url] ?? 0,
          malId: _activeMalIds[url],
          mediaTitle: _activeMediaTitles[url] ?? '',
          coverImage: _activeCoverImages[url] ?? '',
          episodeUrl: url,
          episodeName: _activeNames[url] ?? '',
          videoStreamUrl: _activeVideoStreamUrls[url] ?? '',
          headers: _activeHeaders[url] ?? {},
          rootPath: _activeRootPaths[url] ?? '',
          subtitles: subsList,
        );
      }
    } else {
      if (!isManga) {
        final sub = _activeSubscriptions[url];
        if (sub != null) {
          sub.resume();
        }
      }
    }
    _saveRegistryState();
    notifyListeners();
  }

  void cancelDownload(bool isManga, String url) {
    _manuallyCancelled.add(url);

    _activeDownloads.remove(url);
    _activeTypes.remove(url);
    _activeNames.remove(url);
    _activeMediaTitles.remove(url);
    _activeMediaIds.remove(url);
    _activeCoverImages.remove(url);
    _activeRootPaths.remove(url);
    _activeVideoStreamUrls.remove(url);
    _activeHeaders.remove(url);
    _activeSubtitles.remove(url);
    _activePages.remove(url);
    _pausedDownloads.remove(url);
    _dismissNotification(url);

    final client = _activeClients.remove(url);
    if (client != null) {
      client.close();
    }

    if (!isManga) {
      final sub = _activeSubscriptions[url];
      if (sub != null) {
        sub.cancel();
        _activeSubscriptions.remove(url);
      }

      final completer = _activeCompleters[url];
      if (completer != null && !completer.isCompleted) {
        completer.completeError(Exception('Cancelled by user.'));
        _activeCompleters.remove(url);
      }
    }
    _saveRegistryState();
    notifyListeners();
  }

  bool isDownloaded(bool isManga, String url) {
    final registry = isManga ? _mangaRegistry : _animeRegistry;
    for (final media in registry) {
      if (media.items.any((item) => item.url == url)) {
        return true;
      }
    }
    return false;
  }

  String sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  Future<void> _loadRegistries() async {
    final prefs = await SharedPreferences.getInstance();

    final animeRaw = prefs.getString('download_anime_registry_v2');
    if (animeRaw != null) {
      try {
        final List parsed = json.decode(animeRaw);
        _animeRegistry = parsed
            .map((e) => DownloadedMedia.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }

    final mangaRaw = prefs.getString('download_manga_registry_v2');
    if (mangaRaw != null) {
      try {
        final List parsed = json.decode(mangaRaw);
        _mangaRegistry = parsed
            .map((e) => DownloadedMedia.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }

    final stateRaw = prefs.getString('active_downloads_state_v1');
    if (stateRaw != null) {
      try {
        final Map<String, dynamic> stateMap = json.decode(stateRaw);
        stateMap.forEach((url, data) {
          _activeDownloads[url] = data['progress'] ?? 0.0;
          _activeTypes[url] = data['isManga'] ?? false;
          _activeNames[url] = data['name'] ?? '';
          _activeMediaTitles[url] = data['mediaTitle'] ?? '';
          _activeMediaIds[url] = data['mediaId'] ?? 0;
          _activeMalIds[url] = data['malId'];
          _activeCoverImages[url] = data['coverImage'] ?? '';
          _activeRootPaths[url] = data['rootPath'] ?? '';
          if (data['videoStreamUrl'] != null) _activeVideoStreamUrls[url] = data['videoStreamUrl'];
          if (data['headers'] != null) {
            _activeHeaders[url] = Map<String, String>.from(data['headers']);
          }
          if (data['subtitles'] != null) _activeSubtitles[url] = data['subtitles'];
          if (data['pages'] != null) _activePages[url] = data['pages'];
          
          _pausedDownloads.add(url);
          _downloadSpeeds[url] = 'Paused';
        });
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _saveRegistries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'download_anime_registry_v2',
      json.encode(_animeRegistry.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'download_manga_registry_v2',
      json.encode(_mangaRegistry.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<String?> getOrPromptLocalDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('local_directory_path');
    if (path != null && path.isNotEmpty) {
      return path;
    }
    return null;
  }

  Future<http.StreamedResponse> streamWithRedirects(
    String url,
    Map<String, String> headers, {
    http.Client? client,
  }) async {
    var currentUrl = url;
    var redirectCount = 0;
    const maxRedirects = 5;

    final requestHeaders = Map<String, String>.from(headers);
    if (!requestHeaders.keys.any((k) => k.toLowerCase() == 'user-agent')) {
      requestHeaders['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    }
    if (!requestHeaders.keys.any((k) => k.toLowerCase() == 'accept')) {
      requestHeaders['Accept'] = '*/*';
    }
    if (!requestHeaders.keys.any((k) => k.toLowerCase() == 'accept-language')) {
      requestHeaders['Accept-Language'] = 'en-US,en;q=0.9';
    }

    while (redirectCount < maxRedirects) {
      final activeClient = client ?? http.Client();
      final request = http.Request('GET', Uri.parse(currentUrl));
      request.followRedirects = false;
      requestHeaders.forEach((key, val) {
        request.headers[key] = val;
      });

      final response = await activeClient
          .send(request)
          .timeout(_downloadTimeout);

      if (response.statusCode >= 300 && response.statusCode < 400) {
        final location = response.headers['location'];
        if (location == null || location.isEmpty) {
          return response;
        }

        final resolvedUri = Uri.parse(currentUrl).resolve(location);
        currentUrl = resolvedUri.toString();
        redirectCount++;
        if (client == null) {
          activeClient.close();
        }
      } else {
        return response;
      }
    }

    throw Exception('Too many redirects.');
  }

  Future<http.Response> sendWithRedirects(
    String url,
    Map<String, String> headers, {
    http.Client? client,
  }) async {
    var currentUrl = url;
    var redirectCount = 0;
    const maxRedirects = 5;

    final requestHeaders = Map<String, String>.from(headers);
    if (!requestHeaders.keys.any((k) => k.toLowerCase() == 'user-agent')) {
      requestHeaders['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
    }
    if (!requestHeaders.keys.any((k) => k.toLowerCase() == 'accept')) {
      requestHeaders['Accept'] = '*/*';
    }
    if (!requestHeaders.keys.any((k) => k.toLowerCase() == 'accept-language')) {
      requestHeaders['Accept-Language'] = 'en-US,en;q=0.9';
    }

    while (redirectCount < maxRedirects) {
      final activeClient = client ?? http.Client();
      final request = http.Request('GET', Uri.parse(currentUrl));
      request.followRedirects = false;
      requestHeaders.forEach((key, val) {
        request.headers[key] = val;
      });

      final response = await activeClient
          .send(request)
          .timeout(_downloadTimeout);
      final bodyBytes = await response.stream.toBytes().timeout(
        _downloadTimeout,
      );

      final httpResponse = http.Response.bytes(
        bodyBytes,
        response.statusCode,
        headers: response.headers,
        persistentConnection: response.persistentConnection,
        isRedirect: response.isRedirect,
        reasonPhrase: response.reasonPhrase,
        request: response.request,
      );

      if (response.statusCode >= 300 && response.statusCode < 400) {
        final location = response.headers['location'];
        if (location == null || location.isEmpty) {
          if (client == null) {
            activeClient.close();
          }
          return httpResponse;
        }

        final resolvedUri = Uri.parse(currentUrl).resolve(location);
        currentUrl = resolvedUri.toString();
        redirectCount++;
        if (client == null) {
          activeClient.close();
        }
      } else {
        if (client == null) {
          activeClient.close();
        }
        return httpResponse;
      }
    }

    throw Exception('Too many redirects.');
  }

  Future<void> startAnimeDownload({
    required int mediaId,
    int? malId,
    required String mediaTitle,
    required String coverImage,
    required String episodeUrl,
    required String episodeName,
    required String videoStreamUrl,
    required Map<String, String> headers,
    required String rootPath,
    List<ExtSubtitle>? subtitles,
  }) async {
    saveDownloadMetadata(
      url: episodeUrl,
      isManga: false,
      name: episodeName,
      mediaTitle: mediaTitle,
      mediaId: mediaId,
      malId: malId,
      coverImage: coverImage,
      rootPath: rootPath,
      videoStreamUrl: videoStreamUrl,
      headers: headers,
      subtitles: subtitles,
    );

    String fileDest = '';
    final client = http.Client();
    _activeClients[episodeUrl] = client;

    try {
      final sanitizedTitle = sanitizeFilename(mediaTitle);
      final sanitizedEpName = sanitizeFilename(episodeName);

      final animeRootPath = '$rootPath${Platform.isWindows ? '\\' : '/'}anime';
      final showPath =
          '$animeRootPath${Platform.isWindows ? '\\' : '/'}$sanitizedTitle';
      final showDir = Directory(showPath);
      if (!await showDir.exists()) {
        await showDir.create(recursive: true);
      }

      String ext = '.mp4';
      if (videoStreamUrl.contains('.mkv')) ext = '.mkv';
      if (videoStreamUrl.contains('.webm')) ext = '.webm';

      fileDest =
          '$showPath${Platform.isWindows ? '\\' : '/'}$sanitizedEpName$ext';

      final videoNameWithoutExt = fileDest.substring(
        0,
        fileDest.lastIndexOf('.'),
      );

      if (malId != null) {
        try {
          final epNum = ProgressService.parseEpisodeNumber(episodeUrl, episodeName);
          if (epNum != null) {
            final skipApiUrl =
                'https://api.aniskip.com/v2/skip-times/$malId/$epNum?types[]=op&types[]=ed&types[]=mixed-op&types[]=mixed-ed&types[]=recap&episodeLength=0';
            final skipRes = await http.get(Uri.parse(skipApiUrl));
            if (skipRes.statusCode == 200) {
              final skipData = jsonDecode(skipRes.body);
              if (skipData is Map &&
                  skipData['found'] == true &&
                  skipData['results'] is List) {
                final List<Map<String, dynamic>> parsedSkips = [];
                for (final item in skipData['results']) {
                  final interval = item['interval'];
                  if (interval is Map) {
                    final startTime =
                        double.tryParse(interval['startTime'].toString()) ?? 0.0;
                    final endTime =
                        double.tryParse(interval['endTime'].toString()) ?? 0.0;
                    final skipType = item['skipType']?.toString() ?? 'op';
                    parsedSkips.add({
                      'startTime': startTime,
                      'endTime': endTime,
                      'skipType': skipType,
                    });
                  }
                }
                if (parsedSkips.isNotEmpty) {
                  final jsonDest = '$videoNameWithoutExt.json';
                  await File(jsonDest).writeAsString(jsonEncode(parsedSkips));
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[DOWNLOAD SKIP STAMPS ERROR] Failed to fetch skip times: $e');
        }
      }

      if (subtitles != null && subtitles.isNotEmpty) {
        for (final subtitle in subtitles) {
          if (!_activeDownloads.containsKey(episodeUrl)) {
            break;
          }
          if (subtitle.file.isEmpty) continue;
          try {
            final sanitizedLabel = sanitizeFilename(subtitle.label);
            String subExt = '.vtt';
            final fileUri = Uri.tryParse(subtitle.file);
            if (fileUri != null) {
              final path = fileUri.path.toLowerCase();
              if (path.contains('.srt')) {
                subExt = '.srt';
              } else if (path.contains('.ass')) {
                subExt = '.ass';
              } else if (path.contains('.ssa')) {
                subExt = '.ssa';
              }
            }
            final subFileDest = '$videoNameWithoutExt.$sanitizedLabel$subExt';
            final subResponse = await sendWithRedirects(
              subtitle.file,
              headers,
              client: client,
            );
            if (subResponse.statusCode == 200) {
              final subFile = File(subFileDest);
              await subFile.writeAsBytes(subResponse.bodyBytes);
            }
          } catch (e) {
            debugPrint(
              '[DOWNLOAD SUBS ERROR] Failed to download subtitle (${subtitle.label}): $e',
            );
          }
        }
      }

      final response = await streamWithRedirects(
        videoStreamUrl,
        headers,
        client: client,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      final isHls =
          videoStreamUrl.contains('.m3u8') ||
          contentType.contains('mpegurl') ||
          contentType.contains('application/x-mpegurl');

      if (isHls) {
        try {
          final playlistBytes = await response.stream.toBytes().timeout(
            _downloadTimeout,
          );
          var playlistContent = utf8.decode(playlistBytes);
          var mediaPlaylistUrl = videoStreamUrl;

          var lines = playlistContent.split('\n');
          bool isMaster = lines.any(
            (line) => line.trim().startsWith('#EXT-X-STREAM-INF'),
          );

          if (isMaster) {
            String? bestSubUrl;
            int maxResolution = -1;
            for (int i = 0; i < lines.length; i++) {
              final line = lines[i].trim();
              if (line.startsWith('#EXT-X-STREAM-INF')) {
                var resWidth = 0;
                final resMatch = RegExp(
                  r'RESOLUTION=(\d+)x(\d+)',
                ).firstMatch(line);
                if (resMatch != null) {
                  resWidth = int.tryParse(resMatch.group(1) ?? '0') ?? 0;
                }
                var urlLine = '';
                for (int j = i + 1; j < lines.length; j++) {
                  final l = lines[j].trim();
                  if (l.isNotEmpty && !l.startsWith('#')) {
                    urlLine = l;
                    break;
                  }
                }
                if (urlLine.isNotEmpty) {
                  final absUrl = Uri.parse(
                    mediaPlaylistUrl,
                  ).resolve(urlLine).toString();
                  if (resWidth > maxResolution) {
                    maxResolution = resWidth;
                    bestSubUrl = absUrl;
                  }
                }
              }
            }
            if (bestSubUrl != null) {
              mediaPlaylistUrl = bestSubUrl;
              final subResponse = await sendWithRedirects(
                mediaPlaylistUrl,
                headers,
                client: client,
              );
              if (subResponse.statusCode != 200) {
                throw Exception(
                  'Failed to fetch HLS sub-playlist: HTTP ${subResponse.statusCode}',
                );
              }
              playlistContent = subResponse.body;
              lines = playlistContent.split('\n');
            }
          }

          final segmentUrls = <String>[];
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
              segmentUrls.add(
                Uri.parse(mediaPlaylistUrl).resolve(trimmed).toString(),
              );
            }
          }

          final totalSegments = segmentUrls.length;

          if (totalSegments == 0) {
            throw Exception('No HLS video segments found in playlist.');
          }

          final tempDirPath = '$showPath/temp_$sanitizedEpName';
          final tempDir = Directory(tempDirPath);
          if (!await tempDir.exists()) {
            await tempDir.create(recursive: true);
          }

          try {
            for (int i = 0; i < totalSegments; i++) {
              while (_pausedDownloads.contains(episodeUrl)) {
                await Future.delayed(const Duration(milliseconds: 500));
                if (!_activeDownloads.containsKey(episodeUrl)) {
                  throw Exception('Cancelled by user.');
                }
              }
              if (!_activeDownloads.containsKey(episodeUrl)) {
                throw Exception('Cancelled by user.');
              }
              final segmentUrl = segmentUrls[i];
              final segmentFile = File('$tempDirPath/TS_$i.ts');

              if (!await segmentFile.exists()) {
                final segmentHeaders = Map<String, String>.from(headers);
                if (!segmentHeaders.containsKey('Referer') &&
                    !segmentHeaders.containsKey('referer')) {
                  segmentHeaders['Referer'] = mediaPlaylistUrl;
                }

                final segResponse = await sendWithRedirects(
                  segmentUrl,
                  segmentHeaders,
                  client: client,
                );
                if (segResponse.statusCode == 200) {
                  await segmentFile.writeAsBytes(segResponse.bodyBytes);
                  _downloadedBytes[episodeUrl] =
                      (_downloadedBytes[episodeUrl] ?? 0) +
                      segResponse.bodyBytes.length;
                } else {
                  throw Exception(
                    'Failed to download segment $i: HTTP ${segResponse.statusCode}',
                  );
                }
              }

              if (!_activeDownloads.containsKey(episodeUrl)) {
                throw Exception('Cancelled by user.');
              }

              final progress = (i + 1) / totalSegments;
              _activeDownloads[episodeUrl] = progress;
              _updateNotificationProgress(
                episodeUrl,
                '$mediaTitle - $episodeName',
                progress,
              );
              notifyListeners();
            }

            final outFile = File(fileDest);
            final outSink = outFile.openWrite();
            try {
              for (int i = 0; i < totalSegments; i++) {
                final segmentFile = File('$tempDirPath/TS_$i.ts');
                if (await segmentFile.exists()) {
                  final inStream = segmentFile.openRead();
                  await outSink.addStream(inStream);
                }
              }
            } finally {
              await outSink.close();
            }

            if (await tempDir.exists()) {
              await tempDir.delete(recursive: true);
            }
          } catch (e) {
            try {
              if (await tempDir.exists()) {
                await tempDir.delete(recursive: true);
              }
              final mainFile = File(fileDest);
              if (await mainFile.exists()) {
                await mainFile.delete();
              }
            } catch (_) {}
            rethrow;
          }
        } finally {
          client.close();
        }
      } else {
        final file = File(fileDest);
        var downloadedBytes = 0;
        var mode = FileMode.write;
        final requestHeaders = Map<String, String>.from(headers);

        if (await file.exists()) {
          downloadedBytes = await file.length();
          if (downloadedBytes > 0) {
            requestHeaders['Range'] = 'bytes=$downloadedBytes-';
            mode = FileMode.append;
          }
        }

        final mp4Response = downloadedBytes > 0
            ? await streamWithRedirects(
                videoStreamUrl,
                requestHeaders,
                client: client,
              )
            : response;

        if (downloadedBytes > 0) {
          if (mp4Response.statusCode == 200) {
            downloadedBytes = 0;
            mode = FileMode.write;
          } else if (mp4Response.statusCode != 206) {
            throw Exception('Server returned status code ${mp4Response.statusCode}');
          }
        }

        final contentLength = (mp4Response.contentLength ?? 0) + downloadedBytes;
        final sink = file.openWrite(mode: mode);

        final Completer<void> completer = Completer<void>();
        late StreamSubscription subscription;

        subscription = mp4Response.stream.listen(
          (chunk) {
            if (!_activeDownloads.containsKey(episodeUrl)) {
              return;
            }
            sink.add(chunk);
            downloadedBytes += chunk.length;
            _downloadedBytes[episodeUrl] = downloadedBytes;
            if (contentLength > 0) {
              final progress = downloadedBytes / contentLength;
              _activeDownloads[episodeUrl] = progress;
              _updateNotificationProgress(
                episodeUrl,
                '$mediaTitle - $episodeName',
                progress,
              );
              notifyListeners();
            }
          },
          onError: (err) {
            completer.completeError(err);
          },
          onDone: () {
            completer.complete();
          },
          cancelOnError: true,
        );

        _activeSubscriptions[episodeUrl] = subscription;

        if (_pausedDownloads.contains(episodeUrl)) {
          subscription.pause();
        }

        try {
          await completer.future;
        } finally {
          _activeSubscriptions.remove(episodeUrl);
          _activeCompleters.remove(episodeUrl);
          await sink.close();
        }
      }

      final item = DownloadItem(
        url: episodeUrl,
        name: episodeName,
        localPath: fileDest,
      );

      final mediaIndex = _animeRegistry.indexWhere((e) => e.mediaId == mediaId);
      if (mediaIndex != -1) {
        _animeRegistry[mediaIndex].items.removeWhere(
          (e) => e.url == episodeUrl,
        );
        _animeRegistry[mediaIndex].items.add(item);
      } else {
        _animeRegistry.add(
          DownloadedMedia(
            mediaId: mediaId,
            malId: malId,
            mediaTitle: mediaTitle,
            coverImage: coverImage,
            isManga: false,
            items: [item],
          ),
        );
      }

      await _saveRegistries();
    } catch (e) {
      final wasCancelled =
          e.toString().contains('Cancelled by user.') ||
          !_activeDownloads.containsKey(episodeUrl);
      if (wasCancelled) {
        try {
          final file = File(fileDest);
          if (await file.exists()) {
            await file.delete();
          }
          final videoNameWithoutExt = fileDest.substring(
            0,
            fileDest.lastIndexOf('.'),
          );
          final jsonFile = File('$videoNameWithoutExt.json');
          if (await jsonFile.exists()) {
            await jsonFile.delete();
          }
          final parentDir = file.parent;
          final subsExtensions = ['.srt', '.vtt', '.ass', '.ssa'];
          if (await parentDir.exists()) {
            final parentEntities = parentDir.listSync();
            for (final entity in parentEntities) {
              if (entity is File) {
                final pathLower = entity.path.toLowerCase();
                if (subsExtensions.any((ext) => pathLower.endsWith(ext))) {
                  final subNameWithoutExt = entity.path.substring(
                    0,
                    entity.path.lastIndexOf('.'),
                  );
                  if (subNameWithoutExt.toLowerCase().startsWith(
                    videoNameWithoutExt.toLowerCase(),
                  )) {
                    await entity.delete();
                  }
                }
              }
            }
          }
        } catch (_) {}
      }
      rethrow;
    } finally {
      _activeDownloads.remove(episodeUrl);
      _activeTypes.remove(episodeUrl);
      _activeNames.remove(episodeUrl);
      _activeMediaTitles.remove(episodeUrl);
      _activeClients.remove(episodeUrl);
      _activeMediaIds.remove(episodeUrl);
      _activeMalIds.remove(episodeUrl);
      _activeCoverImages.remove(episodeUrl);
      _activeRootPaths.remove(episodeUrl);
      _activeVideoStreamUrls.remove(episodeUrl);
      _activeHeaders.remove(episodeUrl);
      _activeSubtitles.remove(episodeUrl);
      _pausedDownloads.remove(episodeUrl);
      _dismissNotification(episodeUrl);
      _saveRegistryState();
      notifyListeners();
      client.close();
    }
  }

  Future<void> startMangaDownload({
    required int mediaId,
    required String mediaTitle,
    required String coverImage,
    required String chapterUrl,
    required String chapterName,
    required List<Map<String, dynamic>> pages,
    required String rootPath,
  }) async {
    saveDownloadMetadata(
      url: chapterUrl,
      isManga: true,
      name: chapterName,
      mediaTitle: mediaTitle,
      mediaId: mediaId,
      coverImage: coverImage,
      rootPath: rootPath,
      pages: pages,
    );

    final client = http.Client();
    _activeClients[chapterUrl] = client;
    try {
      try {
        final sanitizedTitle = sanitizeFilename(mediaTitle);
        final sanitizedChapName = sanitizeFilename(chapterName);

        final mangaRootPath =
            '$rootPath${Platform.isWindows ? '\\' : '/'}manga';
        final showPath =
            '$mangaRootPath${Platform.isWindows ? '\\' : '/'}$sanitizedTitle';
        final chapterPath =
            '$showPath${Platform.isWindows ? '\\' : '/'}$sanitizedChapName';
        final chapterDir = Directory(chapterPath);
        if (!await chapterDir.exists()) {
          await chapterDir.create(recursive: true);
        }

        int completedPages = 0;
        final totalPages = pages.length;

        for (int i = 0; i < totalPages; i++) {
          while (_pausedDownloads.contains(chapterUrl)) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (!_activeDownloads.containsKey(chapterUrl)) {
              throw Exception('Cancelled by user.');
            }
          }
          if (!_activeDownloads.containsKey(chapterUrl)) {
            throw Exception('Cancelled by user.');
          }

          final page = pages[i];
          final pageUrl = page['url'] as String? ?? '';
          final pageHeaders = Map<String, String>.from(page['headers'] ?? {});

          final pageNumStr = (i + 1).toString().padLeft(3, '0');

          String ext = '.png';
          if (pageUrl.contains('.jpg') || pageUrl.contains('.jpeg')) {
            ext = '.jpg';
          }
          if (pageUrl.contains('.webp')) {
            ext = '.webp';
          }

          final pageFileDest =
              '$chapterPath${Platform.isWindows ? '\\' : '/'}$pageNumStr$ext';

          if (await File(pageFileDest).exists()) {
            completedPages++;
            if (!_activeDownloads.containsKey(chapterUrl)) {
              throw Exception('Cancelled by user.');
            }
            final progress = completedPages / totalPages;
            _activeDownloads[chapterUrl] = progress;
            _updateNotificationProgress(
              chapterUrl,
              '$mediaTitle - $chapterName',
              progress,
            );
            notifyListeners();
            continue;
          }

          final response = await sendWithRedirects(
            pageUrl,
            pageHeaders,
            client: client,
          );
          if (response.statusCode == 200) {
            await File(pageFileDest).writeAsBytes(response.bodyBytes);
            _downloadedBytes[chapterUrl] =
                (_downloadedBytes[chapterUrl] ?? 0) + response.bodyBytes.length;
          } else {
            throw Exception(
              'Failed to download page ${i + 1}: HTTP ${response.statusCode}',
            );
          }

          completedPages++;
          if (!_activeDownloads.containsKey(chapterUrl)) {
            throw Exception('Cancelled by user.');
          }
          final progress = completedPages / totalPages;
          _activeDownloads[chapterUrl] = progress;
          _updateNotificationProgress(
            chapterUrl,
            '$mediaTitle - $chapterName',
            progress,
          );
          notifyListeners();
        }

        final item = DownloadItem(
          url: chapterUrl,
          name: chapterName,
          localPath: chapterPath,
        );

        final mediaIndex = _mangaRegistry.indexWhere(
          (e) => e.mediaId == mediaId,
        );
        if (mediaIndex != -1) {
          _mangaRegistry[mediaIndex].items.removeWhere(
            (e) => e.url == chapterUrl,
          );
          _mangaRegistry[mediaIndex].items.add(item);
        } else {
          _mangaRegistry.add(
            DownloadedMedia(
              mediaId: mediaId,
              mediaTitle: mediaTitle,
              coverImage: coverImage,
              isManga: true,
              items: [item],
            ),
          );
        }

        await _saveRegistries();
      } finally {
        _activeClients.remove(chapterUrl);
        client.close();
      }
    } catch (e) {
      if (e.toString().contains('Cancelled by user.')) {
        try {
          final sanitizedTitle = sanitizeFilename(mediaTitle);
          final sanitizedChapName = sanitizeFilename(chapterName);
          final mangaRootPath =
              '$rootPath${Platform.isWindows ? '\\' : '/'}manga';
          final showPath =
              '$mangaRootPath${Platform.isWindows ? '\\' : '/'}$sanitizedTitle';
          final chapterPath =
              '$showPath${Platform.isWindows ? '\\' : '/'}$sanitizedChapName';
          final chapterDir = Directory(chapterPath);
          if (await chapterDir.exists()) {
            await chapterDir.delete(recursive: true);
          }
        } catch (_) {}
      }
      rethrow;
    } finally {
      _activeDownloads.remove(chapterUrl);
      _activeTypes.remove(chapterUrl);
      _activeNames.remove(chapterUrl);
      _activeMediaTitles.remove(chapterUrl);
      _activeClients.remove(chapterUrl);
      _activeMediaIds.remove(chapterUrl);
      _activeCoverImages.remove(chapterUrl);
      _activeRootPaths.remove(chapterUrl);
      _activePages.remove(chapterUrl);
      _pausedDownloads.remove(chapterUrl);
      _dismissNotification(chapterUrl);
      _saveRegistryState();
      notifyListeners();
    }
  }

  Future<void> deleteDownloadedItem(bool isManga, String url) async {
    final registry = isManga ? _mangaRegistry : _animeRegistry;
    DownloadItem? targetItem;
    DownloadedMedia? targetMedia;

    for (final media in registry) {
      final index = media.items.indexWhere((e) => e.url == url);
      if (index != -1) {
        targetMedia = media;
        targetItem = media.items[index];
        media.items.removeAt(index);
        break;
      }
    }

    if (targetItem != null && targetMedia != null) {
      try {
        final fileOrDir = File(targetItem.localPath);
        if (await fileOrDir.exists()) {
          if (!isManga) {
            try {
              final parentDir = fileOrDir.parent;
              final videoNameWithoutExt = targetItem.localPath.substring(
                0,
                targetItem.localPath.lastIndexOf('.'),
              );
              final subsExtensions = ['.srt', '.vtt', '.ass', '.ssa'];
              if (await parentDir.exists()) {
                final parentEntities = parentDir.listSync();
                for (final entity in parentEntities) {
                  if (entity is File) {
                    final pathLower = entity.path.toLowerCase();
                    if (subsExtensions.any((ext) => pathLower.endsWith(ext))) {
                      final subNameWithoutExt = entity.path.substring(
                        0,
                        entity.path.lastIndexOf('.'),
                      );
                      if (subNameWithoutExt.toLowerCase().startsWith(
                        videoNameWithoutExt.toLowerCase(),
                      )) {
                        await entity.delete();
                      }
                    }
                  }
                }
              }
              final jsonFile = File('$videoNameWithoutExt.json');
              if (await jsonFile.exists()) {
                await jsonFile.delete();
              }
            } catch (_) {}
          }
          await fileOrDir.delete();
        } else {
          final dir = Directory(targetItem.localPath);
          if (await dir.exists()) {
            await dir.delete(recursive: true);
          }
        }
      } catch (_) {}

      if (targetMedia.items.isEmpty) {
        registry.removeWhere((e) => e.mediaId == targetMedia!.mediaId);
      }
      await _saveRegistries();
    }
  }
}
