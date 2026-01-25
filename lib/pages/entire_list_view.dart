import 'package:zenbu/anilist_connector.dart';
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
      dynamic data;
      if (widget.type == PageType.trendingAnime) {
        data = await getTrendingAnime(page, 48);
      } else if (widget.type == PageType.popularSeasonAnime) {
        data = await getPopularSeason(page, 48);
      } else if (widget.type == PageType.upcomingAnime) {
        data = await getUpcomingAnime(page, 48);
      } else if (widget.type == PageType.popularAllTimeAnime) {
        data = await getPopularAllTimeAnime(page, 48);
      } else if (widget.type == PageType.trendingManga) {
        data = await getTrendingManga(page, 48);
      } else if (widget.type == PageType.popularAllTimeManga) {
        data = await getPopularAllTimeManga(page, 48);
      } else if (widget.type == PageType.highestRatedAnime) {
        data = await getHighestRatedAnime(page, 48);
      } else if (widget.type == PageType.highestRatedManga) {
        data = await getHighestRatedManga(page, 48);
      }
      setState(() {
        for (var media in (data["data"]["list"]["media"] as List)) {
          medias.add(media);
        }
        page++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
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
              margin: EdgeInsets.only(left: 10, right: 10, top: 10),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      controller: _scrollController,
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 137.142,
                        childAspectRatio: 100 / 200,
                      ),
                      itemCount: _isLoading ? medias.length + 1 : medias.length,
                      itemBuilder: (context, index) {
                        //print(MediaQuery.of(context).size.width);
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
                            image:
                                medias[index]["coverImage"]["large"] as String,
                            id: medias[index]["id"] as int,
                            type: (medias[index]["type"] as String)
                                .toLowerCase(),
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
