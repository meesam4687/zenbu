import 'package:flutter/material.dart';
import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/components/media_details_page/details_pane.dart';
import 'package:zenbu/components/media_details_page/title_pane.dart';
import 'package:zenbu/components/media_details_page/watch_pane.dart';
import 'package:zenbu/components/media_details_page/reviews_pane.dart';
import 'package:zenbu/components/media_details_page/read_pane.dart';
import 'package:zenbu/pages/error_page.dart';

class MediaDetailsPage extends StatefulWidget {
  const MediaDetailsPage({super.key, required this.id, required this.isAnime});

  final int? id;
  final bool isAnime;

  @override
  State<MediaDetailsPage> createState() => _MediaDetailsPageState();
}

class _MediaDetailsPageState extends State<MediaDetailsPage>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _mediaData;

  @override
  void initState() {
    super.initState();
    _mediaData = widget.isAnime
        ? getAnimeData(widget.id as int)
        : getMangaData(widget.id as int);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _mediaData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        if (snapshot.hasError) {
          return ErrorPage(
            scaffold: true,
            message: snapshot.error?.toString(),
            onReload: () {
              setState(() {
                _mediaData = widget.isAnime
                    ? getAnimeData(widget.id as int)
                    : getMangaData(widget.id as int);
              });
            },
          );
        }

        final media = snapshot.data!["data"]["Media"];
        final totalChapters = media["chapters"]?.toString() ?? '?';
        final totalEpisodes = media["episodes"]?.toString() ?? '?';
        final progressLimit = widget.isAnime ? totalEpisodes : totalChapters;

        final currentProgress = media["mediaListEntry"]?["progress"] ?? "0";

        final format = media["format"]?.toString() ?? "";
        final showReadTab = !widget.isAnime && format != 'NOVEL';

        return DefaultTabController(
          length: widget.isAnime ? 3 : (showReadTab ? 3 : 2),
          child: Scaffold(
            body: NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 320,
                  pinned: true,
                  floating: false,
                  snap: false,
                  elevation: innerBoxIsScrolled ? 4 : 0,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: TitlePane(
                      id: widget.id as int,
                      totalEpisodes: progressLimit,
                      title: media["title"]["romaji"] ?? '',
                      progress: "Progress: $currentProgress/$progressLimit",
                      cover: media["coverImage"]["extraLarge"],
                      banner: media["bannerImage"],
                      mediaState: media["mediaListEntry"]?["status"] ?? 'NONE',
                      mediaListEntry: media["mediaListEntry"],
                      fullTitle: media["title"]["romaji"] ?? '',
                      isAnime: widget.isAnime,
                      isFavourite: media["isFavourite"] ?? false,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      tabs: widget.isAnime
                          ? const [
                              Tab(text: "About"),
                              Tab(text: "Watch"),
                              Tab(text: "Reviews"),
                            ]
                          : (showReadTab
                              ? const [
                                  Tab(text: "About"),
                                  Tab(text: "Read"),
                                  Tab(text: "Reviews"),
                                ]
                              : const [Tab(text: "About"), Tab(text: "Reviews")]),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: widget.isAnime
                    ? [
                        _KeepAliveWrapper(
                          child: SingleChildScrollView(
                            key: const PageStorageKey('about'),
                            physics: const ClampingScrollPhysics(),
                            child: DetailsPane(
                              mediaId: widget.id as int,
                              isAnime: true,
                            ),
                          ),
                        ),
                        _KeepAliveWrapper(
                          child: SizedBox(
                            child: AnimeWatchPane(
                              mediaId: widget.id as int,
                              malId: media["idMal"] as int?,
                              animeTitle: media["title"]["romaji"] ?? '',
                              coverImage: media["coverImage"]["extraLarge"],
                              streamingEpisodes:
                                  media["streamingEpisodes"] as List?,
                              anilistProgress: int.tryParse(currentProgress.toString()) ?? 0,
                              mediaState: media["mediaListEntry"]?["status"] ?? 'NONE',
                            ),
                          ),
                        ),
                        _KeepAliveWrapper(
                          child: ReviewsPane(mediaId: widget.id as int),
                        ),
                      ]
                    : (showReadTab
                        ? [
                            _KeepAliveWrapper(
                              child: SingleChildScrollView(
                                key: const PageStorageKey('about'),
                                physics: const ClampingScrollPhysics(),
                                child: DetailsPane(
                                  mediaId: widget.id as int,
                                  isAnime: false,
                                ),
                              ),
                            ),
                            _KeepAliveWrapper(
                              child: SizedBox(
                                child: MangaReadPane(
                                  mediaId: widget.id as int,
                                  mangaTitle: media["title"]["romaji"] ?? '',
                                  coverImage: media["coverImage"]["extraLarge"],
                                  anilistProgress: int.tryParse(currentProgress.toString()) ?? 0,
                                  mediaState: media["mediaListEntry"]?["status"] ?? 'NONE',
                                ),
                              ),
                            ),
                            _KeepAliveWrapper(
                              child: ReviewsPane(mediaId: widget.id as int),
                            ),
                          ]
                        : [
                            _KeepAliveWrapper(
                              child: SingleChildScrollView(
                                key: const PageStorageKey('about'),
                                physics: const ClampingScrollPhysics(),
                                child: DetailsPane(
                                  mediaId: widget.id as int,
                                  isAnime: false,
                                ),
                              ),
                            ),
                            _KeepAliveWrapper(
                              child: ReviewsPane(mediaId: widget.id as int),
                            ),
                          ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_) => false;
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(context) {
    super.build(context);
    return widget.child;
  }
}
