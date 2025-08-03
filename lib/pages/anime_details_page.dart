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

  @override
  void initState() {
    super.initState();

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
    List entries = alData["data"]["animeList"]["lists"][0]["entries"];
    Map current = entries.firstWhere((element) => element["id"] == widget.id);

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
              title:
                  ((current["media"]["title"]["romaji"] as String).length > 32)
                  ? '${(current["media"]["title"]["romaji"] as String).substring(0, 32)}...'
                  : (current["media"]["title"]["romaji"] as String),
              airingStatus: "Ongoing",
              progress:
                  "${current["media"]["mediaListEntry"]["progress"]}/${(current["media"]["episodes"] == null) ? '?' : current["media"]["episodes"]}",
              cover: current["media"]["coverImage"]["extraLarge"],
              banner: current["media"]["bannerImage"],
            ),
            DetailsPane(mediaId: current["media"]["id"]),
          ],
        ),
      ),
    );
  }
}
