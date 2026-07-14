import 'package:flutter/material.dart';
import 'package:zenbu/services/mangayomi/models/extensions_models.dart';
import 'package:zenbu/services/repo_service.dart';
import 'package:zenbu/components/global/custom_image.dart';
import 'package:zenbu/services/mangayomi/eval/interface.dart';
import 'package:zenbu/pages/video_player_page.dart';
import 'package:zenbu/pages/extensions_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenbu/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:zenbu/services/download_service.dart';
import 'package:zenbu/services/local_source_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AnimeWatchPane extends StatefulWidget {
  final int mediaId;
  final int? malId;
  final String animeTitle;
  final String? coverImage;
  final List? streamingEpisodes;
  final int anilistProgress;
  final String mediaState;

  const AnimeWatchPane({
    super.key,
    required this.mediaId,
    this.malId,
    required this.animeTitle,
    this.coverImage,
    this.streamingEpisodes,
    required this.anilistProgress,
    required this.mediaState,
  });

  @override
  State<AnimeWatchPane> createState() => _AnimeWatchPaneState();
}

class _AnimeWatchPaneState extends State<AnimeWatchPane> {
  static final ExtSource localSource = ExtSource(
    name: 'Local Source',
    id: -1,
    baseUrl: '',
    lang: '',
    version: '1.0.0',
    sourceCodeUrl: '',
    isManga: false,
  );

  List<ExtSource> _installedExtensions = [];
  Map<String, double> _episodesProgress = {};
  String? _customLinkActive;

  Future<void> _loadLocalProgress() async {
    final Map<String, double> progressMap = {};

    for (final epJson in _allRawEpisodes) {
      final extEpisode = ExtEpisode.fromJson(Map<String, dynamic>.from(epJson));
      final ratio = await ProgressService.getAnimeEpisodeProgressRatio(
        mediaId: widget.mediaId,
        episodeUrl: extEpisode.url,
        episodeName: extEpisode.name,
        anilistProgress: widget.anilistProgress,
      );
      if (ratio > 0.0) {
        progressMap[extEpisode.url] = ratio;
      }
    }

    if (mounted) {
      setState(() {
        _episodesProgress = progressMap;
      });
    }
  }

  ExtSource? _selectedExtension;
  List<dynamic> _allRawEpisodes = [];
  List<dynamic> _rawEpisodes = [];
  bool _isLoadingExtensions = false;
  bool _isLoadingEpisodes = false;
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

