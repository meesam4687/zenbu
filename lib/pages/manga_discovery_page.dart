import 'package:zenbu/pages/entire_list_view.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:zenbu/anilist_connector.dart';
import 'package:zenbu/state_provider.dart';
import 'package:zenbu/components/global/banner.dart';
import 'package:zenbu/components/anime_discovery_page/horizontal_anime_list.dart';
import 'package:zenbu/components/manga_discovery_page/search_segment.dart';
import 'package:provider/provider.dart';

class MangaDiscoveryPage extends StatefulWidget {
  const MangaDiscoveryPage({super.key});

  @override
  State<MangaDiscoveryPage> createState() => _MangaDiscoveryPageState();
}

class _MangaDiscoveryPageState extends State<MangaDiscoveryPage> {
  late Future<Map<String, dynamic>> data;

  void _loadData() {
    setState(() {
      data = getMangaHomePage(1, 10);
    });
  }

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
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: SearchSegment(),
      ),
      child: SafeArea(
        child: (providerData.isEmpty)
            ? FutureBuilder(
                future: data,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CupertinoActivityIndicator(),
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
                    ).updateMangaDiscoveryData(data);
                  });
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
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
                                      media["title"]["romaji"].toString(),
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
                        const SizedBox(height: 10),
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
                        HorizontalAnimeList(
                          heading: "Highst Rated",
                          animeArray: data["data"]["highestRated"]["media"],
                          pagetype: PageType.highestRatedManga,
                        ),
                      ],
                    ),
                  );
                },
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
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
                                  media["title"]["romaji"].toString(),
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
                    const SizedBox(height: 10),
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
                    HorizontalAnimeList(
                      heading: "Highest Rated",
                      animeArray: providerData["data"]["highestRated"]["media"],
                      pagetype: PageType.highestRatedManga,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
