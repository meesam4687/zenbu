import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/components/global/item_card.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:flutter/material.dart';

enum PageType {
  trendingAnime,
  popularSeasonAnime,
  upcomingAnime,
  popularAllTimeAnime,
  trendingManga,
  popularAllTimeManga,
  highestRatedAnime,
  highestRatedManga,
}

class EntireListView extends StatefulWidget {
  const EntireListView({super.key, required this.heading, required this.type});

  final String heading;
  final PageType type;

  @override
  State<EntireListView> createState() => _EntireListViewState();
}

class _EntireListViewState extends State<EntireListView> {
  List<Map> medias = [];
  int page = 1;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading) {
      _loadMore();
    }
  }

  void _loadMore() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final Map<PageType, Future<Map<String, dynamic>> Function(int, int)> apiCalls = {
        PageType.trendingAnime: getTrendingAnime,
        PageType.popularSeasonAnime: getPopularSeason,
        PageType.upcomingAnime: getUpcomingAnime,
        PageType.popularAllTimeAnime: getPopularAllTimeAnime,
        PageType.trendingManga: getTrendingManga,
        PageType.popularAllTimeManga: getPopularAllTimeManga,
        PageType.highestRatedAnime: getHighestRatedAnime,
        PageType.highestRatedManga: getHighestRatedManga,
      };

      final apiCall = apiCalls[widget.type];
      if (apiCall == null) return;
      final data = await apiCall(page, 48);

      if (mounted) {
        setState(() {
          for (var media in (data["data"]["list"]["media"] as List)) {
            medias.add(media);
          }
          page++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _reload() {
    setState(() {
      medias.clear();
      page = 1;
      _hasError = false;
    });
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.heading)),
      body: _hasError
          ? Error(reload: _reload)
          : (medias.isEmpty)
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Container(
                  margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
                  child: Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                          controller: _scrollController,
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 137.142,
                            childAspectRatio: 100 / 200,
                          ),
                          itemCount: _isLoading ? medias.length + 1 : medias.length,
                          itemBuilder: (context, index) {
                            if (index == medias.length && _isLoading == true) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 3.0),
                              child: ItemCard(
                                title: medias[index]["title"]["romaji"] as String,
                                image: medias[index]["coverImage"]["large"] as String,
                                id: medias[index]["id"] as int,
                                type: (medias[index]["type"] as String).toLowerCase(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
