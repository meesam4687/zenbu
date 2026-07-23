import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_subtitle/flutter_subtitle.dart' hide Subtitle;
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:zenbu/services/mangayomi/models/extensions_models.dart';
import 'package:zenbu/services/mangayomi/eval/javascript/service.dart';
import 'package:zenbu/services/mangayomi/eval/interface.dart';
import 'package:zenbu/services/repo_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zenbu/services/progress_service.dart';
import 'package:zenbu/services/discord_service.dart';
import 'package:zenbu/components/video_player_page/video_player_gesture_handler.dart';
import 'package:zenbu/components/video_player_page/buffered_seek_bar_painter.dart';
import 'package:zenbu/components/video_player_page/video_player_controls_overlay.dart';

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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
    final isPlaying = _videoPlayerController!.value.isPlaying;
    if (isPlaying != _lastIsPlaying) {
      _lastIsPlaying = isPlaying;
      _pipChannel.invokeMethod('setVideoPlaying', {'isPlaying': isPlaying});
      if (isPlaying) {
        final epNumDouble = parseEpisodeNumber(_currentEpisode);
        final epNumStr = epNumDouble != null
            ? epNumDouble.toString().replaceAll(RegExp(r'\.0$'), '')
            : _currentEpisode.name;
        final episodeText = epNumDouble != null
            ? "Episode: $epNumStr"
            : epNumStr;

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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
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
    setState(() {
      _isLoading = true;
      _loadingText = 'Resolving stream links...';
      _errorMessage = null;
    });

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
        setState(() {
          _errorMessage = 'No video streams found for this episode.';
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
      setState(() {
        _errorMessage = 'Failed to load video links: $e';
        _isLoading = false;
      });
    }
  }

  Future<_ResolvedStream> _resolveRedirects(
    String url,
    Map<String, String> headers,
  ) async {
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

  Future<void> _initializePlayer() async {
    if (_selectedVideo == null) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _loadingText = 'Initializing player...';
    });

    try {
      _disposePlayer();

      _skipTimes = [];
      _activeSkipTimeNotifier.value = null;

      final headers = Map<String, String>.from(_selectedVideo!.headers);
      final hasUserAgent = headers.keys.any(
        (k) => k.toLowerCase() == 'user-agent',
      );
      if (!hasUserAgent) {
        headers['User-Agent'] =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
      }

      if (!mounted) return;

      final resolvedResult = await _resolveRedirects(
        _selectedVideo!.url,
        headers,
      );
      if (!mounted) return;

      final resolvedUrl = resolvedResult.url;
      final contentType = resolvedResult.contentType;

      VideoFormat? formatHint;
      final lowerUrl = resolvedUrl.toLowerCase();
      final lowerOrigUrl = _selectedVideo!.url.toLowerCase();
      final lowerContentType = contentType?.toLowerCase() ?? '';
      if (lowerUrl.contains('.m3u8') ||
          lowerUrl.contains('/hls/') ||
          lowerUrl.contains('type=m3u8') ||
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
        _videoPlayerController = VideoPlayerController.file(File(filePath));
      } else {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(resolvedUrl),
          httpHeaders: headers,
          formatHint: formatHint,
        );
      }

      await _videoPlayerController!.initialize();
      if (!mounted) return;

      _videoPlayerController!.addListener(_onPlaybackStateChanged);

      if (widget.mediaId != null) {
        final pos = await ProgressService.getAnimeEpisodeProgressPosition(
          mediaId: widget.mediaId!,
          episodeUrl: _currentEpisode.url,
          episodeName: _currentEpisode.name,
        );
        if (pos != null) {
          await _videoPlayerController!.seekTo(Duration(seconds: pos));
        }
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        showControls: false,
        allowFullScreen: false,
        allowMuting: false,
        showOptions: false,
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
      );

      if (_selectedVideo!.subtitles.isNotEmpty) {
        final firstSub = _selectedVideo!.subtitles.first;
        final matchedSub = _allSubtitles.firstWhere(
          (s) => s.file == firstSub.file,
          orElse: () => firstSub,
        );
        await _loadSubtitle(matchedSub);
        if (!mounted) return;
      } else {
        _selectedSubtitle = null;
        _activeSubtitleCtrl = null;
      }

      if (_currentPosition != Duration.zero) {
        await _videoPlayerController!.seekTo(_currentPosition);
        if (!mounted) return;
      }

      bool loadedLocalSkip = false;
      if (isLocal) {
        final filePath = resolvedUrl.startsWith('file://')
            ? Uri.parse(resolvedUrl).toFilePath()
            : (_currentEpisode.url.startsWith('file://')
                ? Uri.parse(_currentEpisode.url).toFilePath()
                : _currentEpisode.url);
        loadedLocalSkip = await _loadLocalSkipTimes(filePath);
        if (!mounted) return;
      }

      if (!loadedLocalSkip && widget.malId != null) {
        final double? epNum = parseEpisodeNumber(_currentEpisode);
        if (epNum != null) {
          final durationSec = _videoPlayerController!.value.duration.inSeconds;
          await _fetchSkipTimes(widget.malId!, epNum, durationSec);
          if (!mounted) return;
        }
      }

      _videoPlayerController!.addListener(_onPlayerPositionChanged);

      await _videoPlayerController!.play();

      WakelockPlus.enable();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _showControls = true;
      });
      _startControlsTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to play video stream: $e';
        _isLoading = false;
      });
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

  void _showSubtitleSelector() {
    final subtitles = _allSubtitles;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'Select Subtitles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text('Off'),
                      trailing: _selectedSubtitle == null
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).pop();
                        _disableSubtitles();
                      },
                    ),
                    ...subtitles.map((sub) {
                      final isSelected = _selectedSubtitle?.file == sub.file;
                      return ListTile(
                        title: Text(
                          sub.label,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          Navigator.of(context).pop();
                          if (!isSelected) _loadSubtitle(sub);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQualitySelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'Select Video Quality',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    final isSel = video == _selectedVideo;
                    return ListTile(
                      title: Text(
                        video.quality,
                        style: TextStyle(
                          fontWeight: isSel
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSel
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      trailing: isSel
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).pop();
                        if (!isSel) {
                          _currentPosition =
                              _videoPlayerController?.value.position ??
                              Duration.zero;
                          setState(() => _selectedVideo = video);
                          _initializePlayer();
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) {
      return;
    }

    if (!_isDraggingSlider) {
      setState(() {});
    }

    final currentPosSec = _videoPlayerController!.value.position.inSeconds;
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

  Widget _buildPlayerUI() {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized ||
        _chewieController == null) {
      return const SizedBox.shrink();
    }

    final totalDuration = _videoPlayerController!.value.duration;
    final isBuffering = _videoPlayerController!.value.isBuffering;
    final currentPosition = _isDraggingSlider
        ? Duration(seconds: _sliderDragValue.toInt())
        : _videoPlayerController!.value.position;

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: Chewie(controller: _chewieController!),
          ),
        ),

        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: VideoPlayerGestureHandler(
                  isLeft: true,
                  onTap: _toggleControlsVisibility,
                  onDoubleTap: () => _skipSeconds(-10),
                  onGestureTriggered: _hideControls,
                ),
              ),
              Expanded(
                child: VideoPlayerGestureHandler(
                  isLeft: false,
                  onTap: _toggleControlsVisibility,
                  onDoubleTap: () => _skipSeconds(10),
                  onGestureTriggered: _hideControls,
                ),
              ),
            ],
          ),
        ),

        if (isBuffering)
          Center(
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
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            ),
          ),

        if (_showControls)
          VideoPlayerControlsOverlay(
            animeTitle: widget.animeTitle,
            episodeName: _currentEpisode.name,
            hasNextEpisode: _nextEpisode != null,
            hasSubtitles: _allSubtitles.isNotEmpty,
            hasMultipleVideos: _videos.length > 1,
            isSubtitleActive: _selectedSubtitle != null,
            isPlaying: _videoPlayerController!.value.isPlaying,
            currentPositionText: _formatDuration(currentPosition),
            totalDurationText: _formatDuration(totalDuration),
            seekBar: _buildSeekBar(
              currentPosition,
              totalDuration,
              primaryColor,
            ),
            onBackPressed: () async {
              final navigator = Navigator.of(context);
              await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
              navigator.pop();
            },
            onNextEpisodePressed: () {
              _startControlsTimer();
              _playNextEpisode();
            },
            onSubtitlePressed: () {
              _startControlsTimer();
              _showSubtitleSelector();
            },
            onQualityPressed: () {
              _startControlsTimer();
              _showQualitySelector();
            },
            onPipPressed: _enterPipMode,
            onPlayPausePressed: () async {
              _startControlsTimer();
              if (_videoPlayerController!.value.isPlaying) {
                await _videoPlayerController!.pause();
                await WakelockPlus.disable();
              } else {
                await _videoPlayerController!.play();
                await WakelockPlus.enable();
              }
              setState(() {});
            },
            onReplayPressed: () {
              _startControlsTimer();
              final newPos =
                  _videoPlayerController!.value.position -
                  const Duration(seconds: 10);
              _videoPlayerController!.seekTo(
                newPos < Duration.zero ? Duration.zero : newPos,
              );
            },
            onForwardPressed: () {
              _startControlsTimer();
              final newPos =
                  _videoPlayerController!.value.position +
                  const Duration(seconds: 10);
              _videoPlayerController!.seekTo(
                newPos > totalDuration ? totalDuration : newPos,
              );
            },
            onSkip85Pressed: () {
              _startControlsTimer();
              final newPos =
                  _videoPlayerController!.value.position +
                  const Duration(seconds: 85);
              _videoPlayerController!.seekTo(
                newPos > totalDuration ? totalDuration : newPos,
              );
            },
            onRotatePressed: _toggleOrientation,
          ),

        if (_activeSubtitleCtrl != null && _videoPlayerController != null)
          Positioned(
            bottom: _showControls ? 76.0 : 20.0,
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
                  return SubtitleView(
                    text: text,
                    backgroundColor: Colors.transparent,
                    subtitleStyle: SubtitleStyle(
                      fontSize: 20.0,
                      textColor: Colors.white,
                      bordered: true,
                      borderStyle: const SubtitleBorderStyle(
                        strokeWidth: 2.0,
                        color: Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        Positioned(
          bottom: 90.0,
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
          body: Center(
            child: AspectRatio(
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            ),
          ),
        );
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
              : _errorMessage != null
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 54,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _fetchVideoList,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildPlayerUI(),
        ),
      ),
    );
  }
}

