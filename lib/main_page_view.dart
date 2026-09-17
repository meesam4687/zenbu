import 'package:zenbu/pages/media_discovery_page.dart';
import 'package:zenbu/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:zenbu/l10n/l10n_extension.dart';
import 'package:zenbu/services/update_service.dart';
import 'package:zenbu/pages/update_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPageView extends StatefulWidget {
  const MainPageView({super.key});

  @override
  State<MainPageView> createState() => MainPageViewState();
}

final List<Widget> pages = [
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
    final double width = MediaQuery.of(context).size.width;
    final bool isTablet = width >= 600;

    final Widget bodyContent = PageTransitionSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation, secondaryAnimation) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      child: pages[selectedIdx],
    );

    if (isTablet) {
      final ThemeData theme = Theme.of(context);

      final Color railColor = ElevationOverlay.applySurfaceTint(
        theme.colorScheme.surface,
        theme.colorScheme.surfaceTint,
        3.0,
      );

      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Row(
          children: [
            ColoredBox(
              color: railColor,
              child: SafeArea(
                left: true,
                right: false,
                top: false,
                bottom: false,
                child: Theme(
                  data: theme.copyWith(
                    navigationRailTheme: theme.navigationRailTheme.copyWith(
                      useIndicator: true,
                      indicatorColor: theme.colorScheme.secondaryContainer,
                      indicatorShape: const StadiumBorder(),
                    ),
                  ),
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      padding: EdgeInsets.zero,
                      viewPadding: EdgeInsets.zero,
                      viewInsets: EdgeInsets.zero,
                    ),
                    child: NavigationRail(
                      backgroundColor: Colors.transparent,
                      groupAlignment: 0.0,
                      selectedIndex: selectedIdx,
                      onDestinationSelected: (value) {
                        setState(() {
                          selectedIdx = value;
                        });
                      },
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        NavigationRailDestination(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          icon: const Icon(Icons.video_collection),
                          selectedIcon: const Icon(Icons.video_collection),
                          label: Text(context.l10n.anime),
                        ),
                        NavigationRailDestination(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          icon: const Icon(Icons.home),
                          selectedIcon: const Icon(Icons.home),
                          label: Text(context.l10n.home),
                        ),
                        NavigationRailDestination(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          icon: const Icon(Icons.book_rounded),
                          selectedIcon: const Icon(Icons.book_rounded),
                          label: Text(context.l10n.manga),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Expanded(child: bodyContent),
          ],
        ),
      );
    }
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
            icon: const Icon(Icons.video_collection),
            label: context.l10n.anime,
          ),
          NavigationDestination(
            icon: const Icon(Icons.home),
            label: context.l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.book_rounded),
            label: context.l10n.manga,
          ),
        ],
      ),
      body: bodyContent,
    );
  }
}
