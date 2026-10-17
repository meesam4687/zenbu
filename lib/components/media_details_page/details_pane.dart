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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  Widget _buildLinkIcon(String? iconUrl) {
    if (iconUrl == null || iconUrl.trim().isEmpty) {
      return const Icon(Icons.public, size: 16);
    }
    final trimmed = iconUrl.trim();
    final isSvg = trimmed.toLowerCase().contains('.svg');

    if (isSvg) {
      return SvgPicture.network(
        trimmed,
        width: 16,
        height: 16,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => const SizedBox(
          width: 16,
          height: 16,
          child: Center(
            child: SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
        ),
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.public, size: 16),
      );
    }

    return CachedNetworkImage(
      imageUrl: trimmed,
      width: 16,
      height: 16,
      fit: BoxFit.contain,
      placeholder: (context, url) => const SizedBox(
        width: 16,
        height: 16,
        child: Center(
          child: SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      ),
      errorWidget: (context, url, error) => const Icon(Icons.public, size: 16),
    );
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

  String _formatState(String state) {
    if (state.isEmpty) return state;
    final words = state.replaceAll('_', ' ').split(' ');
    return words
        .where((w) => w.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  double _calculateListHeight(
    BuildContext context,
    List items, {
    required String Function(dynamic) getTitle,
    String? Function(dynamic)? getState,
  }) {
    if (items.isEmpty) return 0.0;
    final textScaler = MediaQuery.textScalerOf(context);
    final themeTextStyle = Theme.of(context).textTheme.bodyMedium;
    final titleStyle = (themeTextStyle ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.bold,
    );
    final stateStyle = (themeTextStyle ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w200,
    );

    double maxContentHeight = 0.0;
    for (final item in items) {
      final title = getTitle(item);
      final titlePainter = TextPainter(
        text: TextSpan(text: title, style: titleStyle),
        maxLines: 2,
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout(maxWidth: 110.0);

      double stateHeight = 0.0;
      final rawState = getState?.call(item);
      if (rawState != null && rawState.isNotEmpty) {
        final formattedState = _formatState(rawState);
        final statePainter = TextPainter(
          text: TextSpan(text: formattedState, style: stateStyle),
          maxLines: 1,
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        )..layout(maxWidth: 110.0);
        stateHeight = statePainter.height;
      }

      final double itemHeight = 168.0 + titlePainter.height + stateHeight;
      if (itemHeight > maxContentHeight) {
        maxContentHeight = itemHeight;
      }
    }
    return (maxContentHeight + 4.0).ceilToDouble();
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
                  ? Builder(
                      builder: (context) {
                        final charactersList =
                            media["characters"]["characters"] as List;
                        final double listHeight = _calculateListHeight(
                          context,
                          charactersList,
                          getTitle: (item) =>
                              item["node"]?["name"]?["full"] ?? "",
                          getState: (item) => item["role"] as String?,
                        );
                        return Container(
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
                                height: listHeight,
                                width: double.infinity,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: charactersList.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 3.0,
                                      ),
                                      child: ItemCard(
                                        cardHeight: listHeight,
                                        title:
                                            charactersList[index]["node"]["name"]["full"],
                                        image:
                                            charactersList[index]["node"]["image"]["large"],
                                        id: charactersList[index]["node"]["id"],
                                        type: "character",
                                        state: charactersList[index]["role"],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(),
              (media["relations"]["edges"] as List).isNotEmpty
                  ? Builder(
                      builder: (context) {
                        final relationsList =
                            media["relations"]["edges"] as List;
                        final double listHeight = _calculateListHeight(
                          context,
                          relationsList,
                          getTitle: (item) => provider.resolveTitle(
                            item["node"]?["title"] as Map?,
                          ),
                          getState: (item) => item["relationType"] as String?,
                        );
                        return Container(
                          margin: const EdgeInsets.only(top: 14),
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
                                height: listHeight,
                                width: double.infinity,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: relationsList.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 3.0,
                                      ),
                                      child: ItemCard(
                                        cardHeight: listHeight,
                                        id: relationsList[index]["node"]["id"],
                                        type:
                                            relationsList[index]["node"]["type"]
                                                .toString()
                                                .toLowerCase(),
                                        title: provider.resolveTitle(
                                          relationsList[index]["node"]["title"]
                                              as Map?,
                                        ),
                                        image:
                                            relationsList[index]["node"]["coverImage"]["extraLarge"],
                                        state:
                                            relationsList[index]["relationType"],
                                        mediaListEntry:
                                            relationsList[index]["node"]["mediaListEntry"]
                                                as Map?,
                                        listDataPreloaded: true,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(),
              (media["staff"]["edges"] as List).isNotEmpty
                  ? Builder(
                      builder: (context) {
                        final staffList = media["staff"]["edges"] as List;
                        final double listHeight = _calculateListHeight(
                          context,
                          staffList,
                          getTitle: (item) =>
                              item["node"]?["name"]?["full"] ?? "",
                          getState: (item) => item["role"] as String?,
                        );
                        return Container(
                          margin: const EdgeInsets.only(top: 14),
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
                                height: listHeight,
                                width: double.infinity,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: staffList.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 3.0,
                                      ),
                                      child: ItemCard(
                                        cardHeight: listHeight,
                                        id: staffList[index]["node"]["id"],
                                        type: "staff",
                                        title:
                                            (staffList[index]["node"]["name"]["full"]
                                                as String),
                                        image:
                                            staffList[index]["node"]["image"]["large"],
                                        state:
                                            (staffList[index]["role"]
                                                as String),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(),
              (media["recommendations"]["edges"] as List).isNotEmpty
                  ? Builder(
                      builder: (context) {
                        final recs = (media["recommendations"]["edges"] as List)
                            .where((e) => e["node"]?["media"] != null)
                            .toList();
                        final double listHeight = _calculateListHeight(
                          context,
                          recs,
                          getTitle: (item) => provider.resolveTitle(
                            item["node"]?["media"]?["title"] as Map?,
                          ),
                          getState: null,
                        );
                        return Container(
                          margin: const EdgeInsets.only(top: 14),
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
                                height: listHeight,
                                width: double.infinity,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: recs.length,
                                  itemBuilder: (context, index) {
                                    final nodeMedia =
                                        recs[index]["node"]["media"];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 3.0,
                                      ),
                                      child: ItemCard(
                                        cardHeight: listHeight,
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
                        );
                      },
                    )
                  : Container(),
              Builder(
                builder: (context) {
                  final externalLinks = (media["externalLinks"] as List? ?? [])
                      .where(
                        (link) =>
                            link != null &&
                            link["url"] != null &&
                            link["url"].toString().isNotEmpty &&
                            link["isDisabled"] != true,
                      )
                      .toList();

                  if (externalLinks.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 20),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.links,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: externalLinks.map<Widget>((link) {
                            final String site =
                                link["site"]?.toString() ?? context.l10n.link;
                            final String? iconUrl = link["icon"]?.toString();
                            final String? url = link["url"]?.toString();

                            return Tooltip(
                              message: url ?? site,
                              child: ActionChip(
                                elevation: 0,
                                pressElevation: 0,
                                side: BorderSide.none,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.onInverseSurface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide.none,
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                avatar: _buildLinkIcon(iconUrl),
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      site,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      size: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                                onPressed: () async {
                                  if (url != null && url.isNotEmpty) {
                                    final uri = Uri.tryParse(url);
                                    if (uri != null) {
                                      try {
                                        await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } catch (_) {
                                        try {
                                          await launchUrl(
                                            uri,
                                            mode: LaunchMode.platformDefault,
                                          );
                                        } catch (_) {}
                                      }
                                    }
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
