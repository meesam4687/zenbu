import 'package:zenbu/pages/media_details_page.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:zenbu/components/global/custom_image.dart';
import 'package:provider/provider.dart';
import 'package:zenbu/state_provider.dart';
import 'package:zenbu/l10n/l10n_extension.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notificationData,
    this.isUnread = false,
  });
  final Map notificationData;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StateProvider>(context);
    final mediaTitle = provider.resolveTitle(
      notificationData["media"]?["title"] as Map?,
    );
    String notificationText = "";
    if (notificationData["type"] == "AIRING") {
      notificationText = context.l10n.notificationEpisodeAired(
        notificationData["episode"].toString(),
        mediaTitle,
      );
    } else if (notificationData["type"] == "RELATED_MEDIA_ADDITION") {
      notificationText = context.l10n.notificationMediaAdded(mediaTitle);
    } else if (notificationData["type"] == "MEDIA_DATA_CHANGE") {
      notificationText = context.l10n.notificationMediaDataChanged(mediaTitle);
    } else if (notificationData["type"] == "MEDIA_MERGE") {
      notificationText = context.l10n.notificationMediaMerged(
        notificationData["deletedMediaTitles"][0].toString(),
        mediaTitle,
      );
    }
    final cardColor = Theme.of(context).colorScheme.onInverseSurface;
    return Container(
      margin: const EdgeInsets.all(5),
      child: OpenContainer(
        openElevation: 0,
        closedElevation: 0,
        transitionType: ContainerTransitionType.fadeThrough,
        openColor: Theme.of(context).colorScheme.surface,
        middleColor: Theme.of(context).colorScheme.surface,
        closedColor: cardColor,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        closedBuilder: (context, openContainer) {
          return SizedBox(
            height: 250,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                onTap: () {
                  openContainer();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: SizedBox(
                        height: 160,
                        width: 110,
                        child: Card(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          elevation: 5,
                          clipBehavior: Clip.antiAlias,
                          child: CustomImage(
                            imageUrl:
                                notificationData["media"]["coverImage"]["large"],
                            fit: BoxFit.cover,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                            errorWidget: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          notificationText,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        openBuilder: (context, closeContainer) {
          final isAnime = notificationData["media"]["type"] == "ANIME";
          return MediaDetailsPage(
            id: notificationData["media"]["id"],
            isAnime: isAnime,
          );
        },
      ),
    );
  }
}
