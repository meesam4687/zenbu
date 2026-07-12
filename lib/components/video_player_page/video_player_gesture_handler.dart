import 'dart:async';
import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

class VideoPlayerGestureHandler extends StatefulWidget {
  final bool isLeft;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback? onGestureTriggered;

  const VideoPlayerGestureHandler({
    super.key,
    required this.isLeft,
    required this.onTap,
    required this.onDoubleTap,
    this.onGestureTriggered,
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
      duration: const Duration(milliseconds: 530),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 0.965,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 19,
      ),
      TweenSequenceItem(tween: Tween(begin: 0.965, end: 1.0), weight: 57),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 24,
      ),
    ]).animate(_animationController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 9),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 72),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 19),
    ]).animate(_animationController);

    _initCurrentValues();

    if (!widget.isLeft) {
      FlutterVolumeController.updateShowSystemUI(false);
      FlutterVolumeController.addListener((volume) {
        if (mounted && !_showVerticalOverlay) {
          setState(() {
            _currentValue = volume;
          });
        }
      });
    }
  }

  Future<void> _initCurrentValues() async {
    try {
      double val;
      if (widget.isLeft) {
        val = await ScreenBrightness.instance.application;
      } else {
        val =
            await FlutterVolumeController.getVolume(
              stream: AudioStream.music,
            ) ??
            0.5;
      }
      if (mounted) {
        setState(() {
          _currentValue = val;
        });
      }
    } catch (_) {}
  }

  void _handleTap() {
    _singleTapTimer?.cancel();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTapTime < 200) {
      _onDoubleTap();
      _lastTapTime = 0;
    } else {
      _lastTapTime = now;
      _singleTapTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          widget.onTap();
        }
      });
    }
  }

  void _onDoubleTap() {
    _resetTimer?.cancel();
    setState(() {
      _accumulatedSeconds += 10;
    });
    widget.onDoubleTap();
    _animationController.forward(from: 0.0);
    widget.onGestureTriggered?.call();

    _resetTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _accumulatedSeconds = 0;
        });
      }
    });
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _overlayFadeTimer?.cancel();
    setState(() {
      _dragStartPos = details.globalPosition.dy;
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

                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.5),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isLeft
                                ? Icons.fast_rewind_rounded
                                : Icons.fast_forward_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isLeft
                                ? '- $_accumulatedSeconds seconds'
                                : '+ $_accumulatedSeconds seconds',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
          if (_showVerticalOverlay)
            Align(
              alignment: widget.isLeft
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(
                  left: widget.isLeft ? 56.0 : 0.0,
                  right: widget.isLeft ? 0.0 : 56.0,
                ),
                child: Container(
                  width: 36,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                        size: 20,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            width: 6,
                            color: Colors.white24,
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: _currentValue,
                              widthFactor: 1.0,
                              child: Container(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(_currentValue * 100).toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
