import 'dart:async';
import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/components/media_details_page/details.dart';
import 'package:zenbu/pages/error_page.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/components/global/item_card.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' show parseFragment;

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

  String _formatTimeRemaining(int seconds) {
    int days = seconds ~/ 86400;
    int hours = (seconds % 86400) ~/ 3600;

    List<String> parts = [];
    if (days > 0) {
      parts.add("$days ${days == 1 ? 'day' : 'days'}");
    }
    if (hours > 0) {
      parts.add("$hours ${hours == 1 ? 'hour' : 'hours'}");
    }

    if (parts.isEmpty) {
      return "Less than an hour";
    }
    return parts.join(" ");
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Map<int, String> months = {
      1: "January",
      2: "February",
      3: "March",
      4: "April",
      5: "May",
      6: "June",
      7: "July",
      8: "August",
      9: "September",
      10: "October",
      11: "November",
      12: "December",
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
            : ["N/A"];
        final List<dynamic> genres =
            (data['data']['Media']['genres'] as List).isNotEmpty
            ? data['data']['Media']['genres']
            : ["N/A"];

        final media = data["data"]["Media"];

        final List<({String label, String? value})> detailsItems = [];
        if (widget.isAnime && media["nextAiringEpisode"] != null) {
          final nextEp = media["nextAiringEpisode"];
          final airingAt = nextEp["airingAt"] as int;
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final secondsRemaining = airingAt - now;
          if (secondsRemaining > 0) {
            final formattedTime = _formatTimeRemaining(secondsRemaining);
            detailsItems.add((label: "Next Episode in", value: formattedTime));
          }
        }
        final meanScoreVal = media["meanScore"] != null
            ? "${(media["meanScore"] as int) / 10}/10"
            : "N/A";
        detailsItems.add((label: "Mean Score", value: meanScoreVal));

        if (widget.isAnime) {
          final studiosVal = (media["studios"]["nodes"] as List).isNotEmpty
              ? media["studios"]["nodes"][0]["name"] as String
              : "N/A";
          detailsItems.add((label: "Studios", value: studiosVal));
        } else {
          final authorVal = (media["staff"]["edges"] as List).isNotEmpty
              ? media["staff"]["edges"][0]["node"]["name"]["full"] as String
              : "N/A";
          detailsItems.add((label: "Author", value: authorVal));
        }

        final sourceVal = media["source"] != null
            ? "${(media["source"] as String).substring(0, 1).toUpperCase()}${(media["source"] as String).substring(1).toLowerCase()}"
                  .replaceAll("_", " ")
            : "N/A";
        detailsItems.add((label: "Source", value: sourceVal));

        final formatVal = media["format"] != null
            ? media["format"] as String
            : "N/A";
        detailsItems.add((label: "Format", value: formatVal));

        if (widget.isAnime) {
          final episodesVal = media["episodes"] != null
              ? "${media["episodes"]}"
              : "N/A";
          detailsItems.add((label: "Episodes", value: episodesVal));

          final durationVal = media["duration"] != null
              ? "${media["duration"]} mins"
              : "N/A";
          detailsItems.add((label: "Episode Duration", value: durationVal));
        } else {
          final chaptersVal = media["chapters"] != null
              ? "${media["chapters"]}"
              : "N/A";
          detailsItems.add((label: "Chapters", value: chaptersVal));
        }

        final statusVal = media["status"] != null
            ? "${(media["status"] as String).substring(0, 1).toUpperCase()}${(media["status"] as String).substring(1).toLowerCase()}"
            : "N/A";
        detailsItems.add((label: "Status", value: statusVal));

        final startDateVal = (months[media["startDate"]["month"]] != null)
            ? "${months[media["startDate"]["month"]]} ${media["startDate"]["day"]}, ${media["startDate"]["year"]}"
            : "N/A";
        detailsItems.add((label: "Start Date", value: startDateVal));

        final endDateVal = (media["endDate"]["day"] == null)
            ? "N/A"
            : "${months[media["endDate"]["month"]]} ${media["endDate"]["day"]}, ${media["endDate"]["year"]}";
        detailsItems.add((label: "End Date", value: endDateVal));

        if (widget.isAnime) {
          final seasonVal = media["season"] != null
              ? "${(media["season"].toString()).substring(0, 1).toUpperCase()}${(media["season"].toString()).substring(1).toLowerCase()}, ${media["startDate"]["year"]}"
              : "N/A";
          detailsItems.add((label: "Season", value: seasonVal));
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
                    const Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: (media["description"] != null)
                          ? MarkdownBody(
                              data: _convertHtmlToMarkdown(
                                media["description"].toString(),
                              ),
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
                            )
                          : const Text("N/A"),
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
                    const Text(
                      "Genres and Tags",
                      style: TextStyle(
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
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(label: Text((genres + tags)[index])),
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
                          const Text(
                            "Characters",
                            style: TextStyle(
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
                          const Text(
                            "Relations",
                            style: TextStyle(
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
                                    title:
                                        (media["relations"]["edges"][index]["node"]["title"]["romaji"]
                                            as String),
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
                          const Text(
                            "Staff",
                            style: TextStyle(
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
                          const Text(
                            "Recommendations",
                            style: TextStyle(
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
                                    title:
                                        (nodeMedia["title"]["romaji"]
                                            as String),
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
