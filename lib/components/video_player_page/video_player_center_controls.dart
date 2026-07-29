import 'package:flutter/material.dart';

class VideoPlayerCenterControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPausePressed;
  final VoidCallback onReplayPressed;
  final VoidCallback onForwardPressed;
  final Animation<double>? centerScale;
  final Animation<double>? centerOpacity;

  const VideoPlayerCenterControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPausePressed,
    required this.onReplayPressed,
    required this.onForwardPressed,
    this.centerScale,
    this.centerOpacity,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 42,
          icon: const Icon(Icons.replay_10, color: Colors.white),
          onPressed: onReplayPressed,
        ),
        const SizedBox(width: 32),
        IconButton(
          iconSize: 64,
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: Colors.white,
          ),
          onPressed: onPlayPausePressed,
        ),
        const SizedBox(width: 32),
        IconButton(
          iconSize: 42,
          icon: const Icon(Icons.forward_10, color: Colors.white),
          onPressed: onForwardPressed,
        ),
      ],
    );

    if (centerScale != null) {
      content = Transform.scale(
        scale: centerScale!.value,
        child: Opacity(opacity: centerOpacity?.value ?? 1.0, child: content),
      );
    }

    return Center(child: content);
  }
}
