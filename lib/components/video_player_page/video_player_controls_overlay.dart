import 'package:flutter/material.dart';
import 'video_player_header.dart';
import 'video_player_center_controls.dart';
import 'video_player_bottom_controls.dart';

class VideoPlayerControlsOverlay extends StatelessWidget {
  final String animeTitle;
  final String episodeName;
  final bool isFullScreen;
  final bool hasNextEpisode;
  final bool hasSubtitles;
  final bool hasMultipleVideos;
  final bool isSubtitleActive;
  final bool isPlaying;
  final String currentPositionText;
  final String totalDurationText;
  final Widget seekBar;

  final VoidCallback onBackPressed;
  final VoidCallback onNextEpisodePressed;
  final VoidCallback onSubtitlePressed;
  final VoidCallback onQualityPressed;
  final VoidCallback onPipPressed;
  final VoidCallback onPlayPausePressed;
  final VoidCallback onReplayPressed;
  final VoidCallback onForwardPressed;
  final VoidCallback onSkip85Pressed;
  final VoidCallback onFullscreenPressed;

  const VideoPlayerControlsOverlay({
    super.key,
    required this.animeTitle,
    required this.episodeName,
    required this.isFullScreen,
    required this.hasNextEpisode,
    required this.hasSubtitles,
    required this.hasMultipleVideos,
    required this.isSubtitleActive,
    required this.isPlaying,
    required this.currentPositionText,
    required this.totalDurationText,
    required this.seekBar,
    required this.onBackPressed,
    required this.onNextEpisodePressed,
    required this.onSubtitlePressed,
    required this.onQualityPressed,
    required this.onPipPressed,
    required this.onPlayPausePressed,
    required this.onReplayPressed,
    required this.onForwardPressed,
    required this.onSkip85Pressed,
    required this.onFullscreenPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(child: Container(color: Colors.black45)),
        ),

        Positioned(
          top: isFullScreen ? 24.0 : 0.0,
          left: 8.0,
          right: 8.0,
          child: VideoPlayerHeader(
            animeTitle: animeTitle,
            episodeName: episodeName,
            isFullScreen: isFullScreen,
            hasNextEpisode: hasNextEpisode,
            hasSubtitles: hasSubtitles,
            hasMultipleVideos: hasMultipleVideos,
            isSubtitleActive: isSubtitleActive,
            onBackPressed: onBackPressed,
            onNextEpisodePressed: onNextEpisodePressed,
            onSubtitlePressed: onSubtitlePressed,
            onQualityPressed: onQualityPressed,
            onPipPressed: onPipPressed,
          ),
        ),

        VideoPlayerCenterControls(
          isPlaying: isPlaying,
          onPlayPausePressed: onPlayPausePressed,
          onReplayPressed: onReplayPressed,
          onForwardPressed: onForwardPressed,
        ),

        Positioned(
          bottom: isFullScreen ? 16.0 : 8.0,
          left: 16.0,
          right: 16.0,
          child: VideoPlayerBottomControls(
            currentPositionText: currentPositionText,
            totalDurationText: totalDurationText,
            isFullScreen: isFullScreen,
            seekBar: seekBar,
            onSkip85Pressed: onSkip85Pressed,
            onFullscreenPressed: onFullscreenPressed,
          ),
        ),
      ],
    );
  }
}
