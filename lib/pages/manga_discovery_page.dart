import 'package:al_client/pages/entire_list_view.dart';
import 'package:flutter/material.dart';
import 'package:al_client/anilist_connector.dart';
import 'package:al_client/state_provider.dart';
import 'package:al_client/components/global/banner.dart';
import 'package:al_client/components/anime_discovery_page/horizontal_anime_list.dart';
import 'package:al_client/components/manga_discovery_page/search_segment.dart';
import 'package:provider/provider.dart';

class MangaDiscoveryPage extends StatefulWidget {
  const MangaDiscoveryPage({super.key});

  @override
  State<MangaDiscoveryPage> createState() => _MangaDiscoveryPageState();
}

class _MangaDiscoveryPageState extends State<MangaDiscoveryPage> {
  late final Future<Map<String, dynamic>> data;
  @override
  void initState() {
    Map providerData = Provider.of<StateProvider>(
      context,
      listen: false,
    ).mangaDiscoveryData;
    if (providerData.isEmpty) {
      data = getMangaHomePage(1, 10);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Map providerData = Provider.of<StateProvider>(context).mangaDiscoveryData;
    return Scaffold(
      appBar: AppBar(flexibleSpace: SearchSegment(), toolbarHeight: 100),
      body: (providerData.isEmpty)
          ? FutureBuilder(
              future: data,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }
                final data = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Provider.of<StateProvider>(
                    context,
                    listen: false,
                  ).updateMangaDiscoveryData(data);
                });
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 240,
                        child: PageView.builder(
                          itemCount: (data["data"]["trending"]["media"] as List)
                              .length,
                          controller: PageController(viewportFraction: 1.0),
                          itemBuilder: (context, index) {
                            List banners = [];
                            for (
                              int i = 0;
                              i <
                                  (data["data"]["trending"]["media"] as List)
                                      .length;
                              i++
                            ) {
                              Map media =
                                  (data["data"]["trending"]["media"]
                                      as List)[i];
                              final item = AiringBanner(
                                id: media["id"],
                                bannerImage: media["bannerImage"].toString(),
                                coverImage: media["coverImage"]["large"]
                                    .toString(),
                                title:
                                    media["title"]["romaji"].toString().length >
                                        24
                                    ? "${media["title"]["romaji"].toString().substring(0, 24)}..."
                                    : media["title"]["romaji"].toString(),
                                tagString:
                                    ((media["genres"] as List)
                                                .map((tag) => tag.toString())
                                                .join(" • "))
                                            .length >
                                        20
                                    ? "${((media["genres"] as List).map((tag) => tag.toString()).join(" • ")).substring(0, 20)}..."
                                    : ((media["genres"] as List)
                                          .map((tag) => tag.toString())
                                          .join(" • ")),
                                type: media["type"].toString().toLowerCase(),
                              );
                              banners.add(item);
                            }
                            return banners[index];
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                      HorizontalAnimeList(
                        heading: "Trending Now",
                        animeArray: data["data"]["trending"]["media"],
                        pagetype: PageType.trendingManga,
                      ),
                      HorizontalAnimeList(
                        heading: "All Time Popular",
                        animeArray: data["data"]["allTimePopular"]["media"],
                        pagetype: PageType.popularAllTimeManga,
                      ),
                    ],
                  ),
                );
              },
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 240,
                    child: PageView.builder(
                      itemCount:
                          (providerData["data"]["trending"]["media"] as List)
                              .length,
                      controller: PageController(viewportFraction: 1.0),
                      itemBuilder: (context, index) {
                        List banners = [];
                        for (
                          int i = 0;
                          i <
                              (providerData["data"]["trending"]["media"]
                                      as List)
                                  .length;
                          i++
                        ) {
                          Map media =
                              (providerData["data"]["trending"]["media"]
                                  as List)[i];
                          final item = AiringBanner(
                            id: media["id"],
                            bannerImage: media["bannerImage"].toString(),
                            coverImage: media["coverImage"]["large"].toString(),
                            title:
                                media["title"]["romaji"].toString().length > 24
                                ? "${media["title"]["romaji"].toString().substring(0, 24)}..."
                                : media["title"]["romaji"].toString(),
                            tagString:
                                ((media["genres"] as List)
                                            .map((tag) => tag.toString())
                                            .join(" • "))
                                        .length >
                                    20
                                ? "${((media["genres"] as List).map((tag) => tag.toString()).join(" • ")).substring(0, 20)}..."
                                : ((media["genres"] as List)
                                      .map((tag) => tag.toString())
                                      .join(" • ")),
                            type: media["type"].toString().toLowerCase(),
                          );
                          banners.add(item);
                        }
                        return banners[index];
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  HorizontalAnimeList(
                    heading: "Trending Now",
                    animeArray: providerData["data"]["trending"]["media"],
                    pagetype: PageType.trendingManga,
                  ),
                  HorizontalAnimeList(
                    heading: "All Time Popular",
                    animeArray: providerData["data"]["allTimePopular"]["media"],
                    pagetype: PageType.popularAllTimeManga,
                  ),
                ],
              ),
            ),
    );
  }
}
