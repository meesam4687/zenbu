import 'package:zenbu/pages/media_details_page.dart';
import 'package:zenbu/pages/character_details_page.dart';
import 'package:zenbu/pages/staff_details_page.dart';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:zenbu/components/global/custom_image.dart';

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
                    child: Stack(
                      children: [
                        CustomImage(
                          imageUrl: image as String,
                          height: 180,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  (state != null)
                      ? Text(
                          state as String,
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
        if (type == "anime") {
          return MediaDetailsPage(id: id, isAnime: true);
        } else if (type == "manga") {
          return MediaDetailsPage(id: id, isAnime: false);
        } else if (type == "character") {
          return CharacterDetailsPage(id: id);
        } else if (type == "staff") {
          return StaffDetailsPage(id: id);
        }
        return const Placeholder();
      },
    );
  }
}
