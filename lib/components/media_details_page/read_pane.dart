import 'package:flutter/material.dart';
import 'package:zenbu/services/mangayomi/models/extensions_models.dart';
import 'package:zenbu/services/repo_service.dart';
import 'package:zenbu/services/mangayomi/eval/interface.dart';
import 'package:zenbu/components/global/custom_image.dart';
import 'package:zenbu/pages/manga_reader_page.dart';
import 'package:zenbu/pages/extensions_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenbu/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:zenbu/services/download_service.dart';
import 'package:zenbu/services/local_source_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  static final ExtSource localSource = ExtSource(
    name: 'Local Source',
    id: -1,
    baseUrl: '',
    lang: '',
    version: '1.0.0',
    sourceCodeUrl: '',
    isManga: true,
  );

  List<ExtSource> _installedExtensions = [];
  Map<String, bool> _chaptersReadStatus = {};
  Map<String, Map<String, int>> _chaptersPartialProgress = {};
  String? _customLinkActive;

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
  ExtensionService? _cachedEngine;

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
        _installedExtensions = [...mangaExtensions, localSource];
        if (_selectedExtension != null) {
          final index = _installedExtensions.indexWhere(
            (ext) => ext.id == _selectedExtension!.id,
          );
          if (index != -1) {
            _selectedExtension = _installedExtensions[index];
          } else {
            _selectedExtension = _installedExtensions.firstOrNull;
          }
        } else if (_installedExtensions.isNotEmpty) {
          _selectedExtension = _installedExtensions.first;
        }
      });
      if (_selectedExtension != null) {
        _loadChapters();
      }
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

    final prefs = await SharedPreferences.getInstance();
    final key = 'custom_title_link_${widget.mediaId}_${_selectedExtension!.id}';
    final customLink = prefs.getString(key);

    setState(() {
      _isLoadingChapters = true;
      _errorMessage = null;
      _is403Error = false;
      _allRawChapters = [];
      _rawChapters = [];
      _currentPage = 0;
      _isLoadingPage = false;
      _customLinkActive = customLink;
    });

    try {
      if (_selectedExtension!.id == -1) {
        try {
          final rawChapters = await LocalSourceService.scanManga(
            mangaTitle: widget.mangaTitle,
            customLink: customLink,
          );
          if (!mounted) return;
          setState(() {
            _setChapters(rawChapters);
          });
          _loadLocalProgress();
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          });
        }
      } else {
        _cachedEngine ??= await RepoService.loadExtensionEngine(
          _selectedExtension!,
        );

        String matchedLink = '';
        if (customLink != null && customLink.isNotEmpty) {
          matchedLink = customLink;
        } else {
          final searchPages = await _cachedEngine!.search(
            widget.mangaTitle,
            1,
            [],
          );
          final searchResults = searchPages.list.map((e) => e.toJson()).toList();
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

          matchedLink = searchResults.first['link'] ?? '';
        }

        if (matchedLink.isEmpty) {
          if (!mounted) return;
          setState(() {
            _allRawChapters = [];
            _rawChapters = [];
          });
          return;
        }

        final detail = await _cachedEngine!.getDetail(matchedLink);
        final rawChapters = detail.chapters?.map((e) => e.toJson()).toList() ?? [];

        if (!mounted) return;
        setState(() {
          _setChapters(rawChapters);
        });
        _loadLocalProgress();
      }
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
                'Source: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<ExtSource>(
                  value: _selectedExtension,
                  isExpanded: true,
                  items: _installedExtensions.map((ext) {
                    final label = ext.id == -1
                        ? ext.name
                        : '${ext.name} (${ext.lang.toUpperCase()})';
                    return DropdownMenuItem<ExtSource>(
                      value: ext,
                      child: Text(label),
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
              if (_selectedExtension != null) ...[
                IconButton(
                  icon: Icon(
                    _customLinkActive != null ? Icons.link : Icons.link_off,
                    color: _customLinkActive != null
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  tooltip: _customLinkActive != null
                      ? 'Custom Link Active (Tap to edit/reset)'
                      : 'Map Custom Link / Wrong Title',
                  onPressed: _showWrongTitleBottomSheet,
                ),
              ],
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
                  child: (() {
                    if (_errorMessage == 'Local directory is not configured.' ||
                        _errorMessage ==
                            'Configured directory does not exist.') {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Local directory is not configured or does not exist.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _pickMangaDirectory,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Choose Directory'),
                          ),
                        ],
                      );
                    } else if (_errorMessage ==
                        'No matching manga folder found.') {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_off_outlined,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No folder matching "${widget.mangaTitle}" found in local directory.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _showWrongTitleBottomSheet,
                            icon: const Icon(Icons.link),
                            label: const Text('Map Local Folder'),
                          ),
                        ],
                      );
                    }

                    return Column(
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
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
                    );
                  })(),
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
                                ).colorScheme.onInverseSurface,
                                elevation: 0,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                                                  coverImage: widget.coverImage,
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
                                        if (_selectedExtension!.id != -1)
                                          _buildDownloadButton(chap)
                                        else
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
              coverImage: widget.coverImage,
            ),
          ),
        )
        .then((_) {
          _loadLocalProgress();
        });
  }

  Future<void> _showWrongTitleBottomSheet() async {
    if (_selectedExtension == null) return;

    final isLocal = _selectedExtension!.id == -1;

    if (!isLocal && _cachedEngine == null) {
      setState(() {
        _isLoadingChapters = true;
      });
      try {
        _cachedEngine = await RepoService.loadExtensionEngine(
          _selectedExtension!,
        );
      } catch (e) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Failed to load extension engine: $e',
            toastLength: Toast.LENGTH_LONG,
          );
        }
        return;
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingChapters = false;
          });
        }
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: _WrongTitleBottomSheet(
                animeTitle: widget.mangaTitle,
                currentCustomLink: _customLinkActive,
                jsEngine: isLocal ? null : _cachedEngine,
                scrollController: scrollController,
                isManga: true,
                onSelect: (link, name) async {
                  final prefs = await SharedPreferences.getInstance();
                  final key =
                      'custom_title_link_${widget.mediaId}_${_selectedExtension!.id}';
                  await prefs.setString(key, link);
                  if (mounted) {
                    _loadChapters();
                  }
                },
                onClear: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final key =
                      'custom_title_link_${widget.mediaId}_${_selectedExtension!.id}';
                  await prefs.remove(key);
                  if (mounted) {
                    _loadChapters();
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickMangaDirectory() async {
    final dir = await LocalSourceService.pickRootDirectory(context);
    if (dir != null) {
      _loadChapters();
    }
  }

  Future<void> _downloadChapter(ExtEpisode chap) async {
    final prefs = await SharedPreferences.getInstance();
    var rootPath = prefs.getString('local_directory_path');
    if (rootPath == null || rootPath.isEmpty) {
      await _pickMangaDirectory();
      rootPath = prefs.getString('local_directory_path');
      if (rootPath == null || rootPath.isEmpty) return;
    }

    if (!mounted) return;
    if (!await LocalSourceService.checkAndRequestStoragePermission(context)) {
      return;
    }

    final downloadService = DownloadService();
    if (downloadService.isDownloading(chap.url)) return;

    if (downloadService.isDownloaded(true, chap.url)) {
      Fluttertoast.showToast(msg: 'Chapter already downloaded.');
      return;
    }

    downloadService.setDownloadingInitialState(
      chap.url,
      true,
      chap.name,
      widget.mangaTitle,
    );

    _resolveAndStartMangaDownload(chap, rootPath);
  }

  Future<void> _resolveAndStartMangaDownload(
    ExtEpisode chap,
    String rootPath,
  ) async {
    final downloadService = DownloadService();
    try {
      final engine = await RepoService.loadExtensionEngine(_selectedExtension!);
      final rawPages = await engine.getPageList(chap.url);

      final List<Map<String, dynamic>> pagesToDownload = [];
      if (rawPages.isNotEmpty) {
        final headers = engine.getHeaders();

        for (final page in rawPages) {
          pagesToDownload.add({
            'url': page.url,
            'headers': page.headers ?? headers,
          });
        }
      }
      engine.dispose();

      if (pagesToDownload.isEmpty) {
        throw Exception('No pages found.');
      }

      await downloadService.startMangaDownload(
        mediaId: widget.mediaId,
        mediaTitle: widget.mangaTitle,
        coverImage: widget.coverImage ?? '',
        chapterUrl: chap.url,
        chapterName: chap.name,
        pages: pagesToDownload,
        rootPath: rootPath,
      );
    } catch (e) {
      final wasCancelled = downloadService.wasManuallyCancelled(chap.url);
      downloadService.clearManualCancel(chap.url);
      downloadService.cancelDownload(true, chap.url);
      if (mounted) {
        if (!wasCancelled && !e.toString().contains('Cancelled by user.')) {
          Fluttertoast.showToast(
            msg: 'Download failed: $e',
            toastLength: Toast.LENGTH_LONG,
          );
        }
      }
    }
  }

  Widget _buildDownloadButton(ExtEpisode chap) {
    final downloadService = DownloadService();
    return AnimatedBuilder(
      animation: downloadService,
      builder: (context, _) {
        final isDownloading = downloadService.isDownloading(chap.url);
        final isDownloaded = downloadService.isDownloaded(true, chap.url);
        final progress = downloadService.getDownloadProgress(chap.url);

        if (isDownloading) {
          return SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 2,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.12),
                      ),
                      CircularProgressIndicator(
                        value: (progress == null || progress == 0.0)
                            ? null
                            : progress,
                        strokeWidth: 2,
                      ),
                    ],
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () => downloadService.cancelDownload(true, chap.url),
                    borderRadius: BorderRadius.circular(24),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.close, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (isDownloaded) {
          return IconButton(
            icon: Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Download'),
                  content: Text(
                    'Are you sure you want to delete the offline files for ${chap.name}?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await downloadService.deleteDownloadedItem(true, chap.url);
              }
            },
          );
        }

        return IconButton(
          icon: const Icon(Icons.download_for_offline_outlined),
          onPressed: () => _downloadChapter(chap),
        );
      },
    );
  }
}

