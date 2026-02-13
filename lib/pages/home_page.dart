import 'package:zenbu/components/home_page/user_info_modal_sheet.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/anilist_connector.dart';
import 'package:zenbu/state_provider.dart';
import 'package:zenbu/components/home_page/anime_list.dart';
import 'package:zenbu/components/home_page/manga_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>> alData;
  @override
  void initState() {
    super.initState();
    Map providerData = Provider.of<StateProvider>(
      context,
      listen: false,
    ).alData;

    if (providerData.isEmpty) {
      alData = getHomePageData();
    }
  }

  @override
  Widget build(BuildContext context) {
    Map providerData = Provider.of<StateProvider>(context).alData;
    late List palist1;
    late List palist2;
    late List pmlist1;
    late List pmlist2;
    if (providerData.isNotEmpty) {
      palist1 =
          ((providerData["data"]["animeList"]["lists"] as List).isNotEmpty)
          ? providerData["data"]["animeList"]["lists"][0]["entries"]
          : [];
      palist2 =
          ((providerData["data"]["animeList"]["lists"] as List).length > 1)
          ? providerData["data"]["animeList"]["lists"][1]["entries"]
          : [];
      pmlist1 =
          ((providerData["data"]["mangaList"]["lists"] as List).isNotEmpty)
          ? providerData["data"]["mangaList"]["lists"][0]["entries"]
          : [];
      pmlist2 =
          ((providerData["data"]["mangaList"]["lists"] as List).length > 1)
          ? providerData["data"]["mangaList"]["lists"][1]["entries"]
          : [];
    }
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Home"),
        trailing: Padding(
          padding: const EdgeInsets.only(right: 5),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              if (providerData.isNotEmpty) {
                showCupertinoModalPopup(
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
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: CupertinoColors.systemGrey,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(360)),
                  ),
                  child: ClipOval(
                    child: (providerData.isEmpty)
                        ? FutureBuilder(
                            future: alData,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 40,
                                  width: 40,
                                  child: Icon(CupertinoIcons.person),
                                );
                              }
                              if (snapshot.hasError) {
                                return const SizedBox(
                                  height: 40,
                                  width: 40,
                                  child: Icon(CupertinoIcons.person),
                                );
                              }
                              final data = snapshot.data!;
                              return Image(
                                height: 40,
                                width: 40,
                                fit: BoxFit.fill,
                                image: NetworkImage(
                                  data['data']['Viewer']['avatar']['large'],
                                ),
                              );
                            },
                          )
                        : Image(
                            height: 40,
                            width: 40,
                            fit: BoxFit.fill,
                            image: NetworkImage(
                              providerData['data']['Viewer']['avatar']['large'],
                            ),
                          ),
                  ),
                ),
                if (providerData.isNotEmpty &&
                    providerData["data"]["Viewer"]["unreadNotificationCount"] > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: (providerData.isEmpty)
            ? FutureBuilder(
                future: alData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CupertinoActivityIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return ErrorPage(
                      scaffold: false,
                      onReload: () {
                        setState(() {
                          alData = getHomePageData();
                        });
                      },
                    );
                  }
                  final data = snapshot.data!;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Provider.of<StateProvider>(
                      context,
                      listen: false,
                    ).updateData(data);
                  });
                  final alist1 =
                      ((data["data"]["animeList"]["lists"] as List).isNotEmpty)
                      ? data["data"]["animeList"]["lists"][0]["entries"]
                      : [];
                  final alist2 =
                      ((data["data"]["animeList"]["lists"] as List).length > 1)
                      ? data["data"]["animeList"]["lists"][1]["entries"]
                      : [];
                  final animeData = [...alist1, ...alist2];
                  final mlist1 =
                      ((data["data"]["mangaList"]["lists"] as List).isNotEmpty)
                      ? data["data"]["mangaList"]["lists"][0]["entries"]
                      : [];
                  final mlist2 =
                      ((data["data"]["mangaList"]["lists"] as List).length > 1)
                      ? data["data"]["mangaList"]["lists"][1]["entries"]
                      : [];
                  final mangaData = [...mlist1, ...mlist2];
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        AnimeList(items: animeData),
                        MangaList(items: mangaData),
                      ],
                    ),
                  );
                },
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    AnimeList(items: [...palist1, ...palist2]),
                    MangaList(items: [...pmlist1, ...pmlist2]),
                  ],
                ),
              ),
      ),
    );
  }
}
