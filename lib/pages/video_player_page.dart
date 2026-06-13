import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:zenbu/models/extensions_models.dart';
import 'package:zenbu/services/repo_service.dart';

class VideoPlayerPage extends StatefulWidget {
  final ExtEpisode episode;
  final ExtSource source;
  final String animeTitle;

  const VideoPlayerPage({
    super.key,
    required this.episode,
    required this.source,
    required this.animeTitle,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  List<ExtVideo> _videos = [];
  ExtVideo? _selectedVideo;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String _loadingText = 'Resolving stream links...';
  String? _errorMessage;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _fetchVideoList();
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  void _disposePlayer() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;
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
      engine.dispose();

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

  Future<String> _resolveRedirects(
    String url,
    Map<String, String> headers,
  ) async {
    String currentUrl = url;
    try {
      final client = http.Client();
      var request = http.Request('GET', Uri.parse(currentUrl))
        ..followRedirects = false;
      headers.forEach((k, v) {
        request.headers[k] = v;
      });

      var response = await client.send(request);
      await response.stream.listen((_) {}).cancel();

      int redirectCount = 0;
      while (response.statusCode >= 300 &&
          response.statusCode < 400 &&
          redirectCount < 10) {
        final location = response.headers['location'];
        if (location == null) break;

        final uri = Uri.parse(currentUrl);
        final resolvedUri = uri.resolve(location);
        currentUrl = resolvedUri.toString();
        redirectCount++;

        request = http.Request('GET', Uri.parse(currentUrl))
          ..followRedirects = false;
        headers.forEach((k, v) {
          request.headers[k] = v;
        });
        response = await client.send(request);
        await response.stream.listen((_) {}).cancel();
      }
    } catch (_) {}
    return currentUrl;
  }

  Future<void> _initializePlayer() async {
    if (_selectedVideo == null) return;

    setState(() {
      _isLoading = true;
      _loadingText = 'Initializing player...';
    });

    try {
      _disposePlayer();

      final headers = Map<String, String>.from(_selectedVideo!.headers);

      final keysToRemove = headers.keys
          .where((k) => k.toLowerCase() == 'user-agent')
          .toList();
      for (var k in keysToRemove) {
        headers.remove(k);
      }
      headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

      final resolvedUrl = await _resolveRedirects(_selectedVideo!.url, headers);

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(resolvedUrl),
        httpHeaders: headers,
      );

      await _videoPlayerController!.initialize();

      if (_currentPosition != Duration.zero) {
        await _videoPlayerController!.seekTo(_currentPosition);
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowFullScreen: true,
        fullScreenByDefault: true,
        additionalOptions: (context) {
          return [
            OptionItem(
              onTap: (ctx) {
                Navigator.of(ctx).pop();
                _showQualitySelector();
              },
              iconData: Icons.settings,
              title: 'Quality',
            ),
          ];
        },
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 42,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _currentPosition =
                          _videoPlayerController?.value.position ??
                          Duration.zero;
                      _initializePlayer();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to play video stream: $e';
        _isLoading = false;
      });
    }
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
                    final isSel = video.url == _selectedVideo?.url;
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
                          setState(() {
                            _selectedVideo = video;
                          });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.animeTitle,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            Text(
              widget.episode.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          if (_videos.length > 1 && !_isLoading)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Select Quality',
              onPressed: _showQualitySelector,
            ),
        ],
      ),
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
            : _chewieController != null
            ? Chewie(controller: _chewieController!)
            : const SizedBox.shrink(),
      ),
    );
  }
}
