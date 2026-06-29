import 'dart:ui';
import 'package:zenbu/components/media_details_page/list_editor_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenbu/services/anilist/anilist.dart';
import 'package:zenbu/components/global/custom_image.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/state_provider.dart';

class TitlePane extends StatefulWidget {
  const TitlePane({
    super.key,
    required this.id,
    required this.title,
    required this.fullTitle,
    required this.progress,
    required this.cover,
    required this.banner,
    required this.mediaState,
    required this.mediaListEntry,
    required this.totalEpisodes,
    required this.isAnime,
    required this.isFavourite,
  });

  final String title;
  final int id;
  final String progress;
  final String cover;
  final String? banner;
  final String mediaState;
  final Map? mediaListEntry;
  final String totalEpisodes;
  final String fullTitle;
  final bool isAnime;
  final bool isFavourite;

  @override
  State<TitlePane> createState() => _TitlePaneState();
}

class _TitlePaneState extends State<TitlePane> {
  late String mediaState;
  late String progress;
  late Map? mediaListEntry;
  late bool isFavourite;
  bool _isIncrementing = false;
  bool _isTogglingFavourite = false;

  @override
  void initState() {
    super.initState();
    mediaState = widget.mediaState;
    progress = widget.progress;
    mediaListEntry = widget.mediaListEntry;
    isFavourite = widget.isFavourite;
  }

