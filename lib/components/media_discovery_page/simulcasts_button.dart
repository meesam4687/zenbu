import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:zenbu/l10n/l10n_extension.dart';
import 'package:zenbu/pages/simulcasts_page.dart';
import 'package:zenbu/components/global/custom_image.dart';

class SimulcastsButton extends StatefulWidget {
  const SimulcastsButton({super.key, required this.medias});
  final List medias;

  @override
  State<SimulcastsButton> createState() => _SimulcastsButtonState();
}

class _SimulcastsButtonState extends State<SimulcastsButton> {
  late String randomBanner;
  static String? _cachedBanner;

  String _selectBanner(List medias) {
    if (medias.isEmpty) return '';

    final validBanners = medias
        .map((m) => m["bannerImage"]?.toString())
        .where((b) => b != null && b.trim().isNotEmpty && b != 'null')
        .cast<String>()
        .toList();

    if (validBanners.isNotEmpty) {
      return validBanners[Random().nextInt(validBanners.length)];
    }

    final validCovers = medias
        .map(
          (m) =>
              m["coverImage"]?["large"]?.toString() ??
              m["coverImage"]?["medium"]?.toString(),
        )
        .where((c) => c != null && c.trim().isNotEmpty && c != 'null')
        .cast<String>()
        .toList();

    if (validCovers.isNotEmpty) {
      return validCovers[Random().nextInt(validCovers.length)];
    }

    return '';
  }

  @override
  void initState() {
    super.initState();
    if (_cachedBanner != null &&
        _cachedBanner!.trim().isNotEmpty &&
        _cachedBanner != 'null') {
      randomBanner = _cachedBanner!;
    } else {
      randomBanner = _selectBanner(widget.medias);
      if (randomBanner.isNotEmpty) {
        _cachedBanner = randomBanner;
      }
    }
  }

  @override
  void didUpdateWidget(SimulcastsButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.medias != widget.medias ||
        randomBanner.trim().isEmpty ||
        randomBanner == 'null') {
      final newBanner = _selectBanner(widget.medias);
      if (newBanner.isNotEmpty) {
        randomBanner = newBanner;
        _cachedBanner = newBanner;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 0, top: 0),
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        elevation: 3,
        surfaceTintColor: Theme.of(context).colorScheme.onSurface,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: CustomImage(
                    imageUrl: randomBanner,
                    fit: BoxFit.cover,
                    errorWidget: Container(),
                  ),
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
                  const Icon(
                    color: Colors.white,
                    Icons.calendar_month,
                    shadows: [
                      Shadow(
                        blurRadius: 5.0,
                        color: Colors.black,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.only(left: 10)),
                  Text(
                    context.l10n.simulcasts,
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
                  Spacer(),
                  Icon(
                    color: Colors.white,
                    Icons.arrow_forward,
                    shadows: [
                      Shadow(
                        blurRadius: 5.0,
                        color: Colors.black,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  Padding(padding: EdgeInsets.only(right: 10)),
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
                          return const SimulcastsPage();
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
