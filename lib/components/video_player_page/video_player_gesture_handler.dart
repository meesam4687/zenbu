import 'dart:async';
import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

class VideoPlayerGestureHandler extends StatefulWidget {
  final bool isLeft;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback? onGestureTriggered;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  const VideoPlayerGestureHandler({
    super.key,
    required this.isLeft,
    required this.onTap,
    required this.onDoubleTap,
    this.onGestureTriggered,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  State<VideoPlayerGestureHandler> createState() =>
      _VideoPlayerGestureHandlerState();
}

class _VideoPlayerGestureHandlerState extends State<VideoPlayerGestureHandler>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  int _accumulatedSeconds = 0;
  Timer? _resetTimer;

  bool _showVerticalOverlay = false;
  double _currentValue = 0.5;
  double _initialValue = 0.5;
  double _dragStartPos = 0.0;
  Timer? _overlayFadeTimer;

  int _lastTapTime = 0;
  Timer? _singleTapTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _initValue();
  }

  Future<void> _initValue() async {
    try {
      if (widget.isLeft) {
        _currentValue = await ScreenBrightness.instance.application;
      } else {
        _currentValue = (await FlutterVolumeController.getVolume()) ?? 0.5;
        FlutterVolumeController.addListener((volume) {
          if (mounted && !_showVerticalOverlay) {
            setState(() {
              _currentValue = volume;
            });
          }
        });
        FlutterVolumeController.updateShowSystemUI(false);
      }
    } catch (_) {
      _currentValue = 0.5;
    }
  }

  void _handleTap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTapTime < 300) {
      _singleTapTimer?.cancel();
      _handleDoubleTap();
    } else {
      _singleTapTimer?.cancel();
      _singleTapTimer = Timer(const Duration(milliseconds: 300), () {
        widget.onTap();
      });
    }
    _lastTapTime = now;
  }

  void _handleDoubleTap() {
    setState(() {
      _accumulatedSeconds += 10;
    });

    widget.onDoubleTap();
    widget.onGestureTriggered?.call();

    _animationController.forward(from: 0.0);

    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _accumulatedSeconds = 0;
        });
      }
    });
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _overlayFadeTimer?.cancel();
    _dragStartPos = details.globalPosition.dy;
    setState(() {
      _initialValue = _currentValue;
      _showVerticalOverlay = true;
    });
    widget.onGestureTriggered?.call();
  }

  Future<void> _onVerticalDragUpdate(DragUpdateDetails details) async {
    final totalDeltaY = _dragStartPos - details.globalPosition.dy;
    const dragSensitivity = 250.0;
    final newValue = (_initialValue + totalDeltaY / dragSensitivity).clamp(
      0.0,
      1.0,
    );

    setState(() {
      _currentValue = newValue;
    });

    try {
      if (widget.isLeft) {
        await ScreenBrightness.instance.setApplicationScreenBrightness(
          newValue,
        );
      } else {
        await FlutterVolumeController.setVolume(
          newValue,
          stream: AudioStream.music,
        );
      }
    } catch (_) {}
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _overlayFadeTimer?.cancel();
    _overlayFadeTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showVerticalOverlay = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _resetTimer?.cancel();
    _overlayFadeTimer?.cancel();
    _singleTapTimer?.cancel();
    if (!widget.isLeft) {
      FlutterVolumeController.removeListener();
      FlutterVolumeController.updateShowSystemUI(true);
    } else {
      ScreenBrightness.instance.resetApplicationScreenBrightness();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onLongPressStart: (_) {
        widget.onLongPressStart?.call();
      },
      onLongPressEnd: (_) {
        widget.onLongPressEnd?.call();
      },
      onLongPressCancel: () {
        widget.onLongPressEnd?.call();
      },
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      onVerticalDragCancel: () => _onVerticalDragEnd(DragEndDetails()),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                if (_opacityAnimation.value == 0.0) {
                  return const SizedBox.shrink();
                }

                final primaryColor = Theme.of(context).colorScheme.primary;

                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 135,
                      height: 135,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.85),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.35),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isLeft
                                ? Icons.fast_rewind_rounded
                                : Icons.fast_forward_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 40,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isLeft
                                ? '- $_accumulatedSeconds seconds'
                                : '+ $_accumulatedSeconds seconds',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          IgnorePointer(
            ignoring: !_showVerticalOverlay,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showVerticalOverlay ? 1.0 : 0.0,
              child: Align(
                alignment: widget.isLeft
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: widget.isLeft ? 48.0 : 0.0,
                    right: widget.isLeft ? 0.0 : 48.0,
                  ),
                  child: Container(
                    width: 46,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      children: [
                        Icon(
                          widget.isLeft
                              ? Icons.brightness_5_rounded
                              : (_currentValue == 0.0
                                  ? Icons.volume_mute_rounded
                                  : _currentValue < 0.5
                                      ? Icons.volume_down_rounded
                                      : Icons.volume_up_rounded),
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 8,
                              color: Colors.white24,
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: _currentValue,
                                widthFactor: 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${(_currentValue * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