  Future<void> _incrementProgress() async {
    if (_isIncrementing) return;
    setState(() {
      _isIncrementing = true;
    });

    try {
      final currentProg = mediaListEntry?["progress"] ?? 0;
      final newProgress = currentProg + 1;
      final total = int.tryParse(widget.totalEpisodes);

      String newStatus = mediaState;
      Map newEndDate = (mediaListEntry?["completedAt"]?["day"] == null)
          ? {"day": null, "month": null, "year": null}
          : mediaListEntry?["completedAt"] ??
                {"day": null, "month": null, "year": null};

      if (total != null && newProgress >= total) {
        newStatus = 'COMPLETED';
        final now = DateTime.now();
        newEndDate = {"day": now.day, "month": now.month, "year": now.year};
      }

      final response = await updateListItem(
        widget.id,
        newStatus,
        newProgress,
        (mediaListEntry?["startedAt"]?["day"] == null)
            ? {"day": null, "month": null, "year": null}
            : mediaListEntry?["startedAt"] ??
                  {"day": null, "month": null, "year": null},
        newEndDate,
        (mediaListEntry?["score"] is num)
            ? (mediaListEntry?["score"] as num).toDouble()
            : 0.0,
        mediaListEntry?["repeat"] ?? 0,
      );

      if (response["data"] != null &&
          response["data"]["SaveMediaListEntry"] != null) {
        final savedEntry = response["data"]["SaveMediaListEntry"];
        setState(() {
          mediaState = savedEntry["status"];
          progress =
              "Progress: ${savedEntry["progress"]}/${widget.totalEpisodes}";
          mediaListEntry = savedEntry;
        });

        final newAlData = await getHomePageData();
        if (mounted) {
          Provider.of<StateProvider>(
            context,
            listen: false,
          ).updateData(newAlData);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isIncrementing = false;
        });
      }
    }
  }

  Future<void> _toggleFavourite() async {
    if (_isTogglingFavourite) return;
    setState(() {
      _isTogglingFavourite = true;
    });

    try {
      final response = await toggleFavourite(
        animeId: widget.isAnime ? widget.id : null,
        mangaId: !widget.isAnime ? widget.id : null,
      );

      if (response["errors"] != null) {
        if (mounted) {
          final errMsg =
              response["errors"][0]?["message"] ?? "Unknown GraphQL error";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to toggle favorite: $errMsg")),
          );
        }
      }

      if (response["errors"] == null) {
        setState(() {
          isFavourite = !isFavourite;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFavourite = false;
        });
      }
    }
  }

  void updateMediaDetails(
    String newStatus,
    int newProgress,
    Map newMediaListData,
  ) {
    setState(() {
      mediaState = newStatus;
      progress = "Progress: $newProgress/${widget.totalEpisodes}";
      mediaListEntry = newMediaListData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    List<Widget> elementList = [];
    if (mediaState == 'CURRENT') {
      elementList = [
        const Icon(Icons.edit),
        Text(widget.isAnime ? " Watching" : " Reading"),
      ];
    } else if (mediaState == 'COMPLETED') {
      elementList = [const Icon(Icons.check), const Text(" Completed")];
    } else if (mediaState == 'PLANNING') {
      elementList = [const Icon(Icons.schedule), const Text(" Planning")];
    } else if (mediaState == 'DROPPED') {
      elementList = [const Icon(Icons.cancel), const Text(" Dropped")];
    } else if (mediaState == 'PAUSED') {
      elementList = [const Icon(Icons.pause), const Text(" Paused")];
    } else if (mediaState == 'REPEATING') {
      elementList = [
        const Icon(Icons.loop),
        Text(widget.isAnime ? " Rewatching" : " Rereading"),
      ];
    } else {
      elementList = [const Icon(Icons.add), const Text(" Add to List")];
    }
    return SizedBox(
      height: 350,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: (widget.banner == null)
                ? Container()
                : ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: CustomImage(
                      imageUrl: widget.banner as String,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          Scaffold(backgroundColor: surfaceColor.withAlpha(120)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, surfaceColor],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 90),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 10),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      height: 180,
                      width: 127.38,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CustomImage(
                          imageUrl: widget.cover,
                          fit: BoxFit.cover,
                          height: 180,
                          width: 127.38,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onLongPress: () {
                              Clipboard.setData(
                                ClipboardData(text: widget.fullTitle),
                              );
                              HapticFeedback.mediumImpact();
                            },
                            child: SizedBox(
                              width: 200,
                              child: Text(
                                widget.title,
                                style: const TextStyle(fontSize: 27),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(progress),
                              if (mediaState == 'CURRENT') ...[
                                const SizedBox(width: 8),
                                ClipOval(
                                  child: Material(
                                    color: _isIncrementing
                                        ? Colors.grey.shade600
                                        : Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                    child: InkWell(
                                      onTap: _isIncrementing
                                          ? null
                                          : _incrementProgress,
                                      child: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: Center(
                                          child: _isIncrementing
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                              : Text(
                                                  "+1",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(left: 12, right: 12, top: 10),
                  child: Row(
                    children: [
                      ClipOval(
                        child: Material(
                          color: _isTogglingFavourite
                              ? Colors.grey.shade600
                              : (isFavourite
                                    ? Colors.red.shade600
                                    : Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer),
                          child: InkWell(
                            onTap: _isTogglingFavourite
                                ? null
                                : _toggleFavourite,
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: _isTogglingFavourite
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Icon(
                                        isFavourite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(
                                      context,
                                    ).viewInsets.bottom,
                                  ),
                                  child: ListEditorBottomSheet(
                                    isAnime: widget.isAnime,
                                    status: mediaListEntry?["status"] ?? "NONE",
                                    progress: mediaListEntry?["progress"] ?? 0,
                                    startDate:
                                        (mediaListEntry?["startedAt"]?["day"] ==
                                            null)
                                        ? {"day": -1}
                                        : mediaListEntry?["startedAt"] ??
                                              {"day": -1},
                                    endDate:
                                        (mediaListEntry?["completedAt"]?["day"] ==
                                            null)
                                        ? {"day": -1}
                                        : mediaListEntry?["completedAt"] ??
                                              {"day": -1},
                                    score: (mediaListEntry?["score"] is int)
                                        ? (mediaListEntry?["score"] as int)
                                              .toDouble()
                                        : mediaListEntry?["score"] ?? 0.0,
                                    repeatCount: mediaListEntry?["repeat"] ?? 0,
                                    mediaId: widget.id,
                                    onUpdate: updateMediaDetails,
                                  ),
                                );
                              },
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 5,
                            children: elementList,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
