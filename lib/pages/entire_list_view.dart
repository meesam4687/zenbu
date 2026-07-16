import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/components/global/item_card.dart';
import 'package:zenbu/components/global/constant_sliver_grid_delegate.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/state_provider.dart';

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
  String? _errorMessage;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  void _loadMore() async {
    if (!_hasMore) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final Map<PageType, Future<Map<String, dynamic>> Function(int, int)>
      apiCalls = {
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
        final List fetchedList = data["data"]["list"]["media"] as List;
        setState(() {
          for (var media in fetchedList) {
            medias.add(media);
          }
          if (fetchedList.length < 48) {
            _hasMore = false;
          }
          page++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _reload() {
    setState(() {
      medias.clear();
      page = 1;
      _errorMessage = null;
      _hasMore = true;
    });
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final apiCalls = {
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

    try {
      final data = await apiCall(1, 48);
      if (mounted) {
        final List fetchedList = data["data"]["list"]["media"] as List;
        setState(() {
          medias.clear();
          for (var media in fetchedList) {
            medias.add(media);
          }
          page = 2;
          _errorMessage = null;
          _hasMore = fetchedList.length >= 48;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.heading)),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _errorMessage != null
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 120,
                  child: Center(
                    child: Error(reload: _reload, message: _errorMessage),
                  ),
                ),
              )
            : (medias.isEmpty)
            ? const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : Container(
                margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
                child: Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: _scrollController,
                        gridDelegate: const ConstantSliverGridDelegate(
                          itemWidth: 110.0,
                          itemHeight: 226.0,
                        ),
                        itemCount: _isLoading
                            ? medias.length + 1
                            : medias.length,
                        itemBuilder: (context, index) {
                          if (index == medias.length && _isLoading == true) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 3.0),
                              child: ItemCard(
                                title: provider.resolveTitle(
                                    medias[index]["title"] as Map?),
                                image:
                                    medias[index]["coverImage"]["large"]
                                        as String,
                                id: medias[index]["id"] as int,
                                type: (medias[index]["type"] as String)
                                    .toLowerCase(),
                                mediaListEntry:
                                    medias[index]["mediaListEntry"] as Map?,
                                listDataPreloaded: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
