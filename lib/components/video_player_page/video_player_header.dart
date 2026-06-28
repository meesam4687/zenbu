import 'package:flutter/material.dart';

class VideoPlayerHeader extends StatelessWidget implements PreferredSizeWidget {
  final String animeTitle;
  final String episodeName;
  final bool isFullScreen;
  final bool hasNextEpisode;
  final bool hasSubtitles;
  final bool hasMultipleVideos;
  final bool isSubtitleActive;
  final VoidCallback onBackPressed;
  final VoidCallback? onNextEpisodePressed;
  final VoidCallback onSubtitlePressed;
  final VoidCallback onQualityPressed;
  final VoidCallback onPipPressed;

  const VideoPlayerHeader({
    super.key,
    required this.animeTitle,
    required this.episodeName,
    required this.isFullScreen,
    required this.hasNextEpisode,
    required this.hasSubtitles,
    required this.hasMultipleVideos,
    required this.isSubtitleActive,
    required this.onBackPressed,
    required this.onNextEpisodePressed,
    required this.onSubtitlePressed,
    required this.onQualityPressed,
    required this.onPipPressed,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

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
        if (hasSubtitles)
          IconButton(
            icon: Icon(
              Icons.closed_caption,
              color: isSubtitleActive ? primaryColor : Colors.white,
            ),
            tooltip: 'Subtitles',
            onPressed: onSubtitlePressed,
          ),
        if (hasMultipleVideos)
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Quality',
            onPressed: onQualityPressed,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