class ResumeTarget {
  final ExtEpisode episode;
  final bool isResume;
  ResumeTarget({required this.episode, required this.isResume});
}

class _WrongTitleBottomSheet extends StatefulWidget {
  final String animeTitle;
  final String? currentCustomLink;
  final ExtensionService? jsEngine;
  final ScrollController scrollController;
  final Function(String link, String name) onSelect;
  final VoidCallback onClear;
  final bool isManga;

  const _WrongTitleBottomSheet({
    required this.animeTitle,
    this.currentCustomLink,
    required this.jsEngine,
    required this.scrollController,
    required this.onSelect,
    required this.onClear,
    required this.isManga,
  });

  @override
  State<_WrongTitleBottomSheet> createState() => _WrongTitleBottomSheetState();
}

class _WrongTitleBottomSheetState extends State<_WrongTitleBottomSheet> {
  late final TextEditingController _controller;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.animeTitle);
    _performSearch(widget.animeTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _results = [];
    });

    try {
      if (widget.jsEngine == null) {
        try {
          final localResults = await LocalSourceService.searchLocalFolders(
            query: query,
            isManga: widget.isManga,
          );
          if (!mounted) return;
          setState(() {
            _results = localResults;
            _isLoading = false;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _error = e.toString().replaceFirst('Exception: ', '');
            _isLoading = false;
          });
        }
      } else {
        if (query.trim().isEmpty) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
        final searchPages = await widget.jsEngine!.search(query, 1, []);
        final results = searchPages.list.map((e) => e.toJson()).toList();
        if (mounted) {
          setState(() {
            _results = results;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Alternative Title',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.currentCustomLink != null)
                  TextButton.icon(
                    onPressed: () {
                      widget.onClear();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Reset'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search title...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => _performSearch(_controller.text),
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: _performSearch,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator.adaptive())
                  : _error != null
                  ? Center(
                      child: Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _results.isEmpty
                  ? const Center(child: Text('No results found.'))
                  : ListView.builder(
                      controller: widget.scrollController,
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        final name =
                            result['name'] ?? result['title'] ?? 'Unknown';
                        final link = result['link'] ?? '';
                        final cover =
                            result['cover'] ?? result['thumbnail'] ?? '';
                        final isSelected = widget.currentCustomLink == link;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.onInverseSurface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outlineVariant
                                        .withValues(alpha: 0.3),
                            ),
                          ),
                          child: ListTile(
                            leading: cover.isNotEmpty
                                ? SizedBox(
                                    width: 40,
                                    height: 60,
                                    child: cover.startsWith('http')
                                        ? CustomImage(
                                            imageUrl: cover,
                                            fit: BoxFit.cover,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Image.file(
                                              File(cover),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                  )
                                : const Icon(Icons.movie),
                            title: Text(
                              name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                            ),
                            subtitle: Text(
                              link,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              widget.onSelect(link, name);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
