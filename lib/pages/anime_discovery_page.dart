import 'package:al_client/components/anime_discovery_page/airing_banner.dart';
import 'package:al_client/components/anime_discovery_page/horizontal_anime_list.dart';
import 'package:al_client/components/anime_discovery_page/search_segment.dart';
import 'package:flutter/material.dart';

class AnimeDiscoveryPage extends StatelessWidget {
  const AnimeDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SearchSegment(),
          AiringBanner(
            bannerImage:
                "https://s4.anilist.co/file/anilistcdn/media/anime/banner/185660-NdXFgzcYmcDz.jpg",
            coverImage:
                "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx185660-uB8RUMBGovGr.jpg",
            title: "Dandadan",
            totalEpisodes: "12",
            airedEpisodes: "7",
            tagString: "Action • Comedy • D...",
          ),
          HorizontalAnimeList(),
        ],
      ),
    );
  }
}
