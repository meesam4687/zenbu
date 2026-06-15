import 'dart:async';
import 'dart:convert';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_subtitle/flutter_subtitle.dart' hide Subtitle;
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:zenbu/models/extensions_models.dart';
import 'package:zenbu/services/js_engine.dart';
import 'package:zenbu/services/repo_service.dart';

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

class _BufferedSeekBarPainter extends CustomPainter {
  final double played;
  final double buffered;
  final Color playedColor;
  final Color bufferedColor;
  final Color trackColor;
  final double trackHeight;
  final double thumbRadius;

  _BufferedSeekBarPainter({
    required this.played,
    required this.buffered,
    required this.playedColor,
    required this.bufferedColor,
    required this.trackColor,
    required this.trackHeight,
    required this.thumbRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cy = size.height / 2;
    final double startX = thumbRadius;
    final double endX = size.width - thumbRadius;
    final double totalWidth = endX - startX;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = trackHeight
      ..strokeCap = StrokeCap.round;

    final bufferedPaint = Paint()
      ..color = bufferedColor
      ..strokeWidth = trackHeight
      ..strokeCap = StrokeCap.round;

    final playedPaint = Paint()
      ..color = playedColor
      ..strokeWidth = trackHeight
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(startX, cy), Offset(endX, cy), trackPaint);

    final double bufX = startX + buffered.clamp(0.0, 1.0) * totalWidth;
    if (bufX > startX) {
      canvas.drawLine(Offset(startX, cy), Offset(bufX, cy), bufferedPaint);
    }

    final double playX = startX + played.clamp(0.0, 1.0) * totalWidth;
    if (playX > startX) {
      canvas.drawLine(Offset(startX, cy), Offset(playX, cy), playedPaint);
    }

    canvas.drawCircle(
      Offset(playX, cy),
      thumbRadius,
      Paint()..color = playedColor,
    );
  }

  @override
  bool shouldRepaint(_BufferedSeekBarPainter old) =>
      old.played != played ||
      old.buffered != buffered ||
      old.playedColor != playedColor ||
      old.bufferedColor != bufferedColor ||
      old.trackColor != trackColor;
}

class VideoPlayerPage extends StatefulWidget {
  final ExtEpisode episode;
  final ExtSource source;
  final String animeTitle;
  final int? malId;

