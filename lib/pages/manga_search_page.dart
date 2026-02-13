import 'package:zenbu/anilist_connector.dart';
import 'package:zenbu/components/global/item_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:zenbu/components/manga_discovery_page/search_segment.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.query});
  final String query;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
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
    dynamic data = await searchManga(
      page,
      48,
      widget.query,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
    );
    setState(() {
      for (var media in (data["data"]["Page"]["media"] as List)) {
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        middle: SearchSegment(searchText: widget.query),
      ),
      child: SafeArea(
        child: (medias.isEmpty && _isLoading)
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CupertinoActivityIndicator(),
                ),
              )
            : (medias.isNotEmpty)
            ? Container(
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
                                child: CupertinoActivityIndicator(),
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
              )
            : Center(child: Text("No Results")),
      ),
    );
  }
}
