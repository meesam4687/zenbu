import 'package:zenbu/components/home_page/user_info_modal_sheet.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/components/global/custom_image.dart';
import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/state_provider.dart';
import 'package:zenbu/components/home_page/media_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>> _alData;

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
    Map providerData = Provider.of<StateProvider>(context).alData;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: const Text("Home"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: IconButton(
              onPressed: () {
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
              icon: Badge(
                isLabelVisible: (providerData.isNotEmpty)
                    ? (providerData["data"]["Viewer"]["unreadNotificationCount"] >
                          0)
                    : false,
                smallSize: 12,
                child: Container(
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
          ),
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
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        MediaList(items: animeData, isAnime: true),
                        MediaList(items: mangaData, isAnime: false),
                      ],
                    ),
                  );
                },
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    MediaList(
                      items: _extractListEntries(providerData, "animeList"),
                      isAnime: true,
                    ),
                    MediaList(
                      items: _extractListEntries(providerData, "mangaList"),
                      isAnime: false,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
