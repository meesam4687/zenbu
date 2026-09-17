import 'dart:async';
import 'package:flutter/services.dart';
import 'package:zenbu/l10n/l10n_extension.dart';
import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/components/media_details_page/details.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/state_provider.dart';
import 'package:zenbu/components/global/item_card.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' show parseFragment;
import 'package:zenbu/pages/media_search_page.dart';

String _convertHtmlToMarkdown(String html) {
  var out = html;

  out = out.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

  out = out.replaceAll(RegExp(r'</?i>', caseSensitive: false), '*');
  out = out.replaceAll(RegExp(r'</?em>', caseSensitive: false), '*');

  out = out.replaceAll(RegExp(r'</?b>', caseSensitive: false), '**');
  out = out.replaceAll(RegExp(r'</?strong>', caseSensitive: false), '**');

  out = out.replaceAllMapped(
    RegExp(
      r'<a\s+(?:[^>]*?\s+)?href="([^"]*)"[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    ),
    (match) {
      final url = match.group(1) ?? '';
      final text = match.group(2) ?? '';
      return '[$text]($url)';
    },
  );

  final fragment = parseFragment(out);
  return fragment.text ?? out;
}

class DetailsPane extends StatefulWidget {
  const DetailsPane({super.key, required this.mediaId, required this.isAnime});

  final int mediaId;
  final bool isAnime;

  @override
  State<DetailsPane> createState() => _DetailsPaneState();
}

class _DetailsPaneState extends State<DetailsPane>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, dynamic>> mediaData;
  Timer? _countdownTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    mediaData = widget.isAnime
        ? getAnimeData(widget.mediaId)
        : getMangaData(widget.mediaId);

    if (widget.isAnime) {
      _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTimeRemaining(BuildContext context, int seconds) {
    int days = seconds ~/ 86400;
    int hours = (seconds % 86400) ~/ 3600;

    List<String> parts = [];
    if (days > 0) {
      parts.add(context.l10n.daysCount(days));
    }
    if (hours > 0) {
      parts.add(context.l10n.hoursCount(hours));
    }

    if (parts.isEmpty) {
      return context.l10n.lessThanAnHour;
    }
    return parts.join(" ");
  }

  String _formatDate(BuildContext context, Map? date, Map<int, String> months) {
    if (date == null) return context.l10n.na;
    final int? year = date["year"] as int?;
    final int? monthNum = date["month"] as int?;
    final int? day = date["day"] as int?;

    if (year == null && monthNum == null && day == null) {
      return context.l10n.na;
    }

    final isUS = Localizations.localeOf(context).countryCode == 'US';
    final String? monthName = monthNum != null ? months[monthNum] : null;

    if (monthName != null && day != null && year != null) {
      return isUS ? "$monthName $day, $year" : "$day $monthName $year";
    }
    if (monthName != null && day != null && year == null) {
      return isUS ? "$monthName $day" : "$day $monthName";
    }
    if (monthName != null && day == null && year != null) {
      return "$monthName $year";
    }
    if (monthName != null && day == null && year == null) {
      return monthName;
    }
    if (monthName == null && day != null && year != null) {
      final d = day.toString().padLeft(2, '0');
      final m = monthNum?.toString().padLeft(2, '0');
      if (m != null) {
        return isUS ? "$m/$d/$year" : "$d/$m/$year";
      }
      return "$day, $year";
    }
    if (monthName == null && day != null && year == null) {
      return "$day";
    }
    if (monthName == null && day == null && year != null) {
      return "$year";
    }

    return context.l10n.na;
  }

  String _formatSeason(
    BuildContext context,
    String? season,
    dynamic seasonYear,
  ) {
    if (season == null) return context.l10n.na;
    final String seasonText;
    switch (season.toUpperCase()) {
      case 'WINTER':
        seasonText = context.l10n.winter;
        break;
      case 'SPRING':
        seasonText = context.l10n.spring;
        break;
      case 'SUMMER':
        seasonText = context.l10n.summer;
        break;
      case 'FALL':
        seasonText = context.l10n.fall;
        break;
      default:
        seasonText =
            '${season.substring(0, 1).toUpperCase()}${season.substring(1).toLowerCase()}';
    }
    return seasonYear != null ? '$seasonText, $seasonYear' : seasonText;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = Provider.of<StateProvider>(context);
    Map<int, String> months = {
      1: context.l10n.january,
      2: context.l10n.february,
      3: context.l10n.march,
      4: context.l10n.april,
      5: context.l10n.may,
      6: context.l10n.june,
      7: context.l10n.july,
      8: context.l10n.august,
      9: context.l10n.september,
      10: context.l10n.october,
      11: context.l10n.november,
      12: context.l10n.december,
    };

    return FutureBuilder(
      future: mediaData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (snapshot.hasError) {
          return ErrorPage(
            scaffold: false,
            onReload: () {
              setState(() {
                mediaData = widget.isAnime
                    ? getAnimeData(widget.mediaId)
                    : getMangaData(widget.mediaId);
              });
            },
          );
        }
        final Map data = snapshot.data!;
        final List<dynamic> tags =
            (data['data']['Media']['tags'] as List).isNotEmpty
            ? (data['data']['Media']['tags'] as List)
                  .map((tag) => tag['name'] as String)
                  .toList()
            : [context.l10n.na];
        final List<dynamic> genres =
            (data['data']['Media']['genres'] as List).isNotEmpty
            ? data['data']['Media']['genres']
            : [context.l10n.na];

        final media = data["data"]["Media"];

        final List<({String label, String? value})> detailsItems = [];
        if (widget.isAnime && media["nextAiringEpisode"] != null) {
          final nextEp = media["nextAiringEpisode"];
          final airingAt = nextEp["airingAt"] as int;
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final secondsRemaining = airingAt - now;
          if (secondsRemaining > 0) {
            final formattedTime = _formatTimeRemaining(
              context,
              secondsRemaining,
            );
            final episode = nextEp["episode"];
            detailsItems.add((
              label: context.l10n.episodeIn(episode),
              value: formattedTime,
            ));
          }
        }
        final meanScoreVal = media["meanScore"] != null
            ? "${(media["meanScore"] as int) / 10}/10"
            : context.l10n.na;
        detailsItems.add((label: context.l10n.meanScore, value: meanScoreVal));

        if (widget.isAnime) {
          final studiosVal = (media["studios"]["nodes"] as List).isNotEmpty
              ? media["studios"]["nodes"][0]["name"] as String
              : context.l10n.na;
          detailsItems.add((label: context.l10n.studios, value: studiosVal));
        } else {
          final authorVal = (media["staff"]["edges"] as List).isNotEmpty
              ? media["staff"]["edges"][0]["node"]["name"]["full"] as String
              : context.l10n.na;
          detailsItems.add((label: context.l10n.author, value: authorVal));
        }

        final sourceVal = media["source"] != null
            ? "${(media["source"] as String).substring(0, 1).toUpperCase()}${(media["source"] as String).substring(1).toLowerCase()}"
                  .replaceAll("_", " ")
            : context.l10n.na;
        detailsItems.add((label: context.l10n.source, value: sourceVal));

        final formatVal = media["format"] != null
            ? media["format"] as String
            : context.l10n.na;
        detailsItems.add((label: context.l10n.format, value: formatVal));

        if (widget.isAnime) {
          final episodesVal = media["episodes"] != null
              ? "${media["episodes"]}"
              : context.l10n.na;
          detailsItems.add((label: context.l10n.episodes, value: episodesVal));

          final durationVal = media["duration"] != null
              ? "${media["duration"]} ${context.l10n.mins}"
              : context.l10n.na;
          detailsItems.add((
            label: context.l10n.episodeDuration,
            value: durationVal,
          ));
        } else {
          final chaptersVal = media["chapters"] != null
              ? "${media["chapters"]}"
              : context.l10n.na;
          detailsItems.add((label: context.l10n.chapters, value: chaptersVal));
        }

        final statusVal = media["status"] != null
            ? "${(media["status"] as String).substring(0, 1).toUpperCase()}${(media["status"] as String).substring(1).toLowerCase()}"
            : context.l10n.na;
        detailsItems.add((
          label: context.l10n.status,
          value: statusVal.replaceAll("_", " "),
        ));

        final startDateVal = _formatDate(
          context,
          media["startDate"] as Map?,
          months,
        );
        detailsItems.add((label: context.l10n.startDate, value: startDateVal));

        final endDateVal = _formatDate(
          context,
          media["endDate"] as Map?,
          months,
        );
        detailsItems.add((label: context.l10n.endDate, value: endDateVal));

        if (widget.isAnime) {
          final seasonYear = media["seasonYear"] ?? media["startDate"]?["year"];
          final seasonVal = _formatSeason(
            context,
            media["season"] as String?,
            seasonYear,
          );
          detailsItems.add((label: context.l10n.season, value: seasonVal));
        }
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10, left: 20, right: 20),
          child: Column(
            children: [
              Details(items: detailsItems),
              Container(
                margin: const EdgeInsets.only(top: 20),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.description,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final titleMap = media["title"] as Map? ?? {};
                        final resolvedTitle = provider.resolveTitle(titleMap);

                        final Set<String> altTitlesSet = {};
                        if (titleMap["english"] != null &&
                            (titleMap["english"] as String).trim().isNotEmpty) {
                          altTitlesSet.add(
                            (titleMap["english"] as String).trim(),
                          );
                        }
                        if (titleMap["romaji"] != null &&
                            (titleMap["romaji"] as String).trim().isNotEmpty) {
                          altTitlesSet.add(
                            (titleMap["romaji"] as String).trim(),
                          );
                        }
                        if (titleMap["native"] != null &&
                            (titleMap["native"] as String).trim().isNotEmpty) {
                          altTitlesSet.add(
                            (titleMap["native"] as String).trim(),
                          );
                        }
                        if (media["synonyms"] is List) {
                          for (var syn in (media["synonyms"] as List)) {
                            if (syn != null &&
                                syn.toString().trim().isNotEmpty) {
                              altTitlesSet.add(syn.toString().trim());
                            }
                          }
                        }
                        altTitlesSet.remove(resolvedTitle);

                        String rawDesc = media["description"]?.toString() ?? "";
                        String fullDescMarkdown = _convertHtmlToMarkdown(
                          rawDesc,
                        );

                        if (altTitlesSet.isNotEmpty) {
                          final String altTitlesFormatted = altTitlesSet.join(
                            ", ",
                          );
                          if (fullDescMarkdown.isNotEmpty) {
                            fullDescMarkdown +=
                                "\n\n**${context.l10n.alternativeTitles}:**\n$altTitlesFormatted";
                          } else {
                            fullDescMarkdown =
                                "**${context.l10n.alternativeTitles}:**\n$altTitlesFormatted";
                          }
                        }

                        if (fullDescMarkdown.isEmpty) {
                          return Text(context.l10n.na);
                        }

                        return MarkdownBody(
                          data: fullDescMarkdown,
                          selectable: true,
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ).copyWith(
                                p: TextStyle(
                                  fontSize:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.fontSize ??
                                      14,
                                ),
                              ),
                          onTapLink: (text, href, title) async {
                            if (href != null) {
                              final uri = Uri.parse(href);
                              try {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.platformDefault,
                                );
                              } catch (_) {}
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.genresAndTags,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 60,
                      width: double.infinity,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (genres + tags).length,
                        itemBuilder: (context, index) {
                          final item = (genres + tags)[index].toString();
                          final bool isNA = item == context.l10n.na;
                          final bool isGenre = genres.contains(item);

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onLongPress: () {
                                Clipboard.setData(ClipboardData(text: item));
                                HapticFeedback.mediumImpact();
                              },
                              child: ActionChip(
                                label: Text(item),
                                onPressed: isNA
                                    ? null
                                    : () {
                                        final provider =
                                            Provider.of<StateProvider>(
                                              context,
                                              listen: false,
                                            );
                                        final Map filters = Map.of(
                                          widget.isAnime
                                              ? provider.currentAnimeFilters
                                              : provider.currentMangaFilters,
                                        );

                                        if (isGenre) {
                                          filters["selectedGenres"] = <String>{
                                            item,
                                          };
                                          filters["selectedTags"] = <String>{};
                                        } else {
                                          filters["selectedGenres"] =
                                              <String>{};
                                          filters["selectedTags"] = <String>{
                                            item,
                                          };
                                        }

                                        if (widget.isAnime) {
                                          provider.currentAnimeFilters =
                                              filters;
                                        } else {
                                          provider.currentMangaFilters =
                                              filters;
                                        }

                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => SearchPage(
                                              isAnime: widget.isAnime,
                                              query: null,
                                              genres: isGenre ? [item] : null,
                                              tags: !isGenre ? [item] : null,
                                            ),
                                          ),
                                        );
                                      },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              (media["characters"]["characters"] as List).isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.characters,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            height: 260,
                            width: double.infinity,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  (media["characters"]["characters"] as List)
                                      .length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 3.0),
                                  child: ItemCard(
                                    title:
                                        media["characters"]["characters"][index]["node"]["name"]["full"],
                                    image:
                                        media["characters"]["characters"][index]["node"]["image"]["large"],
                                    id: media["characters"]["characters"][index]["node"]["id"],
                                    type: "character",
                                    state:
                                        media["characters"]["characters"][index]["role"],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(),
              (media["relations"]["edges"] as List).isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.only(top: 0),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.relations,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            height: 260,
                            width: double.infinity,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  (media["relations"]["edges"] as List).length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 3.0),
                                  child: ItemCard(
                                    id: media["relations"]["edges"][index]["node"]["id"],
                                    type:
                                        media["relations"]["edges"][index]["node"]["type"]
                                            .toString()
                                            .toLowerCase(),
                                    title: provider.resolveTitle(
                                      media["relations"]["edges"][index]["node"]["title"]
                                          as Map?,
                                    ),
                                    image:
                                        media["relations"]["edges"][index]["node"]["coverImage"]["extraLarge"],
                                    state:
                                        media["relations"]["edges"][index]["relationType"],
                                    mediaListEntry:
                                        media["relations"]["edges"][index]["node"]["mediaListEntry"]
                                            as Map?,
                                    listDataPreloaded: true,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(),
              (media["staff"]["edges"] as List).isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.only(top: 0),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.staff,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            height: 260,
                            width: double.infinity,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  (media["staff"]["edges"] as List).length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 3.0),
                                  child: ItemCard(
                                    id: media["staff"]["edges"][index]["node"]["id"],
                                    type: "staff",
                                    title:
                                        (media["staff"]["edges"][index]["node"]["name"]["full"]
                                            as String),
                                    image:
                                        media["staff"]["edges"][index]["node"]["image"]["large"],
                                    state:
                                        (media["staff"]["edges"][index]["role"]
                                            as String),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(),
              (media["recommendations"]["edges"] as List).isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.only(top: 0),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.recommendations,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            height: 260,
                            width: double.infinity,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  (media["recommendations"]["edges"] as List)
                                      .length,
                              itemBuilder: (context, index) {
                                final recs =
                                    (media["recommendations"]["edges"] as List)
                                        .where(
                                          (e) => e["node"]["media"] != null,
                                        )
                                        .toList();
                                final nodeMedia = recs[index]["node"]["media"];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 3.0),
                                  child: ItemCard(
                                    id: nodeMedia["id"],
                                    type: (nodeMedia["type"] as String)
                                        .toLowerCase(),
                                    title: provider.resolveTitle(
                                      nodeMedia["title"] as Map?,
                                    ),
                                    image:
                                        nodeMedia["coverImage"]["extraLarge"],
                                    mediaListEntry:
                                        nodeMedia["mediaListEntry"] as Map?,
                                    listDataPreloaded: true,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(),
            ],
          ),
        );
      },
    );
  }
}
