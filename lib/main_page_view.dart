import 'package:zenbu/pages/media_discovery_page.dart';
import 'package:zenbu/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

class MainPageView extends StatefulWidget {
  const MainPageView({super.key});

  @override
  State<MainPageView> createState() => _MainPageState();
}

List<Widget> pages = [
  const MediaDiscoveryPage(isAnime: true, key: ValueKey('anime_discovery')),
  const HomePage(),
  const MediaDiscoveryPage(isAnime: false, key: ValueKey('manga_discovery')),
];

class _MainPageState extends State<MainPageView> {
  late int selectedIdx;
  @override
  void initState() {
    super.initState();
    selectedIdx = 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        selectedIndex: selectedIdx,
        onDestinationSelected: (value) {
          setState(() {
            selectedIdx = value;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.video_collection),
            label: "Anime",
          ),
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.book_rounded), label: "Manga"),
        ],
      ),
      body: PageTransitionSwitcher(
        duration: Duration(milliseconds: 400),
        transitionBuilder: (child, animation, secondaryAnimation) =>
            FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            ),
        child: pages[selectedIdx],
      ),
    );
  }
}
