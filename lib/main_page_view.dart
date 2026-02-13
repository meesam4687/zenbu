import 'package:zenbu/pages/anime_discovery_page.dart';
import 'package:zenbu/pages/home_page.dart';
import 'package:zenbu/pages/manga_discovery_page.dart';
import 'package:flutter/cupertino.dart';

class MainPageView extends StatefulWidget {
  const MainPageView({super.key});

  @override
  State<MainPageView> createState() => _MainPageState();
}

class _MainPageState extends State<MainPageView> {
  late int selectedIdx;
  @override
  void initState() {
    super.initState();
    selectedIdx = 1;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: selectedIdx,
        onTap: (value) {
          setState(() {
            selectedIdx = value;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.film),
            label: "Anime",
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.book),
            label: "Manga",
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return AnimeDiscoveryPage();
          case 1:
            return HomePage();
          case 2:
            return MangaDiscoveryPage();
          default:
            return HomePage();
        }
      },
    );
  }
}
