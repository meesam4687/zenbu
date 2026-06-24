import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/components/list_page/list_page_view.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:flutter/material.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key, required this.title, required this.mediaListType});

  final String title;
  final MediaType mediaListType;

  @override
  State<ListPage> createState() => _ListPageState();
}

enum MediaType { anime, manga }

class _ListPageState extends State<ListPage> {
  late Future<Map<String, dynamic>> mediaLists;
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    mediaLists = getMediaLists();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reloadData() {
    setState(() {
      mediaLists = getMediaLists();
    });
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

  @override
  Widget build(BuildContext context) {
    final String list = widget.mediaListType == MediaType.anime
        ? "animeList"
        : "mangaList";
    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Search list...",
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
                  }
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            TabBar(
              tabAlignment: TabAlignment.start,
              isScrollable: true,
              tabs: const [
                Tab(text: "Current"),
                Tab(text: "Planning"),
                Tab(text: "Completed"),
                Tab(text: "Repeating"),
                Tab(text: "Paused"),
                Tab(text: "Dropped"),
                Tab(text: "All"),
                Tab(text: "Favourites"),
              ],
            ),
            FutureBuilder(
              future: mediaLists,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: const Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Expanded(
                    child: Error(
                      reload: _reloadData,
                      message: snapshot.error?.toString(),
                    ),
                  );
                }
                final data = snapshot.data!;
                final List combinedEntries =
                    (data["data"][list]["lists"] as List)
                        .expand((list) => list["entries"] as List)
                        .toList();
                final lists = data["data"][list]["lists"] as List;
                final Map<String, int> listNameIndexMap = {};
                for (var i = 0; i < lists.length; i++) {
                  listNameIndexMap[lists[i]["name"]] = i;
                }
                return Expanded(
                  child: TabBarView(
                    children: [
                      ListPageView(
                        list: _filterList(
                          (listNameIndexMap[(list == "animeList")
                                      ? "Watching"
                                      : "Reading"] !=
                                  null)
                              ? data["data"][list]["lists"][listNameIndexMap[(list ==
                                        "animeList")
                                    ? "Watching"
                                    : "Reading"]]["entries"]
                              : [],
                          _searchQuery,
                        ),
                        mediaType: (list == "animeList") ? "anime" : "manga",
                      ),
                      ListPageView(
                        list: _filterList(
                          (listNameIndexMap['Planning'] != null)
                              ? data["data"][list]["lists"][listNameIndexMap['Planning']]["entries"]
                              : [],
                          _searchQuery,
                        ),
                        mediaType: (list == "animeList") ? "anime" : "manga",
                      ),
                      ListPageView(
                        list: _filterList(
                          (listNameIndexMap['Completed'] != null)
                              ? data["data"][list]["lists"][listNameIndexMap['Completed']]["entries"]
                              : [],
                          _searchQuery,
                        ),
                        mediaType: (list == "animeList") ? "anime" : "manga",
                      ),
                      ListPageView(
                        list: _filterList(
                          (listNameIndexMap[(list == "animeList")
                                      ? "Rewatching"
                                      : "Rereading"] !=
                                  null)
                              ? data["data"][list]["lists"][listNameIndexMap[(list ==
                                        "animeList")
                                    ? "Rewatching"
                                    : "Rereading"]]["entries"]
                              : [],
                          _searchQuery,
                        ),
                        mediaType: (list == "animeList") ? "anime" : "manga",
                      ),
                      ListPageView(
                        list: _filterList(
                          (listNameIndexMap['Paused'] != null)
                              ? data["data"][list]["lists"][listNameIndexMap['Paused']]["entries"]
                              : [],
                          _searchQuery,
                        ),
                        mediaType: (list == "animeList") ? "anime" : "manga",
                      ),
                      ListPageView(
                        list: _filterList(
                          (listNameIndexMap['Dropped'] != null)
                              ? data["data"][list]["lists"][listNameIndexMap['Dropped']]["entries"]
                              : [],
                          _searchQuery,
                        ),
                        mediaType: (list == "animeList") ? "anime" : "manga",
                      ),
                      ListPageView(
                        list: _filterList(combinedEntries, _searchQuery),
                        mediaType: (list == "animeList") ? "anime" : "manga",
                      ),
                      ListPageView(
                        list: _filterList(
                          (data["data"]?["favourites"]?["favourites"]?[list ==
                                              "animeList"
                                          ? "anime"
                                          : "manga"]?["nodes"]
                                      as List? ??
                                  [])
                              .map((media) => {"media": media})
                              .toList(),
                          _searchQuery,
                        ),
                        mediaType: (list == "animeList") ? "anime" : "manga",
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
