import 'package:al_client/anilist_connector.dart';
import 'package:al_client/components/global/item_card.dart';
import 'package:flutter/material.dart';

enum PageType {
  trendingAnime,
  popularSeasonAnime,
  upcomingAnime,
  popularAllTimeAnime,
  trendingManga,
  popularAllTimeManga,
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
    });
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
    }
    setState(() {
      for (var media in (data["data"]["list"]["media"] as List)) {
        medias.add(media);
      }
      page++;
      _isLoading = false;
    });
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
      body: (medias.isEmpty)
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
                        childAspectRatio: 100 / 181,
                        maxCrossAxisExtent: 180,
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
                        return ItemCard(
                          title:
                              ((medias[index]["title"]["romaji"] as String)
                                      .length >
                                  10)
                              ? '${(medias[index]["title"]["romaji"] as String).substring(0, 10)}...'
                              : medias[index]["title"]["romaji"] as String,
                          image: medias[index]["coverImage"]["large"] as String,
                          id: medias[index]["id"] as int,
                          type: (medias[index]["type"] as String).toLowerCase(),
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
