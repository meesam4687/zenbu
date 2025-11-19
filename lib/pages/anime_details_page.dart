import 'package:al_client/anilist_connector.dart';
import 'package:al_client/components/anime_details_page/details_pane.dart';
import 'package:al_client/state_provider.dart';
import 'package:flutter/material.dart';
import 'package:al_client/components/anime_details_page/title_pane.dart';
import 'package:provider/provider.dart';

class AnimeDetailsPage extends StatefulWidget {
  const AnimeDetailsPage({super.key, required this.id});
  final int? id;

  @override
  State<AnimeDetailsPage> createState() => _AnimeDetailsPageState();
}

class _AnimeDetailsPageState extends State<AnimeDetailsPage> {
  double scrollOffset = 0;
  final ScrollController _scrollController = ScrollController();
  late Future<Map<String, dynamic>> animeData;
  @override
  void initState() {
    super.initState();
    animeData = getAnimeData(widget.id as int);
    _scrollController.addListener(() {
      setState(() {
        scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double get appBarOpacity {
    return (scrollOffset <= 0) ? 0.0 : 1.0;
  }

  @override
  Widget build(BuildContext context) {
    Map alData = Provider.of<StateProvider>(context).alData;
    List entries = (alData["data"] != null
        ? alData["data"]["animeList"]["lists"][0]["entries"]
        : [{}]);
    Map current = entries.firstWhere(
      (element) => element["id"] == widget.id,
      orElse: () => {},
    );
    if (current.isNotEmpty) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: (appBarOpacity == 0) ? Colors.transparent : null,
          elevation: appBarOpacity > 0 ? 4 : 0,
          scrolledUnderElevation: 0,
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              TitlePane(
                id: widget.id as int,
                totalEpisodes: (current["media"]["episodes"] == null)
                    ? '?'
                    : current["media"]["episodes"],
                title:
                    ((current["media"]["title"]["romaji"] as String).length >
                        32)
                    ? '${(current["media"]["title"]["romaji"] as String).substring(0, 32)}...'
                    : (current["media"]["title"]["romaji"] as String),
                progress:
                    "Progress: ${current["media"]["mediaListEntry"]["progress"]}/${(current["media"]["episodes"] == null) ? '?' : current["media"]["episodes"]}",
                cover: current["media"]["coverImage"]["extraLarge"],
                banner: current["media"]["bannerImage"],
                mediaState: (current["media"]["mediaListEntry"] != null)
                    ? current["media"]["mediaListEntry"]["status"] ?? 'NONE'
                    : 'NONE',
                mediaListEntry: current["media"]["mediaListEntry"],
              ),
              DetailsPane(mediaId: current["media"]["id"]),
            ],
          ),
        ),
      );
    } else {
      return FutureBuilder(
        future: animeData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final data = snapshot.data!;
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: (appBarOpacity == 0) ? Colors.transparent : null,
              elevation: appBarOpacity > 0 ? 4 : 0,
              scrolledUnderElevation: 0,
            ),
            body: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  TitlePane(
                    id: widget.id as int,
                    totalEpisodes: (data["data"]["Media"]["episodes"] == null)
                        ? '?'
                        : data["data"]["Media"]["episodes"],
                    title:
                        ((data["data"]["Media"]["title"]["romaji"] as String)
                                .length >
                            32)
                        ? '${(data["data"]["Media"]["title"]["romaji"] as String).substring(0, 32)}...'
                        : (data["data"]["Media"]["title"]["romaji"] as String),
                    progress:
                        "Progress: ${(data["data"]["Media"]["mediaListEntry"] != null) ? data["data"]["Media"]["mediaListEntry"]["progress"] : "0"}/${(data["data"]["Media"]["episodes"] == null) ? '?' : data["data"]["Media"]["episodes"]}",
                    cover: data["data"]["Media"]["coverImage"]["extraLarge"],
                    banner: data["data"]["Media"]["bannerImage"],
                    mediaState:
                        (data["data"]["Media"]["mediaListEntry"] != null)
                        ? data["data"]["Media"]["mediaListEntry"]["status"] ??
                              'NONE'
                        : 'NONE',
                    mediaListEntry: data["data"]["Media"]["mediaListEntry"],
                  ),
                  DetailsPane(mediaId: widget.id as int),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}
