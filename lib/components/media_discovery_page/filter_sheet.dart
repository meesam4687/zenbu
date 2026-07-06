import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/components/global/tags_genres_list.dart';
import 'package:zenbu/pages/media_search_page.dart';
import 'package:zenbu/state_provider.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key, required this.maxYear, required this.isAnime});

  final int maxYear;
  final bool isAnime;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late Set<String> selectedGenres;
  late Set<String> selectedTags;
  late Set<String> excludedGenres;
  late Set<String> excludedTags;
  late int? releaseYear;
  late String countryOfOrigin;
  late String season;
  late String format;
  late String airingStatus;
  late String sourceMaterial;
  late String sortBy;
  late final TextEditingController releaseYearController;

  void _onTagTap(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        excludedTags.remove(tag);
        selectedTags.add(tag);
      }
    });
  }

  void _onTagLongPress(String tag) {
    HapticFeedback.vibrate();
    setState(() {
      if (excludedTags.contains(tag)) {
        excludedTags.remove(tag);
      } else {
        selectedTags.remove(tag);
        excludedTags.add(tag);
      }
    });
  }

  void _onGenreTap(String genre) {
    setState(() {
      if (selectedGenres.contains(genre)) {
        selectedGenres.remove(genre);
      } else {
        excludedGenres.remove(genre);
        selectedGenres.add(genre);
      }
    });
  }

  void _onGenreLongPress(String genre) {
    HapticFeedback.vibrate();
    setState(() {
      if (excludedGenres.contains(genre)) {
        excludedGenres.remove(genre);
      } else {
        selectedGenres.remove(genre);
        excludedGenres.add(genre);
      }
    });
  }

  void _showExpandedTags() {
    String query = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredTags = tags
                .where((tag) => tag.toLowerCase().contains(query.toLowerCase()))
                .toList();
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "All Tags",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SearchBar(
                        hintText: "Search tags...",
                        leading: Container(
                          margin: const EdgeInsets.only(left: 5, right: 5),
                          child: const Icon(Icons.search),
                        ),
                        backgroundColor: WidgetStatePropertyAll(
                          Theme.of(context).colorScheme.onInverseSurface,
                        ),
                        elevation: const WidgetStatePropertyAll(0),
                        onChanged: (val) {
                          setModalState(() {
                            query = val;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: GridView.builder(
                          controller: scrollController,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 3,
                              ),
                          itemCount: filteredTags.length,
                          itemBuilder: (context, index) {
                            final tag = filteredTags[index];
                            final isIncluded = selectedTags.contains(tag);
                            final isExcluded = excludedTags.contains(tag);

                            return GestureDetector(
                              onLongPress: () {
                                _onTagLongPress(tag);
                                setModalState(() {});
                              },
                              child: FilterChip(
                                label: Text(
                                  tag,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                selected: isIncluded || isExcluded,
                                showCheckmark: isIncluded,
                                avatar: isExcluded
                                    ? const Icon(Icons.remove, size: 16)
                                    : null,
                                onSelected: (selected) {
                                  _onTagTap(tag);
                                  setModalState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  String getSortByLabel(String value) {
    switch (value) {
      case "TITLE_ROMAJI":
        return "Title (A-Z)";
      case "POPULARITY_DESC":
        return "Popularity";
      case "SCORE_DESC":
        return "Score";
      case "TRENDING_DESC":
        return "Trending";
      case "FAVOURITES_DESC":
        return "Favourites";
      case "ID_DESC":
        return "Date Added";
      case "START_DATE_DESC":
        return "Release Date";
      default:
        return "Popularity";
    }
  }

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<StateProvider>(context, listen: false);
    final filters = widget.isAnime
        ? provider.currentAnimeFilters
        : provider.currentMangaFilters;

    selectedGenres = filters["selectedGenres"] as Set<String>;
    selectedTags = filters["selectedTags"] as Set<String>;
    excludedGenres = (filters["excludedGenres"] as Set<String>?) ?? <String>{};
    excludedTags = (filters["excludedTags"] as Set<String>?) ?? <String>{};
    countryOfOrigin = filters["countryOfOrigin"] as String;
    releaseYear = filters["releaseYear"] as int?;
    season = widget.isAnime ? (filters["season"] as String) : "";
    format = filters["format"] as String;
    airingStatus = filters["airingStatus"] as String;
    sourceMaterial = filters["sourceMaterial"] as String;
    sortBy = filters["sortBy"] as String? ?? "POPULARITY_DESC";

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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              height: 670,
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
                              final isIncluded = selectedGenres.contains(genre);
                              final isExcluded = excludedGenres.contains(genre);
                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  right: 4,
                                ),
                                child: GestureDetector(
                                  onLongPress: () => _onGenreLongPress(genre),
                                  child: FilterChip(
                                    label: Text(genre),
                                    selected: isIncluded || isExcluded,
                                    showCheckmark: isIncluded,
                                    avatar: isExcluded
                                        ? const Icon(Icons.remove, size: 16)
                                        : null,
                                    onSelected: (selected) =>
                                        _onGenreTap(genre),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const Padding(padding: EdgeInsets.all(6)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Tags",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _showExpandedTags,
                              icon: const Icon(Icons.grid_view),
                              label: const Text("Expand"),
                            ),
                          ],
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
                              final isIncluded = selectedTags.contains(tag);
                              final isExcluded = excludedTags.contains(tag);
                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  right: 4,
                                ),
                                child: GestureDetector(
                                  onLongPress: () => _onTagLongPress(tag),
                                  child: FilterChip(
                                    label: Text(tag),
                                    selected: isIncluded || isExcluded,
                                    showCheckmark: isIncluded,
                                    avatar: isExcluded
                                        ? const Icon(Icons.remove, size: 16)
                                        : null,
                                    onSelected: (selected) => _onTagTap(tag),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const Padding(padding: EdgeInsets.all(6)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
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
                                  LayoutBuilder(
                                    builder: (context, c) => TypeAheadField(
                                      suggestionsCallback: (pattern) {
                                        return yearArray
                                            .where(
                                              (item) =>
                                                  item.toLowerCase().contains(
                                                    pattern.toLowerCase(),
                                                  ),
                                            )
                                            .toList();
                                      },
                                      itemBuilder: (context, suggestion) {
                                        return ListTile(
                                          title: Text(suggestion),
                                        );
                                      },
                                      builder:
                                          (context, controller, focusNode) {
                                            return TextField(
                                              keyboardType:
                                                  TextInputType.number,
                                              controller: releaseYearController,
                                              focusNode: focusNode,
                                              decoration: InputDecoration(
                                                hintText: releaseYear != null
                                                    ? releaseYear.toString()
                                                    : "Select year",
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
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
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.isAnime ? "Season" : "Origin",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Padding(padding: EdgeInsets.all(5)),
                                  if (widget.isAnime)
                                    LayoutBuilder(
                                      builder: (context, c) => DropdownMenu(
                                        width: c.maxWidth,
                                        hintText: season != "" ? season : "Any",
                                        dropdownMenuEntries: const [
                                          DropdownMenuEntry(
                                            value: "SPRING",
                                            label: "Spring",
                                          ),
                                          DropdownMenuEntry(
                                            value: "SUMMER",
                                            label: "Summer",
                                          ),
                                          DropdownMenuEntry(
                                            value: "FALL",
                                            label: "Fall",
                                          ),
                                          DropdownMenuEntry(
                                            value: "WINTER",
                                            label: "Winter",
                                          ),
                                          DropdownMenuEntry(
                                            value: "",
                                            label: "Any",
                                          ),
                                        ],
                                        onSelected: (value) {
                                          season = value as String;
                                        },
                                      ),
                                    )
                                  else
                                    LayoutBuilder(
                                      builder: (context, c) => DropdownMenu(
                                        width: c.maxWidth,
                                        hintText: countryOfOrigin != ""
                                            ? countryOfOrigin
                                            : "Any",
                                        dropdownMenuEntries: const [
                                          DropdownMenuEntry(
                                            value: "CN",
                                            label: "China",
                                          ),
                                          DropdownMenuEntry(
                                            value: "JP",
                                            label: "Japan",
                                          ),
                                          DropdownMenuEntry(
                                            value: "KR",
                                            label: "Korea",
                                          ),
                                          DropdownMenuEntry(
                                            value: "",
                                            label: "Any",
                                          ),
                                        ],
                                        onSelected: (value) {
                                          countryOfOrigin = value as String;
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.all(6)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
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
                                  LayoutBuilder(
                                    builder: (context, c) => DropdownMenu(
                                      width: c.maxWidth,
                                      hintText: format != "" ? format : "Any",
                                      dropdownMenuEntries: widget.isAnime
                                          ? const [
                                              DropdownMenuEntry(
                                                value: "TV",
                                                label: "TV",
                                              ),
                                              DropdownMenuEntry(
                                                value: "TV_SHORT",
                                                label: "TV Short",
                                              ),
                                              DropdownMenuEntry(
                                                value: "MOVIE",
                                                label: "Movie",
                                              ),
                                              DropdownMenuEntry(
                                                value: "SPECIAL",
                                                label: "Special",
                                              ),
                                              DropdownMenuEntry(
                                                value: "OVA",
                                                label: "OVA",
                                              ),
                                              DropdownMenuEntry(
                                                value: "ONA",
                                                label: "ONA",
                                              ),
                                              DropdownMenuEntry(
                                                value: "MUSIC",
                                                label: "Music",
                                              ),
                                              DropdownMenuEntry(
                                                value: "",
                                                label: "Any",
                                              ),
                                            ]
                                          : const [
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
                                              DropdownMenuEntry(
                                                value: "",
                                                label: "Any",
                                              ),
                                            ],
                                      onSelected: (value) {
                                        format = value as String;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.isAnime ? "Airing Status" : "Status",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Padding(padding: EdgeInsets.all(5)),
                                  LayoutBuilder(
                                    builder: (context, c) => DropdownMenu(
                                      width: c.maxWidth,
                                      hintText: airingStatus != ""
                                          ? airingStatus
                                          : "Any",
                                      dropdownMenuEntries: const [
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
                                        DropdownMenuEntry(
                                          value: "",
                                          label: "Any",
                                        ),
                                      ],
                                      onSelected: (value) {
                                        airingStatus = value as String;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.all(6)),
                        if (widget.isAnime)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Source",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Padding(padding: EdgeInsets.all(5)),
                                    LayoutBuilder(
                                      builder: (context, c) => DropdownMenu(
                                        width: c.maxWidth,
                                        hintText: sourceMaterial != ""
                                            ? sourceMaterial
                                            : "Any",
                                        dropdownMenuEntries: const [
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
                                          DropdownMenuEntry(
                                            value: "GAME",
                                            label: "Game",
                                          ),
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
                                          DropdownMenuEntry(
                                            value: "",
                                            label: "Any",
                                          ),
                                        ],
                                        onSelected: (value) {
                                          setState(() {
                                            sourceMaterial = value as String;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Origin",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Padding(padding: EdgeInsets.all(5)),
                                    LayoutBuilder(
                                      builder: (context, c) => DropdownMenu(
                                        width: c.maxWidth,
                                        hintText: countryOfOrigin != ""
                                            ? countryOfOrigin
                                            : "Any",
                                        dropdownMenuEntries: const [
                                          DropdownMenuEntry(
                                            value: "CN",
                                            label: "China",
                                          ),
                                          DropdownMenuEntry(
                                            value: "JP",
                                            label: "Japan",
                                          ),
                                          DropdownMenuEntry(
                                            value: "KR",
                                            label: "Korea",
                                          ),
                                          DropdownMenuEntry(
                                            value: "",
                                            label: "Any",
                                          ),
                                        ],
                                        onSelected: (value) {
                                          setState(() {
                                            countryOfOrigin = value as String;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Sort",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Padding(padding: EdgeInsets.all(5)),
                                    LayoutBuilder(
                                      builder: (context, c) => DropdownMenu(
                                        width: c.maxWidth,
                                        hintText: getSortByLabel(sortBy),
                                        dropdownMenuEntries: const [
                                          DropdownMenuEntry(
                                            value: "TITLE_ROMAJI",
                                            label: "Title (A-Z)",
                                          ),
                                          DropdownMenuEntry(
                                            value: "POPULARITY_DESC",
                                            label: "Popularity",
                                          ),
                                          DropdownMenuEntry(
                                            value: "SCORE_DESC",
                                            label: "Score",
                                          ),
                                          DropdownMenuEntry(
                                            value: "TRENDING_DESC",
                                            label: "Trending",
                                          ),
                                          DropdownMenuEntry(
                                            value: "FAVOURITES_DESC",
                                            label: "Favourites",
                                          ),
                                          DropdownMenuEntry(
                                            value: "ID_DESC",
                                            label: "Date Added",
                                          ),
                                          DropdownMenuEntry(
                                            value: "START_DATE_DESC",
                                            label: "Release Date",
                                          ),
                                        ],
                                        onSelected: (value) {
                                          setState(() {
                                            sortBy = value as String;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Source Material",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Padding(padding: EdgeInsets.all(5)),
                                    LayoutBuilder(
                                      builder: (context, c) => DropdownMenu(
                                        width: c.maxWidth,
                                        hintText: sourceMaterial != ""
                                            ? sourceMaterial
                                            : "Any",
                                        dropdownMenuEntries: const [
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
                                          DropdownMenuEntry(
                                            value: "GAME",
                                            label: "Game",
                                          ),
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
                                          DropdownMenuEntry(
                                            value: "",
                                            label: "Any",
                                          ),
                                        ],
                                        onSelected: (value) {
                                          setState(() {
                                            sourceMaterial = value as String;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Sort By",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Padding(padding: EdgeInsets.all(5)),
                                    LayoutBuilder(
                                      builder: (context, c) => DropdownMenu(
                                        width: c.maxWidth,
                                        hintText: getSortByLabel(sortBy),
                                        dropdownMenuEntries: const [
                                          DropdownMenuEntry(
                                            value: "TITLE_ROMAJI",
                                            label: "Title (A-Z)",
                                          ),
                                          DropdownMenuEntry(
                                            value: "POPULARITY_DESC",
                                            label: "Popularity",
                                          ),
                                          DropdownMenuEntry(
                                            value: "SCORE_DESC",
                                            label: "Score",
                                          ),
                                          DropdownMenuEntry(
                                            value: "TRENDING_DESC",
                                            label: "Trending",
                                          ),
                                          DropdownMenuEntry(
                                            value: "FAVOURITES_DESC",
                                            label: "Favourites",
                                          ),
                                          DropdownMenuEntry(
                                            value: "ID_DESC",
                                            label: "Date Added",
                                          ),
                                          DropdownMenuEntry(
                                            value: "START_DATE_DESC",
                                            label: "Release Date",
                                          ),
                                        ],
                                        onSelected: (value) {
                                          setState(() {
                                            sortBy = value as String;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const Padding(padding: EdgeInsets.all(10)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(120, 56),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                              onPressed: () {
                                _clearFilters();
                                _applyFilters();
                              },
                              child: const Text("Clear Filters"),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
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
      },
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
      "excludedGenres": excludedGenres,
      "excludedTags": excludedTags,
      "releaseYear": releaseYear,
      "countryOfOrigin": countryOfOrigin,
      "format": format,
      "airingStatus": airingStatus,
      "sourceMaterial": sourceMaterial,
      "sortBy": sortBy,
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

    final targetFilters = widget.isAnime
        ? provider.currentAnimeFilters
        : provider.currentMangaFilters;
    final query = widget.isAnime
        ? provider.animeSearchQuery
        : provider.mangaSearchQuery;

    final route = PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SearchPage(
          isAnime: widget.isAnime,
          query: query.isNotEmpty ? query : null,
          genres: (targetFilters["selectedGenres"] as Set).toList().isNotEmpty
              ? (targetFilters["selectedGenres"] as Set).toList()
              : null,
          tags: (targetFilters["selectedTags"] as Set).toList().isNotEmpty
              ? (targetFilters["selectedTags"] as Set).toList()
              : null,
          genresNotIn:
              (targetFilters["excludedGenres"] as Set).toList().isNotEmpty
              ? (targetFilters["excludedGenres"] as Set).toList()
              : null,
          tagsNotIn: (targetFilters["excludedTags"] as Set).toList().isNotEmpty
              ? (targetFilters["excludedTags"] as Set).toList()
              : null,
          countryOfOrigin: targetFilters["countryOfOrigin"] != ""
              ? targetFilters["countryOfOrigin"]
              : null,
          releaseYear: targetFilters["releaseYear"],
          season: widget.isAnime && targetFilters["season"] != ""
              ? targetFilters["season"]
              : null,
          format: targetFilters["format"] != ""
              ? targetFilters["format"]
              : null,
          airingStatus: targetFilters["airingStatus"] != ""
              ? targetFilters["airingStatus"]
              : null,
          sourceMaterial: targetFilters["sourceMaterial"] != ""
              ? targetFilters["sourceMaterial"]
              : null,
          sortBy: targetFilters["sortBy"],
        );
      },
    );

    if (!Navigator.of(context).canPop()) {
      Navigator.of(context).push(route);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }

  void _clearFilters() {
    setState(() {
      selectedGenres.clear();
      selectedTags.clear();
      excludedGenres.clear();
      excludedTags.clear();
      releaseYear = null;
      releaseYearController.clear();
      countryOfOrigin = "";
      season = "";
      format = "";
      airingStatus = "";
      sourceMaterial = "";
      sortBy = "POPULARITY_DESC";
    });
  }
}
