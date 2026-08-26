import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_subtitle/flutter_subtitle.dart' hide Subtitle;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:zenbu/services/mangayomi/models/extensions_models.dart';
import 'package:zenbu/services/mangayomi/eval/javascript/service.dart';
import 'package:zenbu/services/mangayomi/eval/interface.dart';
import 'package:zenbu/services/repo_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zenbu/services/progress_service.dart';
import 'package:zenbu/services/discord_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenbu/components/video_player_page/video_player_gesture_handler.dart';
import 'package:zenbu/components/video_player_page/buffered_seek_bar_painter.dart';
import 'package:zenbu/components/video_player_page/video_player_controls_overlay.dart';
import 'package:zenbu/components/video_player_page/video_player_settings_modal.dart';
import 'package:zenbu/components/video_player_page/custom_subtitle_view.dart';
import 'package:zenbu/components/video_player_page/video_player_error_view.dart';

class SkipTime {
  final double startTime;
  final double endTime;
  final String skipType;

  SkipTime({
    required this.startTime,
    required this.endTime,
    required this.skipType,
  });
}

enum VideoZoomMode { fit, fill, stretch }

class VideoPlayerPage extends StatefulWidget {
  final ExtEpisode episode;
  final ExtSource source;
  final String animeTitle;
  final String? coverImage;
  final int? malId;
  final int? mediaId;
  final List<ExtEpisode>? allEpisodes;

  const VideoPlayerPage({
    super.key,
    required this.episode,
    required this.source,
    required this.animeTitle,
    this.coverImage,
    this.malId,
    this.mediaId,
    this.allEpisodes,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage>
    with TickerProviderStateMixin {
  VideoZoomMode _zoomMode = VideoZoomMode.fit;

  void _toggleZoomMode() {
    _startControlsTimer();
    setState(() {
      switch (_zoomMode) {
        case VideoZoomMode.fit:
          _zoomMode = VideoZoomMode.fill;
          Fluttertoast.showToast(msg: 'Zoom: Fill');
          break;
        case VideoZoomMode.fill:
          _zoomMode = VideoZoomMode.stretch;
          Fluttertoast.showToast(msg: 'Zoom: Stretch');
          break;
        case VideoZoomMode.stretch:
          _zoomMode = VideoZoomMode.fit;
          Fluttertoast.showToast(msg: 'Zoom: Fit (Default)');
          break;
      }
    });
  }

  String _getZoomModeName() {
    switch (_zoomMode) {
      case VideoZoomMode.fill:
        return 'Fill';
      case VideoZoomMode.stretch:
        return 'Stretch';
      case VideoZoomMode.fit:
        return 'Fit';
    }
  }

  static const _pipChannel = MethodChannel('zenbu/pip');
  bool _isInPip = false;
  bool _lastIsPlaying = false;
  List<ExtVideo> _videos = [];
  ExtVideo? _selectedVideo;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  ExtensionService? _jsEngine;

  bool _isLoading = true;
  String _loadingText = 'Resolving stream links...';
  String? _errorMessage;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isHolding2x = false;
  double _currentPlaybackSpeed = 1.0;

  int _autoRetryCount = 0;
  static const int _maxAutoRetries = 10;
  bool _isAutoRetrying = false;
  bool _playerFailed = false;
  bool _wasPlaybackEstablished = false;

  final GlobalKey _repaintKey = GlobalKey();
  Uint8List? _lastFrameBytes;

  Future<void> _captureCurrentFrame() async {
    try {
      final RenderRepaintBoundary? boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null && boundary.hasSize) {
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          _lastFrameBytes = byteData.buffer.asUint8List();
        }
      }
    } catch (_) {}
  }

  Future<void> _triggerAutoRetry() async {
    if (!_wasPlaybackEstablished) return;

    if (_autoRetryCount < _maxAutoRetries) {
      _autoRetryCount++;

      if (!_isAutoRetrying) {
        _isAutoRetrying = true;

        await _captureCurrentFrame();

        final controller = _videoPlayerController;
        if (controller != null && controller.value.isInitialized) {
          final pos = controller.value.position;
          final dur = controller.value.duration;
          if (pos > Duration.zero) _currentPosition = pos;
          if (dur > Duration.zero) _totalDuration = dur;
          try {
            controller.pause();
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            _errorMessage = null;
            _isLoading = false;
          });
        }
      }

      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      _fetchVideoList();
    } else {
      _disposePlayer();
      if (mounted) {
        setState(() {
          _isAutoRetrying = false;
          _playerFailed = true;
          _lastFrameBytes = null;
          _errorMessage =
              'Unable to load video stream. Please check your internet connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _onLongPressStart() {
    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      _hideControls();
      _videoPlayerController!.setPlaybackSpeed(2.0);
      HapticFeedback.mediumImpact();
      setState(() {
        _isHolding2x = true;
      });
    }
  }

  void _onLongPressEnd() {
    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      _videoPlayerController!.setPlaybackSpeed(_currentPlaybackSpeed);
    }
    if (_isHolding2x) {
      setState(() {
        _isHolding2x = false;
      });
    }
  }

  late ExtEpisode _currentEpisode;
  ExtEpisode? _nextEpisode;
  DateTime? _lastProgressSaveTime;

  void _saveEpisodeProgress(int posSec, int durSec) {
    if (widget.mediaId == null || durSec <= 0) return;
    ProgressService.saveAnimeProgress(
      mediaId: widget.mediaId!,
      episodeUrl: _currentEpisode.url,
      episodeName: _currentEpisode.name,
      positionSeconds: posSec,
      durationSeconds: durSec,
    );
  }

  void _updateNextEpisode() {
    if (widget.allEpisodes == null || widget.allEpisodes!.isEmpty) {
      _nextEpisode = null;
      return;
    }
    _nextEpisode = findNextEpisode(_currentEpisode, widget.allEpisodes!);
  }

  void _playNextEpisode() {
    if (_nextEpisode == null) return;

    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      final pos = _videoPlayerController!.value.position.inSeconds;
      final dur = _videoPlayerController!.value.duration.inSeconds;
      _saveEpisodeProgress(pos, dur);
    }

    setState(() {
      _currentEpisode = _nextEpisode!;
      _updateNextEpisode();
      _videos = [];
      _selectedVideo = null;
      _currentPosition = Duration.zero;
      _wasPlaybackEstablished = false;
    });

    _fetchVideoList();
  }

  void _skipSeconds(int seconds) {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) {
      return;
    }

    final currentPos = _videoPlayerController!.value.position;
    final totalDuration = _videoPlayerController!.value.duration;

    Duration newPos = currentPos + Duration(seconds: seconds);
    if (newPos < Duration.zero) {
      newPos = Duration.zero;
    } else if (newPos > totalDuration) {
      newPos = totalDuration;
    }

    _videoPlayerController!.seekTo(newPos);
  }

