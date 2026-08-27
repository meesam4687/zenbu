import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:zenbu/components/global/custom_image.dart';
import 'package:zenbu/components/global/shimmer_placeholder.dart';
import 'package:zenbu/pages/list_page.dart';
import 'package:zenbu/services/anilist/anilist.dart';

class ProfileListButton extends StatefulWidget {
  final int userId;
  final String username;
  final bool isAnime;

  const ProfileListButton({
    super.key,
    required this.userId,
    required this.username,
    required this.isAnime,
  });

  @override
  State<ProfileListButton> createState() => _ProfileListButtonState();
}

class _ProfileListButtonState extends State<ProfileListButton> {
  String? _bannerImage;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  @override
  void didUpdateWidget(ProfileListButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.isAnime != widget.isAnime) {
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    try {
      final listData = await getMediaLists(userId: widget.userId);
      final listKey = widget.isAnime ? "animeList" : "mangaList";
      final lists = listData["data"]?[listKey]?["lists"] as List? ?? [];
      final List<String> userBanners = [];

      for (final l in lists) {
        final entries = l["entries"] as List? ?? [];
        for (final entry in entries) {
          final banner = entry["media"]?["bannerImage"] as String?;
          if (banner != null && banner.isNotEmpty) {
            userBanners.add(banner);
          }
        }
      }

      if (userBanners.isNotEmpty) {
        if (mounted) {
          setState(() {
            _bannerImage = userBanners[Random().nextInt(userBanners.length)];
          });
        }
        return;
      }
    } catch (_) {}

    try {
      final trendingData = widget.isAnime
          ? await getTrendingAnime(1, 20)
          : await getTrendingManga(1, 20);
      final mediaList = trendingData["data"]?["list"]?["media"] as List? ?? [];
      final List<String> trendingBanners = [];

      for (final m in mediaList) {
        final banner = m["bannerImage"] as String?;
        if (banner != null && banner.isNotEmpty) {
          trendingBanners.add(banner);
        }
      }

      if (mounted) {
        setState(() {
          if (trendingBanners.isNotEmpty) {
            _bannerImage =
                trendingBanners[Random().nextInt(trendingBanners.length)];
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isAnime ? "Anime List" : "Manga List";
    final iconData = widget.isAnime ? Icons.tv : Icons.menu_book;

    return SizedBox(
      height: 60,
      width: double.infinity,
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        elevation: 3,
        surfaceTintColor: Theme.of(context).colorScheme.onSurface,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: (_bannerImage != null && _bannerImage!.isNotEmpty)
                    ? ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: 15,
                          sigmaY: 15,
                        ),
                        child: CustomImage(
                          imageUrl: _bannerImage!,
                          fit: BoxFit.cover,
                          errorWidget: const ShimmerPlaceholder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                      )
                    : const ShimmerPlaceholder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.4)),
            Container(
              margin: const EdgeInsets.all(10),
              height: 60,
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(padding: EdgeInsets.only(left: 10)),
                  Icon(
                    iconData,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 5.0,
                        color: Colors.black,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.only(left: 10)),
                  Text(
                    titleText,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 5.0,
                          color: Colors.black,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 5.0,
                        color: Colors.black,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.only(right: 10)),
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return ListPage(
                            title:
                                "${widget.username}'s ${widget.isAnime ? 'Anime' : 'Manga'} List",
                            mediaListType: widget.isAnime
                                ? MediaType.anime
                                : MediaType.manga,
                            userId: widget.userId,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
