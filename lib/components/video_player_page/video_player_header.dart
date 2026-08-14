import 'package:flutter/material.dart';

class VideoPlayerHeader extends StatelessWidget implements PreferredSizeWidget {
  final String animeTitle;
  final String episodeName;
  final bool hasNextEpisode;
  final VoidCallback onBackPressed;
  final VoidCallback? onNextEpisodePressed;
  final VoidCallback onZoomPressed;
  final String zoomModeName;
  final VoidCallback onSettingsPressed;
  final VoidCallback onPipPressed;

  const VideoPlayerHeader({
    super.key,
    required this.animeTitle,
    required this.episodeName,
    required this.hasNextEpisode,
    required this.onBackPressed,
    required this.onNextEpisodePressed,
    required this.onZoomPressed,
    required this.zoomModeName,
    required this.onSettingsPressed,
    required this.onPipPressed,
  });

  IconData _getZoomIcon() {
    switch (zoomModeName.toLowerCase()) {
      case 'fill':
        return Icons.crop_free;
      case 'stretch':
        return Icons.fullscreen;
      case 'fit':
      default:
        return Icons.aspect_ratio;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBackPressed,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            animeTitle,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          Text(
            episodeName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white),
          tooltip: 'Picture in Picture',
          onPressed: onPipPressed,
        ),
        if (hasNextEpisode && onNextEpisodePressed != null)
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white),
            tooltip: 'Next Episode',
            onPressed: onNextEpisodePressed,
          ),
        IconButton(
          icon: Icon(_getZoomIcon(), color: Colors.white),
          tooltip: 'Zoom Mode ($zoomModeName)',
          onPressed: onZoomPressed,
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          tooltip: 'Settings',
          onPressed: onSettingsPressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
