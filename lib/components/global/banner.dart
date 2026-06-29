import 'dart:ui' as ui;
import 'package:zenbu/pages/media_details_page.dart';
import 'package:zenbu/pages/character_details_page.dart';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/components/global/custom_image.dart';

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
      openColor: Theme.of(context).colorScheme.surface,
      closedColor: Theme.of(context).colorScheme.surface,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      closedBuilder: (context, openContainer) {
        return Container(
          height: 240,
          width: double.infinity,
          margin: const EdgeInsets.only(top: 1, left: 10, right: 10, bottom: 5),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
            ),
            elevation: 3,
            surfaceTintColor: Theme.of(context).colorScheme.onSurface,
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(cardRadius),
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: CustomImage(
                        imageUrl: bannerImage,
                        fit: BoxFit.cover,
                        errorWidget: Container(),
                      ),
                    ),
                  ),
                ),
                Container(color: Colors.black.withValues(alpha: 0.4)),
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
                        child: Card(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                          elevation: 5,
                          clipBehavior: Clip.antiAlias,
                          child: CustomImage(
                            imageUrl: coverImage,
                            fit: BoxFit.cover,
                            borderRadius: const BorderRadius.all(Radius.circular(14)),
                            errorWidget: const Icon(Icons.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  shadows: [
                                    BoxShadow(
                                      blurRadius: 5.0,
                                      color: Colors.black,
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
                                      style: const TextStyle(
                                        fontSize: 15,
                                        shadows: [
                                          BoxShadow(
                                            blurRadius: 5.0,
                                            color: Colors.black,
                                          ),
                                        ],
                                        color: Color.fromRGBO(227, 226, 233, 1),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : Text(
                                      tagString,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        shadows: [
                                          BoxShadow(
                                            blurRadius: 5.0,
                                            color: Colors.black,
                                          ),
                                        ],
                                        color: Color.fromRGBO(227, 226, 233, 1),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              const SizedBox(height: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
        );
      },
      openBuilder: (context, closeContainer) {
        if (type == "anime") {
          return MediaDetailsPage(id: id, isAnime: true);
        } else if (type == "manga") {
          return MediaDetailsPage(id: id, isAnime: false);
        } else if (type == "character") {
          return CharacterDetailsPage(id: id);
        }
        return const Placeholder();
      },
    );
  }
}
