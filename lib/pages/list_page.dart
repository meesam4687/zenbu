import 'package:flutter/material.dart';
import 'package:zenbu/components/list_page/list_page_view.dart';
import 'package:zenbu/l10n/l10n_extension.dart';
import 'package:zenbu/services/anilist/anilist.dart';

class ListPage extends StatefulWidget {
  const ListPage({
    super.key,
    required this.title,
    required this.mediaListType,
    this.userId,
  });

  final String title;
  final MediaType mediaListType;
  final int? userId;

  @override
  State<ListPage> createState() => _ListPageState();
}

enum MediaType { anime, manga }

class _ListPageState extends State<ListPage> {
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _searchDataCache;
  bool _isSearchLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _ensureSearchDataLoaded(String type) async {
    if (_searchDataCache != null || _isSearchLoading) return;
    setState(() {
      _isSearchLoading = true;
    });

    try {
      final collection = await getMediaListCollection(
        type: type,
        userId: widget.userId,
      );

      final List allFavNodes = [];
      int favPage = 1;
      bool hasNextFav = true;
      while (hasNextFav && favPage <= 20) {
        final favData = await getFavourites(
          page: favPage,
          perPage: 25,
          type: type,
          userId: widget.userId,
        );
        final mediaKey = type == "anime" ? "anime" : "manga";
        final favsObj = favData["data"]?["User"]?["favourites"]?[mediaKey];
        final nodes = (favsObj?["nodes"] as List?) ?? [];
        allFavNodes.addAll(nodes);
        hasNextFav = favsObj?["pageInfo"]?["hasNextPage"] as bool? ?? false;
        favPage++;
      }

      if (mounted) {
        setState(() {
          _searchDataCache = {
            "collection": collection,
            "favourites": allFavNodes,
          };
          _isSearchLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSearchLoading = false;
        });
      }
    }
  }

  List _filterList(List entries, String query) {
    if (query.isEmpty) return entries;
    final lowercaseQuery = query.toLowerCase();
    return entries.where((entry) {
      final media = entry["media"];
      if (media == null) return false;
      final title = media["title"];
      if (title == null) return false;

      final romaji = (title["romaji"] as String?)?.toLowerCase() ?? "";
      final english = (title["english"] as String?)?.toLowerCase() ?? "";
      final native = (title["native"] as String?)?.toLowerCase() ?? "";

      return romaji.contains(lowercaseQuery) ||
          english.contains(lowercaseQuery) ||
          native.contains(lowercaseQuery);
    }).toList();
  }

  List _getFilteredResults(String? status, String mediaType) {
    if (_searchDataCache == null) return [];

    if (status == "FAVOURITES") {
      final nodes = (_searchDataCache!["favourites"] as List?) ?? [];
      final favEntries = nodes.map((n) => {"media": n}).toList();
      return _filterList(favEntries, _searchQuery);
    }

    final collection = _searchDataCache!["collection"]?["data"]
        ?["MediaListCollection"];
    final lists = (collection?["lists"] as List?) ?? [];

    if (status == null) {
      final allEntries =
          lists.expand((l) => (l["entries"] as List?) ?? []).toList();
      return _filterList(allEntries, _searchQuery);
    }

    final statusEntries = <dynamic>[];
    for (final l in lists) {
      final entries = (l["entries"] as List?) ?? [];
      for (final entry in entries) {
        if (entry["status"] == status) {
          statusEntries.add(entry);
        }
      }
    }
    return _filterList(statusEntries, _searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final String mediaType =
        widget.mediaListType == MediaType.anime ? "anime" : "manga";
    final bool isSearchActive = _isSearching && _searchQuery.isNotEmpty;

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: context.l10n.searchList,
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    if (value.isNotEmpty) {
                      _ensureSearchDataLoaded(mediaType);
                    }
                  },
                )
              : Text(widget.title),
          actions: [
            if (_isSearching)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = "";
                  });
                },
              ),
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _searchQuery = "";
                  } else {
                    _ensureSearchDataLoaded(mediaType);
                  }
                });
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              TabBar(
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                tabs: [
                  Tab(text: context.l10n.current),
                  Tab(text: context.l10n.planning),
                  Tab(text: context.l10n.completed),
                  Tab(text: context.l10n.repeating),
                  Tab(text: context.l10n.paused),
                  Tab(text: context.l10n.dropped),
                  Tab(text: context.l10n.all),
                  Tab(text: context.l10n.favorites),
                ],
              ),
              if (_isSearchLoading && isSearchActive)
                const LinearProgressIndicator(),
              Expanded(
                child: TabBarView(
                  children: [
                    ListPageView(
                      key: PageStorageKey("${mediaType}_CURRENT"),
                      mediaType: mediaType,
                      userId: widget.userId,
                      status: "CURRENT",
                      isSearching: isSearchActive,
                      searchQuery: _searchQuery,
                      searchResults: isSearchActive
                          ? _getFilteredResults("CURRENT", mediaType)
                          : null,
                    ),
                    ListPageView(
                      key: PageStorageKey("${mediaType}_PLANNING"),
                      mediaType: mediaType,
                      userId: widget.userId,
                      status: "PLANNING",
                      isSearching: isSearchActive,
                      searchQuery: _searchQuery,
                      searchResults: isSearchActive
                          ? _getFilteredResults("PLANNING", mediaType)
                          : null,
                    ),
                    ListPageView(
                      key: PageStorageKey("${mediaType}_COMPLETED"),
                      mediaType: mediaType,
                      userId: widget.userId,
                      status: "COMPLETED",
                      isSearching: isSearchActive,
                      searchQuery: _searchQuery,
                      searchResults: isSearchActive
                          ? _getFilteredResults("COMPLETED", mediaType)
                          : null,
                    ),
                    ListPageView(
                      key: PageStorageKey("${mediaType}_REPEATING"),
                      mediaType: mediaType,
                      userId: widget.userId,
                      status: "REPEATING",
                      isSearching: isSearchActive,
                      searchQuery: _searchQuery,
                      searchResults: isSearchActive
                          ? _getFilteredResults("REPEATING", mediaType)
                          : null,
                    ),
                    ListPageView(
                      key: PageStorageKey("${mediaType}_PAUSED"),
                      mediaType: mediaType,
                      userId: widget.userId,
                      status: "PAUSED",
                      isSearching: isSearchActive,
                      searchQuery: _searchQuery,
                      searchResults: isSearchActive
                          ? _getFilteredResults("PAUSED", mediaType)
                          : null,
                    ),
                    ListPageView(
                      key: PageStorageKey("${mediaType}_DROPPED"),
                      mediaType: mediaType,
                      userId: widget.userId,
                      status: "DROPPED",
                      isSearching: isSearchActive,
                      searchQuery: _searchQuery,
                      searchResults: isSearchActive
                          ? _getFilteredResults("DROPPED", mediaType)
                          : null,
                    ),
                    ListPageView(
                      key: PageStorageKey("${mediaType}_ALL"),
                      mediaType: mediaType,
                      userId: widget.userId,
                      status: null,
                      isSearching: isSearchActive,
                      searchQuery: _searchQuery,
                      searchResults: isSearchActive
                          ? _getFilteredResults(null, mediaType)
                          : null,
                    ),
                    ListPageView(
                      key: PageStorageKey("${mediaType}_FAVOURITES"),
                      mediaType: mediaType,
                      userId: widget.userId,
                      isFavourites: true,
                      isSearching: isSearchActive,
                      searchQuery: _searchQuery,
                      searchResults: isSearchActive
                          ? _getFilteredResults("FAVOURITES", mediaType)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
