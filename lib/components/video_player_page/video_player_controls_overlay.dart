import 'package:flutter/material.dart';
import 'video_player_header.dart';
import 'video_player_center_controls.dart';
import 'video_player_bottom_controls.dart';

class VideoPlayerControlsOverlay extends StatefulWidget {
  final bool visible;
  final bool isHolding;
  final String animeTitle;
  final String episodeName;
  final bool hasNextEpisode;
  final bool isPlaying;
  final String currentPositionText;
  final String totalDurationText;
  final Widget seekBar;

  final VoidCallback onZoomPressed;
  final String zoomModeName;

  final VoidCallback onBackPressed;
  final VoidCallback onNextEpisodePressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onPipPressed;
  final VoidCallback onPlayPausePressed;
  final VoidCallback onReplayPressed;
  final VoidCallback onForwardPressed;
  final VoidCallback onSkip85Pressed;
  final VoidCallback onRotatePressed;
  final VoidCallback? onBackgroundTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  const VideoPlayerControlsOverlay({
    super.key,
    required this.visible,
    this.isHolding = false,
    required this.animeTitle,
    required this.episodeName,
    required this.hasNextEpisode,
    required this.isPlaying,
    required this.currentPositionText,
    required this.totalDurationText,
    required this.seekBar,
    required this.onZoomPressed,
    required this.zoomModeName,
    required this.onBackPressed,
    required this.onNextEpisodePressed,
    required this.onSettingsPressed,
    required this.onPipPressed,
    required this.onPlayPausePressed,
    required this.onReplayPressed,
    required this.onForwardPressed,
    required this.onSkip85Pressed,
    required this.onRotatePressed,
    this.onBackgroundTap,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  State<VideoPlayerControlsOverlay> createState() =>
      _VideoPlayerControlsOverlayState();
}

class _VideoPlayerControlsOverlayState extends State<VideoPlayerControlsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bgOpacity;
  late Animation<double> _centerScale;
  late Animation<double> _centerOpacity;
  late Animation<double> _topOffset;
  late Animation<double> _topOpacity;
  late Animation<double> _bottomOffset;
  late Animation<double> _bottomOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _bgOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _centerScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInBack,
      ),
    );

    _centerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.80, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ),
    );

    _topOffset = Tween<double>(begin: -40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _topOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ),
    );

    _bottomOffset = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _bottomOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ),
    );

    if (widget.visible) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(VideoPlayerControlsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.isDismissed && !widget.visible && !widget.isHolding) {
          return const SizedBox.shrink();
        }

        return IgnorePointer(
          ignoring: !widget.visible && !widget.isHolding,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.onBackgroundTap,
                  onLongPressStart: (_) {
                    widget.onLongPressStart?.call();
                  },
                  onLongPressEnd: (_) {
                    widget.onLongPressEnd?.call();
                  },
                  onLongPressCancel: () {
                    widget.onLongPressEnd?.call();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Opacity(
                    opacity: _bgOpacity.value,
                    child: Container(color: Colors.black45),
                  ),
                ),
              ),

              Positioned(
                top: 24.0,
                left: 8.0,
                right: 8.0,
                child: Transform.translate(
                  offset: Offset(0, _topOffset.value),
                  child: Opacity(
                    opacity: _topOpacity.value,
                    child: VideoPlayerHeader(
                      animeTitle: widget.animeTitle,
                      episodeName: widget.episodeName,
                      hasNextEpisode: widget.hasNextEpisode,
                      onBackPressed: widget.onBackPressed,
                      onNextEpisodePressed: widget.onNextEpisodePressed,
                      onZoomPressed: widget.onZoomPressed,
                      zoomModeName: widget.zoomModeName,
                      onSettingsPressed: widget.onSettingsPressed,
                      onPipPressed: widget.onPipPressed,
                    ),
                  ),
                ),
              ),

              VideoPlayerCenterControls(
                isPlaying: widget.isPlaying,
                onPlayPausePressed: widget.onPlayPausePressed,
                onReplayPressed: widget.onReplayPressed,
                onForwardPressed: widget.onForwardPressed,
                centerScale: _centerScale,
                centerOpacity: _centerOpacity,
              ),

              Positioned(
                bottom: 16.0,
                left: 16.0,
                right: 16.0,
                child: Transform.translate(
                  offset: Offset(0, _bottomOffset.value),
                  child: Opacity(
                    opacity: _bottomOpacity.value,
                    child: VideoPlayerBottomControls(
                      currentPositionText: widget.currentPositionText,
                      totalDurationText: widget.totalDurationText,
                      seekBar: widget.seekBar,
                      onSkip85Pressed: widget.onSkip85Pressed,
                      onRotatePressed: widget.onRotatePressed,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
