import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/components/global/tags_genres_list.dart';
import 'package:zenbu/pages/media_search_page.dart';
import 'package:zenbu/state_provider.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.maxYear,
    required this.isAnime,
  });

  final int maxYear;
  final bool isAnime;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late Set<String> selectedGenres;
  late Set<String> selectedTags;
  late int? releaseYear;
  late String countryOfOrigin;
  late String season;
  late String format;
  late String airingStatus;
  late String sourceMaterial;
  late final TextEditingController releaseYearController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<StateProvider>(context, listen: false);
    final filters = widget.isAnime ? provider.currentAnimeFilters : provider.currentMangaFilters;

    selectedGenres = filters["selectedGenres"] as Set<String>;
    selectedTags = filters["selectedTags"] as Set<String>;
    countryOfOrigin = filters["countryOfOrigin"] as String;
    releaseYear = filters["releaseYear"] as int?;
    season = widget.isAnime ? (filters["season"] as String) : "";
    format = filters["format"] as String;
    airingStatus = filters["airingStatus"] as String;
    sourceMaterial = filters["sourceMaterial"] as String;

    releaseYearController = TextEditingController();
    if (releaseYear != null) {
      releaseYearController.text = releaseYear.toString();
    }
  }

  @override
  void dispose() {
    releaseYearController.dispose();
    super.dispose();
  }

  List<String> yearOptions(int maxYear) {
    if (maxYear < 1940) return <String>[];
    return List<String>.generate(
      maxYear - 1939,
      (index) => (maxYear - index).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> yearArray = yearOptions(widget.maxYear);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          height: widget.isAnime ? 670 : 600,
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.all(10)),
              Container(
                margin: const EdgeInsets.all(15),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Genre",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(6)),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: genres.length,
                        itemBuilder: (context, index) {
                          final genre = genres[index];
                          return Padding(
                            padding: const EdgeInsets.only(left: 4, right: 4),
                            child: FilterChip(
                              label: Text(genre),
                              selected: selectedGenres.contains(genre),
                              onSelected: (selected) {
                                setState(() {
                                  selected
                                      ? selectedGenres.add(genre)
                                      : selectedGenres.remove(genre);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(6)),
                    const Text(
                      "Tags",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(6)),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: tags.length,
                        itemBuilder: (context, index) {
                          final tag = tags[index];
                          return Padding(
                            padding: const EdgeInsets.only(left: 4, right: 4),
                            child: FilterChip(
                              label: Text(tag),
                              selected: selectedTags.contains(tag),
                              onSelected: (selected) {
                                setState(() {
                                  selected
                                      ? selectedTags.add(tag)
                                      : selectedTags.remove(tag);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(6)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Release Year",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Padding(padding: EdgeInsets.all(5)),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.44,
                              child: TypeAheadField(
                                suggestionsCallback: (pattern) {
                                  return yearArray
                                      .where(
                                        (item) => item.toLowerCase().contains(
                                              pattern.toLowerCase(),
                                            ),
                                      )
                                      .toList();
                                },
                                itemBuilder: (context, suggestion) {
                                  return ListTile(title: Text(suggestion));
                                },
                                builder: (context, controller, focusNode) {
                                  return TextField(
                                    keyboardType: TextInputType.number,
                                    controller: releaseYearController,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      hintText: releaseYear != null
                                          ? releaseYear.toString()
                                          : "Select year",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  );
                                },
                                onSelected: (suggestion) {
                                  releaseYearController.text = suggestion;
                                },
                              ),
                            ),
                          ],
                        ),
                        if (widget.isAnime)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Season",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Padding(padding: EdgeInsets.all(5)),
                              DropdownMenu(
                                width: MediaQuery.of(context).size.width * 0.44,
                                hintText: season != "" ? season : "Any",
                                dropdownMenuEntries: const [
                                  DropdownMenuEntry(value: "SPRING", label: "Spring"),
                                  DropdownMenuEntry(value: "SUMMER", label: "Summer"),
                                  DropdownMenuEntry(value: "FALL", label: "Fall"),
                                  DropdownMenuEntry(value: "WINTER", label: "Winter"),
                                  DropdownMenuEntry(value: "", label: "Any"),
                                ],
                                onSelected: (value) {
                                  season = value as String;
                                },
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Country of Origin",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Padding(padding: EdgeInsets.all(5)),
                              DropdownMenu(
                                width: MediaQuery.of(context).size.width * 0.44,
                                hintText: countryOfOrigin != "" ? countryOfOrigin : "Any",
                                dropdownMenuEntries: const [
                                  DropdownMenuEntry(value: "CN", label: "China"),
                                  DropdownMenuEntry(value: "JP", label: "Japan"),
                                  DropdownMenuEntry(value: "KR", label: "Korea"),
                                  DropdownMenuEntry(value: "", label: "Any"),
                                ],
                                onSelected: (value) {
                                  countryOfOrigin = value as String;
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                    const Padding(padding: EdgeInsets.all(6)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Format",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Padding(padding: EdgeInsets.all(5)),
                            DropdownMenu(
                              width: MediaQuery.of(context).size.width * 0.44,
                              hintText: format != "" ? format : "Any",
                              dropdownMenuEntries: widget.isAnime
                                  ? const [
                                      DropdownMenuEntry(value: "TV", label: "TV"),
                                      DropdownMenuEntry(value: "TV_SHORT", label: "TV Short"),
                                      DropdownMenuEntry(value: "MOVIE", label: "Movie"),
                                      DropdownMenuEntry(value: "SPECIAL", label: "Special"),
                                      DropdownMenuEntry(value: "OVA", label: "OVA"),
                                      DropdownMenuEntry(value: "ONA", label: "ONA"),
                                      DropdownMenuEntry(value: "MUSIC", label: "Music"),
                                      DropdownMenuEntry(value: "", label: "Any"),
                                    ]
                                  : const [
                                      DropdownMenuEntry(value: "MANGA", label: "Manga"),
                                      DropdownMenuEntry(value: "NOVEL", label: "Novel"),
                                      DropdownMenuEntry(value: "ONE_SHOT", label: "One Shot"),
                                      DropdownMenuEntry(value: "", label: "Any"),
                                    ],
                              onSelected: (value) {
                                format = value as String;
                              },
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.isAnime ? "Airing Status" : "Status",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Padding(padding: EdgeInsets.all(5)),
                            DropdownMenu(
                              width: MediaQuery.of(context).size.width * 0.44,
                              hintText: airingStatus != "" ? airingStatus : "Any",
                              dropdownMenuEntries: const [
                                DropdownMenuEntry(value: "RELEASING", label: "Releasing"),
                                DropdownMenuEntry(value: "FINISHED", label: "Finished"),
                                DropdownMenuEntry(value: "NOT_YET_RELEASED", label: "Not released yet"),
                                DropdownMenuEntry(value: "CANCELLED", label: "Cancelled"),
                                DropdownMenuEntry(value: "HIATUS", label: "Hiatus"),
                                DropdownMenuEntry(value: "", label: "Any"),
                              ],
                              onSelected: (value) {
                                airingStatus = value as String;
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Padding(padding: EdgeInsets.all(6)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Source Material",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Padding(padding: EdgeInsets.all(5)),
                            DropdownMenu(
                              width: MediaQuery.of(context).size.width * 0.44,
                              hintText: sourceMaterial != "" ? sourceMaterial : "Any",
                              dropdownMenuEntries: const [
                                DropdownMenuEntry(value: "ORIGINAL", label: "Original"),
                                DropdownMenuEntry(value: "MANGA", label: "Manga"),
                                DropdownMenuEntry(value: "LIGHT_NOVEL", label: "Light Novel"),
                                DropdownMenuEntry(value: "VISUAL_NOVEL", label: "Visual Novel"),
                                DropdownMenuEntry(value: "VIDEO_GAME", label: "Video Game"),
                                DropdownMenuEntry(value: "OTHER", label: "Other"),
                                DropdownMenuEntry(value: "NOVEL", label: "Novel"),
                                DropdownMenuEntry(value: "DOUJINSHI", label: "Doujinshi"),
                                DropdownMenuEntry(value: "ANIME", label: "Anime"),
                                DropdownMenuEntry(value: "WEB_NOVEL", label: "Web Novel"),
                                DropdownMenuEntry(value: "LIVE_ACTION", label: "Live Action"),
                                DropdownMenuEntry(value: "GAME", label: "Game"),
                                DropdownMenuEntry(value: "COMIC", label: "Comic"),
                                DropdownMenuEntry(value: "MULTIMEDIA_PROJECT", label: "Multimedia Project"),
                                DropdownMenuEntry(value: "PICTURE_BOOK", label: "Picture Book"),
                                DropdownMenuEntry(value: "", label: "Any"),
                              ],
                              onSelected: (value) {
                                sourceMaterial = value as String;
                              },
                            ),
                          ],
                        ),
                        if (widget.isAnime)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Country of Origin",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Padding(padding: EdgeInsets.all(5)),
                              DropdownMenu(
                                width: MediaQuery.of(context).size.width * 0.44,
                                hintText: countryOfOrigin != "" ? countryOfOrigin : "Any",
                                dropdownMenuEntries: const [
                                  DropdownMenuEntry(value: "CN", label: "China"),
                                  DropdownMenuEntry(value: "JP", label: "Japan"),
                                  DropdownMenuEntry(value: "KR", label: "Korea"),
                                  DropdownMenuEntry(value: "", label: "Any"),
                                ],
                                onSelected: (value) {
                                  countryOfOrigin = value as String;
                                },
                              ),
                            ],
                          )
                        else
                          Container(
                            height: 100,
                            width: MediaQuery.of(context).size.width * 0.44,
                            alignment: Alignment.bottomRight,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(180, 56),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                              onPressed: _applyFilters,
                              child: const Text("Apply Filters"),
                            ),
                          ),
                      ],
                    ),
                    if (widget.isAnime) ...[
                      const Padding(padding: EdgeInsets.all(10)),
                      Container(
                        alignment: Alignment.bottomRight,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(180, 56),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          onPressed: _applyFilters,
                          child: const Text("Apply Filters"),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyFilters() {
    releaseYear = releaseYearController.text != ""
        ? int.parse(releaseYearController.text)
        : null;

    final provider = Provider.of<StateProvider>(context, listen: false);
    final filtersMap = {
      "selectedGenres": selectedGenres,
      "selectedTags": selectedTags,
      "releaseYear": releaseYear,
      "countryOfOrigin": countryOfOrigin,
      "format": format,
      "airingStatus": airingStatus,
      "sourceMaterial": sourceMaterial,
      if (widget.isAnime) "season": season,
    };

    if (widget.isAnime) {
      provider.currentAnimeFilters = filtersMap;
    } else {
      provider.currentMangaFilters = filtersMap;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }

    final targetFilters = widget.isAnime ? provider.currentAnimeFilters : provider.currentMangaFilters;

    final route = PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SearchPage(
          isAnime: widget.isAnime,
          query: null,
          genres: (targetFilters["selectedGenres"] as Set).toList().isNotEmpty
              ? (targetFilters["selectedGenres"] as Set).toList()
              : null,
          tags: (targetFilters["selectedTags"] as Set).toList().isNotEmpty
              ? (targetFilters["selectedTags"] as Set).toList()
              : null,
          countryOfOrigin: targetFilters["countryOfOrigin"] != ""
              ? targetFilters["countryOfOrigin"]
              : null,
          releaseYear: targetFilters["releaseYear"],
          season: widget.isAnime && targetFilters["season"] != ""
              ? targetFilters["season"]
              : null,
          format: targetFilters["format"] != "" ? targetFilters["format"] : null,
          airingStatus: targetFilters["airingStatus"] != "" ? targetFilters["airingStatus"] : null,
          sourceMaterial: targetFilters["sourceMaterial"] != "" ? targetFilters["sourceMaterial"] : null,
        );
      },
    );

    if (!Navigator.of(context).canPop()) {
      Navigator.of(context).push(route);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }
}
