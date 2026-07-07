import 'package:zenbu/pages/media_details_page.dart';
import 'package:zenbu/pages/character_details_page.dart';
import 'package:zenbu/pages/staff_details_page.dart';
import 'package:zenbu/components/media_details_page/list_editor_bottom_sheet.dart';
import 'package:zenbu/services/anilist/anilist.dart';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenbu/components/global/custom_image.dart';

class ItemCard extends StatefulWidget {
  const ItemCard({
    super.key,
    required this.title,
    this.state,
    required this.image,
    required this.id,
    required this.type,
    this.mediaListEntry,
  });
  final String? title;
  final String? state;
  final String? image;
  final int id;
  final String type;

  final Map? mediaListEntry;

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _isLoadingEditor = false;

  void _openListEditor(BuildContext context, Map? entry) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: ListEditorBottomSheet(
            isAnime: widget.type == 'anime',
            status: entry?['status'] ?? 'NONE',
            progress: entry?['progress'] ?? 0,
            startDate: (entry?['startedAt']?['day'] == null)
                ? {'day': -1}
                : entry?['startedAt'] ?? {'day': -1},
            endDate: (entry?['completedAt']?['day'] == null)
                ? {'day': -1}
                : entry?['completedAt'] ?? {'day': -1},
            score: (entry?['score'] is int)
                ? (entry?['score'] as int).toDouble()
                : entry?['score'] ?? 0.0,
            repeatCount: entry?['repeat'] ?? 0,
            mediaId: widget.id,
            onUpdate: (_, _, _) {},
          ),
        );
      },
    );
  }

  Future<void> _onLongPress(BuildContext context) async {
    if (widget.mediaListEntry != null) {
      _openListEditor(context, widget.mediaListEntry);
      return;
    }

    if (_isLoadingEditor) return;
    setState(() => _isLoadingEditor = true);
    HapticFeedback.mediumImpact();

    try {
      final Map<String, dynamic> data = widget.type == 'anime'
          ? await getAnimeData(widget.id)
          : await getMangaData(widget.id);

      if (!context.mounted) return;
      final entry = data['data']['Media']['mediaListEntry'];
      _openListEditor(context, entry);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingEditor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMedia = widget.type == 'anime' || widget.type == 'manga';

    return OpenContainer(
      openElevation: 0,
      closedElevation: 0,
      transitionType: ContainerTransitionType.fadeThrough,
      openColor: Theme.of(context).colorScheme.surface,
      closedColor: Theme.of(context).colorScheme.surface,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: openContainer,
          onLongPress: isMedia ? () => _onLongPress(context) : null,
          child: Material(
            child: Ink(
              height: 248,
              width: 120.7,
              child: Column(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        CustomImage(
                          imageUrl: widget.image as String,
                          height: 172,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(onTap: openContainer),
                          ),
                        ),
                        if (_isLoadingEditor)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black45,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.title as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  (widget.state != null)
                      ? Text(
                          widget.state as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w200),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Container(),
                ],
              ),
            ),
          ),
        );
      },
      openBuilder: (context, closeContainer) {
        if (widget.type == "anime") {
          return MediaDetailsPage(id: widget.id, isAnime: true);
        } else if (widget.type == "manga") {
          return MediaDetailsPage(id: widget.id, isAnime: false);
        } else if (widget.type == "character") {
          return CharacterDetailsPage(id: widget.id);
        } else if (widget.type == "staff") {
          return StaffDetailsPage(id: widget.id);
        }
        return const Placeholder();
      },
    );
  }
}
