import 'package:flutter/material.dart';

class VideoPlayerCenterControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPausePressed;
  final VoidCallback onReplayPressed;
  final VoidCallback onForwardPressed;

  const VideoPlayerCenterControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPausePressed,
    required this.onReplayPressed,
    required this.onForwardPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
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
      ),
    );
  }
}
