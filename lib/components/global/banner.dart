import 'dart:ui' as ui;
import 'package:zenbu/pages/anime_details_page.dart';
import 'package:zenbu/pages/character_details_page.dart';
import 'package:zenbu/pages/manga_details_page.dart';
import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';

class AiringBanner extends StatelessWidget {
  const AiringBanner({
    super.key,
    required this.id,
    required this.bannerImage,
    required this.coverImage,
    required this.title,
    this.totalEpisodes,
    this.airedEpisodes,
    required this.tagString,
    required this.type,
  });
  final int id;
  final String bannerImage;
  final String coverImage;
  final String title;
  final String? totalEpisodes;
  final String? airedEpisodes;
  final String tagString;
  final String type;

  @override
  Widget build(BuildContext context) {
    final double cardRadius = 15;
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
          height: 240,
          width: double.infinity,
          margin: EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(cardRadius),
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Image.network(
                        bannerImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(),
                      ),
                    ),
                  ),
                ),
                Container(color: CupertinoColors.black.withOpacity(0.4)),
                Container(
                  margin: const EdgeInsets.all(10),
                  height: 240,
                  width: double.infinity,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 190,
                        width: 140,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            coverImage,
                            fit: BoxFit.cover,

                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(CupertinoIcons.exclamationmark_triangle),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 24,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 5.0,
                                      color: CupertinoColors.black,
                                    ),
                                  ],
                                  color: Color.fromRGBO(227, 226, 233, 1),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              (totalEpisodes != null && airedEpisodes != null)
                                  ? Text(
                                      "Episodes: $airedEpisodes/$totalEpisodes\n$tagString",
                                      style: TextStyle(
                                        fontSize: 15,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 5.0,
                                            color: CupertinoColors.black,
                                          ),
                                        ],
                                        color: Color.fromRGBO(227, 226, 233, 1),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : Text(
                                      tagString,
                                      style: TextStyle(
                                        fontSize: 15,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 5.0,
                                            color: CupertinoColors.black,
                                          ),
                                        ],
                                        color: Color.fromRGBO(227, 226, 233, 1),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              SizedBox(height: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(onTap: openContainer),
                ),
              ],
            ),
          ),
        );
      },
      openBuilder: (context, closeContainer) {
        if (type == "anime") {
          return AnimeDetailsPage(id: id);
        } else if (type == "manga") {
          return MangaDetailsPage(id: id);
        } else if (type == "character") {
          return CharacterDetailsPage(id: id);
        }
        return Placeholder();
      },
    );
  }
}
