import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zenbu/models/extensions_models.dart';
import 'package:zenbu/services/repo_service.dart';
import 'package:zenbu/services/js_engine.dart';
import 'package:zenbu/pages/video_player_page.dart';
import 'package:zenbu/pages/extensions_page.dart';

class AnimeWatchPane extends StatefulWidget {
  final int mediaId;
  final int? malId;
  final String animeTitle;
  final String? coverImage;
  final List? streamingEpisodes;

  const AnimeWatchPane({
    super.key,
    required this.mediaId,
    this.malId,
    required this.animeTitle,
    this.coverImage,
    this.streamingEpisodes,
  });

  @override
  State<AnimeWatchPane> createState() => _AnimeWatchPaneState();
}

class _AnimeWatchPaneState extends State<AnimeWatchPane> {
  List<ExtSource> _installedExtensions = [];
  ExtSource? _selectedExtension;
  List<dynamic> _allRawEpisodes = [];
  List<dynamic> _rawEpisodes = [];
  bool _isLoadingExtensions = false;
  bool _isLoadingEpisodes = false;
  bool _isLoadingPage = false;
  String? _errorMessage;

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
      if (!mounted) return;
      setState(() {
        _installedExtensions = list;
        if (list.isNotEmpty) {
          _selectedExtension = list.first;
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

    //TODO: Remove this and see what happens
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
      _allRawEpisodes = [];
      _rawEpisodes = [];
      _currentPage = 0;
      _isLoadingPage = false;
    });

    try {
      _cachedEngine ??= await RepoService.loadExtensionEngine(
        _selectedExtension!,
      );

      final url = '${_selectedExtension!.baseUrl}/anime/${widget.mediaId}';

      final detail = await _cachedEngine!.getDetail(url);

      final rawEpisodes = detail['chapters'] as List? ?? [];

      if (!mounted) return;
      setState(() {
        _setEpisodes(rawEpisodes);
      });
    } catch (e) {
      try {
        if (!mounted) return;
        _cachedEngine ??= await RepoService.loadExtensionEngine(
          _selectedExtension!,
        );
        final searchResults = await _cachedEngine!.search(widget.animeTitle, 1);
        if (searchResults.isNotEmpty) {
          final matchedLink = searchResults.first['link'] ?? '';
          if (matchedLink.isNotEmpty) {
            final detail = await _cachedEngine!.getDetail(matchedLink);
            final rawEpisodes = detail['chapters'] as List? ?? [];
            if (mounted) {
              setState(() {
                _setEpisodes(rawEpisodes);
              });
              return;
            }
          }
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Failed to load episodes from ${_selectedExtension!.name}: $e';
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
                icon: const Icon(Icons.refresh),
                onPressed: _loadEpisodes,
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
                      const Icon(
                        Icons.error_outline,
                        size: 40,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.red),
                      ),
                      const SizedBox(height: 16),
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
                  Text(
                    'Episodes (${_allRawEpisodes.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => VideoPlayerPage(
                                          episode: ep,
                                          source: _selectedExtension!,
                                          animeTitle: widget.animeTitle,
                                          malId: widget.malId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 140,
                                        height: 80,
                                        child:
                                            widget.coverImage != null &&
                                                    widget.coverImage!.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: widget.coverImage!,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context, url) =>
                                                        const Center(
                                                          child:
                                                              CircularProgressIndicator.adaptive(
                                                                strokeWidth: 2,
                                                              ),
                                                        ),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            _buildPlaceholderThumbnail(),
                                                  )
                                                : _buildPlaceholderThumbnail(),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
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
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
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
}
