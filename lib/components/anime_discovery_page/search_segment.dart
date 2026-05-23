import 'package:provider/provider.dart';
import 'package:zenbu/components/anime_discovery_page/filter_sheet.dart';
import 'package:zenbu/pages/anime_search_page.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/state_provider.dart';

class SearchSegment extends StatelessWidget {
  const SearchSegment({super.key, this.searchText});
  final String? searchText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 50, left: 12, right: 12),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              leading: Container(
                margin: EdgeInsets.only(left: 5, right: 5),
                child: Icon(Icons.search),
              ),
              hintText: "Search...",
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.onInverseSurface,
              ),
              controller: TextEditingController(text: (searchText) ?? ""),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  (!Navigator.of(context).canPop())
                      ? Navigator.of(context).push(
                          PageRouteBuilder(
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
                                  Map filters = Provider.of<StateProvider>(
                                    context,
                                    listen: false,
                                  ).currentAnimeFilters;
                                  return SearchPage(
                                    query: value,
                                    genres:
                                        (filters["selectedGenres"] as Set)
                                            .toList()
                                            .isNotEmpty
                                        ? (filters["selectedGenres"] as Set)
                                              .toList()
                                        : null,
                                    tags:
                                        (filters["selectedTags"] as Set)
                                            .toList()
                                            .isNotEmpty
                                        ? (filters["selectedTags"] as Set)
                                              .toList()
                                        : null,
                                    countryOfOrigin:
                                        filters["countryOfOrigin"] != ""
                                        ? filters["countryOfOrigin"]
                                        : null,
                                    releaseYear: filters["releaseYear"],
                                    season: filters["season"] != ""
                                        ? filters["season"]
                                        : null,
                                    format: filters["format"] != ""
                                        ? filters["format"]
                                        : null,
                                    airingStatus: filters["airingStatus"] != ""
                                        ? filters["airingStatus"]
                                        : null,
                                    sourceMaterial:
                                        filters["sourceMaterial"] != ""
                                        ? filters["sourceMaterial"]
                                        : null,
                                  );
                                },
                          ),
                        )
                      : Navigator.of(context).pushReplacement(
                          PageRouteBuilder(
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
                                  Map filters = Provider.of<StateProvider>(
                                    context,
                                    listen: false,
                                  ).currentAnimeFilters;
                                  return SearchPage(
                                    query: value,
                                    genres:
                                        (filters["selectedGenres"] as Set)
                                            .toList()
                                            .isNotEmpty
                                        ? (filters["selectedGenres"] as Set)
                                              .toList()
                                        : null,
                                    tags:
                                        (filters["selectedTags"] as Set)
                                            .toList()
                                            .isNotEmpty
                                        ? (filters["selectedTags"] as Set)
                                              .toList()
                                        : null,
                                    countryOfOrigin:
                                        filters["countryOfOrigin"] != ""
                                        ? filters["countryOfOrigin"]
                                        : null,
                                    releaseYear: filters["releaseYear"],
                                    season: filters["season"] != ""
                                        ? filters["season"]
                                        : null,
                                    format: filters["format"] != ""
                                        ? filters["format"]
                                        : null,
                                    airingStatus: filters["airingStatus"] != ""
                                        ? filters["airingStatus"]
                                        : null,
                                    sourceMaterial:
                                        filters["sourceMaterial"] != ""
                                        ? filters["sourceMaterial"]
                                        : null,
                                  );
                                },
                          ),
                        );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: FilledButton(
              style: ButtonStyle(
                elevation: WidgetStatePropertyAll(6),
                backgroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.onInverseSurface,
                ),
                foregroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.onSurface,
                ),
                fixedSize: WidgetStatePropertyAll(Size(80, 56)),
                overlayColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return FilterSheet(maxYear: DateTime.now().year + 1);
                  },
                );
              },
              child: Icon(Icons.tune, size: 27),
            ),
          ),
        ],
      ),
    );
  }
}
