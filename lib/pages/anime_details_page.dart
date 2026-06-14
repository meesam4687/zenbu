import 'package:flutter/material.dart';
import 'package:zenbu/anilist_connector.dart';
import 'package:zenbu/components/anime_details_page/details_pane.dart';
import 'package:zenbu/components/anime_details_page/title_pane.dart';
import 'package:zenbu/components/anime_details_page/watch_pane.dart';
import 'package:zenbu/pages/error_page.dart';

class AnimeDetailsPage extends StatefulWidget {
  const AnimeDetailsPage({super.key, required this.id});
  final int? id;

  @override
  State<AnimeDetailsPage> createState() => _AnimeDetailsPageState();
}

class _AnimeDetailsPageState extends State<AnimeDetailsPage>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> animeData;

  @override
  void initState() {
    super.initState();
    animeData = getAnimeData(widget.id as int);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: animeData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        if (snapshot.hasError) {
          return ErrorPage(
            scaffold: true,
            onReload: () {
              setState(() {
                animeData = getAnimeData(widget.id as int);
              });
            },
          );
        }

        final media = snapshot.data!["data"]["Media"];

        return DefaultTabController(
          length: 3,
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
                      totalEpisodes: media["episodes"]?.toString() ?? '?',
                      title: media["title"]["romaji"],
                      progress:
                          "Progress: ${(media["mediaListEntry"]?["progress"] ?? "0")}/${media["episodes"] ?? "?"}",
                      cover: media["coverImage"]["extraLarge"],
                      banner: media["bannerImage"],
                      mediaState: media["mediaListEntry"]?["status"] ?? 'NONE',
                      mediaListEntry: media["mediaListEntry"],
                      fullTitle: media["title"]["romaji"],
                    ),
                  ),
                ),

                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    const TabBar(
                      tabs: [
                        Tab(text: "About"),
                        Tab(text: "Watch"),
                        Tab(text: "Reviews"),
                      ],
                    ),
                  ),
                ),
              ],

              body: TabBarView(
                children: [
                  _KeepAliveWrapper(
                    child: SingleChildScrollView(
                      key: const PageStorageKey('about'),
                      physics: const ClampingScrollPhysics(),
                      child: DetailsPane(mediaId: widget.id as int),
                    ),
                  ),

                  _KeepAliveWrapper(
                    child: SizedBox(
                      child: AnimeWatchPane(
                        mediaId: widget.id as int,
                        malId: media["idMal"] as int?,
                        animeTitle: media["title"]["romaji"] ?? '',
                        coverImage: media["coverImage"]["extraLarge"],
                        streamingEpisodes: media["streamingEpisodes"] as List?,
                      ),
                    ),
                  ),

                  const _KeepAliveWrapper(
                    child: Center(child: Text("Reviews coming soon")),
                  ),
                ],
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
