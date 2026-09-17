import 'package:flutter/material.dart';
import 'package:zenbu/l10n/l10n_extension.dart';
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
                          Text(
                            context.l10n.allTags,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SearchBar(
                        hintText: context.l10n.searchTags,
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

  String getSortByLabel(String value, BuildContext context) {
    switch (value) {
      case "TITLE_ROMAJI":
        return context.l10n.titleAZ;
      case "POPULARITY_DESC":
        return context.l10n.popularity;
      case "SCORE_DESC":
        return context.l10n.scoreDesc;
      case "TRENDING_DESC":
        return context.l10n.trending;
      case "FAVOURITES_DESC":
        return context.l10n.favorites;
      case "ID_DESC":
        return context.l10n.dateAdded;
      case "START_DATE_DESC":
        return context.l10n.releaseDate;
      default:
        return context.l10n.popularity;
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
            child: SafeArea(
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
                          Text(
                            context.l10n.genre,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                                final isIncluded = selectedGenres.contains(
                                  genre,
                                );
                                final isExcluded = excludedGenres.contains(
                                  genre,
                                );
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
                              Text(
                                context.l10n.tags,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              TextButton.icon(
                                onPressed: _showExpandedTags,
                                icon: const Icon(Icons.grid_view),
                                label: Text(context.l10n.expand),
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
                                    Text(
                                      context.l10n.releaseYear,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                                controller:
                                                    releaseYearController,
                                                focusNode: focusNode,
                                                decoration: InputDecoration(
                                                  hintText: releaseYear != null
                                                      ? releaseYear.toString()
                                                      : context.l10n.selectYear,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            },
                                        onSelected: (suggestion) {
                                          releaseYearController.text =
                                              suggestion;
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
                                      widget.isAnime
                                          ? context.l10n.season
                                          : context.l10n.origin,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Padding(padding: EdgeInsets.all(5)),
                                    if (widget.isAnime)
                                      LayoutBuilder(
                                        builder: (context, c) => DropdownMenu(
                                          width: c.maxWidth,
                                          hintText: season != ""
                                              ? season
                                              : context.l10n.any,
                                          dropdownMenuEntries: [
                                            DropdownMenuEntry(
                                              value: "SPRING",
                                              label: context.l10n.spring,
                                            ),
                                            DropdownMenuEntry(
                                              value: "SUMMER",
                                              label: context.l10n.summer,
                                            ),
                                            DropdownMenuEntry(
                                              value: "FALL",
                                              label: context.l10n.fall,
                                            ),
                                            DropdownMenuEntry(
                                              value: "WINTER",
                                              label: context.l10n.winter,
                                            ),
                                            DropdownMenuEntry(
                                              value: "",
                                              label: context.l10n.any,
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
                                              : context.l10n.any,
                                          dropdownMenuEntries: [
                                            DropdownMenuEntry(
                                              value: "CN",
                                              label: context.l10n.china,
                                            ),
                                            DropdownMenuEntry(
                                              value: "JP",
                                              label: context.l10n.japan,
                                            ),
                                            DropdownMenuEntry(
                                              value: "KR",
                                              label: context.l10n.korea,
                                            ),
                                            DropdownMenuEntry(
                                              value: "",
                                              label: context.l10n.any,
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
                                    Text(
                                      context.l10n.format,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Padding(padding: EdgeInsets.all(5)),
                                    LayoutBuilder(
                                      builder: (context, c) => DropdownMenu(
                                        width: c.maxWidth,
                                        hintText: format != ""
                                            ? format
                                            : context.l10n.any,
                                        dropdownMenuEntries: widget.isAnime
                                            ? [
                                                DropdownMenuEntry(
                                                  value: "TV",
                                                  label: context.l10n.tv,
                                                ),
                                                DropdownMenuEntry(
                                                  value: "TV_SHORT",
                                                  label: context.l10n.tvShort,
                                                ),
                                                DropdownMenuEntry(
                                                  value: "MOVIE",
                                                  label: context.l10n.movie,
                                                ),
                                                DropdownMenuEntry(
                                                  value: "SPECIAL",
                                                  label: context.l10n.special,
                                                ),
                                                DropdownMenuEntry(
                                                  value: "OVA",
                                                  label: context.l10n.ova,
                                                ),
                                                DropdownMenuEntry(
                                                  value: "ONA",
                                                  label: context.l10n.ona,
                                                ),
                                                DropdownMenuEntry(
                                                  value: "MUSIC",
                                                  label: context.l10n.music,
                                                ),
                                                DropdownMenuEntry(
                                                  value: "",
                                                  label: context.l10n.any,
                                                ),
                                              ]
                                            : [
                                                DropdownMenuEntry(
                                                  value: "MANGA",
                                                  label:
                                                      context.l10n.mangaFormat,
                                                ),
                                                DropdownMenuEntry(
                                                  value: "NOVEL",
                                                  label: context.l10n.novel,
                                                ),
                                                DropdownMenuEntry(
                                                  value: "ONE_SHOT",
                                                  label: context.l10n.oneShot,
                                                ),
                                                DropdownMenuEntry(
                                                  value: "",
                                                  label: context.l10n.any,
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
                                      widget.isAnime
                                          ? context.l10n.airingStatus
                                          : context.l10n.status,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Padding(padding: EdgeInsets.all(5)),
                                    LayoutBuilder(
                                      builder: (context, c) => DropdownMenu(
                                        width: c.maxWidth,
                                        hintText: airingStatus != ""
                                            ? airingStatus
                                            : context.l10n.any,
                                        dropdownMenuEntries: [
                                          DropdownMenuEntry(
                                            value: "RELEASING",
                                            label: context.l10n.releasing,
                                          ),
                                          DropdownMenuEntry(
                                            value: "FINISHED",
                                            label: context.l10n.finished,
                                          ),
                                          DropdownMenuEntry(
                                            value: "NOT_YET_RELEASED",
                                            label: context.l10n.notReleasedYet,
                                          ),
                                          DropdownMenuEntry(
                                            value: "CANCELLED",
                                            label: context.l10n.cancelled,
                                          ),
                                          DropdownMenuEntry(
                                            value: "HIATUS",
                                            label: context.l10n.hiatus,
                                          ),
                                          DropdownMenuEntry(
                                            value: "",
                                            label: context.l10n.any,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n.source,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Padding(padding: EdgeInsets.all(5)),
                                      LayoutBuilder(
                                        builder: (context, c) => DropdownMenu(
                                          width: c.maxWidth,
                                          hintText: sourceMaterial != ""
                                              ? sourceMaterial
                                              : context.l10n.any,
                                          dropdownMenuEntries: [
                                            DropdownMenuEntry(
                                              value: "ORIGINAL",
                                              label: context.l10n.original,
                                            ),
                                            DropdownMenuEntry(
                                              value: "MANGA",
                                              label: context.l10n.mangaFormat,
                                            ),
                                            DropdownMenuEntry(
                                              value: "LIGHT_NOVEL",
                                              label: context.l10n.lightNovel,
                                            ),
                                            DropdownMenuEntry(
                                              value: "VISUAL_NOVEL",
                                              label: context.l10n.visualNovel,
                                            ),
                                            DropdownMenuEntry(
                                              value: "VIDEO_GAME",
                                              label: context.l10n.videoGame,
                                            ),
                                            DropdownMenuEntry(
                                              value: "OTHER",
                                              label: context.l10n.other,
                                            ),
                                            DropdownMenuEntry(
                                              value: "NOVEL",
                                              label: context.l10n.novel,
                                            ),
                                            DropdownMenuEntry(
                                              value: "DOUJINSHI",
                                              label: context.l10n.doujinshi,
                                            ),
                                            DropdownMenuEntry(
                                              value: "ANIME",
                                              label: context.l10n.anime,
                                            ),
                                            DropdownMenuEntry(
                                              value: "WEB_NOVEL",
                                              label: context.l10n.webNovel,
                                            ),
                                            DropdownMenuEntry(
                                              value: "LIVE_ACTION",
                                              label: context.l10n.liveAction,
                                            ),
                                            DropdownMenuEntry(
                                              value: "GAME",
                                              label: context.l10n.game,
                                            ),
                                            DropdownMenuEntry(
                                              value: "COMIC",
                                              label: context.l10n.comic,
                                            ),
                                            DropdownMenuEntry(
                                              value: "MULTIMEDIA_PROJECT",
                                              label: context
                                                  .l10n
                                                  .multimediaProject,
                                            ),
                                            DropdownMenuEntry(
                                              value: "PICTURE_BOOK",
                                              label: context.l10n.pictureBook,
                                            ),
                                            DropdownMenuEntry(
                                              value: "",
                                              label: context.l10n.any,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n.origin,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Padding(padding: EdgeInsets.all(5)),
                                      LayoutBuilder(
                                        builder: (context, c) => DropdownMenu(
                                          width: c.maxWidth,
                                          hintText: countryOfOrigin != ""
                                              ? countryOfOrigin
                                              : context.l10n.any,
                                          dropdownMenuEntries: [
                                            DropdownMenuEntry(
                                              value: "CN",
                                              label: context.l10n.china,
                                            ),
                                            DropdownMenuEntry(
                                              value: "JP",
                                              label: context.l10n.japan,
                                            ),
                                            DropdownMenuEntry(
                                              value: "KR",
                                              label: context.l10n.korea,
                                            ),
                                            DropdownMenuEntry(
                                              value: "",
                                              label: context.l10n.any,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n.sort,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Padding(padding: EdgeInsets.all(5)),
                                      LayoutBuilder(
                                        builder: (context, c) => DropdownMenu(
                                          width: c.maxWidth,
                                          hintText: getSortByLabel(
                                            sortBy,
                                            context,
                                          ),
                                          dropdownMenuEntries: [
                                            DropdownMenuEntry(
                                              value: "TITLE_ROMAJI",
                                              label: context.l10n.titleAZ,
                                            ),
                                            DropdownMenuEntry(
                                              value: "POPULARITY_DESC",
                                              label: context.l10n.popularity,
                                            ),
                                            DropdownMenuEntry(
                                              value: "SCORE_DESC",
                                              label: context.l10n.scoreDesc,
                                            ),
                                            DropdownMenuEntry(
                                              value: "TRENDING_DESC",
                                              label: context.l10n.trending,
                                            ),
                                            DropdownMenuEntry(
                                              value: "FAVOURITES_DESC",
                                              label: context.l10n.favorites,
                                            ),
                                            DropdownMenuEntry(
                                              value: "ID_DESC",
                                              label: context.l10n.dateAdded,
                                            ),
                                            DropdownMenuEntry(
                                              value: "START_DATE_DESC",
                                              label: context.l10n.releaseDate,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n.sourceMaterial,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Padding(padding: EdgeInsets.all(5)),
                                      LayoutBuilder(
                                        builder: (context, c) => DropdownMenu(
                                          width: c.maxWidth,
                                          hintText: sourceMaterial != ""
                                              ? sourceMaterial
                                              : context.l10n.any,
                                          dropdownMenuEntries: [
                                            DropdownMenuEntry(
                                              value: "ORIGINAL",
                                              label: context.l10n.original,
                                            ),
                                            DropdownMenuEntry(
                                              value: "MANGA",
                                              label: context.l10n.mangaFormat,
                                            ),
                                            DropdownMenuEntry(
                                              value: "LIGHT_NOVEL",
                                              label: context.l10n.lightNovel,
                                            ),
                                            DropdownMenuEntry(
                                              value: "VISUAL_NOVEL",
                                              label: context.l10n.visualNovel,
                                            ),
                                            DropdownMenuEntry(
                                              value: "VIDEO_GAME",
                                              label: context.l10n.videoGame,
                                            ),
                                            DropdownMenuEntry(
                                              value: "OTHER",
                                              label: context.l10n.other,
                                            ),
                                            DropdownMenuEntry(
                                              value: "NOVEL",
                                              label: context.l10n.novel,
                                            ),
                                            DropdownMenuEntry(
                                              value: "DOUJINSHI",
                                              label: context.l10n.doujinshi,
                                            ),
                                            DropdownMenuEntry(
                                              value: "ANIME",
                                              label: context.l10n.anime,
                                            ),
                                            DropdownMenuEntry(
                                              value: "WEB_NOVEL",
                                              label: context.l10n.webNovel,
                                            ),
                                            DropdownMenuEntry(
                                              value: "LIVE_ACTION",
                                              label: context.l10n.liveAction,
                                            ),
                                            DropdownMenuEntry(
                                              value: "GAME",
                                              label: context.l10n.game,
                                            ),
                                            DropdownMenuEntry(
                                              value: "COMIC",
                                              label: context.l10n.comic,
                                            ),
                                            DropdownMenuEntry(
                                              value: "MULTIMEDIA_PROJECT",
                                              label: context
                                                  .l10n
                                                  .multimediaProject,
                                            ),
                                            DropdownMenuEntry(
                                              value: "PICTURE_BOOK",
                                              label: context.l10n.pictureBook,
                                            ),
                                            DropdownMenuEntry(
                                              value: "",
                                              label: context.l10n.any,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n.sortBy,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Padding(padding: EdgeInsets.all(5)),
                                      LayoutBuilder(
                                        builder: (context, c) => DropdownMenu(
                                          width: c.maxWidth,
                                          hintText: getSortByLabel(
                                            sortBy,
                                            context,
                                          ),
                                          dropdownMenuEntries: [
                                            DropdownMenuEntry(
                                              value: "TITLE_ROMAJI",
                                              label: context.l10n.titleAZ,
                                            ),
                                            DropdownMenuEntry(
                                              value: "POPULARITY_DESC",
                                              label: context.l10n.popularity,
                                            ),
                                            DropdownMenuEntry(
                                              value: "SCORE_DESC",
                                              label: context.l10n.scoreDesc,
                                            ),
                                            DropdownMenuEntry(
                                              value: "TRENDING_DESC",
                                              label: context.l10n.trending,
                                            ),
                                            DropdownMenuEntry(
                                              value: "FAVOURITES_DESC",
                                              label: context.l10n.favorites,
                                            ),
                                            DropdownMenuEntry(
                                              value: "ID_DESC",
                                              label: context.l10n.dateAdded,
                                            ),
                                            DropdownMenuEntry(
                                              value: "START_DATE_DESC",
                                              label: context.l10n.releaseDate,
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
                                child: Text(context.l10n.clearFilters),
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
                                child: Text(context.l10n.applyFilters),
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
      transitionDuration: const Duration(milliseconds: 350),
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
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
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
