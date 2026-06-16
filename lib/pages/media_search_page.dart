import 'package:provider/provider.dart';
import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/components/global/item_card.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/components/media_discovery_page/search_segment.dart';
import 'package:zenbu/state_provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.isAnime,
    required this.query,
    this.genres,
    this.tags,
    this.countryOfOrigin,
    this.releaseYear,
    this.season,
    this.format,
    this.airingStatus,
    this.sourceMaterial,
    this.sortBy,
    this.genresNotIn,
    this.tagsNotIn,
  });

  final bool isAnime;
  final String? query;
  final List? genres;
  final List? tags;
  final String? countryOfOrigin;
  final int? releaseYear;
  final String? season;
  final String? format;
  final String? airingStatus;
  final String? sourceMaterial;
  final String? sortBy;
  final List? genresNotIn;
  final List? tagsNotIn;

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

    dynamic data;
    if (widget.isAnime) {
      data = await searchAnime(
        page,
        48,
        widget.query,
        widget.genres,
        widget.tags,
        widget.season,
        widget.releaseYear,
        widget.format,
        widget.airingStatus,
        widget.countryOfOrigin,
        widget.sourceMaterial,
        widget.sortBy,
        widget.genresNotIn,
        widget.tagsNotIn,
      );
    } else {
      data = await searchManga(
        page,
        48,
        widget.query,
        widget.genres,
        widget.tags,
        widget.releaseYear,
        widget.format,
        widget.airingStatus,
        widget.countryOfOrigin,
        widget.sourceMaterial,
        widget.sortBy,
        widget.genresNotIn,
        widget.tagsNotIn,
      );
    }

    if (mounted) {
      setState(() {
        if (data != null && data["data"] != null && data["data"]["Page"] != null && data["data"]["Page"]["media"] != null) {
          for (var media in (data["data"]["Page"]["media"] as List)) {
            medias.add(media);
          }
        }
        page++;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        final provider = Provider.of<StateProvider>(context, listen: false);
        if (widget.isAnime) {
          provider.clearAnimeFilters();
        } else {
          provider.clearMangaFilters();
        }
        Navigator.of(context).pop(result);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: SearchSegment(
            searchText: widget.query,
            isAnime: widget.isAnime,
          ),
          toolbarHeight: 100,
        ),
        body: (medias.isEmpty && _isLoading)
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : (medias.isNotEmpty)
                ? Container(
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
                              if (index == medias.length && _isLoading) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.only(left: 3.0),
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
                  )
                : const Center(child: Text("No Results")),
      ),
    );
  }
}
