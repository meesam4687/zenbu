import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenbu/models/extensions_models.dart';
import 'package:zenbu/services/js_engine.dart';
import 'package:zenbu/services/repo_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MangaReaderPage extends StatefulWidget {
  final List<ExtEpisode> chapters;
  final int currentIndex;
  final ExtSource source;
  final String mangaTitle;
  final int? mediaId;

  const MangaReaderPage({
    super.key,
    required this.chapters,
    required this.currentIndex,
    required this.source,
    required this.mangaTitle,
    this.mediaId,
  });

  @override
  State<MangaReaderPage> createState() => _MangaReaderPageState();
}

class _MangaReaderPageState extends State<MangaReaderPage> {
  late int _currentChapterIndex;
  List<dynamic> _pages = [];
  bool _isLoading = true;
  String? _errorMessage;
  JsEngine? _jsEngine;

  bool _isWebtoonMode = true;
  bool _showControls = true;
  int _currentPageIndex = 0;

  final ScrollController _scrollController = ScrollController();
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.currentIndex;
    _loadReadingModePreference();
    _loadChapterPages();
    _scrollController.addListener(_onScroll);
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pageController?.dispose();
    _jsEngine?.dispose();
    super.dispose();
  }

  Future<void> _loadReadingModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isWebtoon = prefs.getBool('manga_reader_webtoon') ?? true;
    setState(() {
      _isWebtoonMode = isWebtoon;
      if (!_isWebtoonMode) {
        _pageController = PageController(initialPage: _currentPageIndex);
      }
    });
  }

  Future<void> _toggleReadingMode() async {
    final prefs = await SharedPreferences.getInstance();
    final newMode = !_isWebtoonMode;
    await prefs.setBool('manga_reader_webtoon', newMode);
    setState(() {
      _isWebtoonMode = newMode;
      if (_isWebtoonMode) {
        _pageController?.dispose();
        _pageController = null;
      } else {
        _pageController = PageController(initialPage: _currentPageIndex);
      }
    });
  }

  void _onScroll() {
    if (!_isWebtoonMode || _pages.isEmpty) return;
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final curScroll = _scrollController.position.pixels;
      if (maxScroll > 0) {
        final ratio = (curScroll / maxScroll).clamp(0.0, 1.0);
        final estimatedPage = (ratio * (_pages.length - 1)).round();
        if (estimatedPage != _currentPageIndex) {
          setState(() {
            _currentPageIndex = estimatedPage;
          });
        }
      }
    }
  }

  Future<void> _loadChapterPages() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _pages = [];
      _currentPageIndex = 0;
    });

    try {
      _jsEngine?.dispose();
      _jsEngine = await RepoService.loadExtensionEngine(widget.source);
      final currentChapter = widget.chapters[_currentChapterIndex];
      final rawPages = await _jsEngine!.getPageList(currentChapter.url);

      final List<Map<String, dynamic>> standardizedPages = [];
      if (rawPages.isNotEmpty) {
        final firstUrl = rawPages.first is Map
            ? (rawPages.first['url'] ?? '')
            : rawPages.first.toString();
        final headers = await _jsEngine!.getHeaders(firstUrl);

        for (final page in rawPages) {
          if (page is Map) {
            standardizedPages.add({
              'url': page['url'] as String? ?? '',
              'headers': Map<String, String>.from(page['headers'] ?? headers),
            });
          } else {
            standardizedPages.add({'url': page.toString(), 'headers': headers});
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _pages = standardizedPages;
        _isLoading = false;
        if (!_isWebtoonMode) {
          _pageController?.dispose();
          _pageController = PageController(initialPage: 0);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load pages: $e';
        _isLoading = false;
      });
    }
  }

  void _goToChapter(int index) {
    if (index >= 0 && index < widget.chapters.length) {
      setState(() {
        _currentChapterIndex = index;
      });
      _loadChapterPages();
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentChapter = widget.chapters[_currentChapterIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: _toggleControls,
            behavior: HitTestBehavior.translucent,
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator.adaptive(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading pages...',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _loadChapterPages,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _pages.isEmpty
                ? const Center(
                    child: Text(
                      'No pages found for this chapter.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : _isWebtoonMode
                ? _buildWebtoonReader()
                : _buildSinglePageReader(),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: _buildHeader(currentChapter),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: _showControls ? 0 : -120,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildWebtoonReader() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60,
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        final page = _pages[index];
        final url = page['url'] as String;
        final headers = Map<String, String>.from(page['headers'] ?? {});

        return CachedNetworkImage(
          imageUrl: url,
          httpHeaders: headers,
          fit: BoxFit.fitWidth,
          width: double.infinity,
          placeholder: (context, url) => Container(
            height: 400,
            color: Colors.black,
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 300,
            color: Colors.grey.shade900,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSinglePageReader() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _pages.length,
      onPageChanged: (index) {
        setState(() {
          _currentPageIndex = index;
        });
      },
      itemBuilder: (context, index) {
        final page = _pages[index];
        final url = page['url'] as String;
        final headers = Map<String, String>.from(page['headers'] ?? {});

        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: url,
              httpHeaders: headers,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 300,
                color: Colors.transparent,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 36,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ExtEpisode chapter) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.mangaTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              chapter.name,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isWebtoonMode ? Icons.view_day : Icons.swap_horizontal_circle,
              color: Colors.white,
            ),
            tooltip: _isWebtoonMode
                ? 'Switch to Single Page'
                : 'Switch to Webtoon Scroll',
            onPressed: _toggleReadingMode,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final hasPrev = _currentChapterIndex > 0;
    final hasNext = _currentChapterIndex < widget.chapters.length - 1;

    return Container(
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.95)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Page ${_currentPageIndex + 1} / ${_pages.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: hasPrev
                    ? () => _goToChapter(_currentChapterIndex - 1)
                    : null,
                icon: const Icon(Icons.skip_previous, size: 18),
                label: const Text('Prev'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white30,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),

              Text(
                'Chapter ${_currentChapterIndex + 1} of ${widget.chapters.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),

              ElevatedButton.icon(
                onPressed: hasNext
                    ? () => _goToChapter(_currentChapterIndex + 1)
                    : null,
                icon: const Icon(Icons.skip_next, size: 18),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white30,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
