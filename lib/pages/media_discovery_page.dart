import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/components/global/banner.dart';
import 'package:zenbu/components/media_discovery_page/horizontal_list.dart';
import 'package:zenbu/components/media_discovery_page/search_segment.dart';
import 'package:zenbu/components/media_discovery_page/simulcasts_button.dart';
import 'package:zenbu/pages/entire_list_view.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:zenbu/state_provider.dart';

class MediaDiscoveryPage extends StatefulWidget {
  const MediaDiscoveryPage({super.key, required this.isAnime});
  final bool isAnime;

  @override
  State<MediaDiscoveryPage> createState() => _MediaDiscoveryPageState();
}

class _MediaDiscoveryPageState extends State<MediaDiscoveryPage> {
  late Future<Map<String, dynamic>> _data;

  void _loadData() {
    setState(() {
      _data = widget.isAnime ? getAnimeHomePage(1, 10) : getMangaHomePage(1, 10);
    });
  }

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<StateProvider>(context, listen: false);
    final providerData = widget.isAnime ? provider.animeDiscoveryData : provider.mangaDiscoveryData;
    if (providerData.isEmpty) {
      _data = widget.isAnime ? getAnimeHomePage(1, 10) : getMangaHomePage(1, 10);
    }
  }

  Future<void> _handleRefresh() async {
    try {
      final fetchedData = await (widget.isAnime
          ? getAnimeHomePage(1, 10)
          : getMangaHomePage(1, 10));
      if (mounted) {
        final provider = Provider.of<StateProvider>(context, listen: false);
        if (widget.isAnime) {
          provider.updateDiscoveryData(fetchedData);
        } else {
          provider.updateMangaDiscoveryData(fetchedData);
        }
        setState(() {
          _data = Future.value(fetchedData);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateProvider>(context);
    final providerData = widget.isAnime ? provider.animeDiscoveryData : provider.mangaDiscoveryData;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: SearchSegment(isAnime: widget.isAnime),
        toolbarHeight: 100,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: providerData.isEmpty
            ? FutureBuilder(
                future: _data,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }
                  if (snapshot.hasError) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 200,
                        child: Center(
                          child: ErrorPage(scaffold: false, onReload: _loadData),
                        ),
                      ),
                    );
                  }
                  final fetchedData = snapshot.data!;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (widget.isAnime) {
                      Provider.of<StateProvider>(context, listen: false)
                          .updateDiscoveryData(fetchedData);
                    } else {
                      Provider.of<StateProvider>(context, listen: false)
                          .updateMangaDiscoveryData(fetchedData);
                    }
                  });
                  return _buildContent(fetchedData);
                },
              )
            : _buildContent(providerData),
      ),
    );
  }

  Widget _buildContent(Map dataMap) {
    final mediaList = widget.isAnime
        ? (dataMap["data"]["popularSeason"]["media"] as List)
        : (dataMap["data"]["trending"]["media"] as List);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: PageView.builder(
              itemCount: mediaList.length,
              controller: PageController(viewportFraction: 1.0),
              itemBuilder: (context, index) {
                final media = mediaList[index];
                final List? genresList = media["genres"] as List?;
                final String tagString = genresList != null
                    ? genresList.map((tag) => tag.toString()).join(" • ")
                    : "";
                final String displayTags = tagString.length > 20
                    ? "${tagString.substring(0, 20)}..."
                    : tagString;

                return AiringBanner(
                  id: media["id"],
                  bannerImage: media["bannerImage"]?.toString() ?? '',
                  coverImage: media["coverImage"]?["large"]?.toString() ?? '',
                  title: media["title"]?["romaji"]?.toString() ?? '',
                  totalEpisodes: widget.isAnime
                      ? (media["episodes"] != null ? media["episodes"].toString() : "??")
                      : null,
                  airedEpisodes: widget.isAnime
                      ? ((media["nextAiringEpisode"] != null)
                          ? (media["nextAiringEpisode"]["episode"] - 1).toString()
                          : "0")
                      : null,
                  tagString: displayTags,
                  type: media["type"].toString().toLowerCase(),
                );
              },
            ),
          ),
          if (widget.isAnime) ...[
            SimulcastsButton(medias: mediaList),
            const SizedBox(height: 10),
          ] else ...[
            const SizedBox(height: 10),
          ],
          if (widget.isAnime) ...[
            HorizontalList(
              heading: "Trending Now",
              mediaArray: dataMap["data"]["trending"]["media"],
              pagetype: PageType.trendingAnime,
            ),
            HorizontalList(
              heading: "Popular this season",
              mediaArray: dataMap["data"]["popularSeason"]["media"],
              pagetype: PageType.popularSeasonAnime,
            ),
            HorizontalList(
              heading: "Upcoming",
              mediaArray: dataMap["data"]["upcoming"]["media"],
              pagetype: PageType.upcomingAnime,
            ),
            HorizontalList(
              heading: "All Time Popular",
              mediaArray: dataMap["data"]["allTimePopular"]["media"],
              pagetype: PageType.popularAllTimeAnime,
            ),
            HorizontalList(
              heading: "Highest Rated",
              mediaArray: dataMap["data"]["highestRated"]["media"],
              pagetype: PageType.highestRatedAnime,
            ),
          ] else ...[
            HorizontalList(
              heading: "Trending Now",
              mediaArray: dataMap["data"]["trending"]["media"],
              pagetype: PageType.trendingManga,
            ),
            HorizontalList(
              heading: "All Time Popular",
              mediaArray: dataMap["data"]["allTimePopular"]["media"],
              pagetype: PageType.popularAllTimeManga,
            ),
            HorizontalList(
              heading: "Highest Rated",
              mediaArray: dataMap["data"]["highestRated"]["media"],
              pagetype: PageType.highestRatedManga,
            ),
          ],
        ],
      ),
    );
  }
}
