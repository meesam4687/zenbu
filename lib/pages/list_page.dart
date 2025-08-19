import 'package:al_client/anilist_connector.dart';
import 'package:al_client/components/list_page/list_page_view.dart';
import 'package:flutter/material.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key, required this.title});

  final String title;

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  late final Future<Map<String, dynamic>> mediaLists;

  @override
  void initState() {
    mediaLists = getMediaLists();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
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
                final data = snapshot.data!;
                final List combinedEntries =
                    (data["data"]["animeList"]["lists"] as List)
                        .expand((list) => list["entries"] as List)
                        .toList();
                final lists = data["data"]["animeList"]["lists"] as List;
                final Map<String, int> listNameIndexMap = {};
                for (var i = 0; i < lists.length; i++) {
                  listNameIndexMap[lists[i]["name"]] = i;
                }
                return Expanded(
                  child: TabBarView(
                    children: [
                      ListPageView(
                        list:
                            data["data"]["animeList"]["lists"][listNameIndexMap['Watching']]["entries"],
                        mediaType: "anime",
                      ),
                      ListPageView(
                        list:
                            data["data"]["animeList"]["lists"][listNameIndexMap['Planning']]["entries"],
                        mediaType: "anime",
                      ),
                      ListPageView(
                        list:
                            data["data"]["animeList"]["lists"][listNameIndexMap['Completed']]["entries"],
                        mediaType: "anime",
                      ),
                      ListPageView(
                        list:
                            data["data"]["animeList"]["lists"][listNameIndexMap['Paused']]["entries"],
                        mediaType: "anime",
                      ),
                      ListPageView(
                        list:
                            data["data"]["animeList"]["lists"][listNameIndexMap['Dropped']]["entries"],
                        mediaType: "anime",
                      ),
                      ListPageView(list: combinedEntries, mediaType: "anime"),
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
