import 'package:zenbu/pages/entire_list_view.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/anilist_connector.dart';
import 'package:zenbu/state_provider.dart';
import 'package:zenbu/components/global/banner.dart';
import 'package:zenbu/components/anime_discovery_page/horizontal_anime_list.dart';
import 'package:zenbu/components/anime_discovery_page/search_segment.dart';
import 'package:provider/provider.dart';

class AnimeDiscoveryPage extends StatefulWidget {
  const AnimeDiscoveryPage({super.key});

  @override
  State<AnimeDiscoveryPage> createState() => _AnimeDiscoveryPageState();
}

class _AnimeDiscoveryPageState extends State<AnimeDiscoveryPage> {
  late Future<Map<String, dynamic>> data;

  void _loadData() {
    setState(() {
      data = getAnimeHomePage(1, 10);
    });
  }

  @override
  void initState() {
    Map providerData = Provider.of<StateProvider>(
      context,
      listen: false,
    ).animeDiscoveryData;
    if (providerData.isEmpty) {
      data = getAnimeHomePage(1, 10);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Map providerData = Provider.of<StateProvider>(context).animeDiscoveryData;
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
                if (snapshot.hasError) {
                  return ErrorPage(scaffold: false, onReload: _loadData);
                }
                final data = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Provider.of<StateProvider>(
                    context,
                    listen: false,
                  ).updateDiscoveryData(data);
                });
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 240,
                        child: PageView.builder(
                          itemCount:
                              (data["data"]["popularSeason"]["media"] as List)
                                  .length,
                          controller: PageController(viewportFraction: 1.0),
                          itemBuilder: (context, index) {
                            List banners = [];
                            for (
                              int i = 0;
                              i <
                                  (data["data"]["popularSeason"]["media"]
                                          as List)
                                      .length;
                              i++
                            ) {
                              Map media =
                                  (data["data"]["popularSeason"]["media"]
                                      as List)[i];
                              final item = AiringBanner(
                                id: media["id"],
                                bannerImage: media["bannerImage"].toString(),
                                coverImage: media["coverImage"]["large"]
                                    .toString(),
                                title:
                                    media["title"]["romaji"].toString(),
                                totalEpisodes: (media["episodes"] != null)
                                    ? media["episodes"].toString()
                                    : "??",
                                airedEpisodes:
                                    (media["nextAiringEpisode"] != null)
                                    ? (media["nextAiringEpisode"]["episode"] -
                                              1)
                                          .toString()
                                    : "0",
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
                        pagetype: PageType.trendingAnime,
                      ),
                      HorizontalAnimeList(
                        heading: "Popular this season",
                        animeArray: data["data"]["popularSeason"]["media"],
                        pagetype: PageType.popularSeasonAnime,
                      ),
                      HorizontalAnimeList(
                        heading: "Upcoming",
                        animeArray: data["data"]["upcoming"]["media"],
                        pagetype: PageType.upcomingAnime,
                      ),
                      HorizontalAnimeList(
                        heading: "All Time Popular",
                        animeArray: data["data"]["allTimePopular"]["media"],
                        pagetype: PageType.popularAllTimeAnime,
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
                          (providerData["data"]["popularSeason"]["media"]
                                  as List)
                              .length,
                      controller: PageController(viewportFraction: 1.0),
                      itemBuilder: (context, index) {
                        List banners = [];
                        for (
                          int i = 0;
                          i <
                              (providerData["data"]["popularSeason"]["media"]
                                      as List)
                                  .length;
                          i++
                        ) {
                          Map media =
                              (providerData["data"]["popularSeason"]["media"]
                                  as List)[i];
                          final item = AiringBanner(
                            id: media["id"],
                            bannerImage: media["bannerImage"].toString(),
                            coverImage: media["coverImage"]["large"].toString(),
                            title:
                                media["title"]["romaji"].toString(),
                            totalEpisodes: (media["episodes"] != null)
                                ? media["episodes"].toString()
                                : "??",
                            airedEpisodes: (media["nextAiringEpisode"] != null)
                                ? (media["nextAiringEpisode"]["episode"] - 1)
                                      .toString()
                                : "0",
                            tagString:
                                ((media["genres"] as List)
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
                    pagetype: PageType.trendingAnime,
                  ),
                  HorizontalAnimeList(
                    heading: "Popular this season",
                    animeArray: providerData["data"]["popularSeason"]["media"],
                    pagetype: PageType.popularSeasonAnime,
                  ),
                  HorizontalAnimeList(
                    heading: "Upcoming",
                    animeArray: providerData["data"]["upcoming"]["media"],
                    pagetype: PageType.upcomingAnime,
                  ),
                  HorizontalAnimeList(
                    heading: "All Time Popular",
                    animeArray: providerData["data"]["allTimePopular"]["media"],
                    pagetype: PageType.popularAllTimeAnime,
                  ),
                ],
              ),
            ),
    );
  }
}
