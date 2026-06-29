import 'package:flutter/material.dart';
import 'package:zenbu/models/extensions_models.dart';
import 'package:zenbu/services/repo_service.dart';
import 'package:zenbu/services/js_engine.dart';
import 'package:zenbu/pages/manga_reader_page.dart';
import 'package:zenbu/pages/extensions_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenbu/services/progress_service.dart';

class MangaReadPane extends StatefulWidget {
  final int mediaId;
  final String mangaTitle;
  final String? coverImage;
  final int anilistProgress;
  final String mediaState;

  const MangaReadPane({
    super.key,
    required this.mediaId,
    required this.mangaTitle,
    this.coverImage,
    required this.anilistProgress,
    required this.mediaState,
  });

  @override
  State<MangaReadPane> createState() => _MangaReadPaneState();
}

class _MangaReadPaneState extends State<MangaReadPane> {
  List<ExtSource> _installedExtensions = [];
  Map<String, bool> _chaptersReadStatus = {};
  Map<String, Map<String, int>> _chaptersPartialProgress = {};

  Future<void> _loadLocalProgress() async {
    final Map<String, bool> readStatus = {};
    final Map<String, Map<String, int>> partialProgress = {};

    for (final chap in _allRawChapters) {
      final extChapter = ExtEpisode.fromJson(Map<String, dynamic>.from(chap));

      final isRead = await ProgressService.isMangaChapterRead(
        mediaId: widget.mediaId,
        chapterUrl: extChapter.url,
        chapterName: extChapter.name,
        anilistProgress: widget.anilistProgress,
      );
      if (isRead) {
        readStatus[extChapter.url] = true;
      } else {
        final progress = await ProgressService.getMangaChapterProgress(
          mediaId: widget.mediaId,
          chapterUrl: extChapter.url,
          chapterName: extChapter.name,
        );
        if (progress != null) {
          partialProgress[extChapter.url] = progress;
        }
      }
    }

    if (mounted) {
      setState(() {
        _chaptersReadStatus = readStatus;
        _chaptersPartialProgress = partialProgress;
      });
    }
  }

  ExtSource? _selectedExtension;
  List<dynamic> _allRawChapters = [];
  List<dynamic> _rawChapters = [];
  bool _isLoadingExtensions = false;
  bool _isLoadingChapters = false;
  bool _isLoadingPage = false;
  String? _errorMessage;
  bool _is403Error = false;
  String? _failedUrl;

  int _currentPage = 0;
  JsEngine? _cachedEngine;

  @override
  void initState() {
    super.initState();
    _loadExtensions();
  }

  @override
  void dispose() {
    _cachedEngine?.dispose();
    super.dispose();
  }

  Future<void> _loadExtensions() async {
    if (!mounted) return;
    setState(() {
      _isLoadingExtensions = true;
      _errorMessage = null;
    });

    try {
      final list = await RepoService.getInstalledExtensions();
      final mangaExtensions = list.where((ext) => ext.isManga).toList();
      if (!mounted) return;
      setState(() {
        _installedExtensions = mangaExtensions;
        if (mangaExtensions.isNotEmpty) {
          _selectedExtension = mangaExtensions.first;
          _loadChapters();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load extensions: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExtensions = false;
        });
      }
    }
  }

  void _setChapters(List<dynamic> rawChapters) {
    _allRawChapters = rawChapters;
    _currentPage = 0;

    final endIndex = (30 < _allRawChapters.length)
        ? 30
        : _allRawChapters.length;
    final List<dynamic> pageSlice = [];
    for (var k = 0; k < endIndex; k++) {
      final originalIndex = _allRawChapters.length - 1 - k;
      pageSlice.add(_allRawChapters[originalIndex]);
    }
    _rawChapters = pageSlice;
  }

  void _changePage(int idx) {
    setState(() {
      _currentPage = idx;
      _isLoadingPage = true;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      final startIndex = idx * 30;
      final endIndex = (startIndex + 30 < _allRawChapters.length)
          ? startIndex + 30
          : _allRawChapters.length;
      final List<dynamic> pageSlice = [];
      for (var k = startIndex; k < endIndex; k++) {
        final originalIndex = _allRawChapters.length - 1 - k;
        pageSlice.add(_allRawChapters[originalIndex]);
      }

      setState(() {
        _rawChapters = pageSlice;
        _isLoadingPage = false;
      });
    });
  }

