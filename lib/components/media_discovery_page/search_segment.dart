import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:zenbu/components/media_discovery_page/filter_sheet.dart';
import 'package:zenbu/pages/media_search_page.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/state_provider.dart';

class _SearchShuttle extends StatefulWidget {
  const _SearchShuttle({required this.animation, required this.queryText});

  final Animation<double> animation;
  final String? queryText;

  @override
  State<_SearchShuttle> createState() => _SearchShuttleState();
}

class _SearchShuttleState extends State<_SearchShuttle> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.queryText ?? "");
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Widget _buildMorphIcon(double t, Color iconColor) {
    final progress = Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));

    if (progress < 0.5) {
      final p = progress / 0.5;
      final angle = -p * (math.pi / 2);
      final scale = 1.0 - (p * 0.4);
      final opacity = (1.0 - p).clamp(0.0, 1.0);

      return Transform.scale(
        scale: scale,
        child: Transform.rotate(
          angle: angle,
          child: Opacity(
            opacity: opacity,
            child: Icon(Icons.search, color: iconColor),
          ),
        ),
      );
    } else {
      final p = (progress - 0.5) / 0.5;
      final angle = (1.0 - p) * (math.pi / 2);
      final scale = 0.6 + (p * 0.4);
      final opacity = p.clamp(0.0, 1.0);

      return Transform.scale(
        scale: scale,
        child: Transform.rotate(
          angle: angle,
          child: Opacity(
            opacity: opacity,
            child: Icon(Icons.arrow_back, color: iconColor),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface;
    final hintColor = theme.colorScheme.onSurfaceVariant;
    final textColor = theme.colorScheme.onSurface;

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final double t = widget.animation.value.clamp(0.0, 1.0);
        final double hintOpacity = t <= 0.3
            ? (1.0 - (t / 0.3)).clamp(0.0, 1.0)
            : 0.0;
        final double morphProgress = t <= 0.3
            ? 0.0
            : ((t - 0.3) / 0.7).clamp(0.0, 1.0);
        final double textOpacity = t <= 0.3
            ? 0.0
            : ((t - 0.3) / 0.7).clamp(0.0, 1.0);

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SearchBar(
                leading: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: _buildMorphIcon(morphProgress, iconColor),
                  ),
                ),
                hintText: "Search...",
                hintStyle: WidgetStatePropertyAll(
                  theme.textTheme.bodyLarge?.copyWith(
                    color: hintColor.withValues(alpha: hintOpacity),
                  ),
                ),
                backgroundColor: WidgetStatePropertyAll(
                  theme.colorScheme.onInverseSurface,
                ),
                readOnly: true,
              ),
              if (widget.queryText != null && widget.queryText!.isNotEmpty)
                SearchBar(
                  leading: const SizedBox(width: 48, height: 48),
                  controller: _queryController,
                  hintText: "",
                  textStyle: WidgetStatePropertyAll(
                    theme.textTheme.bodyLarge?.copyWith(
                      color: textColor.withValues(alpha: textOpacity),
                    ),
                  ),
                  backgroundColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  shadowColor: const WidgetStatePropertyAll(Colors.transparent),
                  surfaceTintColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  elevation: const WidgetStatePropertyAll(0),
                  readOnly: true,
                ),
            ],
          ),
        );
      },
    );
  }
}

class SearchSegment extends StatelessWidget {
  const SearchSegment({
    super.key,
    this.searchText,
    required this.isAnime,
    this.isSearchPage = false,
  });

  final String? searchText;
  final bool isAnime;
  final bool isSearchPage;

  Widget _buildFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    String? queryText = searchText;
    if (queryText == null || queryText.isEmpty) {
      final toHero = toHeroContext.widget;
      if (toHero is Hero && toHero.child is SearchBar) {
        queryText = (toHero.child as SearchBar).controller?.text;
      }
    }
    if (flightDirection == HeroFlightDirection.pop) {
      final fromHero = fromHeroContext.widget;
      if (fromHero is Hero && fromHero.child is SearchBar) {
        queryText = (fromHero.child as SearchBar).controller?.text;
      }
    }

