import 'package:al_client/components/anime_details_page/details_pane.dart';
import 'package:al_client/state_provider.dart';
import 'package:flutter/material.dart';
import 'package:al_client/components/anime_details_page/title_pane.dart';
import 'package:provider/provider.dart';

class AnimeDetailsPage extends StatelessWidget {
  const AnimeDetailsPage({super.key, required this.id});
  final int? id;
  @override
  Widget build(BuildContext context) {
    Map alData = Provider.of<StateProvider>(context).alData;
    List entries = alData["data"]["animeList"]["lists"][0]["entries"];
    Map current = entries.firstWhere((element) => element["id"] == id);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Column(
        children: [
          TitlePane(
            title: ((current["media"]["title"]["romaji"] as String).length > 32)
                ? '${(current["media"]["title"]["romaji"] as String).substring(0, 32)}...'
                : (current["media"]["title"]["romaji"] as String),
            airingStatus: "Ongoing",
            progress:
                "${current["media"]["mediaListEntry"]["progress"]}/${(current["media"]["episodes"] == null) ? '?' : current["media"]["episodes"]}",
            cover: current["media"]["coverImage"]["extraLarge"],
            banner: current["media"]["bannerImage"],
          ),
          DetailsPane(),
        ],
      ),
    );
  }
}
