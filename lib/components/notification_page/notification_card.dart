import 'package:zenbu/pages/anime_details_page.dart';
import 'package:zenbu/pages/manga_details_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:animations/animations.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key, required this.notificationData});
  final Map notificationData;

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
      openColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
      closedColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
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
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    border: Border.all(
                      color: CupertinoColors.systemGrey,
                    ),
                    color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey.withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 160,
                        width: 110,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            color: CupertinoColors.systemGrey,
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.systemGrey.withOpacity(0.4),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            notificationData["media"]["coverImage"]["large"],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(CupertinoIcons.exclamationmark_triangle),
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
                child: GestureDetector(
                  onTap: () {
                    openContainer();
                  },
                ),
              ),
            ],
          ),
        );
      },
      openBuilder: (context, closeContainer) {
        if (notificationData["media"]["type"] == "ANIME") {
          return AnimeDetailsPage(id: notificationData["media"]["id"]);
        } else if (notificationData["media"]["type"] == "CHARACTER") {
          return MangaDetailsPage(id: notificationData["media"]["id"]);
        }
        return Placeholder();
      },
    );
  }
}
