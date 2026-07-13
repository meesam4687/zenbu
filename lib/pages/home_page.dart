import 'package:zenbu/components/home_page/user_info_modal_sheet.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:zenbu/pages/appearance_settings_page.dart';
import 'package:zenbu/pages/downloads_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zenbu/components/global/custom_image.dart';
import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/state_provider.dart';
import 'package:zenbu/components/home_page/media_list.dart';
import 'package:zenbu/components/home_page/global_search_bar.dart';
import 'package:zenbu/services/download_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>> _alData;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    Map providerData = Provider.of<StateProvider>(
      context,
      listen: false,
    ).alData;

    if (providerData.isEmpty) {
      _alData = getHomePageData();
    }
  }

  List<dynamic> _extractListEntries(Map data, String listKey) {
    if (data.isEmpty) return [];
    final listData = data["data"]?[listKey];
    if (listData == null || listData["lists"] == null) return [];
    final lists = listData["lists"] as List;
    final entries = [];
    for (var list in lists) {
      if (list["entries"] != null) {
        entries.addAll(list["entries"]);
      }
    }
    return entries;
  }

  Future<void> _handleRefresh() async {
    try {
      final newData = await getHomePageData();
      if (mounted) {
        Provider.of<StateProvider>(context, listen: false).updateData(newData);
        setState(() {
          _alData = Future.value(newData);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateProvider>(context);
    Map providerData = provider.alData;
    final showAnime = provider.showAnimeList;
    final showManga = provider.showMangaList;
    final showRecommendations = provider.showRecommendationsList;
    final homeListOrder = provider.homeListOrder;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: _isSearching ? const SizedBox() : const Text("Home"),
        actions: [
          GlobalSearchBar(
            onSearchStateChanged: (isSearching) {
              setState(() {
                _isSearching = isSearching;
              });
            },
          ),
          const SizedBox(width: 8),
          const HomeDownloadButton(),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (providerData.isNotEmpty) {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return UserInfoModalSheet(
                      profileImage:
                          providerData['data']['Viewer']['avatar']['large'],
                      username: providerData['data']['Viewer']['name'],
                      userId: providerData['data']['Viewer']['id'],
                    );
                  },
                );
              }
            },
            child: Badge(
              isLabelVisible: (providerData.isNotEmpty)
                  ? (providerData["data"]["Viewer"]["unreadNotificationCount"] >
                        0)
                  : false,
              smallSize: 12,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(360)),
                ),
                child: ClipOval(
                  child: (providerData.isEmpty)
                      ? FutureBuilder(
                          future: _alData,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 40,
                                width: 40,
                                child: Icon(Icons.face),
                              );
                            }
                            if (snapshot.hasError) {
                              return const SizedBox(
                                height: 40,
                                width: 40,
                                child: Icon(Icons.face),
                              );
                            }
                            final data = snapshot.data!;
                            return CustomImage(
                              height: 40,
                              width: 40,
                              fit: BoxFit.fill,
                              imageUrl:
                                  data['data']['Viewer']['avatar']['large']
                                      as String,
                              borderRadius: BorderRadius.circular(360),
                            );
                          },
                        )
                      : CustomImage(
                          height: 40,
                          width: 40,
                          fit: BoxFit.fill,
                          imageUrl:
                              providerData['data']['Viewer']['avatar']['large']
                                  as String,
                          borderRadius: BorderRadius.circular(360),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: (providerData.isEmpty)
            ? FutureBuilder(
                future: _alData,
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
                        height: MediaQuery.of(context).size.height - 120,
                        child: Center(
                          child: ErrorPage(
                            scaffold: false,
                            message: snapshot.error?.toString(),
                            onReload: () {
                              setState(() {
                                _alData = getHomePageData();
                              });
                            },
                          ),
                        ),
                      ),
                    );
                  }
                  final data = snapshot.data!;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Provider.of<StateProvider>(
                      context,
                      listen: false,
                    ).updateData(data);
                  });
                  final animeData = _extractListEntries(data, "animeList");
                  final mangaData = _extractListEntries(data, "mangaList");

                  if (!showAnime && !showManga && !showRecommendations) {
                    return const _BothDisabledView();
                  }

                  final bool recommendationsActive =
                      showRecommendations &&
                      provider.recommendations.isNotEmpty;
                  final int activeCount =
                      (showAnime ? 1 : 0) +
                      (showManga ? 1 : 0) +
                      (recommendationsActive ? 1 : 0);
                  final bool singleListActive = activeCount == 1;

                  final List<Widget> listWidgets = [];
                  for (var key in homeListOrder) {
                    if (key == 'anime' && showAnime) {
                      listWidgets.add(
                        MediaList(
                          items: animeData,
                          isAnime: true,
                          multiRow: singleListActive,
                        ),
                      );
                    } else if (key == 'manga' && showManga) {
                      listWidgets.add(
                        MediaList(
                          items: mangaData,
                          isAnime: false,
                          multiRow: singleListActive,
                        ),
                      );
                    } else if (key == 'recommendations' &&
                        recommendationsActive) {
                      listWidgets.add(
                        MediaList(
                          items: provider.recommendations,
                          isAnime: true,
                          title: "Recommended for You",
                          multiRow: singleListActive,
                        ),
                      );
                    }
                  }

                  final bool firstIsAnime =
                      listWidgets.isNotEmpty &&
                      (listWidgets.first as MediaList).isAnime;
                  final double topSpacing = firstIsAnime ? 24.0 : 16.0;

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: topSpacing),
                        ...listWidgets,
                      ],
                    ),
                  );
                },
              )
            : (!showAnime && !showManga && !showRecommendations)
            ? const _BothDisabledView()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Builder(
                  builder: (context) {
                    final bool recommendationsActive =
                        showRecommendations &&
                        provider.recommendations.isNotEmpty;
                    final int activeCount =
                        (showAnime ? 1 : 0) +
                        (showManga ? 1 : 0) +
                        (recommendationsActive ? 1 : 0);
                    final bool singleListActive = activeCount == 1;

                    final List<Widget> listWidgets = [];
                    for (var key in homeListOrder) {
                      if (key == 'anime' && showAnime) {
                        listWidgets.add(
                          MediaList(
                            items: _extractListEntries(
                              providerData,
                              "animeList",
                            ),
                            isAnime: true,
                            multiRow: singleListActive,
                          ),
                        );
                      } else if (key == 'manga' && showManga) {
                        listWidgets.add(
                          MediaList(
                            items: _extractListEntries(
                              providerData,
                              "mangaList",
                            ),
                            isAnime: false,
                            multiRow: singleListActive,
                          ),
                        );
                      } else if (key == 'recommendations' &&
                          recommendationsActive) {
                        listWidgets.add(
                          MediaList(
                            items: provider.recommendations,
                            isAnime: true,
                            title: "Recommended for You",
                            multiRow: singleListActive,
                          ),
                        );
                      }
                    }

                    final bool firstIsAnime =
                        listWidgets.isNotEmpty &&
                        (listWidgets.first as MediaList).isAnime;
                    final double topSpacing = firstIsAnime ? 24.0 : 16.0;

                    return Column(
                      children: [
                        SizedBox(height: topSpacing),
                        ...listWidgets,
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _BothDisabledView extends StatelessWidget {
  const _BothDisabledView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/oops.svg',
              height: 120,
              width: 120,
              colorFilter: ColorFilter.mode(cs.outline, BlendMode.srcIn),
              placeholderBuilder: (context) => const SizedBox(
                height: 120,
                width: 120,
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Home Screen is empty',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You put nothing on the homescreen.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AppearanceSettingsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.settings_suggest_rounded),
              label: const Text('Open Appearance Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeDownloadButton extends StatefulWidget {
  const HomeDownloadButton({super.key});

  @override
  State<HomeDownloadButton> createState() => _HomeDownloadButtonState();
}

class _HomeDownloadButtonState extends State<HomeDownloadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadService = DownloadService();
    return AnimatedBuilder(
      animation: downloadService,
      builder: (context, _) {
        final hasActiveDownloads = downloadService.activeDownloads.isNotEmpty;
        if (hasActiveDownloads) {
          if (!_controller.isAnimating) {
            _controller.repeat(reverse: true);
          }
        } else {
          if (_controller.isAnimating) {
            _controller.stop();
          }
        }

        final primaryColor = Theme.of(context).colorScheme.primary;
        final iconWidget = hasActiveDownloads
            ? FadeTransition(
                opacity: _animation,
                child: Icon(Icons.download, color: primaryColor),
              )
            : const Icon(Icons.download);

        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.onSecondary,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(360),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 20,
            icon: iconWidget,
            tooltip: 'Downloads',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DownloadsPage()),
              );
            },
          ),
        );
      },
    );
  }
}
