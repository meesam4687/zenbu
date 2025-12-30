import 'package:zenbu/anilist_connector.dart';
import 'package:zenbu/components/manga_details_page/details_pane.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/components/manga_details_page/title_pane.dart';

class MangaDetailsPage extends StatefulWidget {
  const MangaDetailsPage({super.key, required this.id});
  final int? id;

  @override
  State<MangaDetailsPage> createState() => _MangaDetailsPageState();
}

class _MangaDetailsPageState extends State<MangaDetailsPage> {
  double scrollOffset = 0;
  final ScrollController _scrollController = ScrollController();
  late Future<Map<String, dynamic>> mangaData;
  @override
  void initState() {
    super.initState();
    mangaData = getMangaData(widget.id as int);
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
    return FutureBuilder(
      future: mangaData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (snapshot.hasError) {
          return ErrorPage(
            scaffold: true,
            onReload: () {
              setState(() {
                mangaData = getMangaData(widget.id as int);
              });
            },
          );
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
                  totalEpisodes: (data["data"]["Media"]["chapters"] == null)
                      ? '?'
                      : data["data"]["Media"]["chapters"].toString(),
                  title:
                      ((data["data"]["Media"]["title"]["romaji"] as String)
                              .length >
                          32)
                      ? '${(data["data"]["Media"]["title"]["romaji"] as String).substring(0, 32)}...'
                      : (data["data"]["Media"]["title"]["romaji"] as String),
                  progress:
                      "Progress: ${(data["data"]["Media"]["mediaListEntry"] != null) ? data["data"]["Media"]["mediaListEntry"]["progress"] : "0"}/${(data["data"]["Media"]["chapters"] == null) ? '?' : data["data"]["Media"]["chapters"]}",
                  cover: data["data"]["Media"]["coverImage"]["extraLarge"],
                  banner: data["data"]["Media"]["bannerImage"],
                  mediaState: (data["data"]["Media"]["mediaListEntry"] != null)
                      ? data["data"]["Media"]["mediaListEntry"]["status"] ??
                            'NONE'
                      : 'NONE',
                  mediaListEntry: data["data"]["Media"]["mediaListEntry"],
                  fullTitle:
                      (data["data"]["Media"]["title"]["romaji"] as String),
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