double? parseEpisodeNumber(ExtEpisode episode) {
  try {
    final parsed = jsonDecode(episode.url);
    if (parsed is Map && parsed.containsKey('num')) {
      return double.tryParse(parsed['num'].toString());
    }
  } catch (_) {}

  if (episode.url.contains('/')) {
    final parts = episode.url.split('/');
    final parsed = double.tryParse(parts.last);
    if (parsed != null) return parsed;
  }

  if (episode.url.contains('|')) {
    final parts = episode.url.split('|');
    final parsed = double.tryParse(parts.last);
    if (parsed != null) return parsed;
  }

  final match = RegExp(
    r'(?:episode|ep|e)\.?\s*(\d+(?:\.\d+)?)',
    caseSensitive: false,
  ).firstMatch(episode.name);
  if (match != null) return double.tryParse(match.group(1)!);

  final matchAny = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(episode.name);
  if (matchAny != null) return double.tryParse(matchAny.group(1)!);

  return null;
}

class _ResolvedStream {
  final String url;
  final String? contentType;
  _ResolvedStream(this.url, this.contentType);
}

ExtEpisode? findNextEpisode(ExtEpisode current, List<ExtEpisode> allEpisodes) {
  final currentNum = parseEpisodeNumber(current);
  if (currentNum == null) {
    final firstNum = allEpisodes.isNotEmpty
        ? parseEpisodeNumber(allEpisodes.first)
        : null;
    final lastNum = allEpisodes.isNotEmpty
        ? parseEpisodeNumber(allEpisodes.last)
        : null;
    final currentIndex = allEpisodes.indexWhere((e) => e.url == current.url);
    if (currentIndex == -1) return null;

    if (firstNum != null && lastNum != null && firstNum < lastNum) {
      if (currentIndex + 1 < allEpisodes.length) {
        return allEpisodes[currentIndex + 1];
      }
    } else {
      if (currentIndex - 1 >= 0) {
        return allEpisodes[currentIndex - 1];
      }
    }
    return null;
  }

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
