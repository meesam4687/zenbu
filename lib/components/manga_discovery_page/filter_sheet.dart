import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/components/global/tags_genres_list.dart';
import 'package:zenbu/pages/manga_search_page.dart';
import 'package:zenbu/state_provider.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key, required this.maxYear});

  final int maxYear;
  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

late Set<String> selectedGenres;
late Set<String> selectedtags;
late int? releaseYear;
late String countryOfOrigin;
late String season;
late String format;
late String airingStatus;
late String sourceMaterial;

List<String> yearOptions(int maxYear) {
  if (maxYear < 1940) return <String>[];
  return List<String>.generate(
    maxYear - 1939,
    (index) => (maxYear - index).toString(),
  );
}

class _FilterSheetState extends State<FilterSheet> {
  @override
  void initState() {
    super.initState();
    selectedGenres = Provider.of<StateProvider>(
      context,
      listen: false,
    ).currentMangaFilters["selectedGenres"];
    selectedtags = Provider.of<StateProvider>(
      context,
      listen: false,
    ).currentMangaFilters["selectedTags"];
    countryOfOrigin = Provider.of<StateProvider>(
      context,
      listen: false,
    ).currentMangaFilters["countryOfOrigin"];
    releaseYear = Provider.of<StateProvider>(
      context,
      listen: false,
    ).currentMangaFilters["releaseYear"];
    format = Provider.of<StateProvider>(
      context,
      listen: false,
    ).currentMangaFilters["format"];
    airingStatus = Provider.of<StateProvider>(
      context,
      listen: false,
    ).currentMangaFilters["airingStatus"];
    sourceMaterial = Provider.of<StateProvider>(
      context,
      listen: false,
    ).currentMangaFilters["sourceMaterial"];
    releaseYearController = TextEditingController();
    if (releaseYear != null) {
      releaseYearController.text = releaseYear.toString();
    }
  }

  late final TextEditingController releaseYearController;

