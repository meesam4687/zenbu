import 'package:zenbu/pages/anime_discovery_page.dart';
import 'package:zenbu/pages/home_page.dart';
import 'package:zenbu/pages/manga_discovery_page.dart';
import 'package:flutter/cupertino.dart';

class MainPageView extends StatelessWidget {
  const MainPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: 1,
        items: const [
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
            return const AnimeDiscoveryPage();
          case 1:
            return const HomePage();
          case 2:
            return const MangaDiscoveryPage();
          default:
            return const HomePage();
        }
      },
    );
  }
}
