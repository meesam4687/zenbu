import 'package:flutter/material.dart';

import 'package:al_client/components/anime_discovery_page/airing_banner.dart';
import 'package:al_client/components/anime_discovery_page/horizontal_anime_list.dart';
import 'package:al_client/components/anime_discovery_page/search_segment.dart';

class AnimeDiscoveryPage extends StatelessWidget {
  const AnimeDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List items = [
      {
        "title": "Dandadan Season 2",
        "coverImage":
            "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx185660-uB8RUMBGovGr.jpg",
        "id": 1,
        "type": "anime",
      },
      {
        "title": "Sono Bisque Doll wa Koi wo Suru...",
        "coverImage":
            "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx154768-DHHvNd4MjV1p.jpg",
        "id": 2,
        "type": "anime",
      },
      {
        "title": "Gachiakuta",
        "coverImage":
            "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx178025-cWJKEsZynkil.jpg",
        "id": 3,
        "type": "anime",
      },
      {
        "title": "Kaoru Hana wa Rin to Saku",
        "coverImage":
            "https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx181444-Ut9DDUZdfHwg.jpg",
        "id": 4,
        "type": "anime",
      },
    ];

    return Scaffold(
      appBar: AppBar(flexibleSpace: SearchSegment(), toolbarHeight: 100),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
            SizedBox(height: 10),
            HorizontalAnimeList(heading: "Trending Now", animeArray: items),
            HorizontalAnimeList(
              heading: "Popular this season",
              animeArray: items,
            ),
            HorizontalAnimeList(heading: "Upcoming", animeArray: items),
            HorizontalAnimeList(heading: "All Time Popular", animeArray: items),
          ],
        ),
      ),
    );
  }
}
