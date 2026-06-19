import 'package:provider/provider.dart';
import 'package:zenbu/components/media_discovery_page/filter_sheet.dart';
import 'package:zenbu/pages/media_search_page.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/state_provider.dart';

class SearchSegment extends StatelessWidget {
  const SearchSegment({super.key, this.searchText, required this.isAnime});

  final String? searchText;
  final bool isAnime;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateProvider>(context);
    final isFilterActive = isAnime
        ? provider.isAnimeFilterActive
        : provider.isMangaFilterActive;

    return Container(
      margin: const EdgeInsets.only(top: 50, left: 12, right: 12),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              leading: Container(
                margin: const EdgeInsets.only(left: 5, right: 5),
                child: const Icon(Icons.search),
              ),
              hintText: "Search...",
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
                    transitionDuration: const Duration(milliseconds: 300),
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
                            (filters["selectedTags"] as Set).toList().isNotEmpty
                            ? (filters["selectedTags"] as Set).toList()
                            : null,
                        genresNotIn:
                            (filters["excludedGenres"] as Set)
                                .toList()
                                .isNotEmpty
                            ? (filters["excludedGenres"] as Set).toList()
                            : null,
                        tagsNotIn:
                            (filters["excludedTags"] as Set).toList().isNotEmpty
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
