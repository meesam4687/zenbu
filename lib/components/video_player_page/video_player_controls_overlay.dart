import 'package:flutter/material.dart';

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

  IconData _getZoomIcon() {
    switch (widget.zoomModeName.toLowerCase()) {
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
                  onLongPressStart: (_) => widget.onLongPressStart?.call(),
                  onLongPressEnd: (_) => widget.onLongPressEnd?.call(),
                  onLongPressCancel: () => widget.onLongPressEnd?.call(),
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
                    child: _buildHeader(),
                  ),
                ),
              ),

              _buildCenterControls(),

              Positioned(
                bottom: 16.0,
                left: 16.0,
                right: 16.0,
                child: Transform.translate(
                  offset: Offset(0, _bottomOffset.value),
                  child: Opacity(
                    opacity: _bottomOpacity.value,
                    child: _buildBottomControls(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: widget.onBackPressed,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.animeTitle,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          Text(
            widget.episodeName,
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
          onPressed: widget.onPipPressed,
        ),
        if (widget.hasNextEpisode)
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white),
            tooltip: 'Next Episode',
            onPressed: widget.onNextEpisodePressed,
          ),
        IconButton(
          icon: Icon(_getZoomIcon(), color: Colors.white),
          tooltip: 'Zoom Mode (${widget.zoomModeName})',
          onPressed: widget.onZoomPressed,
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          tooltip: 'Settings',
          onPressed: widget.onSettingsPressed,
        ),
      ],
    );
  }

  Widget _buildCenterControls() {
    return Center(
      child: Transform.scale(
        scale: _centerScale.value,
        child: Opacity(
          opacity: _centerOpacity.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 42,
                icon: const Icon(Icons.replay_10, color: Colors.white),
                onPressed: widget.onReplayPressed,
              ),
              const SizedBox(width: 32),
              IconButton(
                iconSize: 64,
                icon: Icon(
                  widget.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                ),
                onPressed: widget.onPlayPausePressed,
              ),
              const SizedBox(width: 32),
              IconButton(
                iconSize: 42,
                icon: const Icon(Icons.forward_10, color: Colors.white),
                onPressed: widget.onForwardPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              widget.currentPositionText,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Expanded(child: widget.seekBar),
            const SizedBox(width: 8),
            Text(
              widget.totalDurationText,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: widget.onSkip85Pressed,
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
              icon: const Icon(
                Icons.screen_rotation_rounded,
                color: Colors.white,
              ),
              tooltip: 'Rotate',
              onPressed: widget.onRotatePressed,
            ),
          ],
        ),
      ],
    );
  }
}
