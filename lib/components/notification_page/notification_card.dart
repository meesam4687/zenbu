import 'package:zenbu/pages/media_details_page.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

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
    String notificationText = "";
    if (notificationData["type"] == "AIRING") {
      notificationText =
          "Episode ${notificationData["episode"].toString()} of ${notificationData["media"]["title"]["romaji"]} aired";
    } else if (notificationData["type"] == "RELATED_MEDIA_ADDITION") {
      notificationText =
          "${notificationData["media"]["title"]["romaji"]} was recently added to the site.";
    } else if (notificationData["type"] == "MEDIA_DATA_CHANGE") {
      notificationText =
          "${notificationData["media"]["title"]["romaji"]} received site data changes";
    } else if (notificationData["type"] == "MEDIA_MERGE") {
      notificationText =
          "${notificationData["deletedMediaTitles"][0]} was merged with ${notificationData["media"]["title"]["romaji"]}";
    }
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
        return Container(
          margin: EdgeInsets.all(5),
          child: Stack(
            children: [
              SizedBox(
                height: 250,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    side: BorderSide(
                      color: isUnread
                          ? Color.lerp(
                              Theme.of(context).colorScheme.onSecondaryFixed,
                              Colors.white,
                              0.5,
                            )!
                          : Theme.of(context).colorScheme.onSecondaryFixed,
                      width: isUnread ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 160,
                        width: 110,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          elevation: 5,
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            notificationData["media"]["coverImage"]["large"],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: Text(
                          notificationText,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsetsGeometry.all(5),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      onTap: () {
                        openContainer();
                      },
                    ),
                  ),
                ),
              ),
            ],
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
    );
  }
}