  @override
  void didUpdateWidget(covariant AnimeWatchPane oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _loadExtensions() async {
    if (!mounted) return;
    setState(() {
      _isLoadingExtensions = true;
      _errorMessage = null;
    });

    try {
      final list = await RepoService.getInstalledExtensions();
      final animeExtensions = list.where((ext) => !ext.isManga).toList();
      if (!mounted) return;
      setState(() {
        _installedExtensions = [...animeExtensions, localSource];
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
        _loadEpisodes();
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

  void _setEpisodes(List<dynamic> rawEpisodes) {
    _allRawEpisodes = rawEpisodes;
    _currentPage = 0;

    final endIndex = (30 < _allRawEpisodes.length)
        ? 30
        : _allRawEpisodes.length;
    final List<dynamic> pageSlice = [];
    for (var k = 0; k < endIndex; k++) {
      final originalIndex = _allRawEpisodes.length - 1 - k;
      pageSlice.add(_allRawEpisodes[originalIndex]);
    }
    _rawEpisodes = pageSlice;
  }

  void _changePage(int idx) {
    setState(() {
      _currentPage = idx;
      _isLoadingPage = true;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      final startIndex = idx * 30;
      final endIndex = (startIndex + 30 < _allRawEpisodes.length)
          ? startIndex + 30
          : _allRawEpisodes.length;
      final List<dynamic> pageSlice = [];
      for (var k = startIndex; k < endIndex; k++) {
        final originalIndex = _allRawEpisodes.length - 1 - k;
        pageSlice.add(_allRawEpisodes[originalIndex]);
      }

      setState(() {
        _rawEpisodes = pageSlice;
        _isLoadingPage = false;
      });
    });
  }

  Future<void> _loadEpisodes() async {
    if (_selectedExtension == null || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'custom_title_link_${widget.mediaId}_${_selectedExtension!.id}';
    final customLink = prefs.getString(key);

    setState(() {
      _isLoadingEpisodes = true;
      _errorMessage = null;
      _is403Error = false;
      _allRawEpisodes = [];
      _rawEpisodes = [];
      _currentPage = 0;
      _isLoadingPage = false;
      _customLinkActive = customLink;
    });

    try {
      if (_selectedExtension!.id == -1) {
        try {
          final rawEpisodes = await LocalSourceService.scanAnime(
            animeTitle: widget.animeTitle,
            customLink: customLink,
          );
          if (!mounted) return;
          setState(() {
            _setEpisodes(rawEpisodes);
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
            widget.animeTitle,
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
              _allRawEpisodes = [];
              _rawEpisodes = [];
            });
            return;
          }

          matchedLink = searchResults.first['link'] ?? '';
        }

        if (matchedLink.isEmpty) {
          if (!mounted) return;
          setState(() {
            _allRawEpisodes = [];
            _rawEpisodes = [];
          });
          return;
        }

        final detail = await _cachedEngine!.getDetail(matchedLink);
        final rawEpisodes = detail.chapters?.map((e) => e.toJson()).toList() ?? [];

        if (!mounted) return;
        setState(() {
          _setEpisodes(rawEpisodes);
        });
        _loadLocalProgress();
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint("[WATCH PANE ERROR] Failed to load episodes: $e");
      final is403 =
          _cachedEngine?.lastStatusCode == 403 ||
          _cachedEngine?.lastStatusCode == 503;
      final failedUrl = _cachedEngine?.lastRequestUrl;
      setState(() {
        _errorMessage = 'An error occurred while loading episodes: $e';
        _is403Error = is403;
        _failedUrl = failedUrl;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEpisodes = false;
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
              'No Extensions Installed',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'To start watching, add repositories and install an anime extension.',
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
                      _loadEpisodes();
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
                      : 'Wrong Title',
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
          if (_isLoadingEpisodes)
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
                            onPressed: _pickAnimeDirectory,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Choose Directory'),
                          ),
                        ],
                      );
                    } else if (_errorMessage ==
                        'No matching anime folder found.') {
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
                            'No folder matching "${widget.animeTitle}" found in local directory.',
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
                              : 'An error occurred while loading episodes.',
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
                          onPressed: _loadEpisodes,
                          child: const Text('Retry'),
                        ),
                      ],
                    );
                  })(),
                ),
              ),
            )
          else if (_allRawEpisodes.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No episodes found for this show.',
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
                          'Episodes (${_allRawEpisodes.length})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (target != null)
                          TextButton.icon(
                            onPressed: () => _launchEpisode(target.episode),
                            icon: const Icon(Icons.play_arrow),
                            label: Text(
                              '${target.isResume ? "Resume" : "Start"} Ep. ${(ProgressService.parseEpisodeNumber(target.episode.url, target.episode.name) ?? 1.0).toString().replaceAll(RegExp(r'\.0$'), '')}',
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
                    final totalPages = (_allRawEpisodes.length / 30).ceil();
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
                                  (idx + 1) * 30 < _allRawEpisodes.length
                                  ? (idx + 1) * 30
                                  : _allRawEpisodes.length;
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
                            itemCount: _rawEpisodes.length,
                            itemBuilder: (context, index) {
                              final rawEp = _rawEpisodes[index];
                              final ep = ExtEpisode.fromJson(
                                Map<String, dynamic>.from(rawEp),
                              );
                              final progressRatio =
                                  _episodesProgress[ep.url] ?? 0.0;

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
                                    final allEpisodes = _allRawEpisodes
                                        .map(
                                          (e) => ExtEpisode.fromJson(
                                            Map<String, dynamic>.from(e),
                                          ),
                                        )
                                        .toList();
                                    Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                VideoPlayerPage(
                                                  episode: ep,
                                                  source: _selectedExtension!,
                                                  animeTitle: widget.animeTitle,
                                                  coverImage: widget.coverImage,
                                                  malId: widget.malId,
                                                  mediaId: widget.mediaId,
                                                  allEpisodes: allEpisodes,
                                                ),
                                          ),
                                        )
                                        .then((_) {
                                          _loadLocalProgress();
                                        });
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 140,
                                            height: 80,
                                            child:
                                                widget.coverImage != null &&
                                                    widget
                                                        .coverImage!
                                                        .isNotEmpty
                                                ? CustomImage(
                                                    imageUrl:
                                                        widget.coverImage!,
                                                    fit: BoxFit.cover,
                                                    errorWidget:
                                                        _buildPlaceholderThumbnail(),
                                                  )
                                                : _buildPlaceholderThumbnail(),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 8,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    ep.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (ep.description != null &&
                                                      ep
                                                          .description!
                                                          .isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      ep.description!,
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
                                          ),
                                          if (_selectedExtension!.id != -1)
                                            _buildDownloadButton(ep),
                                        ],
                                      ),
                                      if (progressRatio > 0.0)
                                        Container(
                                          height: 3,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.3),
                                          alignment: Alignment.centerLeft,
                                          child: FractionallySizedBox(
                                            widthFactor: progressRatio,
                                            child: Container(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                    ],
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

  Widget _buildPlaceholderThumbnail() {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 32),
      ),
    );
  }

  ResumeTarget? _getResumeTarget() {
    if (_allRawEpisodes.isEmpty) return null;

    final bool isActiveState =
        widget.mediaState == 'CURRENT' || widget.mediaState == 'REPEATING';
    if (!isActiveState) {
      return null;
    }

    final chronologicalEpisodes = _allRawEpisodes
        .map((e) => ExtEpisode.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    chronologicalEpisodes.sort((a, b) {
      final numA = ProgressService.parseEpisodeNumber(a.url, a.name) ?? 0.0;
      final numB = ProgressService.parseEpisodeNumber(b.url, b.name) ?? 0.0;
      return numA.compareTo(numB);
    });

    ExtEpisode? lastStarted;
    double highestWatchedEpisodeNum = -1.0;
    bool hasAnyProgress = false;

    for (final ep in chronologicalEpisodes) {
      final ratio = _episodesProgress[ep.url] ?? 0.0;
      final epNum = ProgressService.parseEpisodeNumber(ep.url, ep.name) ?? 0.0;
      if (ratio > 0.0) {
        hasAnyProgress = true;
      }
      if (ratio > 0.0 && ratio < 0.95) {
        lastStarted = ep;
      }
      if (ratio >= 0.95) {
        if (epNum > highestWatchedEpisodeNum) {
          highestWatchedEpisodeNum = epNum;
        }
      }
    }

    final lastEp = chronologicalEpisodes.last;
    final lastEpNum =
        ProgressService.parseEpisodeNumber(lastEp.url, lastEp.name) ?? 0.0;

    final isCompleted =
        widget.mediaState == 'COMPLETED' ||
        widget.anilistProgress >= chronologicalEpisodes.length ||
        highestWatchedEpisodeNum >= lastEpNum;

    if (isCompleted) {
      return null;
    }

    if (lastStarted != null) {
      return ResumeTarget(episode: lastStarted, isResume: true);
    }

    if (highestWatchedEpisodeNum >= 0) {
      for (final ep in chronologicalEpisodes) {
        final epNum =
            ProgressService.parseEpisodeNumber(ep.url, ep.name) ?? 0.0;
        if (epNum > highestWatchedEpisodeNum) {
          return ResumeTarget(episode: ep, isResume: true);
        }
      }
    }

    if (chronologicalEpisodes.isNotEmpty) {
      return ResumeTarget(
        episode: chronologicalEpisodes.first,
        isResume: hasAnyProgress,
      );
    }

    return null;
  }

  void _launchEpisode(ExtEpisode ep) {
    final allEpisodes = _allRawEpisodes
        .map((e) => ExtEpisode.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(
              episode: ep,
              source: _selectedExtension!,
              animeTitle: widget.animeTitle,
              coverImage: widget.coverImage,
              malId: widget.malId,
              mediaId: widget.mediaId,
              allEpisodes: allEpisodes,
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
        _isLoadingEpisodes = true;
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
            _isLoadingEpisodes = false;
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
                animeTitle: widget.animeTitle,
                currentCustomLink: _customLinkActive,
                jsEngine: isLocal ? null : _cachedEngine,
                scrollController: scrollController,
                isManga: false,
                onSelect: (link, name) async {
                  final prefs = await SharedPreferences.getInstance();
                  final key =
                      'custom_title_link_${widget.mediaId}_${_selectedExtension!.id}';
                  await prefs.setString(key, link);
                  if (mounted) {
                    _loadEpisodes();
                  }
                },
                onClear: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final key =
                      'custom_title_link_${widget.mediaId}_${_selectedExtension!.id}';
                  await prefs.remove(key);
                  if (mounted) {
                    _loadEpisodes();
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAnimeDirectory() async {
    final dir = await LocalSourceService.pickRootDirectory(context);
    if (dir != null) {
      _loadEpisodes();
    }
  }

  Future<void> _downloadEpisode(ExtEpisode ep) async {
    final prefs = await SharedPreferences.getInstance();
    var rootPath = prefs.getString('local_directory_path');
    if (rootPath == null || rootPath.isEmpty) {
      await _pickAnimeDirectory();
      rootPath = prefs.getString('local_directory_path');
      if (rootPath == null || rootPath.isEmpty) return;
    }

    if (!mounted) return;
    if (!await LocalSourceService.checkAndRequestStoragePermission(context)) {
      return;
    }

    final downloadService = DownloadService();
    if (downloadService.isDownloading(ep.url)) return;

    if (downloadService.isDownloaded(false, ep.url)) {
      Fluttertoast.showToast(msg: 'Episode already downloaded.');
      return;
    }

    if (!mounted) return;

    final selectedStream = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _StreamSelectionDialog(
        episodeUrl: ep.url,
        extension: _selectedExtension!,
      ),
    );

    if (selectedStream == null) {
      return;
    }

    downloadService.setDownloadingInitialState(
      ep.url,
      false,
      ep.name,
      widget.animeTitle,
    );

    _startAnimeDownloadWithStream(ep, selectedStream, rootPath);
  }

  Future<void> _startAnimeDownloadWithStream(
    ExtEpisode ep,
    Map<String, dynamic> selectedStream,
    String rootPath,
  ) async {
    final downloadService = DownloadService();
    try {
      final extVideo = ExtVideo.fromJson(selectedStream);
      final videoUrl = extVideo.url;
      final headers = extVideo.headers;

      if (videoUrl.isEmpty) {
        throw Exception('Stream URL is empty.');
      }

      await downloadService.startAnimeDownload(
        mediaId: widget.mediaId,
        mediaTitle: widget.animeTitle,
        coverImage: widget.coverImage ?? '',
        episodeUrl: ep.url,
        episodeName: ep.name,
        videoStreamUrl: videoUrl,
        headers: headers,
        rootPath: rootPath,
        subtitles: extVideo.subtitles,
      );
    } catch (e) {
      final wasCancelled = downloadService.wasManuallyCancelled(ep.url);
      downloadService.clearManualCancel(ep.url);
      downloadService.cancelDownload(false, ep.url);
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

  Widget _buildDownloadButton(ExtEpisode ep) {
    final downloadService = DownloadService();
    return AnimatedBuilder(
      animation: downloadService,
      builder: (context, _) {
        final isDownloading = downloadService.isDownloading(ep.url);
        final isDownloaded = downloadService.isDownloaded(false, ep.url);
        final progress = downloadService.getDownloadProgress(ep.url);

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
                    onTap: () => downloadService.cancelDownload(false, ep.url),
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
                    'Are you sure you want to delete the offline file for ${ep.name}?',
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
                await downloadService.deleteDownloadedItem(false, ep.url);
              }
            },
          );
        }

        return IconButton(
          icon: const Icon(Icons.download_for_offline_outlined),
          onPressed: () => _downloadEpisode(ep),
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

class _DownloadResolverDialog extends StatefulWidget {
  final ExtEpisode episode;
  final ExtSource source;

  const _DownloadResolverDialog({required this.episode, required this.source});

  @override
  State<_DownloadResolverDialog> createState() =>
      _DownloadResolverDialogState();
}

class _DownloadResolverDialogState extends State<_DownloadResolverDialog> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _streams = [];

  @override
  void initState() {
    super.initState();
    _resolveLinks();
  }

  Future<void> _resolveLinks() async {
    try {
      final engine = await RepoService.loadExtensionEngine(widget.source);
      final rawList = await engine.getVideoList(widget.episode.url);
      engine.dispose();

      if (rawList.isEmpty) {
        throw Exception('No stream links found.');
      }

      if (mounted) {
        setState(() {
          _streams = rawList.map((e) => e.toJson()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Download ${widget.episode.name}'),
      content: Builder(
        builder: (context) {
          if (_isLoading) {
            return const SizedBox(
              height: 120,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Resolving download links...'),
                  ],
                ),
              ),
            );
          }

          if (_error != null) {
            return SizedBox(
              height: 120,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _streams.length,
              itemBuilder: (context, index) {
                final stream = _streams[index];
                final quality = stream['quality'] ?? 'Unknown Quality';
                return ListTile(
                  title: Text(quality),
                  trailing: const Icon(Icons.download),
                  onTap: () => Navigator.of(context).pop(stream),
                );
              },
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _StreamSelectionDialog extends StatefulWidget {
  final String episodeUrl;
  final ExtSource extension;
  const _StreamSelectionDialog({
    required this.episodeUrl,
    required this.extension,
  });

  @override
  _StreamSelectionDialogState createState() => _StreamSelectionDialogState();
}

class _StreamSelectionDialogState extends State<_StreamSelectionDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _streams = [];

  @override
  void initState() {
    super.initState();
    _resolveStreams();
  }

  Future<void> _resolveStreams() async {
    try {
      final engine = await RepoService.loadExtensionEngine(widget.extension);
      final rawList = await engine.getVideoList(widget.episodeUrl);
      engine.dispose();
      if (mounted) {
        if (rawList.isEmpty) {
          setState(() {
            _errorMessage = 'No stream links found.';
            _isLoading = false;
          });
        } else {
          setState(() {
            _streams = rawList.map((e) => e.toJson()).toList();
            _isLoading = false;
          });
          if (rawList.length == 1) {
            Navigator.of(context).pop(rawList.first.toJson());
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Download Quality'),
      content: SizedBox(width: double.maxFinite, child: _buildContent()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _streams.length,
      itemBuilder: (context, index) {
        final stream = Map<String, dynamic>.from(_streams[index]);
        final quality = stream['quality'] ?? 'Unknown Quality';
        return ListTile(
          title: Text(quality),
          onTap: () => Navigator.of(context).pop(stream),
        );
      },
    );
  }
}
