import 'package:zenbu/pages/media_discovery_page.dart';
import 'package:zenbu/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:zenbu/services/update_service.dart';
import 'package:zenbu/pages/update_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPageView extends StatefulWidget {
  const MainPageView({super.key});

  @override
  State<MainPageView> createState() => MainPageViewState();
}

List<Widget> pages = [
  const MediaDiscoveryPage(isAnime: true, key: ValueKey('anime_discovery')),
  const HomePage(),
  const MediaDiscoveryPage(isAnime: false, key: ValueKey('manga_discovery')),
];

class MainPageViewState extends State<MainPageView> {
  late int selectedIdx;
  @override
  void initState() {
    super.initState();
    selectedIdx = 1;
    _checkAppUpdate();
  }

  void _checkAppUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navigator = Navigator.of(context);
      final updateInfo = await UpdateService.checkUpdate();
      if (updateInfo != null && mounted) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'cached_update_version',
            updateInfo.remoteVersion,
          );
          await prefs.setString(
            'cached_update_changelog',
            updateInfo.changelog,
          );
          await prefs.setString('cached_update_url', updateInfo.downloadUrl);
        } catch (_) {}

        navigator.push(
          MaterialPageRoute(
            builder: (context) => UpdatePage(updateInfo: updateInfo),
          ),
        );
      } else {
        await UpdateService.clearUpdateCache();
      }
    });
  }

  void changeTab(int index) {
    setState(() {
      selectedIdx = index;
    });
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
