import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zenbu/services/discord_service.dart';
import 'package:zenbu/services/mangayomi/eval/interface.dart';
import 'package:zenbu/services/mangayomi/models/extensions_models.dart';
import 'package:zenbu/services/progress_service.dart';
import 'package:zenbu/services/repo_service.dart';

enum NovelReaderTheme { light, dark, sepia, oled }

class NovelReaderPage extends StatefulWidget {
  final List<ExtEpisode> chapters;
  final int currentIndex;
  final ExtSource source;
  final String novelTitle;
  final int? mediaId;
  final String? coverImage;

  const NovelReaderPage({
    super.key,
    required this.chapters,
    required this.currentIndex,
    required this.source,
    required this.novelTitle,
    this.mediaId,
    this.coverImage,
  });

  @override
  State<NovelReaderPage> createState() => _NovelReaderPageState();
}

class _NovelReaderPageState extends State<NovelReaderPage> {
  late int _currentChapterIndex;
  String _chapterMarkdown = '';
  bool _isLoading = true;
  String? _errorMessage;
  ExtensionService? _jsEngine;
  final ScrollController _scrollController = ScrollController();

  double _fontSize = 16.0;
  double _lineHeight = 1.6;
  NovelReaderTheme _theme = NovelReaderTheme.dark;
  String _fontFamily = 'System';
  bool _showControls = true;
  double _scrollProgressPct = 0.0;