  final ValueNotifier<SkipTime?> _activeSkipTimeNotifier =
      ValueNotifier<SkipTime?>(null);
  List<SkipTime> _skipTimes = [];

  ExtSubtitle? _selectedSubtitle;
  SubtitleController? _activeSubtitleCtrl;
  SubtitleConfig _subtitleConfig = const SubtitleConfig();

  Future<void> _loadSubtitleConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('zenbu_subtitle_config');
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _subtitleConfig = SubtitleConfig.fromJson(map);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveSubtitleConfig(SubtitleConfig config) async {
    setState(() {
      _subtitleConfig = config;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'zenbu_subtitle_config',
        jsonEncode(config.toJson()),
      );
    } catch (_) {}
  }

  bool _showControls = true;
  Timer? _controlsTimer;
  bool _isDraggingSlider = false;
  double _sliderDragValue = 0.0;

  List<ExtSubtitle> get _allSubtitles {
    final Map<String, ExtSubtitle> unique = {};
    for (final video in _videos) {
      for (final sub in video.subtitles) {
        if (sub.file.isNotEmpty) {
          final suffix = ' - ${video.quality}';
          final newLabel = sub.label.contains(suffix)
              ? sub.label
              : '${sub.label}$suffix';
          unique.putIfAbsent(
            sub.file,
            () => ExtSubtitle(file: sub.file, label: newLabel),
          );
        }
      }
    }
    return unique.values.toList();
  }

