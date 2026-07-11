import 'package:zenbu/pages/media_details_page.dart';
import 'package:zenbu/pages/character_details_page.dart';
import 'package:zenbu/pages/staff_details_page.dart';
import 'package:zenbu/pages/studio_details_page.dart';
import 'package:zenbu/pages/user_profile_page.dart';

import 'package:zenbu/components/media_details_page/list_editor_bottom_sheet.dart';
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
    this.listDataPreloaded = false,
  });
  final String? title;
  final String? state;
  final String? image;
  final int id;
  final String type;

  final Map? mediaListEntry;

  final bool listDataPreloaded;

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
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

  void _onLongPress(BuildContext context) {
    if (!widget.listDataPreloaded) return;
    _openListEditor(context, widget.mediaListEntry);
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
              height: 230,
              width: 110.0,
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
                          imageUrl: widget.image ?? "",
                          height: 156,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(10),
                          errorWidget: widget.type == 'studio'
                              ? Container(
                                  height: 156,
                                  width: double.infinity,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.business,
                                    size: 40,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : widget.type == 'user'
                              ? Container(
                                  height: 156,
                                  width: double.infinity,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : null,
                        ),
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(onTap: openContainer),
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
        } else if (widget.type == "studio") {
          return StudioDetailsPage(
            studioId: widget.id,
            studioName: widget.title,
          );
        } else if (widget.type == "user") {
          return UserProfilePage(userId: widget.id, username: widget.title);
        }
        return const Placeholder();
      },
    );
  }
}
