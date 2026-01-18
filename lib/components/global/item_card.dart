import 'package:zenbu/pages/anime_details_page.dart';
import 'package:zenbu/pages/character_details_page.dart';
import 'package:zenbu/pages/manga_details_page.dart';
import 'package:zenbu/pages/staff_details_page.dart';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.title,
    this.state,
    required this.image,
    required this.id,
    required this.type,
  });
  final String? title;
  final String? state;
  final String? image;
  final int id;
  final String type;

  @override
  Widget build(BuildContext context) {
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
          child: Material(
            child: Ink(
              height: 260,
              width: 126.41,
              child: Column(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Ink.image(
                      image: NetworkImage(image as String),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      child: InkWell(onTap: openContainer),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  (state != null)
                      ? Text(
                          state as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w200),
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
        if (type == "anime") {
          return AnimeDetailsPage(id: id);
        } else if (type == "manga") {
          return MangaDetailsPage(id: id);
        } else if (type == "character") {
          return CharacterDetailsPage(id: id);
        } else if (type == "staff") {
          return StaffDetailsPage(id: id);
        }
        return Placeholder();
      },
    );
  }
}
