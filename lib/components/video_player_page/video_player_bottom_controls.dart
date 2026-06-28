import 'package:flutter/material.dart';

class VideoPlayerBottomControls extends StatelessWidget {
  final String currentPositionText;
  final String totalDurationText;
  final bool isFullScreen;
  final Widget seekBar;
  final VoidCallback onSkip85Pressed;
  final VoidCallback onFullscreenPressed;

  const VideoPlayerBottomControls({
    super.key,
    required this.currentPositionText,
    required this.totalDurationText,
    required this.isFullScreen,
    required this.seekBar,
    required this.onSkip85Pressed,
    required this.onFullscreenPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              currentPositionText,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Expanded(child: seekBar),
            const SizedBox(width: 8),
            Text(
              totalDurationText,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: onSkip85Pressed,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+85s',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white,
              ),
              tooltip: 'Fullscreen',
              onPressed: onFullscreenPressed,
            ),
          ],
        ),
      ],
    );
  }
}
