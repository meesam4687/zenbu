import 'package:al_client/anilist_connector.dart';
import 'package:al_client/components/list_page/list_page_view.dart';
import 'package:al_client/pages/error_page.dart';
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

  @override
  void initState() {
    mediaLists = getMediaLists();
    super.initState();
  }

  void _reloadData() {
    setState(() {
      mediaLists = getMediaLists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String list = widget.mediaListType == MediaType.anime
        ? "animeList"
        : "mangaList";
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
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
                  return Expanded(child: Error(reload: _reloadData));
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
                        list:
                            (listNameIndexMap[(list == "animeList")
                                    ? "Watching"
                                    : "Reading"] !=
                                null)
                            ? data["data"][list]["lists"][listNameIndexMap[(list ==
                                      "animeList")
                                  ? "Watching"
                                  : "Reading"]]["entries"]
                            : [],
                        mediaType: (list == "animeList") ? "anime" : "manga",
                      ),
                      ListPageView(
                        list: (listNameIndexMap['Planning'] != null)
                            ? data["data"][list]["lists"][listNameIndexMap['Planning']]["entries"]
                            : [],
                        mediaType: (list == "animeList") ? "anime" : "manga",
                      ),
                      ListPageView(
                        list: (listNameIndexMap['Completed'] != null)
                            ? data["data"][list]["lists"][listNameIndexMap['Completed']]["entries"]
                            : [],
                        mediaType: (list == "animeList") ? "anime" : "manga",
                      ),
                      ListPageView(
                        list:
                            (listNameIndexMap[(list == "animeList")
                                    ? "Rewatching"
                                    : "Rereading"] !=
                                null)
                            ? data["data"][list]["lists"][listNameIndexMap[(list ==
                                      "animeList")
                                  ? "Rewatching"
                                  : "Rereading"]]["entries"]
                            : [],
                        mediaType: (list == "animeList") ? "anime" : "manga",
                      ),
                      ListPageView(
                        list: (listNameIndexMap['Paused'] != null)
                            ? data["data"][list]["lists"][listNameIndexMap['Paused']]["entries"]
                            : [],
                        mediaType: (list == "animeList") ? "anime" : "manga",
                      ),
                      ListPageView(
                        list: (listNameIndexMap['Dropped'] != null)
                            ? data["data"][list]["lists"][listNameIndexMap['Dropped']]["entries"]
                            : [],
                        mediaType: (list == "animeList") ? "anime" : "manga",
                      ),
                      ListPageView(
                        list: combinedEntries,
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
