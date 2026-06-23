import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:zenbu/pages/simulcasts_page.dart';

class SimulcastsButton extends StatefulWidget {
  const SimulcastsButton({super.key, required this.medias});
  final List medias;

  @override
  State<SimulcastsButton> createState() => _SimulcastsButtonState();
}

class _SimulcastsButtonState extends State<SimulcastsButton> {
  late String randomBanner;
  static String? _cachedBanner;

  @override
  void initState() {
    super.initState();
    if (_cachedBanner != null) {
      randomBanner = _cachedBanner!;
    } else {
      randomBanner = widget
          .medias[Random().nextInt(widget.medias.length)]["bannerImage"]
          .toString();
      _cachedBanner = randomBanner;
    }
  }

  @override
  void didUpdateWidget(SimulcastsButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.medias != widget.medias) {
      randomBanner = widget
          .medias[Random().nextInt(widget.medias.length)]["bannerImage"]
          .toString();
      _cachedBanner = randomBanner;
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
                  child: Image.network(
                    randomBanner,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(),
                  ),
                ),
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.4)),
            Container(
              margin: const EdgeInsets.all(10),
              height: 60,
              width: double.infinity,
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(padding: EdgeInsets.only(left: 10)),
                  Icon(
                    Icons.calendar_month,
                    shadows: [
                      Shadow(
                        blurRadius: 5.0,
                        color: Colors.black,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  Padding(padding: EdgeInsets.only(left: 10)),
                  Text(
                    "Simulcasts",
                    style: TextStyle(
                      fontSize: 17,
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
