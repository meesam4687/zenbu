import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:html/parser.dart' show parseFragment;
import 'package:video_player/video_player.dart';
import 'package:zenbu/components/global/spoiler.dart';

class ReviewSegment {
  final String type;
  final String content;
  ReviewSegment(this.type, this.content);
}

List<ReviewSegment> _parseReviewBody(String body) {
  final List<ReviewSegment> segments = [];
  final regex = RegExp(r'(img\d*%?|webm|video)\((.*?)\)', caseSensitive: false);

  int lastIndex = 0;
  for (final match in regex.allMatches(body)) {
    if (match.start > lastIndex) {
      final text = body.substring(lastIndex, match.start);
      if (text.trim().isNotEmpty) {
        segments.add(ReviewSegment('text', text));
      }
    }

    final tag = match.group(1)!.toLowerCase();
    final url = match.group(2)!;

    if (tag.startsWith('img')) {
      segments.add(ReviewSegment('image', url));
    } else {
      segments.add(ReviewSegment('video', url));
    }

    lastIndex = match.end;
  }

  if (lastIndex < body.length) {
    final text = body.substring(lastIndex);
    if (text.trim().isNotEmpty) {
      segments.add(ReviewSegment('text', text));
    }
  }

  return segments;
}

String _convertHtmlToMarkdown(String html) {
  var out = html;

  out = out.replaceAll('~~~', '');

  out = out.replaceAllMapped(
    RegExp(r'^(#+)([^\s#])', multiLine: true),
    (match) => '${match.group(1)} ${match.group(2)}',
  );

  out = out.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

  out = out.replaceAll(RegExp(r'</?i>', caseSensitive: false), '*');
  out = out.replaceAll(RegExp(r'</?em>', caseSensitive: false), '*');

  out = out.replaceAll(RegExp(r'</?b>', caseSensitive: false), '**');
  out = out.replaceAll(RegExp(r'</?strong>', caseSensitive: false), '**');

  out = out.replaceAllMapped(
    RegExp(
      r'<a\s+(?:[^>]*?\s+)?href="([^"]*)"[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    ),
    (match) {
      final url = match.group(1) ?? '';
      final text = match.group(2) ?? '';
      return '[$text]($url)';
    },
  );

  final fragment = parseFragment(out);
  return fragment.text ?? out;
}

class LoopVideoPlayer extends StatefulWidget {
  const LoopVideoPlayer({super.key, required this.url});
  final String url;

  @override
  State<LoopVideoPlayer> createState() => _LoopVideoPlayerState();
}

class _LoopVideoPlayerState extends State<LoopVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
              _controller.setVolume(0.0);
              _controller.setLooping(true);
              _controller.play();
            }
          })
          .catchError((_) {
            if (mounted) {
              setState(() {
                _hasError = true;
              });
            }
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 120,
        color: Colors.black12,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.grey, size: 36),
            const SizedBox(height: 8),
            Text(
              "Failed to load video clip",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 200,
        color: Colors.black12,
        alignment: Alignment.center,
        child: const CircularProgressIndicator.adaptive(),
      );
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}

class ReviewPage extends StatelessWidget {
  const ReviewPage({
    super.key,
    required this.summary,
    required this.body,
    required this.score,
    this.username,
    this.avatarUrl,
  });

  final String summary;
  final String body;
  final int score;
  final String? username;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final segments = _parseReviewBody(body);

    return Scaffold(
      appBar: AppBar(title: const Text("Review")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          "Written by ",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        if (avatarUrl != null) ...[
                          ClipOval(
                            child: Image.network(
                              avatarUrl!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.account_circle, size: 24),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          username ?? "Unknown Reviewer",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    ...segments.map((segment) {
                      if (segment.type == 'image') {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 12.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            segment.content,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 100,
                                  color: Colors.black12,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                          ),
                        );
                      } else if (segment.type == 'video') {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 12.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: LoopVideoPlayer(url: segment.content),
                        );
                      } else {
                        return MarkdownBody(
                          data: preprocessSpoilers(
                            _convertHtmlToMarkdown(segment.content),
                          ),
                          selectable: true,
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ).copyWith(
                                p: const TextStyle(fontSize: 16, height: 1.5),
                              ),
                          inlineSyntaxes: [SpoilerSyntax()],
                          builders: {'spoiler': SpoilerBuilder()},
                        );
                      }
                    }),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                "Score: $score / 100",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
