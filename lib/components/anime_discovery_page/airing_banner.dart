import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AiringBanner extends StatelessWidget {
  const AiringBanner({
    super.key,
    required this.bannerImage,
    required this.coverImage,
    required this.title,
    required this.totalEpisodes,
    required this.airedEpisodes,
    required this.tagString,
  });

  final String bannerImage;
  final String coverImage;
  final String title;
  final String totalEpisodes;
  final String airedEpisodes;
  final String tagString;

  @override
  Widget build(BuildContext context) {
    final double cardRadius = 15;
    return Container(
      height: 240,
      width: double.infinity,
      margin: EdgeInsets.all(10),
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
                  child: Image.network(
                    bannerImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(10),
              height: 240,
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 190,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      elevation: 5,
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        coverImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(title, style: TextStyle(fontSize: 28)),
                        Text(
                          "Episodes: $airedEpisodes/$totalEpisodes\n$tagString",
                          style: TextStyle(fontSize: 15),
                        ),
                        SizedBox(height: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: () {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
