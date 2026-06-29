import 'package:flutter/material.dart';
import 'package:zenbu/models/extensions_models.dart';
import 'package:zenbu/services/repo_service.dart';
import 'package:zenbu/components/global/custom_image.dart';
import 'package:zenbu/services/js_engine.dart';
import 'package:zenbu/pages/video_player_page.dart';
import 'package:zenbu/pages/extensions_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenbu/services/progress_service.dart';

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
  List<ExtSource> _installedExtensions = [];
  Map<String, double> _episodesProgress = {};

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
        _installedExtensions = animeExtensions;
        if (animeExtensions.isNotEmpty) {
          _selectedExtension = animeExtensions.first;
          _loadEpisodes();
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

    setState(() {
      _isLoadingEpisodes = true;
      _errorMessage = null;
      _is403Error = false;
      _allRawEpisodes = [];
      _rawEpisodes = [];
      _currentPage = 0;
      _isLoadingPage = false;
    });

    try {
      _cachedEngine ??= await RepoService.loadExtensionEngine(
        _selectedExtension!,
      );

      final searchResults = await _cachedEngine!.search(widget.animeTitle, 1);
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

      final matchedLink = searchResults.first['link'] ?? '';
      if (matchedLink.isEmpty) {
        if (!mounted) return;
        setState(() {
          _allRawEpisodes = [];
          _rawEpisodes = [];
        });
        return;
      }

      final detail = await _cachedEngine!.getDetail(matchedLink);
      final rawEpisodes = detail['chapters'] as List? ?? [];

      if (!mounted) return;
      setState(() {
        _setEpisodes(rawEpisodes);
      });
      _loadLocalProgress();
    } catch (e) {
      if (!mounted) return;
      debugPrint("[WATCH PANE ERROR] Failed to load episodes: $e");
      final is403 =
          _cachedEngine?.lastStatusCode == 403 ||
          _cachedEngine?.lastStatusCode == 503;
      final failedUrl = _cachedEngine?.lastRequestUrl;
      setState(() {
        _errorMessage = 'An error occurred while loading episodes.';
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
                      _loadEpisodes();
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
                            : 'An error occurred while loading episodes.',
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
                        onPressed: _loadEpisodes,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
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
                                            child: widget.coverImage != null &&
                                                    widget
                                                        .coverImage!
                                                        .isNotEmpty
                                                ? CustomImage(
                                                    imageUrl: widget.coverImage!,
                                                    fit: BoxFit.cover,
                                                    errorWidget: _buildPlaceholderThumbnail(),
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
}

class ResumeTarget {
  final ExtEpisode episode;
  final bool isResume;
  ResumeTarget({required this.episode, required this.isResume});
}