  DateTime? _pointerDownTime;
  Offset? _pointerDownPosition;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.currentIndex;
    _loadReaderPreferences();
    _loadChapterContent();
    _scrollController.addListener(_onScroll);
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _jsEngine?.dispose();
    DiscordService.clearPresence();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || widget.mediaId == null) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final currentChapter = widget.chapters[_currentChapterIndex];

    if (maxScroll <= 0) {
      if (_scrollProgressPct != 100.0) {
        setState(() {
          _scrollProgressPct = 100.0;
        });
      }
      ProgressService.saveMangaProgress(
        mediaId: widget.mediaId!,
        chapterUrl: currentChapter.url,
        chapterName: currentChapter.name,
        pagesRead: 100,
        totalPages: 100,
      );
      return;
    }

    final pct = (currentScroll / maxScroll * 100).clamp(0.0, 100.0);

    if ((pct - _scrollProgressPct).abs() >= 0.5) {
      setState(() {
        _scrollProgressPct = pct;
      });
    }

    final isFinished = pct >= 95.0;

    ProgressService.saveMangaProgress(
      mediaId: widget.mediaId!,
      chapterUrl: currentChapter.url,
      chapterName: currentChapter.name,
      pagesRead: isFinished ? 100 : pct.toInt(),
      totalPages: 100,
    );
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

  Future<void> _loadReaderPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('novel_font_size') ?? 16.0;
      _lineHeight = prefs.getDouble('novel_line_height') ?? 1.6;
      final themeIndex =
          prefs.getInt('novel_theme_mode') ?? NovelReaderTheme.dark.index;
      _theme = NovelReaderTheme
          .values[themeIndex.clamp(0, NovelReaderTheme.values.length - 1)];
      _fontFamily = prefs.getString('novel_font_family') ?? 'System';
    });
  }

  Future<void> _saveReaderPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('novel_font_size', _fontSize);
    await prefs.setDouble('novel_line_height', _lineHeight);
    await prefs.setInt('novel_theme_mode', _theme.index);
    await prefs.setString('novel_font_family', _fontFamily);
  }

  Future<void> _loadChapterContent() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _chapterMarkdown = '';
      _scrollProgressPct = 0.0;
    });

    try {
      final currentChapter = widget.chapters[_currentChapterIndex];

      _jsEngine?.dispose();
      _jsEngine = await RepoService.loadExtensionEngine(widget.source);

      String rawContent = await _jsEngine!.getHtmlContent(
        currentChapter.name,
        currentChapter.url,
      );

      if (rawContent.isEmpty) {
        rawContent = await _jsEngine!.cleanHtmlContent(rawContent);
      }

      final markdown = _convertHtmlToMarkdown(rawContent);

      if (!mounted) return;
      setState(() {
        _chapterMarkdown = markdown;
        _isLoading = false;
      });

      if (widget.mediaId != null) {
        final savedProgress = await ProgressService.getMangaChapterProgress(
          mediaId: widget.mediaId!,
          chapterUrl: currentChapter.url,
          chapterName: currentChapter.name,
        );

        double savedPct = 0.0;
        if (savedProgress != null && savedProgress['totalPages']! > 0) {
          savedPct = savedProgress['pagesRead']! / savedProgress['totalPages']!;
          setState(() {
            _scrollProgressPct = (savedPct * 100).clamp(0.0, 100.0);
          });
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final maxScroll = _scrollController.position.maxScrollExtent;
            if (maxScroll <= 0) {
              setState(() {
                _scrollProgressPct = 100.0;
              });
              ProgressService.saveMangaProgress(
                mediaId: widget.mediaId!,
                chapterUrl: currentChapter.url,
                chapterName: currentChapter.name,
                pagesRead: 100,
                totalPages: 100,
              );
            } else if (savedPct > 0) {
              _scrollController.jumpTo(
                (maxScroll * savedPct).clamp(0.0, maxScroll),
              );
            } else {
              _scrollController.jumpTo(0);
            }
          }
        });
      } else if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }

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
        mangaTitle: widget.novelTitle,
        chapterDetails: chapterText,
        imageUrl: widget.coverImage,
        mediaId: widget.mediaId,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load chapter content: $e';
      });
    }
  }

  String _convertHtmlToMarkdown(String html) {
    if (html.trim().isEmpty) return '';

    try {
      String cleanedHtml = html
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\\n', '\n')
          .replaceAll(r'<br>', '\n')
          .replaceAll(r'<br/>', '\n')
          .replaceAll(r'<br />', '\n');

      final document = html_parser.parse(cleanedHtml);

      document
          .querySelectorAll('script, style, iframe, noscript')
          .forEach((e) => e.remove());

      final body = document.body;
      if (body == null) return html;

      final buffer = StringBuffer();

      void processNode(dynamic node) {
        if (node is html_dom.Text || node.nodeType == 3) {
          final text = node.text;
          if (text != null && text.trim().isNotEmpty) {
            buffer.write(text.replaceAll(r'\n', '\n'));
          }
        } else if (node.nodeType == 1) {
          final tag = node.localName?.toLowerCase();
          if (tag == 'p' ||
              tag == 'div' ||
              tag == 'br' ||
              tag == 'h1' ||
              tag == 'h2' ||
              tag == 'h3' ||
              tag == 'h4') {
            buffer.writeln();
            for (var child in node.nodes) {
              processNode(child);
            }
            buffer.writeln();
          } else {
            for (var child in node.nodes) {
              processNode(child);
            }
          }
        }
      }

      for (var node in body.nodes) {
        processNode(node);
      }

      final result = buffer
          .toString()
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
      return result.isNotEmpty
          ? result
          : body.text.replaceAll(r'\n', '\n').trim();
    } catch (_) {
      return html.replaceAll(r'\n', '\n').replaceAll(RegExp(r'<[^>]*>'), '\n');
    }
  }

  Color _getBackgroundColor(BuildContext context, NovelReaderTheme theme) {
    return switch (theme) {
      NovelReaderTheme.light => const Color(0xFFFAF9F6),
      NovelReaderTheme.dark => Theme.of(context).colorScheme.surface,
      NovelReaderTheme.sepia => const Color(0xFFF4ECD8),
      NovelReaderTheme.oled => Colors.black,
    };
  }

  Color _getTextColor(BuildContext context, NovelReaderTheme theme) {
    return switch (theme) {
      NovelReaderTheme.light => const Color(0xFF2B2B2B),
      NovelReaderTheme.dark => Theme.of(context).colorScheme.onSurface,
      NovelReaderTheme.sepia => const Color(0xFF5F4B32),
      NovelReaderTheme.oled => const Color(0xFFD4D4D4),
    };
  }

  TextStyle? _getBaseTextStyle(BuildContext context) {
    final textColor = _getTextColor(context, _theme);
    TextStyle style = TextStyle(
      fontSize: _fontSize,
      height: _lineHeight,
      color: textColor,
    );

    if (_fontFamily == 'Serif') {
      return style.copyWith(fontFamily: 'serif');
    } else if (_fontFamily == 'Sans-Serif') {
      return style.copyWith(fontFamily: 'sans-serif');
    } else if (_fontFamily == 'Monospace') {
      return style.copyWith(fontFamily: 'monospace');
    }
    return style;
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final modalBgColor = _getBackgroundColor(context, _theme);
            final modalTextColor = _getTextColor(context, _theme);

            return Container(
              decoration: BoxDecoration(
                color: modalBgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reader Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: modalTextColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 14,
                      color: modalTextColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: NovelReaderTheme.values.map((t) {
                      final name = t.name.toUpperCase();
                      final isSel = _theme == t;
                      return ChoiceChip(
                        label: Text(name),
                        selected: isSel,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _theme = t);
                            setModalState(() {});
                            _saveReaderPreferences();
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Font Size: ${_fontSize.toInt()}pt',
                        style: TextStyle(color: modalTextColor),
                      ),
                      Slider(
                        value: _fontSize,
                        min: 12,
                        max: 32,
                        divisions: 20,
                        onChanged: (val) {
                          setState(() => _fontSize = val);
                          setModalState(() {});
                          _saveReaderPreferences();
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Line Height: ${_lineHeight.toStringAsFixed(1)}',
                        style: TextStyle(color: modalTextColor),
                      ),
                      Slider(
                        value: _lineHeight,
                        min: 1.2,
                        max: 2.4,
                        divisions: 12,
                        onChanged: (val) {
                          setState(() => _lineHeight = val);
                          setModalState(() {});
                          _saveReaderPreferences();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Font Family',
                        style: TextStyle(color: modalTextColor),
                      ),
                      DropdownButton<String>(
                        value: _fontFamily,
                        dropdownColor: modalBgColor,
                        style: TextStyle(color: modalTextColor),
                        items: ['System', 'Serif', 'Sans-Serif', 'Monospace']
                            .map(
                              (f) => DropdownMenuItem(value: f, child: Text(f)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _fontFamily = val);
                            setModalState(() {});
                            _saveReaderPreferences();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showChapterPicker() {
    final bgColor = _getBackgroundColor(context, _theme);
    final textColor = _getTextColor(context, _theme);
    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      useSafeArea: true,
      builder: (context) {
        return ListView.builder(
          itemCount: widget.chapters.length,
          itemBuilder: (context, index) {
            final chap = widget.chapters[index];
            final isSelected = index == _currentChapterIndex;
            return ListTile(
              title: Text(
                chap.name,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                if (index != _currentChapterIndex) {
                  setState(() {
                    _currentChapterIndex = index;
                  });
                  _loadChapterContent();
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentChapter = widget.chapters[_currentChapterIndex];
    final hasPrev = _currentChapterIndex > 0;
    final hasNext = _currentChapterIndex < widget.chapters.length - 1;
    final bgColor = _getBackgroundColor(context, _theme);
    final textColor = _getTextColor(context, _theme);
    final baseStyle = _getBaseTextStyle(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  _pointerDownTime = DateTime.now();
                  _pointerDownPosition = event.position;
                },
                onPointerUp: (event) {
                  if (_pointerDownTime != null &&
                      _pointerDownPosition != null) {
                    final duration = DateTime.now().difference(
                      _pointerDownTime!,
                    );
                    final distance =
                        (event.position - _pointerDownPosition!).distance;

                    if (duration.inMilliseconds < 300 && distance < 15) {
                      _toggleControls();
                    }
                  }
                  _pointerDownTime = null;
                  _pointerDownPosition = null;
                },
                child: SafeArea(
                  bottom: false,
                  top: false,
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator.adaptive(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              textColor,
                            ),
                          ),
                        )
                      : (_errorMessage != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        size: 60,
                                        color: Colors.red.shade300,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: _loadChapterContent,
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    controller: _scrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      20.0,
                                      90.0,
                                      20.0,
                                      90.0,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight - 180,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentChapter.name,
                                            style: TextStyle(
                                              fontSize: _fontSize * 1.4,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          SelectionArea(
                                            child: MarkdownBody(
                                              data: _chapterMarkdown,
                                              selectable: false,
                                              styleSheet: MarkdownStyleSheet(
                                                p: baseStyle,
                                                h1: baseStyle?.copyWith(
                                                  fontSize: _fontSize * 1.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                h2: baseStyle?.copyWith(
                                                  fontSize: _fontSize * 1.3,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                h3: baseStyle?.copyWith(
                                                  fontSize: _fontSize * 1.1,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                blockquote: baseStyle?.copyWith(
                                                  fontStyle: FontStyle.italic,
                                                ),
                                                listBullet: baseStyle,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 40),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 350),
                curve: Curves.fastOutSlowIn,
                offset: _showControls ? Offset.zero : const Offset(0, -1),
                child: Container(
                  decoration: BoxDecoration(color: bgColor),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBar(
                          backgroundColor: bgColor,
                          surfaceTintColor: Colors.transparent,
                          elevation: 0,
                          leading: IconButton(
                            icon: Icon(Icons.arrow_back, color: textColor),
                            onPressed: () {
                              SystemChrome.setEnabledSystemUIMode(
                                SystemUiMode.edgeToEdge,
                              );
                              Navigator.of(context).pop();
                            },
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.novelTitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor.withValues(alpha: 0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                currentChapter.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          actions: [
                            IconButton(
                              icon: Icon(Icons.list_rounded, color: textColor),
                              onPressed: _showChapterPicker,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.format_size_rounded,
                                color: textColor,
                              ),
                              onPressed: _showSettingsModal,
                            ),
                          ],
                        ),
                        LinearProgressIndicator(
                          value: _scrollProgressPct / 100.0,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 2,
                        ),
                      ],
                    ),
                  ),
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
                child: Container(
                  decoration: BoxDecoration(color: bgColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: hasPrev
                              ? () {
                                  setState(() => _currentChapterIndex--);
                                  _loadChapterContent();
                                }
                              : null,
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: hasPrev
                                ? textColor
                                : textColor.withValues(alpha: 0.3),
                          ),
                          label: Text(
                            'Prev',
                            style: TextStyle(
                              color: hasPrev
                                  ? textColor
                                  : textColor.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        Text(
                          'Ch. ${_currentChapterIndex + 1} / ${widget.chapters.length} • ${_scrollProgressPct.toInt()}%',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: hasNext
                              ? () {
                                  setState(() => _currentChapterIndex++);
                                  _loadChapterContent();
                                }
                              : null,
                          icon: Icon(
                            Icons.arrow_forward_rounded,
                            color: hasNext
                                ? textColor
                                : textColor.withValues(alpha: 0.3),
                          ),
                          label: Text(
                            'Next',
                            style: TextStyle(
                              color: hasNext
                                  ? textColor
                                  : textColor.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