  const VideoPlayerPage({
    super.key,
    required this.episode,
    required this.source,
    required this.animeTitle,
    this.malId,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  List<ExtVideo> _videos = [];
  ExtVideo? _selectedVideo;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  JsEngine? _jsEngine;

  bool _isLoading = true;
  String _loadingText = 'Resolving stream links...';
  String? _errorMessage;
  Duration _currentPosition = Duration.zero;

  final ValueNotifier<SkipTime?> _activeSkipTimeNotifier =
      ValueNotifier<SkipTime?>(null);
  List<SkipTime> _skipTimes = [];

  ExtSubtitle? _selectedSubtitle;
  SubtitleController? _activeSubtitleCtrl;

  bool _isFullScreen = false;
  bool _showControls = true;
  Timer? _controlsTimer;
  bool _isDraggingSlider = false;
  double _sliderDragValue = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchVideoList();
  }

  @override
  void dispose() {
    _activeSkipTimeNotifier.dispose();
    _disposePlayer();
    _disposeEngine();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _disposePlayer() {
    _videoPlayerController?.removeListener(_onPlayerPositionChanged);
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;
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

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  Future<void> _fetchVideoList() async {
    setState(() {
      _isLoading = true;
      _loadingText = 'Resolving stream links...';
      _errorMessage = null;
    });

    try {
      final engine = await RepoService.loadExtensionEngine(widget.source);
      final rawList = await engine.getVideoList(widget.episode.url);

      _disposeEngine();
      _jsEngine = engine;

      if (!mounted) return;

      final List<ExtVideo> list = rawList
          .map((e) => ExtVideo.fromJson(Map<String, dynamic>.from(e)))
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
    try {
      final client = http.Client();
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
    } catch (_) {}
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
      final hasUserAgent = headers.keys.any((k) => k.toLowerCase() == 'user-agent');
      if (!hasUserAgent) {
        headers['User-Agent'] =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
      }

      if (!mounted) return;

      final resolvedResult = await _resolveRedirects(_selectedVideo!.url, headers);
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

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(resolvedUrl),
        httpHeaders: headers,
        formatHint: formatHint,
      );

      await _videoPlayerController!.initialize();
      if (!mounted) return;

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
        await _loadSubtitle(_selectedVideo!.subtitles.first);
        if (!mounted) return;
      } else {
        _selectedSubtitle = null;
      }

      if (_currentPosition != Duration.zero) {
        await _videoPlayerController!.seekTo(_currentPosition);
        if (!mounted) return;
      }

      if (widget.malId != null) {
        final double? epNum = parseEpisodeNumber(widget.episode);
        if (epNum != null) {
          final durationSec = _videoPlayerController!.value.duration.inSeconds;
          await _fetchSkipTimes(widget.malId!, epNum, durationSec);
          if (!mounted) return;
        }
      }

      _videoPlayerController!.addListener(_onPlayerPositionChanged);

      await _videoPlayerController!.play();

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

    final base = Map<String, String>.from(_selectedVideo?.headers ?? {});
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
      () => _jsEngine?.fetchUrl(url, base),
      () async {
        final r = await http.get(Uri.parse(url), headers: base);
        return r.statusCode == 200 ? utf8.decode(r.bodyBytes, allowMalformed: true) : null;
      },
      () async {
        final h = <String, String>{'User-Agent': ua};
        final ref = base['Referer'] ?? base['referer'];
        if (ref != null) h['Referer'] = ref;
        final r = await http.get(Uri.parse(url), headers: h);
        return r.statusCode == 200 ? utf8.decode(r.bodyBytes, allowMalformed: true) : null;
      },
      () async {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': ua});
        return r.statusCode == 200 ? utf8.decode(r.bodyBytes, allowMalformed: true) : null;
      },
      () async {
        final r = await http.get(Uri.parse(url));
        return r.statusCode == 200 ? utf8.decode(r.bodyBytes, allowMalformed: true) : null;
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
      final resolvedResult = await _resolveRedirects(
        sub.file,
        Map<String, String>.from(_selectedVideo?.headers ?? {}),
      );
      final resolvedUrl = resolvedResult.url;

      final body = await _fetchSubtitleBody(resolvedUrl);
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
    final subtitles = _selectedVideo?.subtitles ?? [];
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
          painter: _BufferedSeekBarPainter(
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
        GestureDetector(
          onTap: _toggleControlsVisibility,
          child: Center(
            child: AspectRatio(
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            ),
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

        if (_showControls) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleControlsVisibility,
              child: Container(color: Colors.black45),
            ),
          ),

          Positioned(
            top: _isFullScreen ? 24.0 : 0.0,
            left: 8.0,
            right: 8.0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (_isFullScreen) {
                    _toggleFullScreen();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.animeTitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    widget.episode.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              actions: [
                if ((_selectedVideo?.subtitles ?? []).isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.closed_caption,
                      color: _selectedSubtitle != null
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white,
                    ),
                    tooltip: 'Subtitles',
                    onPressed: () {
                      _startControlsTimer();
                      _showSubtitleSelector();
                    },
                  ),
                if (_videos.length > 1)
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    tooltip: 'Quality',
                    onPressed: () {
                      _startControlsTimer();
                      _showQualitySelector();
                    },
                  ),
              ],
            ),
          ),

          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 42,
                  icon: const Icon(Icons.replay_10, color: Colors.white),
                  onPressed: () {
                    _startControlsTimer();
                    final newPos =
                        _videoPlayerController!.value.position -
                        const Duration(seconds: 10);
                    _videoPlayerController!.seekTo(
                      newPos < Duration.zero ? Duration.zero : newPos,
                    );
                  },
                ),
                const SizedBox(width: 32),
                IconButton(
                  iconSize: 64,
                  icon: Icon(
                    _videoPlayerController!.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    _startControlsTimer();
                    if (_videoPlayerController!.value.isPlaying) {
                      _videoPlayerController!.pause();
                    } else {
                      _videoPlayerController!.play();
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(width: 32),
                IconButton(
                  iconSize: 42,
                  icon: const Icon(Icons.forward_10, color: Colors.white),
                  onPressed: () {
                    _startControlsTimer();
                    final newPos =
                        _videoPlayerController!.value.position +
                        const Duration(seconds: 10);
                    _videoPlayerController!.seekTo(
                      newPos > totalDuration ? totalDuration : newPos,
                    );
                  },
                ),
              ],
            ),
          ),

          Positioned(
            bottom: _isFullScreen ? 16.0 : 8.0,
            left: 16.0,
            right: 16.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _formatDuration(currentPosition),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSeekBar(
                        currentPosition,
                        totalDuration,
                        primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(totalDuration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isFullScreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: Colors.white,
                      ),
                      tooltip: 'Fullscreen',
                      onPressed: _toggleFullScreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        if (_activeSubtitleCtrl != null && _videoPlayerController != null)
          Positioned(
            bottom: _isFullScreen ? (_showControls ? 76.0 : 20.0) : 80.0,
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
                      fontSize: _isFullScreen ? 20.0 : 16.0,
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
          bottom: _isFullScreen ? 90.0 : 100.0,
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
    return PopScope(
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isFullScreen) _toggleFullScreen();
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