    return _SearchShuttle(animation: animation, queryText: queryText);
  }

  Widget _buildLeading(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: isSearchPage
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : const Center(child: Icon(Icons.search)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateProvider>(context);
    final isFilterActive = isAnime
        ? provider.isAnimeFilterActive
        : provider.isMangaFilterActive;

    return Container(
      margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
      child: Row(
        children: [
          Expanded(
            child: Hero(
              tag: 'search_bar_${isAnime ? "anime" : "manga"}',
              flightShuttleBuilder: _buildFlightShuttle,
              child: SearchBar(
                leading: _buildLeading(context),
                hintText: isSearchPage ? "" : "Search...",
                backgroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.onInverseSurface,
                ),
                controller: TextEditingController(text: searchText ?? ""),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    final provider = Provider.of<StateProvider>(
                      context,
                      listen: false,
                    );
                    if (isAnime) {
                      provider.animeSearchQuery = value;
                    } else {
                      provider.mangaSearchQuery = value;
                    }
                    final filters = isAnime
                        ? provider.currentAnimeFilters
                        : provider.currentMangaFilters;

                    final route = PageRouteBuilder(
                      transitionDuration: isSearchPage
                          ? Duration.zero
                          : const Duration(milliseconds: 350),
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return SearchPage(
                          isAnime: isAnime,
                          query: value,
                          genres:
                              (filters["selectedGenres"] as Set)
                                  .toList()
                                  .isNotEmpty
                              ? (filters["selectedGenres"] as Set).toList()
                              : null,
                          tags:
                              (filters["selectedTags"] as Set)
                                  .toList()
                                  .isNotEmpty
                              ? (filters["selectedTags"] as Set).toList()
                              : null,
                          genresNotIn:
                              (filters["excludedGenres"] as Set)
                                  .toList()
                                  .isNotEmpty
                              ? (filters["excludedGenres"] as Set).toList()
                              : null,
                          tagsNotIn:
                              (filters["excludedTags"] as Set)
                                  .toList()
                                  .isNotEmpty
                              ? (filters["excludedTags"] as Set).toList()
                              : null,
                          countryOfOrigin: filters["countryOfOrigin"] != ""
                              ? filters["countryOfOrigin"]
                              : null,
                          releaseYear: filters["releaseYear"],
                          season: isAnime && filters["season"] != ""
                              ? filters["season"]
                              : null,
                          format: filters["format"] != ""
                              ? filters["format"]
                              : null,
                          airingStatus: filters["airingStatus"] != ""
                              ? filters["airingStatus"]
                              : null,
                          sourceMaterial: filters["sourceMaterial"] != ""
                              ? filters["sourceMaterial"]
                              : null,
                          sortBy: filters["sortBy"],
                        );
                      },
                      transitionsBuilder: isSearchPage
                          ? (context, animation, secondaryAnimation, child) =>
                              child
                          : (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                    );

                    if (!Navigator.of(context).canPop()) {
                      Navigator.of(context).push(route);
                    } else {
                      Navigator.of(context).pushReplacement(route);
                    }
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: FilledButton(
              style: ButtonStyle(
                elevation: const WidgetStatePropertyAll(6),
                backgroundColor: WidgetStatePropertyAll(
                  isFilterActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onInverseSurface,
                ),
                foregroundColor: WidgetStatePropertyAll(
                  isFilterActive
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
                fixedSize: const WidgetStatePropertyAll(Size(80, 56)),
                overlayColor: WidgetStatePropertyAll(
                  isFilterActive
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) {
                    return FilterSheet(
                      maxYear: DateTime.now().year + 1,
                      isAnime: isAnime,
                    );
                  },
                );
              },
              child: const Icon(Icons.tune, size: 27),
            ),
          ),
        ],
      ),
    );
  }
}