  Future<void> _loadChapters() async {
    if (_selectedExtension == null || !mounted) return;

    setState(() {
      _isLoadingChapters = true;
      _errorMessage = null;
      _is403Error = false;
      _allRawChapters = [];
      _rawChapters = [];
      _currentPage = 0;
      _isLoadingPage = false;
    });

    try {
      _cachedEngine ??= await RepoService.loadExtensionEngine(
        _selectedExtension!,
      );

      final searchResults = await _cachedEngine!.search(widget.mangaTitle, 1);
      final is403 =
          _cachedEngine?.lastStatusCode == 403 ||
          _cachedEngine?.lastStatusCode == 503;
      if (is403) {
        throw Exception('Cloudflare challenge detected.');
      }

      if (searchResults.isEmpty) {
        if (!mounted) return;
        setState(() {
          _allRawChapters = [];
          _rawChapters = [];
        });
        return;
      }

      final matchedLink = searchResults.first['link'] ?? '';
      if (matchedLink.isEmpty) {
        if (!mounted) return;
        setState(() {
          _allRawChapters = [];
          _rawChapters = [];
        });
        return;
      }

      final detail = await _cachedEngine!.getDetail(matchedLink);
      final rawChapters = detail['chapters'] as List? ?? [];

      if (!mounted) return;
      setState(() {
        _setChapters(rawChapters);
      });
      _loadLocalProgress();
    } catch (e) {
      if (!mounted) return;
      debugPrint("[READ PANE ERROR] Failed to load chapters: $e");
      final is403 =
          _cachedEngine?.lastStatusCode == 403 ||
          _cachedEngine?.lastStatusCode == 503;
      final failedUrl = _cachedEngine?.lastRequestUrl;
      setState(() {
        _errorMessage = 'An error occurred while loading chapters: $e';
        _is403Error = is403;
        _failedUrl = failedUrl;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingChapters = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingExtensions) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_installedExtensions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.extension_off_outlined,
              size: 54,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Manga Extensions Installed',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'To start reading, add repositories and install a manga extension.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ExtensionsPage(),
                  ),
                );
                _loadExtensions();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Manage Extensions'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Source Extension: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<ExtSource>(
                  value: _selectedExtension,
                  isExpanded: true,
                  items: _installedExtensions.map((ext) {
                    return DropdownMenuItem<ExtSource>(
                      value: ext,
                      child: Text('${ext.name} (${ext.lang.toUpperCase()})'),
                    );
                  }).toList(),
                  onChanged: (ext) {
                    if (ext != null) {
                      _cachedEngine?.dispose();
                      _cachedEngine = null;
                      setState(() {
                        _selectedExtension = ext;
                      });
                      _loadChapters();
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ExtensionsPage(),
                    ),
                  );
                  _loadExtensions();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingChapters)
            Expanded(
              child: Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            )
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 40,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _is403Error
                            ? 'Cloudflare might be preventing fetching. Try opening in browser and completing the captcha.'
                            : 'An error occurred while loading chapters.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_is403Error && _selectedExtension != null) ...[
                        OutlinedButton.icon(
                          onPressed: () async {
                            final urlString =
                                _failedUrl ?? _selectedExtension!.baseUrl;
                            final url = Uri.parse(urlString);
                            try {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Open in Browser'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      FilledButton(
                        onPressed: _loadChapters,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_allRawChapters.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No chapters found for this manga.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (() {
                    final target = _getResumeTarget();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chapters (${_allRawChapters.length})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (target != null)
                          TextButton.icon(
                            onPressed: () => _launchChapter(target.episode),
                            icon: const Icon(Icons.chrome_reader_mode),
                            label: Text(
                              '${target.isResume ? "Resume" : "Start"} Ch. ${(ProgressService.parseEpisodeNumber(target.episode.url, target.episode.name) ?? 1.0).toString().replaceAll(RegExp(r'\.0$'), '')}',
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                      ],
                    );
                  })(),
                  const SizedBox(height: 12),
                  (() {
                    final totalPages = (_allRawChapters.length / 30).ceil();
                    if (totalPages <= 1) return const SizedBox.shrink();
                    return Column(
                      children: [
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: totalPages,
                            itemBuilder: (context, idx) {
                              final startEp = idx * 30 + 1;
                              final endEp =
                                  (idx + 1) * 30 < _allRawChapters.length
                                  ? (idx + 1) * 30
                                  : _allRawChapters.length;
                              final isSelected = _currentPage == idx;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text('$startEp - $endEp'),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      _changePage(idx);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  })(),
                  Expanded(
                    child: _isLoadingPage
                        ? Center(
                            child: CircularProgressIndicator.adaptive(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: _rawChapters.length,
                            itemBuilder: (context, index) {
                              final rawChap = _rawChapters[index];
                              final chap = ExtEpisode.fromJson(
                                Map<String, dynamic>.from(rawChap),
                              );
                              final isRead =
                                  _chaptersReadStatus[chap.url] ?? false;
                              final progress =
                                  _chaptersPartialProgress[chap.url];
                              final isPartial = progress != null;

                              return Card(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainer,
                                elevation: 0,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    final chronologicalChapters =
                                        _allRawChapters.reversed
                                            .map(
                                              (e) => ExtEpisode.fromJson(
                                                Map<String, dynamic>.from(e),
                                              ),
                                            )
                                            .toList();

                                    final curIdx = chronologicalChapters
                                        .indexWhere((c) => c.url == chap.url);

                                    Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MangaReaderPage(
                                                  chapters:
                                                      chronologicalChapters,
                                                  currentIndex: curIdx >= 0
                                                      ? curIdx
                                                      : 0,
                                                  source: _selectedExtension!,
                                                  mangaTitle: widget.mangaTitle,
                                                  mediaId: widget.mediaId,
                                                ),
                                          ),
                                        )
                                        .then((_) {
                                          _loadLocalProgress();
                                        });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        if (isRead)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                        else if (isPartial)
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              value:
                                                  progress['pagesRead']! /
                                                  progress['totalPages']!,
                                              strokeWidth: 3.0,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant
                                                  .withValues(alpha: 0.3),
                                            ),
                                          )
                                        else
                                          const Icon(
                                            Icons.menu_book,
                                            color: Colors.blueGrey,
                                          ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                chap.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (chap.description != null &&
                                                  chap
                                                      .description!
                                                      .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  chap.description!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.color ??
                                                        Colors.grey,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  ResumeTarget? _getResumeTarget() {
    if (_allRawChapters.isEmpty) return null;

    final bool isActiveState =
        widget.mediaState == 'CURRENT' || widget.mediaState == 'REPEATING';
    if (!isActiveState) {
      return null;
    }

    final chronologicalChapters = _allRawChapters
        .map((e) => ExtEpisode.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    chronologicalChapters.sort((a, b) {
      final numA = ProgressService.parseEpisodeNumber(a.url, a.name) ?? 0.0;
      final numB = ProgressService.parseEpisodeNumber(b.url, b.name) ?? 0.0;
      return numA.compareTo(numB);
    });

    ExtEpisode? lastStarted;
    double highestReadChapterNum = -1.0;
    bool hasAnyProgress = false;

    for (final chap in chronologicalChapters) {
      final isRead = _chaptersReadStatus[chap.url] ?? false;
      final progress = _chaptersPartialProgress[chap.url];
      final chapNum =
          ProgressService.parseEpisodeNumber(chap.url, chap.name) ?? 0.0;

      if (isRead || progress != null) {
        hasAnyProgress = true;
      }
      if (progress != null && !isRead) {
        lastStarted = chap;
      }
      if (isRead) {
        if (chapNum > highestReadChapterNum) {
          highestReadChapterNum = chapNum;
        }
      }
    }

    final lastChap = chronologicalChapters.last;
    final lastChapNum =
        ProgressService.parseEpisodeNumber(lastChap.url, lastChap.name) ?? 0.0;

    final isCompleted =
        widget.mediaState == 'COMPLETED' ||
        widget.anilistProgress >= chronologicalChapters.length ||
        highestReadChapterNum >= lastChapNum;

    if (isCompleted) {
      return null;
    }

    if (lastStarted != null) {
      return ResumeTarget(episode: lastStarted, isResume: true);
    }

    if (highestReadChapterNum >= 0) {
      for (final chap in chronologicalChapters) {
        final chapNum =
            ProgressService.parseEpisodeNumber(chap.url, chap.name) ?? 0.0;
        if (chapNum > highestReadChapterNum) {
          return ResumeTarget(episode: chap, isResume: true);
        }
      }
    }

    if (chronologicalChapters.isNotEmpty) {
      return ResumeTarget(
        episode: chronologicalChapters.first,
        isResume: hasAnyProgress,
      );
    }

    return null;
  }

  void _launchChapter(ExtEpisode chap) {
    final chronologicalChapters = _allRawChapters.reversed
        .map((e) => ExtEpisode.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final curIdx = chronologicalChapters.indexWhere((c) => c.url == chap.url);

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => MangaReaderPage(
              chapters: chronologicalChapters,
              currentIndex: curIdx >= 0 ? curIdx : 0,
              source: _selectedExtension!,
              mangaTitle: widget.mangaTitle,
              mediaId: widget.mediaId,
            ),
          ),
        )
        .then((_) {
          _loadLocalProgress();
        });
  }
}

class ResumeTarget {
  final ExtEpisode episode;
  final bool isResume;
  ResumeTarget({required this.episode, required this.isResume});
}