  @override
  void dispose() {
    releaseYearController.dispose();
    super.dispose();
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
          height: 600,
          child: Column(
            children: [
              Padding(padding: EdgeInsetsGeometry.all(10)),
              Container(
                margin: EdgeInsets.all(15),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Genre",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(padding: EdgeInsetsGeometry.all(6)),
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
                    Padding(padding: EdgeInsetsGeometry.all(6)),
                    Text(
                      "Tags",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(padding: EdgeInsetsGeometry.all(6)),
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
                              selected: selectedtags.contains(tag),
                              onSelected: (selected) {
                                setState(() {
                                  selected
                                      ? selectedtags.add(tag)
                                      : selectedtags.remove(tag);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(padding: EdgeInsetsGeometry.all(6)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Release Year",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(padding: EdgeInsetsGeometry.all(5)),
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
                                      hint: Text("Select year"),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Country of Origin",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(padding: EdgeInsetsGeometry.all(5)),
                            DropdownMenu(
                              width: MediaQuery.of(context).size.width * 0.44,
                              hintText:
                                  Provider.of<StateProvider>(
                                        context,
                                        listen: false,
                                      ).currentMangaFilters["countryOfOrigin"] !=
                                      ""
                                  ? Provider.of<StateProvider>(
                                      context,
                                      listen: false,
                                    ).currentMangaFilters["countryOfOrigin"]
                                  : "Any",
                              dropdownMenuEntries: [
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
                    Padding(padding: EdgeInsetsGeometry.all(6)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Format",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(padding: EdgeInsetsGeometry.all(5)),
                            DropdownMenu(
                              width: MediaQuery.of(context).size.width * 0.44,
                              hintText:
                                  Provider.of<StateProvider>(
                                        context,
                                        listen: false,
                                      ).currentMangaFilters["format"] !=
                                      ""
                                  ? Provider.of<StateProvider>(
                                      context,
                                      listen: false,
                                    ).currentMangaFilters["format"]
                                  : "Any",
                              dropdownMenuEntries: [
                                DropdownMenuEntry(
                                  value: "MANGA",
                                  label: "Manga",
                                ),
                                DropdownMenuEntry(
                                  value: "NOVEL",
                                  label: "Novel",
                                ),
                                DropdownMenuEntry(
                                  value: "ONE_SHOT",
                                  label: "One Shot",
                                ),
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
                              "Status",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(padding: EdgeInsetsGeometry.all(5)),
                            DropdownMenu(
                              width: MediaQuery.of(context).size.width * 0.44,
                              hintText:
                                  Provider.of<StateProvider>(
                                        context,
                                        listen: false,
                                      ).currentMangaFilters["airingStatus"] !=
                                      ""
                                  ? Provider.of<StateProvider>(
                                      context,
                                      listen: false,
                                    ).currentMangaFilters["airingStatus"]
                                  : "Any",
                              dropdownMenuEntries: [
                                DropdownMenuEntry(
                                  value: "RELEASING",
                                  label: "Releasing",
                                ),
                                DropdownMenuEntry(
                                  value: "FINISHED",
                                  label: "Finished",
                                ),
                                DropdownMenuEntry(
                                  value: "NOT_YET_RELEASED",
                                  label: "Not released yet",
                                ),
                                DropdownMenuEntry(
                                  value: "CANCELLED",
                                  label: "Cancelled",
                                ),
                                DropdownMenuEntry(
                                  value: "HIATUS",
                                  label: "Hiatus",
                                ),
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
                    Padding(padding: EdgeInsetsGeometry.all(6)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Source Material",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(padding: EdgeInsetsGeometry.all(5)),
                            DropdownMenu(
                              width: MediaQuery.of(context).size.width * 0.44,
                              hintText:
                                  Provider.of<StateProvider>(
                                        context,
                                        listen: false,
                                      ).currentMangaFilters["sourceMaterial"] !=
                                      ""
                                  ? Provider.of<StateProvider>(
                                      context,
                                      listen: false,
                                    ).currentMangaFilters["sourceMaterial"]
                                  : "Any",
                              dropdownMenuEntries: [
                                DropdownMenuEntry(
                                  value: "ORIGINAL",
                                  label: "Original",
                                ),
                                DropdownMenuEntry(
                                  value: "MANGA",
                                  label: "Manga",
                                ),
                                DropdownMenuEntry(
                                  value: "LIGHT_NOVEL",
                                  label: "Light Novel",
                                ),
                                DropdownMenuEntry(
                                  value: "VISUAL_NOVEL",
                                  label: "Visual Novel",
                                ),
                                DropdownMenuEntry(
                                  value: "VIDEO_GAME",
                                  label: "Video Game",
                                ),
                                DropdownMenuEntry(
                                  value: "OTHER",
                                  label: "Other",
                                ),
                                DropdownMenuEntry(
                                  value: "NOVEL",
                                  label: "Novel",
                                ),
                                DropdownMenuEntry(
                                  value: "DOUJINSHI",
                                  label: "Doujinshi",
                                ),
                                DropdownMenuEntry(
                                  value: "ANIME",
                                  label: "Anime",
                                ),
                                DropdownMenuEntry(
                                  value: "WEB_NOVEL",
                                  label: "Web Novel",
                                ),
                                DropdownMenuEntry(
                                  value: "LIVE_ACTION",
                                  label: "Live Action",
                                ),
                                DropdownMenuEntry(value: "GAME", label: "Game"),
                                DropdownMenuEntry(
                                  value: "COMIC",
                                  label: "Comic",
                                ),
                                DropdownMenuEntry(
                                  value: "MULTIMEDIA_PROJECT",
                                  label: "Multimedia Project",
                                ),
                                DropdownMenuEntry(
                                  value: "PICTURE_BOOK",
                                  label: "Picture Book",
                                ),
                                DropdownMenuEntry(value: "", label: "Any"),
                              ],
                              onSelected: (value) {
                                sourceMaterial = value as String;
                              },
                            ),
                          ],
                        ),
                        Container(
                          height: 100,
                          width: MediaQuery.of(context).size.width * 0.44,
                          alignment: AlignmentGeometry.bottomEnd,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(180, 56),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                            onPressed: () {
                              releaseYear = releaseYearController.text != ""
                                  ? int.parse(releaseYearController.text)
                                  : null;
                              Provider.of<StateProvider>(
                                context,
                                listen: false,
                              ).currentMangaFilters = {
                                "selectedGenres": selectedGenres,
                                "selectedTags": selectedtags,
                                "releaseYear": releaseYear,
                                "countryOfOrigin": countryOfOrigin,
                                "format": format,
                                "airingStatus": airingStatus,
                                "sourceMaterial": sourceMaterial,
                              };
                              if (mounted) {
                                Navigator.of(context).pop();
                              }
                              (!Navigator.of(context).canPop())
                                  ? Navigator.of(context).push(
                                      PageRouteBuilder(
                                        transitionDuration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) {
                                              Map filters =
                                                  Provider.of<StateProvider>(
                                                    context,
                                                    listen: false,
                                                  ).currentMangaFilters;
                                              return SearchPage(
                                                query: null,
                                                genres:
                                                    (filters["selectedGenres"]
                                                            as Set)
                                                        .toList()
                                                        .isNotEmpty
                                                    ? (filters["selectedGenres"]
                                                              as Set)
                                                          .toList()
                                                    : null,
                                                tags:
                                                    (filters["selectedTags"]
                                                            as Set)
                                                        .toList()
                                                        .isNotEmpty
                                                    ? (filters["selectedTags"]
                                                              as Set)
                                                          .toList()
                                                    : null,
                                                countryOfOrigin:
                                                    filters["countryOfOrigin"] !=
                                                        ""
                                                    ? filters["countryOfOrigin"]
                                                    : null,
                                                releaseYear:
                                                    filters["releaseYear"],
                                                format: filters["format"] != ""
                                                    ? filters["format"]
                                                    : null,
                                                airingStatus:
                                                    filters["airingStatus"] !=
                                                        ""
                                                    ? filters["airingStatus"]
                                                    : null,
                                                sourceMaterial:
                                                    filters["sourceMaterial"] !=
                                                        ""
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
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) {
                                              Map filters =
                                                  Provider.of<StateProvider>(
                                                    context,
                                                    listen: false,
                                                  ).currentMangaFilters;
                                              return SearchPage(
                                                query: null,
                                                genres:
                                                    (filters["selectedGenres"]
                                                            as Set)
                                                        .toList()
                                                        .isNotEmpty
                                                    ? (filters["selectedGenres"]
                                                              as Set)
                                                          .toList()
                                                    : null,
                                                tags:
                                                    (filters["selectedTags"]
                                                            as Set)
                                                        .toList()
                                                        .isNotEmpty
                                                    ? (filters["selectedTags"]
                                                              as Set)
                                                          .toList()
                                                    : null,
                                                countryOfOrigin:
                                                    filters["countryOfOrigin"] !=
                                                        ""
                                                    ? filters["countryOfOrigin"]
                                                    : null,
                                                releaseYear:
                                                    filters["releaseYear"],
                                                format: filters["format"] != ""
                                                    ? filters["format"]
                                                    : null,
                                                airingStatus:
                                                    filters["airingStatus"] !=
                                                        ""
                                                    ? filters["airingStatus"]
                                                    : null,
                                                sourceMaterial:
                                                    filters["sourceMaterial"] !=
                                                        ""
                                                    ? filters["sourceMaterial"]
                                                    : null,
                                              );
                                            },
                                      ),
                                    );
                            },
                            child: Text("Apply Filters"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