  @override
  void initState() {
    super.initState();
    _loadSubtitleConfig();
    _currentEpisode = widget.episode;
    _updateNextEpisode();
    _fetchVideoList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && route.animation != null) {
        if (route.animation!.isCompleted) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        } else {
          void listener(AnimationStatus status) {
            if (status == AnimationStatus.completed) {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]);
              route.animation?.removeStatusListener(listener);
            }
          }

          route.animation!.addStatusListener(listener);
        }
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    });

    _pipChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPipModeChanged':
          final isInPip = call.arguments as bool;
          if (mounted) {
            setState(() {
              _isInPip = isInPip;
            });
          }
          break;
        case 'onPipPlayPausePressed':
          if (_videoPlayerController != null &&
              _videoPlayerController!.value.isInitialized) {
            if (_videoPlayerController!.value.isPlaying) {
              await _videoPlayerController!.pause();
            } else {
              await _videoPlayerController!.play();
            }
          }
          break;
        case 'onPipRewindPressed':
          if (_videoPlayerController != null &&
              _videoPlayerController!.value.isInitialized) {
            final current = _videoPlayerController!.value.position;
            final target = current - const Duration(seconds: 10);
            await _videoPlayerController!.seekTo(
              target < Duration.zero ? Duration.zero : target,
            );
          }
          break;
        case 'onPipForwardPressed':
          if (_videoPlayerController != null &&
              _videoPlayerController!.value.isInitialized) {
            final current = _videoPlayerController!.value.position;
            final duration = _videoPlayerController!.value.duration;
            final target = current + const Duration(seconds: 10);
            await _videoPlayerController!.seekTo(
              target > duration ? duration : target,
            );
          }
          break;
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _activeSkipTimeNotifier.dispose();
    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      final pos = _videoPlayerController!.value.position.inSeconds;
      final dur = _videoPlayerController!.value.duration.inSeconds;
      _saveEpisodeProgress(pos, dur);
    }
    _disposePlayer();
    _disposeEngine();
    _lastFrameBytes = null;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    DiscordService.clearPresence();
    super.dispose();
  }

  void _disposePlayer() {
    _videoPlayerController?.removeListener(_onPlayerPositionChanged);
    _videoPlayerController?.removeListener(_onPlaybackStateChanged);
    _pipChannel.invokeMethod('setVideoPlaying', {'isPlaying': false});
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;
    _lastIsPlaying = false;
  }

  void _onPlaybackStateChanged() {
    if (_videoPlayerController == null) return;
    if (_videoPlayerController!.value.hasError) {
      if (!_isAutoRetrying) {
        _triggerAutoRetry();
      }
      return;
    }
    final isPlaying = _videoPlayerController!.value.isPlaying;
    if (isPlaying != _lastIsPlaying) {
      _lastIsPlaying = isPlaying;
      _pipChannel.invokeMethod('setVideoPlaying', {'isPlaying': isPlaying});
      if (isPlaying) {
        final curIdx = widget.allEpisodes != null
            ? widget.allEpisodes!.indexWhere(
                (e) => e.url == _currentEpisode.url,
              )
            : -1;
        final epNumStr = curIdx >= 0 ? "${curIdx + 1}" : "";
        final episodeText = epNumStr.isNotEmpty
            ? (_currentEpisode.name.contains(epNumStr)
                  ? _currentEpisode.name
                  : "Ep. $epNumStr: ${_currentEpisode.name}")
            : _currentEpisode.name;

        DiscordService.updateWatchingStatus(
          animeTitle: widget.animeTitle,
          episodeDetails: episodeText,
          imageUrl: widget.coverImage,
          mediaId: widget.mediaId,
        );
      }
    }
  }

  Future<void> _enterPipMode() async {
    try {
      await _pipChannel.invokeMethod('enterPip');
    } catch (_) {}
  }

  void _disposeEngine() {
    _jsEngine?.dispose();
    _jsEngine = null;
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControlsVisibility() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startControlsTimer();
  }

  void _hideControls() {
    _controlsTimer?.cancel();
    if (mounted && _showControls) {
      setState(() => _showControls = false);
    }
  }

  void _toggleOrientation() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  Future<void> _fetchVideoList() async {
    if (_autoRetryCount == 0) {
      setState(() {
        _isLoading = true;
        _loadingText = 'Resolving stream links...';
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }

    if (widget.source.id == -1) {
      final List<ExtSubtitle> localSubtitles = [];
      try {
        final videoFile = File(_currentEpisode.url);
        final parentDir = videoFile.parent;
        if (await parentDir.exists()) {
          final videoNameWithoutExt = videoFile.path.substring(
            0,
            videoFile.path.lastIndexOf('.'),
          );
          final subsExtensions = ['.srt', '.vtt', '.ass', '.ssa'];
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
                  String label = 'Local';
                  final suffix = subNameWithoutExt.substring(
                    videoNameWithoutExt.length,
                  );
                  if (suffix.startsWith('.')) {
                    label = suffix.substring(1).toUpperCase();
                  } else if (suffix.isNotEmpty) {
                    label = suffix.trim();
                  }
                  localSubtitles.add(
                    ExtSubtitle(file: entity.path, label: label),
                  );
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[LOCAL SUBTITLES SCAN ERROR] $e');
      }

      final localVideo = ExtVideo(
        url: _currentEpisode.url,
        originalUrl: _currentEpisode.url,
        quality: 'Local',
        headers: {},
        subtitles: localSubtitles,
      );

      setState(() {
        _videos = [localVideo];
        _selectedVideo = localVideo;
        _isLoading = false;
      });

      await _initializePlayer();
      return;
    }

    try {
      final engine = await RepoService.loadExtensionEngine(widget.source);
      final rawList = await engine.getVideoList(_currentEpisode.url);

      _disposeEngine();
      _jsEngine = engine;

      if (!mounted) return;

      final List<ExtVideo> list = rawList
          .map((e) => ExtVideo.fromJson(e.toJson()))
          .toList();

      if (list.isEmpty) {
        if (_wasPlaybackEstablished && _autoRetryCount < _maxAutoRetries) {
          _triggerAutoRetry();
          return;
        }
        _disposePlayer();
        setState(() {
          _isAutoRetrying = false;
          _playerFailed = _wasPlaybackEstablished;
          _lastFrameBytes = null;
          _errorMessage =
              'No video streams found. Please check your internet connection and try again.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _videos = list;
        _selectedVideo = list.first;
      });

      await _initializePlayer();
    } catch (e) {
      if (!mounted) return;
      if (_wasPlaybackEstablished && _autoRetryCount < _maxAutoRetries) {
        _triggerAutoRetry();
        return;
      }
      _disposePlayer();
      setState(() {
        _isAutoRetrying = false;
        _playerFailed = _wasPlaybackEstablished;
        _lastFrameBytes = null;
        _errorMessage =
            'Unable to load video stream. Please check your internet connection and try again.';
        _isLoading = false;
      });
    }
  }

  Future<_ResolvedStream> _resolveRedirects(
    String url,
    Map<String, String> headers,
  ) async {
    if (url.startsWith('data:')) {
      String? mime;
      final commaIndex = url.indexOf(',');
      if (commaIndex != -1) {
        final header = url.substring(5, commaIndex);
        final parts = header.split(';');
        if (parts.isNotEmpty && parts[0].isNotEmpty) {
          mime = parts[0];
        }
      }
      return _ResolvedStream(url, mime);
    }
    String currentUrl = url;
    String? contentType;
    final client = http.Client();
    try {
      var request = http.Request('GET', Uri.parse(currentUrl))
        ..followRedirects = false;
      headers.forEach((k, v) => request.headers[k] = v);

      var response = await client.send(request);
      contentType = response.headers['content-type'];
      await response.stream.listen((_) {}).cancel();

      int redirectCount = 0;
      while (response.statusCode >= 300 &&
          response.statusCode < 400 &&
          redirectCount < 10) {
        final location = response.headers['location'];
        if (location == null) break;

        final uri = Uri.parse(currentUrl);
        currentUrl = uri.resolve(location).toString();
        redirectCount++;

        request = http.Request('GET', Uri.parse(currentUrl))
          ..followRedirects = false;
        headers.forEach((k, v) => request.headers[k] = v);
        response = await client.send(request);
        contentType = response.headers['content-type'];
        await response.stream.listen((_) {}).cancel();
      }
    } catch (_) {
    } finally {
      client.close();
    }
    return _ResolvedStream(currentUrl, contentType);
  }

  Future<bool> _isLocalVideoFileValid(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      final length = await file.length();
      if (length < 50 * 1024) return false;

      final handle = await file.open(mode: FileMode.read);
      final bytes = await handle.read(512);
      await handle.close();

      if (bytes.isEmpty) return false;

      final snippet = utf8
          .decode(bytes, allowMalformed: true)
          .trimLeft()
          .toLowerCase();
      if (snippet.startsWith('<html>') ||
          snippet.startsWith('<!doctype html') ||
          snippet.startsWith('<head') ||
          snippet.startsWith('<script') ||
          snippet.startsWith('{"error"') ||
          snippet.startsWith('{"message"')) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _initializePlayer() async {
    final video = _selectedVideo;
    if (video == null) return;
    if (!mounted) return;

    if (_autoRetryCount == 0) {
      setState(() {
        _isLoading = true;
        _loadingText = 'Initializing player...';
      });
    }

    VideoPlayerController? newController;
    ChewieController? newChewieController;

    try {
      _skipTimes = [];
      _activeSkipTimeNotifier.value = null;

      final headers = Map<String, String>.from(video.headers);
      final hasUserAgent = headers.keys.any(
        (k) => k.toLowerCase() == 'user-agent',
      );
      if (!hasUserAgent) {
        headers['User-Agent'] =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
      }

      if (!mounted) return;

      final resolvedResult = await _resolveRedirects(video.url, headers);
      if (!mounted) return;

      final resolvedUrl = resolvedResult.url;
      final contentType = resolvedResult.contentType;

      VideoFormat? formatHint;
      final lowerUrl = resolvedUrl.toLowerCase();
      final lowerOrigUrl = video.url.toLowerCase();
      final lowerContentType = contentType?.toLowerCase() ?? '';
      if (lowerUrl.startsWith('data:application/x-mpegurl') ||
          lowerUrl.startsWith('data:application/vnd.apple.mpegurl') ||
          lowerUrl.contains('mpegurl') ||
          lowerUrl.contains('.m3u8') ||
          lowerUrl.contains('/hls/') ||
          lowerUrl.contains('type=m3u8') ||
          lowerOrigUrl.startsWith('data:application/x-mpegurl') ||
          lowerOrigUrl.startsWith('data:application/vnd.apple.mpegurl') ||
          lowerOrigUrl.contains('mpegurl') ||
          lowerOrigUrl.contains('.m3u8') ||
          lowerOrigUrl.contains('/hls/') ||
          lowerOrigUrl.contains('type=m3u8') ||
          lowerContentType.contains('mpegurl') ||
          lowerContentType.contains('m3u8')) {
        formatHint = VideoFormat.hls;
      } else if (lowerUrl.contains('.mpd') ||
          lowerUrl.contains('/dash/') ||
          lowerUrl.contains('type=mpd') ||
          lowerOrigUrl.contains('.mpd') ||
          lowerOrigUrl.contains('/dash/') ||
          lowerOrigUrl.contains('type=mpd') ||
          lowerContentType.contains('dash+xml')) {
        formatHint = VideoFormat.dash;
      }

      final isLocal =
          resolvedUrl.startsWith('file://') || File(resolvedUrl).existsSync();

      if (isLocal) {
        final filePath = resolvedUrl.startsWith('file://')
            ? Uri.parse(resolvedUrl).toFilePath()
            : resolvedUrl;
        final isValid = await _isLocalVideoFileValid(filePath);
        if (!isValid) {
          if (!mounted) return;
          setState(() {
            _errorMessage =
                'The downloaded video file is corrupt or invalid.\n(An HTML error page or incomplete stream was saved instead of video data).\n\nPlease delete this download and try again.';
            _isLoading = false;
          });
          return;
        }
        newController = VideoPlayerController.file(File(filePath));
      } else {
        newController = VideoPlayerController.networkUrl(
          Uri.parse(resolvedUrl),
          httpHeaders: headers,
          formatHint: formatHint,
        );
      }

      try {
        await newController.initialize();
      } catch (e, stack) {
        debugPrint('[VIDEO PLAYER INIT EXCEPTION] $e\n$stack');
        newController.dispose();
        newController = null;
        if (!mounted) return;
        _triggerAutoRetry();
        return;
      }
      if (!mounted) {
        newController.dispose();
        return;
      }

      Duration targetPosition = _currentPosition;
      if (targetPosition == Duration.zero && _autoRetryCount == 0) {
        final mediaId = widget.mediaId;
        if (mediaId != null) {
          final pos = await ProgressService.getAnimeEpisodeProgressPosition(
            mediaId: mediaId,
            episodeUrl: _currentEpisode.url,
            episodeName: _currentEpisode.name,
          );
          if (pos != null && pos > 0) {
            targetPosition = Duration(seconds: pos);
          }
        }
      }
      if (targetPosition > Duration.zero) {
        await newController.seekTo(targetPosition);
        if (!mounted) {
          newController.dispose();
          return;
        }
      }

      if (video.subtitles.isNotEmpty) {
        final firstSub = video.subtitles.first;
        final matchedSub = _allSubtitles.firstWhere(
          (s) => s.file == firstSub.file,
          orElse: () => firstSub,
        );
        await _loadSubtitle(matchedSub);
        if (!mounted) {
          newController.dispose();
          return;
        }
      } else {
        _selectedSubtitle = null;
        _activeSubtitleCtrl = null;
      }

      bool loadedLocalSkip = false;
      if (isLocal) {
        final filePath = resolvedUrl.startsWith('file://')
            ? Uri.parse(resolvedUrl).toFilePath()
            : (_currentEpisode.url.startsWith('file://')
                  ? Uri.parse(_currentEpisode.url).toFilePath()
                  : _currentEpisode.url);
        loadedLocalSkip = await _loadLocalSkipTimes(filePath);
        if (!mounted) {
          newController.dispose();
          return;
        }
      }

      final malId = widget.malId;
      if (!loadedLocalSkip && malId != null) {
        final curIdx = widget.allEpisodes != null
            ? widget.allEpisodes!.indexWhere(
                (e) => e.url == _currentEpisode.url,
              )
            : -1;
        final double? epNum = curIdx >= 0
            ? (curIdx + 1).toDouble()
            : ProgressService.parseEpisodeNumber(
                _currentEpisode.url,
                _currentEpisode.name,
              );
        if (epNum != null) {
          final durationSec = newController.value.duration.inSeconds;
          await _fetchSkipTimes(malId, epNum, durationSec);
          if (!mounted) {
            newController.dispose();
            return;
          }
        }
      }

      newChewieController = ChewieController(
        videoPlayerController: newController,
        autoPlay: false,
        looping: false,
        showControls: false,
        allowFullScreen: false,
        allowMuting: false,
        showOptions: false,
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
      );

      if (!mounted) {
        newController.dispose();
        newChewieController.dispose();
        return;
      }

      final oldVideoController = _videoPlayerController;
      final oldChewieController = _chewieController;
      oldVideoController?.removeListener(_onPlayerPositionChanged);
      oldVideoController?.removeListener(_onPlaybackStateChanged);

      newController.addListener(_onPlaybackStateChanged);
      newController.addListener(_onPlayerPositionChanged);

      if (!mounted) {
        newController.dispose();
        newChewieController.dispose();
        return;
      }

      final createdVideoCtrl = newController;
      final createdChewieCtrl = newChewieController;
      setState(() {
        _videoPlayerController = createdVideoCtrl;
        _chewieController = createdChewieCtrl;
        _currentPosition = targetPosition;
        _totalDuration = createdVideoCtrl.value.duration;
        _isLoading = false;
        _showControls = true;
        _isAutoRetrying = false;
        _playerFailed = false;
        _wasPlaybackEstablished = true;
        _autoRetryCount = 0;
        _errorMessage = null;
        _lastFrameBytes = null;
        _lastIsPlaying = true;
      });

      try {
        oldChewieController?.dispose();
      } catch (_) {}
      try {
        oldVideoController?.dispose();
      } catch (_) {}

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          await createdVideoCtrl.play();
          WakelockPlus.enable();
          _pipChannel.invokeMethod('setVideoPlaying', {'isPlaying': true});
        } catch (_) {}
      });

      _startControlsTimer();
    } catch (e) {
      try {
        newChewieController?.dispose();
      } catch (_) {}
      try {
        newController?.dispose();
      } catch (_) {}
      if (!mounted) return;
      if (_wasPlaybackEstablished && _autoRetryCount < _maxAutoRetries) {
        _triggerAutoRetry();
      } else {
        _disposePlayer();
        setState(() {
          _isAutoRetrying = false;
          _playerFailed = _wasPlaybackEstablished;
          _lastFrameBytes = null;
          _errorMessage =
              'Unable to load video stream. Please check your internet connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _fetchSubtitleBody(String url) async {
    const ua =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Safari/537.36';

    Map<String, String> base = {};
    ExtVideo? matchingVideo;
    for (final v in _videos) {
      if (v.subtitles.any((s) => s.file == url)) {
        matchingVideo = v;
        break;
      }
    }
    if (matchingVideo != null) {
      base = Map<String, String>.from(matchingVideo.headers);
    } else {
      base = Map<String, String>.from(_selectedVideo?.headers ?? {});
    }
    final hasUserAgent = base.keys.any((k) => k.toLowerCase() == 'user-agent');
    if (!hasUserAgent) {
      base['User-Agent'] = ua;
    }

    if (!base.containsKey('Origin') && !base.containsKey('origin')) {
      final originParam = Uri.tryParse(url)?.queryParameters['origin'];
      if (originParam != null && originParam.isNotEmpty) {
        base['Origin'] = originParam;
        base.putIfAbsent(
          'Referer',
          () => originParam.endsWith('/') ? originParam : '$originParam/',
        );
      } else {
        final ref = base['Referer'] ?? base['referer'] ?? '';
        final refUri = Uri.tryParse(ref);
        if (refUri != null) {
          base['Origin'] = '${refUri.scheme}://${refUri.host}';
        }
      }
    }

    final attempts = [
      () async {
        if (_jsEngine is JsExtensionService) {
          return await (_jsEngine as JsExtensionService).fetchUrl(url, base);
        }
        return null;
      },
      () async {
        final r = await http.get(Uri.parse(url), headers: base);
        return r.statusCode == 200
            ? utf8.decode(r.bodyBytes, allowMalformed: true)
            : null;
      },
      () async {
        final h = <String, String>{'User-Agent': ua};
        final ref = base['Referer'] ?? base['referer'];
        if (ref != null) h['Referer'] = ref;
        final r = await http.get(Uri.parse(url), headers: h);
        return r.statusCode == 200
            ? utf8.decode(r.bodyBytes, allowMalformed: true)
            : null;
      },
      () async {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': ua});
        return r.statusCode == 200
            ? utf8.decode(r.bodyBytes, allowMalformed: true)
            : null;
      },
      () async {
        final r = await http.get(Uri.parse(url));
        return r.statusCode == 200
            ? utf8.decode(r.bodyBytes, allowMalformed: true)
            : null;
      },
    ];

    for (final attempt in attempts) {
      final body = await attempt();
      if (body != null) return body;
    }
    return null;
  }

  Future<void> _loadSubtitle(ExtSubtitle sub) async {
    try {
      String? body;
      if (!sub.file.startsWith('http://') && !sub.file.startsWith('https://')) {
        final file = File(sub.file);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          body = utf8.decode(bytes, allowMalformed: true);
        }
      } else {
        final resolvedResult = await _resolveRedirects(
          sub.file,
          Map<String, String>.from(_selectedVideo?.headers ?? {}),
        );
        final resolvedUrl = resolvedResult.url;

        body = await _fetchSubtitleBody(resolvedUrl);
      }

      if (body == null) return;

      final format = body.trimLeft().startsWith('WEBVTT')
          ? SubtitleFormat.webvtt
          : SubtitleFormat.srt;
      final ctrl = SubtitleController.string(body, format: format);

      if (mounted) {
        setState(() {
          _selectedSubtitle = sub;
          _activeSubtitleCtrl = ctrl;
        });
      }
    } catch (_) {}
  }

  void _disableSubtitles() {
    setState(() {
      _selectedSubtitle = null;
      _activeSubtitleCtrl = null;
    });
  }

  void _setPlaybackSpeed(double speed) {
    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      _videoPlayerController!.setPlaybackSpeed(speed);
      setState(() {
        _currentPlaybackSpeed = speed;
      });
    }
  }

  void _showSettingsModal() {
    _startControlsTimer();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return VideoPlayerSettingsModal(
          videos: _videos,
          selectedVideo: _selectedVideo,
          onQualitySelected: (video) {
            _currentPosition =
                _videoPlayerController?.value.position ?? Duration.zero;
            setState(() => _selectedVideo = video);
            _initializePlayer();
          },
          subtitles: _allSubtitles,
          selectedSubtitle: _selectedSubtitle,
          onSubtitleSelected: (sub) {
            if (sub == null) {
              _disableSubtitles();
            } else {
              _loadSubtitle(sub);
            }
          },
          currentSpeed: _currentPlaybackSpeed,
          onSpeedSelected: _setPlaybackSpeed,
          subtitleConfig: _subtitleConfig,
          onSubtitleConfigChanged: _saveSubtitleConfig,
          previewImageUrl: widget.coverImage,
        );
      },
    );
  }

  Future<bool> _loadLocalSkipTimes(String videoFilePath) async {
    try {
      final dotIdx = videoFilePath.lastIndexOf('.');
      final jsonPath = dotIdx != -1
          ? '${videoFilePath.substring(0, dotIdx)}.json'
          : '$videoFilePath.json';
      final jsonFile = File(jsonPath);
      if (await jsonFile.exists()) {
        final content = await jsonFile.readAsString();
        final data = jsonDecode(content);
        final List<SkipTime> parsedSkips = [];
        if (data is List) {
          for (final item in data) {
            if (item is Map) {
              final startTime =
                  double.tryParse(item['startTime'].toString()) ?? 0.0;
              final endTime =
                  double.tryParse(item['endTime'].toString()) ?? 0.0;
              final skipType = item['skipType']?.toString() ?? 'op';
              parsedSkips.add(
                SkipTime(
                  startTime: startTime,
                  endTime: endTime,
                  skipType: skipType,
                ),
              );
            }
          }
        } else if (data is Map && data['results'] is List) {
          for (final item in data['results']) {
            final interval = item['interval'];
            if (interval is Map) {
              final startTime =
                  double.tryParse(interval['startTime'].toString()) ?? 0.0;
              final endTime =
                  double.tryParse(interval['endTime'].toString()) ?? 0.0;
              final skipType = item['skipType']?.toString() ?? 'op';
              parsedSkips.add(
                SkipTime(
                  startTime: startTime,
                  endTime: endTime,
                  skipType: skipType,
                ),
              );
            }
          }
        }
        if (parsedSkips.isNotEmpty) {
          if (mounted) {
            setState(() => _skipTimes = parsedSkips);
          }
          return true;
        }
      }
    } catch (e) {
      debugPrint('[LOAD LOCAL SKIP TIMES ERROR] $e');
    }
    return false;
  }

  Future<void> _fetchSkipTimes(
    int malId,
    double episodeNum,
    int durationSeconds,
  ) async {
    try {
      final url =
          'https://api.aniskip.com/v2/skip-times/$malId/$episodeNum?types[]=op&types[]=ed&types[]=mixed-op&types[]=mixed-ed&types[]=recap&episodeLength=$durationSeconds';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['found'] == true && data['results'] is List) {
          final List<SkipTime> parsedSkips = [];
          for (final item in data['results']) {
            final interval = item['interval'];
            if (interval is Map) {
              final startTime =
                  double.tryParse(interval['startTime'].toString()) ?? 0.0;
              final endTime =
                  double.tryParse(interval['endTime'].toString()) ?? 0.0;
              final skipType = item['skipType']?.toString() ?? 'op';
              parsedSkips.add(
                SkipTime(
                  startTime: startTime,
                  endTime: endTime,
                  skipType: skipType,
                ),
              );
            }
          }
          if (mounted) {
            setState(() => _skipTimes = parsedSkips);
          }
        }
      }
    } catch (_) {}
  }

  void _onPlayerPositionChanged() {
    if (_videoPlayerController == null) return;
    if (_videoPlayerController!.value.hasError) {
      if (!_isAutoRetrying) {
        _triggerAutoRetry();
      }
      return;
    }
    if (!_videoPlayerController!.value.isInitialized) {
      return;
    }

    if (!_isDraggingSlider) {
      setState(() {});
    }

    final pos = _videoPlayerController!.value.position;
    if (pos > Duration.zero) {
      _currentPosition = pos;
    }

    final currentPosSec = pos.inSeconds;
    final totalDurSec = _videoPlayerController!.value.duration.inSeconds;
    final now = DateTime.now();
    if (_lastProgressSaveTime == null ||
        now.difference(_lastProgressSaveTime!) > const Duration(seconds: 5)) {
      _lastProgressSaveTime = now;
      _saveEpisodeProgress(currentPosSec, totalDurSec);
    }

    final currentSec =
        _videoPlayerController!.value.position.inMilliseconds / 1000.0;
    SkipTime? matchingSkip;
    for (final skip in _skipTimes) {
      if (currentSec >= skip.startTime && currentSec <= skip.endTime) {
        matchingSkip = skip;
        break;
      }
    }
    if (matchingSkip != _activeSkipTimeNotifier.value) {
      _activeSkipTimeNotifier.value = matchingSkip;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Widget _buildSeekBar(
    Duration currentPosition,
    Duration totalDuration,
    Color primaryColor,
  ) {
    final double totalSec = totalDuration.inSeconds.toDouble();
    final double currentSec = currentPosition.inSeconds.toDouble().clamp(
      0.0,
      totalSec == 0 ? 1.0 : totalSec,
    );

    double bufferedSec = 0.0;
    if (_videoPlayerController != null) {
      for (final range in _videoPlayerController!.value.buffered) {
        bufferedSec = bufferedSec > range.end.inSeconds.toDouble()
            ? bufferedSec
            : range.end.inSeconds.toDouble();
      }
    }

    final double played = totalSec > 0 ? currentSec / totalSec : 0.0;
    final double buffered = totalSec > 0
        ? bufferedSec.clamp(0.0, totalSec) / totalSec
        : 0.0;

    double fractionFromGlobalX(double globalX) {
      final RenderBox? seekBox =
          _seekBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (seekBox == null) return 0.0;
      const double thumbR = 8.0;
      final double trackWidth = seekBox.size.width - thumbR * 2;
      final double localX = seekBox.globalToLocal(Offset(globalX, 0)).dx;
      return ((localX - thumbR) / trackWidth).clamp(0.0, 1.0);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final fraction = fractionFromGlobalX(details.globalPosition.dx);
        final targetSec = (fraction * totalSec).toInt();
        _videoPlayerController?.seekTo(Duration(seconds: targetSec));
        _startControlsTimer();
      },
      onHorizontalDragStart: (details) {
        setState(() => _isDraggingSlider = true);
      },
      onHorizontalDragUpdate: (details) {
        final fraction = fractionFromGlobalX(details.globalPosition.dx);
        setState(() {
          _sliderDragValue = fraction * totalSec;
        });
      },
      onHorizontalDragEnd: (_) {
        _videoPlayerController?.seekTo(
          Duration(seconds: _sliderDragValue.toInt()),
        );
        setState(() => _isDraggingSlider = false);
        _startControlsTimer();
      },
      child: SizedBox(
        key: _seekBarKey,
        height: 28,
        child: CustomPaint(
          painter: BufferedSeekBarPainter(
            played: played,
            buffered: buffered,
            playedColor: primaryColor,
            bufferedColor: primaryColor.withAlpha(100),
            trackColor: Colors.white24,
            trackHeight: 4.0,
            thumbRadius: 8.0,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  final GlobalKey _seekBarKey = GlobalKey();

  Widget _buildVideoDisplay() {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized ||
        _chewieController == null) {
      return const SizedBox.shrink();
    }

    final size = _videoPlayerController!.value.size;
    final double videoWidth = size.width > 0 ? size.width : 16.0;
    final double videoHeight = size.height > 0 ? size.height : 9.0;

    switch (_zoomMode) {
      case VideoZoomMode.fill:
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: videoWidth,
              height: videoHeight,
              child: Chewie(
                key: ValueKey(_chewieController),
                controller: _chewieController!,
              ),
            ),
          ),
        );
      case VideoZoomMode.stretch:
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: videoWidth,
              height: videoHeight,
              child: Chewie(
                key: ValueKey(_chewieController),
                controller: _chewieController!,
              ),
            ),
          ),
        );
      case VideoZoomMode.fit:
        return Center(
          child: AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: Chewie(
              key: ValueKey(_chewieController),
              controller: _chewieController!,
            ),
          ),
        );
    }
  }

  Widget _buildPlayerUI() {
    final primaryColor = Theme.of(context).colorScheme.primary;

    final bool isPlayerInitialized =
        _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized &&
        _chewieController != null;
    final bool isPlayerReady = isPlayerInitialized && !_isAutoRetrying;

    if (!isPlayerReady && _errorMessage != null) {
      return const SizedBox.shrink();
    }

    final totalDuration = isPlayerReady
        ? _videoPlayerController!.value.duration
        : (_totalDuration != Duration.zero ? _totalDuration : Duration.zero);
    final isBuffering =
        _isAutoRetrying ||
        (isPlayerReady && _videoPlayerController!.value.isBuffering);
    final currentPosition = isPlayerReady
        ? (_isDraggingSlider
              ? Duration(seconds: _sliderDragValue.toInt())
              : _videoPlayerController!.value.position)
        : _currentPosition;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (isPlayerInitialized)
          RepaintBoundary(key: _repaintKey, child: _buildVideoDisplay())
        else if (_lastFrameBytes != null)
          SizedBox.expand(
            child: Image.memory(
              _lastFrameBytes!,
              fit: _zoomMode == VideoZoomMode.fill
                  ? BoxFit.cover
                  : (_zoomMode == VideoZoomMode.stretch
                        ? BoxFit.fill
                        : BoxFit.contain),
            ),
          )
        else
          Container(color: Colors.black),

        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: VideoPlayerGestureHandler(
                  isLeft: true,
                  onTap: _toggleControlsVisibility,
                  onDoubleTap: () => _skipSeconds(-10),
                  onGestureTriggered: _hideControls,
                  onLongPressStart: _onLongPressStart,
                  onLongPressEnd: _onLongPressEnd,
                ),
              ),
              Expanded(
                child: VideoPlayerGestureHandler(
                  isLeft: false,
                  onTap: _toggleControlsVisibility,
                  onDoubleTap: () => _skipSeconds(10),
                  onGestureTriggered: _hideControls,
                  onLongPressStart: _onLongPressStart,
                  onLongPressEnd: _onLongPressEnd,
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: 28.0,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedScale(
              scale: _isHolding2x ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: _isHolding2x ? Curves.easeOutBack : Curves.easeIn,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _isHolding2x ? 1.0 : 0.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    left: false,
                    right: false,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '2x',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.fast_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        if (isBuffering)
          Center(
            key: const Key('buffering_spinner_container'),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: CircularProgressIndicator(
                  key: const Key('buffering_spinner'),
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            ),
          ),

        VideoPlayerControlsOverlay(
          visible: _showControls,
          isHolding: _isHolding2x,
          animeTitle: widget.animeTitle,
          episodeName: _currentEpisode.name,
          hasNextEpisode: _nextEpisode != null,
          isPlaying:
              isPlayerReady &&
              (_videoPlayerController?.value.isPlaying ?? false),
          currentPositionText: _formatDuration(currentPosition),
          totalDurationText: _formatDuration(totalDuration),
          seekBar: _buildSeekBar(currentPosition, totalDuration, primaryColor),
          onZoomPressed: _toggleZoomMode,
          zoomModeName: _getZoomModeName(),
          onBackPressed: () async {
            final navigator = Navigator.of(context);
            await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            await SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
            ]);
            navigator.pop();
          },
          onNextEpisodePressed: () {
            _startControlsTimer();
            _playNextEpisode();
          },
          onSettingsPressed: _showSettingsModal,
          onPipPressed: _enterPipMode,
          onPlayPausePressed: () async {
            _startControlsTimer();
            final ctrl = _videoPlayerController;
            if (ctrl != null && ctrl.value.isInitialized) {
              if (ctrl.value.isPlaying) {
                await ctrl.pause();
                await WakelockPlus.disable();
              } else {
                await ctrl.play();
                await WakelockPlus.enable();
              }
              if (mounted) setState(() {});
            }
          },
          onReplayPressed: () {
            _startControlsTimer();
            _skipSeconds(-10);
          },
          onForwardPressed: () {
            _startControlsTimer();
            _skipSeconds(10);
          },
          onSkip85Pressed: () {
            _startControlsTimer();
            _skipSeconds(85);
          },
          onRotatePressed: _toggleOrientation,
          onBackgroundTap: _toggleControlsVisibility,
          onLongPressStart: _onLongPressStart,
          onLongPressEnd: _onLongPressEnd,
        ),

        if (_activeSubtitleCtrl != null &&
            _videoPlayerController != null &&
            _videoPlayerController!.value.isInitialized)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 135),
            curve: _showControls ? Curves.easeOutCubic : Curves.easeInCubic,
            bottom: _showControls ? 86.0 : 20.0,
            left: 16.0,
            right: 16.0,
            child: IgnorePointer(
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _videoPlayerController!,
                builder: (context, value, child) {
                  final posMs = value.position.inMilliseconds;
                  final text = _activeSubtitleCtrl!.textFromMilliseconds(
                    posMs,
                    _activeSubtitleCtrl!.subtitles,
                  );
                  if (text.isEmpty) return const SizedBox.shrink();
                  return CustomSubtitleView(
                    text: text,
                    config: _subtitleConfig,
                  );
                },
              ),
            ),
          ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 135),
          curve: _showControls ? Curves.easeOutCubic : Curves.easeInCubic,
          bottom: _showControls ? 124.0 : 90.0,
          right: 24.0,
          child: ValueListenableBuilder<SkipTime?>(
            valueListenable: _activeSkipTimeNotifier,
            builder: (context, activeSkip, child) {
              if (activeSkip == null) return const SizedBox.shrink();
              return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  _videoPlayerController!.seekTo(
                    Duration(seconds: activeSkip.endTime.toInt()),
                  );
                },
                icon: const Icon(Icons.skip_next),
                label: Text(
                  activeSkip.skipType == 'op' ||
                          activeSkip.skipType == 'mixed-op'
                      ? 'Skip Opening'
                      : activeSkip.skipType == 'ed' ||
                            activeSkip.skipType == 'mixed-ed'
                      ? 'Skip Ending'
                      : 'Skip Recap',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInPip) {
      if (_videoPlayerController != null &&
          _videoPlayerController!.value.isInitialized &&
          _chewieController != null) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: _buildVideoDisplay(),
        );
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        navigator.pop(result);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: null,
        body: Center(
          child: _isLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator.adaptive(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _loadingText,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                )
              : (_playerFailed || _errorMessage != null)
              ? VideoPlayerErrorView(
                  playerFailed: _playerFailed,
                  errorMessage: _errorMessage,
                  isLocalSource: widget.source.id == -1,
                  episodeUrl: widget.episode.url,
                  onRetry: () {
                    if (_playerFailed) {
                      setState(() {
                        _autoRetryCount = 0;
                        _isAutoRetrying = true;
                        _playerFailed = false;
                        _errorMessage = null;
                      });
                    }
                    _fetchVideoList();
                  },
                )
              : _buildPlayerUI(),
        ),
      ),
    );
  }
}

double? parseEpisodeNumber(ExtEpisode episode) {
  return ProgressService.parseEpisodeNumber(episode.url, episode.name);
}

class _ResolvedStream {
  final String url;
  final String? contentType;
  _ResolvedStream(this.url, this.contentType);
}

ExtEpisode? findNextEpisode(ExtEpisode current, List<ExtEpisode> allEpisodes) {
  final currentIndex = allEpisodes.indexWhere((e) => e.url == current.url);
  if (currentIndex != -1) {
    if (currentIndex + 1 < allEpisodes.length) {
      return allEpisodes[currentIndex + 1];
    }
    return null;
  }

  final currentNum = parseEpisodeNumber(current);
  if (currentNum != null) {
    ExtEpisode? bestMatch;
    double? bestMatchNum;
    for (final ep in allEpisodes) {
      final num = parseEpisodeNumber(ep);
      if (num != null && num > currentNum) {
        if (bestMatchNum == null || num < bestMatchNum) {
          bestMatch = ep;
          bestMatchNum = num;
        }
      }
    }
    return bestMatch;
  }

  return null;
}
