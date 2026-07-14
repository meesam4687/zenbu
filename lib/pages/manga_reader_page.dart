import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenbu/services/mangayomi/models/extensions_models.dart';
import 'package:zenbu/services/mangayomi/eval/interface.dart';
import 'package:zenbu/services/repo_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';
import 'package:zenbu/components/manga_reader_page/manga_header.dart';
import 'package:zenbu/components/manga_reader_page/manga_bottom_controls.dart';
import 'package:zenbu/services/progress_service.dart';
import 'package:zenbu/services/discord_service.dart';

class MangaReaderPage extends StatefulWidget {
  final List<ExtEpisode> chapters;
  final int currentIndex;
  final ExtSource source;
  final String mangaTitle;
  final int? mediaId;
  final String? coverImage;

  const MangaReaderPage({
    super.key,
    required this.chapters,
    required this.currentIndex,
    required this.source,
    required this.mangaTitle,
    this.mediaId,
    this.coverImage,
  });

  @override
  State<MangaReaderPage> createState() => _MangaReaderPageState();
}

class _MangaReaderPageState extends State<MangaReaderPage>
    with SingleTickerProviderStateMixin {
  late int _currentChapterIndex;
  List<dynamic> _pages = [];
  bool _isLoading = true;
  String? _errorMessage;
  ExtensionService? _jsEngine;

  bool _isWebtoonMode = true;
  bool _showControls = true;
  int _currentPageIndex = 0;

  final ScrollController _scrollController = ScrollController();
  PageController? _pageController;

  late AnimationController _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;
  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;
  int _pointerCount = 0;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.currentIndex;
    _loadReadingModePreference();
    _loadChapterPages();
    _scrollController.addListener(_onScroll);
    WakelockPlus.enable();

    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pageController?.dispose();
    _jsEngine?.dispose();
    _zoomAnimationController.dispose();
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    DiscordService.clearPresence();
    super.dispose();
  }

  void _onTransformationChanged() {
    final Matrix4 matrix = _transformationController.value;
    final double scale = matrix.getMaxScaleOnAxis();
    final bool zoomed = scale > 1.001;
    if (zoomed != _isZoomed) {
      setState(() {
        _isZoomed = zoomed;
      });
    }
  }

  void _handleDoubleTap() {
    if (_zoomAnimationController.isAnimating) return;

    final Matrix4 currentMatrix = _transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();

    final Matrix4 targetMatrix;
    if (currentScale > 1.001) {
      targetMatrix = Matrix4.identity();
    } else {
      final localPosition = _doubleTapDetails?.localPosition ?? Offset.zero;
      final double targetScale = 2.5;
      final double x = localPosition.dx;
      final double y = localPosition.dy;
      final translation = Matrix4.translationValues(x, y, 0.0);
      final scale = Matrix4.diagonal3Values(targetScale, targetScale, 1.0);
      final translationInverse = Matrix4.translationValues(-x, -y, 0.0);
      targetMatrix = translation * scale * translationInverse;
    }

    _zoomAnimation = Matrix4Tween(begin: currentMatrix, end: targetMatrix)
        .animate(
          CurvedAnimation(
            parent: _zoomAnimationController,
            curve: Curves.easeOut,
          ),
        );

    _zoomAnimationController.addListener(_onZoomAnimationTick);
    _zoomAnimationController.forward(from: 0.0).then((_) {
      _zoomAnimationController.removeListener(_onZoomAnimationTick);
    });
  }

  void _onZoomAnimationTick() {
    if (_zoomAnimation != null) {
      _transformationController.value = _zoomAnimation!.value;
    }
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
    _transformationController.value = Matrix4.identity();
    setState(() {
      _isWebtoonMode = newMode;
      _isZoomed = false;
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
          _saveCurrentPageProgress();
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
      final currentChapter = widget.chapters[_currentChapterIndex];
      final List<Map<String, dynamic>> standardizedPages = [];

      if (widget.source.id == -1) {
        final path = currentChapter.url;
        final isZip =
            path.toLowerCase().endsWith('.zip') ||
            path.toLowerCase().endsWith('.cbz');

        if (isZip) {
          final file = File(path);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final archive = ZipDecoder().decodeBytes(bytes);
            final imageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];

            final List<ArchiveFile> imageFiles = [];
            for (final archiveFile in archive) {
              if (archiveFile.isFile) {
                final nameLower = archiveFile.name.toLowerCase();
                if (imageExtensions.any((ext) => nameLower.endsWith(ext))) {
                  imageFiles.add(archiveFile);
                }
              }
            }

            imageFiles.sort((a, b) => a.name.compareTo(b.name));

            for (final archiveFile in imageFiles) {
              final content = archiveFile.content as List<int>;
              standardizedPages.add({
                'url': 'archive://${archiveFile.name}',
                'bytes': Uint8List.fromList(content),
                'headers': <String, String>{},
              });
            }
          } else {
            throw Exception('Manga archive file does not exist: $path');
          }
        } else {
          final directory = Directory(path);
          if (await directory.exists()) {
            final List<FileSystemEntity> files = directory.listSync();
            final imageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
            final imageFiles = files.whereType<File>().where((file) {
              final nameLower = file.path.toLowerCase();
              return imageExtensions.any((ext) => nameLower.endsWith(ext));
            }).toList();

            imageFiles.sort((a, b) => a.path.compareTo(b.path));

            for (final file in imageFiles) {
              standardizedPages.add({
                'url': file.path,
                'headers': <String, String>{},
              });
            }
          } else {
            throw Exception('Manga directory does not exist: $path');
          }
        }
      } else {
        _jsEngine?.dispose();
        _jsEngine = await RepoService.loadExtensionEngine(widget.source);
        final rawPages = await _jsEngine!.getPageList(currentChapter.url);

        if (rawPages.isNotEmpty) {
          final headers = _jsEngine!.getHeaders();

          for (final page in rawPages) {
            standardizedPages.add({
              'url': page.url,
              'headers': page.headers ?? headers,
            });
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
      _restoreProgress();

      final chapNumDouble = ProgressService.parseEpisodeNumber(
        currentChapter.url,
        currentChapter.name,
      );
      final chapNumStr = chapNumDouble != null
          ? chapNumDouble.toString().replaceAll(RegExp(r'\.0$'), '')
          : currentChapter.name;
      final chapterText = chapNumDouble != null
          ? "Chapter: $chapNumStr"
          : chapNumStr;

      DiscordService.updateReadingStatus(
        mangaTitle: widget.mangaTitle,
        chapterDetails: chapterText,
        imageUrl: widget.coverImage,
        mediaId: widget.mediaId,
      );
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

    if (_showControls) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentChapter = widget.chapters[_currentChapterIndex];

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            GestureDetector(
              onTap: _toggleControls,
              onDoubleTapDown: (details) {
                _doubleTapDetails = details;
              },
              onDoubleTap: _handleDoubleTap,
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
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
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

            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 350),
                curve: Curves.fastOutSlowIn,
                offset: _showControls ? Offset.zero : const Offset(0, -1),
                child: MangaHeader(
                  mangaTitle: widget.mangaTitle,
                  chapter: currentChapter,
                  isWebtoonMode: _isWebtoonMode,
                  onToggleReadingMode: _toggleReadingMode,
                  onBackPressed: () {
                    SystemChrome.setEnabledSystemUIMode(
                      SystemUiMode.edgeToEdge,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 350),
                curve: Curves.fastOutSlowIn,
                offset: _showControls ? Offset.zero : const Offset(0, 1),
                child: MangaBottomControls(
                  currentPageIndex: _currentPageIndex,
                  totalPages: _pages.length,
                  currentChapterIndex: _currentChapterIndex,
                  totalChapters: widget.chapters.length,
                  onPrevChapter: _currentChapterIndex > 0
                      ? () => _goToChapter(_currentChapterIndex - 1)
                      : null,
                  onNextChapter:
                      _currentChapterIndex < widget.chapters.length - 1
                      ? () => _goToChapter(_currentChapterIndex + 1)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebtoonReader() {
    return Listener(
      onPointerDown: (_) => setState(() => _pointerCount++),
      onPointerUp: (_) => setState(() => _pointerCount--),
      onPointerCancel: (_) => setState(() => _pointerCount--),
      child: InteractiveViewer(
        transformationController: _transformationController,
        constrained: true,
        panEnabled: _isZoomed || _pointerCount >= 2,
        minScale: 1.0,
        maxScale: 4.0,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: ListView.builder(
            controller: _scrollController,
            physics: (_isZoomed || _pointerCount >= 2)
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              final url = page['url'] as String;
              final headers = Map<String, String>.from(page['headers'] ?? {});
              final bytes = page['bytes'] as Uint8List?;
              return bytes != null
                  ? Image.memory(
                      bytes,
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                    )
                  : (url.startsWith('file://') || File(url).existsSync())
                  ? Image.file(
                      File(
                        url.startsWith('file://')
                            ? Uri.parse(url).toFilePath()
                            : url,
                      ),
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 400,
                        color: Colors.black,
                        child: const Center(
                          child: Text('Failed to load local image'),
                        ),
                      ),
                    )
                  : CachedNetworkImage(
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white30,
                              ),
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
                              Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 36,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSinglePageReader() {
    return Listener(
      onPointerDown: (_) => setState(() => _pointerCount++),
      onPointerUp: (_) => setState(() => _pointerCount--),
      onPointerCancel: (_) => setState(() => _pointerCount--),
      child: PageView.builder(
        controller: _pageController,
        physics: (_isZoomed || _pointerCount >= 2)
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(),
        itemCount: _pages.length,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
          _transformationController.value = Matrix4.identity();
          setState(() {
            _isZoomed = false;
          });
          _saveCurrentPageProgress();
        },
        itemBuilder: (context, index) {
          final page = _pages[index];
          final url = page['url'] as String;
          final headers = Map<String, String>.from(page['headers'] ?? {});
          final isActive = index == _currentPageIndex;

          return InteractiveViewer(
            transformationController: isActive
                ? _transformationController
                : null,
            panEnabled: _isZoomed || _pointerCount >= 2,
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: page['bytes'] != null
                  ? Image.memory(
                      page['bytes'] as Uint8List,
                      fit: BoxFit.contain,
                    )
                  : (url.startsWith('file://') || File(url).existsSync())
                  ? Image.file(
                      File(
                        url.startsWith('file://')
                            ? Uri.parse(url).toFilePath()
                            : url,
                      ),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(
                            height: 300,
                            child: Center(
                              child: Text('Failed to load local image'),
                            ),
                          ),
                    )
                  : CachedNetworkImage(
                      imageUrl: url,
                      httpHeaders: headers,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator.adaptive(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white30,
                            ),
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
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  void _saveCurrentPageProgress() {
    if (widget.mediaId == null || _pages.isEmpty) return;
    final currentChapter = widget.chapters[_currentChapterIndex];
    ProgressService.saveMangaProgress(
      mediaId: widget.mediaId!,
      chapterUrl: currentChapter.url,
      chapterName: currentChapter.name,
      pagesRead: _currentPageIndex + 1,
      totalPages: _pages.length,
    );
  }

  Future<void> _restoreProgress() async {
    if (widget.mediaId == null || _pages.isEmpty) return;
    final currentChapter = widget.chapters[_currentChapterIndex];
    final progress = await ProgressService.getMangaChapterProgress(
      mediaId: widget.mediaId!,
      chapterUrl: currentChapter.url,
      chapterName: currentChapter.name,
    );
    if (progress != null &&
        progress['pagesRead'] != null &&
        progress['pagesRead']! <= _pages.length) {
      final targetPage = progress['pagesRead']! - 1;
      if (mounted) {
        setState(() {
          _currentPageIndex = targetPage;
        });
        if (_isWebtoonMode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              final maxScroll = _scrollController.position.maxScrollExtent;
              final targetScroll =
                  (targetPage / (_pages.length - 1)) * maxScroll;
              _scrollController.jumpTo(targetScroll);
            }
          });
        } else {
          _pageController?.jumpToPage(targetPage);
        }
      }
    }
  }
}
