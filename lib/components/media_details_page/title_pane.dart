import 'dart:ui';
import 'package:zenbu/components/media_details_page/list_editor_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  State<TitlePane> createState() => _TitlePaneState();
}

class _TitlePaneState extends State<TitlePane> {
  late String mediaState;
  late String progress;
  late Map? mediaListEntry;

  @override
  void initState() {
    super.initState();
    mediaState = widget.mediaState;
    progress = widget.progress;
    mediaListEntry = widget.mediaListEntry;
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
      elementList = [const Icon(Icons.edit), Text(widget.isAnime ? " Watching" : " Reading")];
    } else if (mediaState == 'COMPLETED') {
      elementList = [const Icon(Icons.check), const Text(" Completed")];
    } else if (mediaState == 'PLANNING') {
      elementList = [const Icon(Icons.schedule), const Text(" Planning")];
    } else if (mediaState == 'DROPPED') {
      elementList = [const Icon(Icons.cancel), const Text(" Dropped")];
    } else if (mediaState == 'PAUSED') {
      elementList = [const Icon(Icons.pause), const Text(" Paused")];
    } else if (mediaState == 'REPEATING') {
      elementList = [const Icon(Icons.loop), Text(widget.isAnime ? " Rewatching" : " Rereading")];
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
                    child: Image.network(
                      widget.banner as String,
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
                        child: Image.network(
                          widget.cover,
                          fit: BoxFit.cover,
                          height: 180,
                          width: 127.38,
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
                          Text(progress),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 12, right: 12, top: 10),
                  child: FilledButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: ListEditorBottomSheet(
                              isAnime: widget.isAnime,
                              status: mediaListEntry?["status"] ?? "NONE",
                              progress: mediaListEntry?["progress"] ?? 0,
                              startDate:
                                  (mediaListEntry?["startedAt"]?["day"] == null)
                                  ? {"day": -1}
                                  : mediaListEntry?["startedAt"] ?? {"day": -1},
                              endDate:
                                  (mediaListEntry?["completedAt"]?["day"] ==
                                      null)
                                  ? {"day": -1}
                                  : mediaListEntry?["completedAt"] ??
                                        {"day": -1},
                              score: (mediaListEntry?["score"] is int)
                                  ? (mediaListEntry?["score"] as int).toDouble()
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
    );
  }
}
