import 'package:flutter/material.dart';

typedef CloseContainerBuilder =
    Widget Function(BuildContext context, VoidCallback openContainer);

typedef OpenContainerBuilder<T> =
    Widget Function(
      BuildContext context,
      void Function({T? returnValue}) closeContainer,
    );

class CustomOpenContainer<T> extends StatefulWidget {
  const CustomOpenContainer({
    super.key,
    required this.closedBuilder,
    required this.openBuilder,
    this.closedBorderRadius = 10.0,
    this.openBorderRadius = 0.0,
    this.closedElevation = 0.0,
    this.openElevation = 0.0,
    this.closedShape,
    this.transitionDuration = const Duration(milliseconds: 320),
    this.reverseTransitionDuration = const Duration(milliseconds: 260),
    this.closedColor,
    this.openColor,
    this.middleColor,
  });

  final CloseContainerBuilder closedBuilder;
  final OpenContainerBuilder<T> openBuilder;
  final double closedBorderRadius;
  final double openBorderRadius;
  final double closedElevation;
  final double openElevation;
  final ShapeBorder? closedShape;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final Color? closedColor;
  final Color? openColor;
  final Color? middleColor;

  @override
  State<CustomOpenContainer<T>> createState() => _CustomOpenContainerState<T>();
}

class _CustomOpenContainerState<T> extends State<CustomOpenContainer<T>> {
  final GlobalKey _cardKey = GlobalKey();

  void openContainer() {
    final RenderBox? cardBox =
        _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (cardBox == null || !cardBox.hasSize) return;

    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final Rect cardRect = MatrixUtils.transformRect(
      cardBox.getTransformTo(overlay),
      Offset.zero & cardBox.size,
    );

    final ThemeData theme = Theme.of(context);
    final Color effectiveClosedColor =
        widget.closedColor ?? theme.colorScheme.surface;
    final Color effectiveOpenColor =
        widget.openColor ?? theme.colorScheme.surface;
    final Color effectiveMiddleColor =
        widget.middleColor ?? theme.colorScheme.surface;

    double effectiveClosedRadius = widget.closedBorderRadius;
    if (widget.closedShape is RoundedRectangleBorder) {
      final borderRadius =
          (widget.closedShape as RoundedRectangleBorder).borderRadius;
      if (borderRadius is BorderRadius) {
        effectiveClosedRadius = borderRadius.topLeft.x;
      }
    }

    Navigator.of(context).push<T>(
      _CustomOpenContainerRoute<T>(
        cardRect: cardRect,
        screenSize: overlay.size,
        closedBuilder: widget.closedBuilder,
        openBuilder: widget.openBuilder,
        closedBorderRadius: effectiveClosedRadius,
        openBorderRadius: widget.openBorderRadius,
        closedElevation: widget.closedElevation,
        openElevation: widget.openElevation,
        transitionDuration: widget.transitionDuration,
        reverseTransitionDuration: widget.reverseTransitionDuration,
        closedColor: effectiveClosedColor,
        openColor: effectiveOpenColor,
        middleColor: effectiveMiddleColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.closedBuilder(context, openContainer);
    if (widget.closedColor != null ||
        widget.closedElevation > 0 ||
        widget.closedShape != null) {
      child = Material(
        color: widget.closedColor ?? Theme.of(context).colorScheme.surface,
        elevation: widget.closedElevation,
        shape:
            widget.closedShape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.closedBorderRadius),
            ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    }
    return Container(key: _cardKey, child: child);
  }
}

class _CustomOpenContainerRoute<T> extends PageRoute<T> {
  _CustomOpenContainerRoute({
    required this.cardRect,
    required this.screenSize,
    required this.closedBuilder,
    required this.openBuilder,
    required this.closedBorderRadius,
    required this.openBorderRadius,
    required this.closedElevation,
    required this.openElevation,
    required this.transitionDuration,
    required this.reverseTransitionDuration,
    required this.closedColor,
    required this.openColor,
    required this.middleColor,
  });

  final Rect cardRect;
  final Size screenSize;
  final CloseContainerBuilder closedBuilder;
  final OpenContainerBuilder<T> openBuilder;
  final double closedBorderRadius;
  final double openBorderRadius;
  final double closedElevation;
  final double openElevation;
  @override
  final Duration transitionDuration;
  @override
  final Duration reverseTransitionDuration;
  final Color closedColor;
  final Color openColor;
  final Color middleColor;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  void closeContainer({T? returnValue}) {
    Navigator.of(subtreeContext!).pop(returnValue);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return openBuilder(context, closeContainer);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (animation.isCompleted) {
      return child;
    }

    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn.flipped,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final double t = curved.value;

        final double left = cardRect.left + (0.0 - cardRect.left) * t;
        final double top = cardRect.top + (0.0 - cardRect.top) * t;
        final double width =
            cardRect.width + (screenSize.width - cardRect.width) * t;
        final double height =
            cardRect.height + (screenSize.height - cardRect.height) * t;
        final double radius =
            closedBorderRadius + (openBorderRadius - closedBorderRadius) * t;
        final double elevation =
            closedElevation + (openElevation - closedElevation) * t;

        final double closedOpacity = (1.0 - (t / 0.25)).clamp(0.0, 1.0);
        final double openOpacity = ((t - 0.2) / 0.8).clamp(0.0, 1.0);

        final Color containerBg;
        if (t <= 0.25) {
          containerBg =
              Color.lerp(closedColor, middleColor, t / 0.25) ?? closedColor;
        } else {
          containerBg =
              Color.lerp(middleColor, openColor, (t - 0.25) / 0.75) ??
              openColor;
        }

        final double scrimOpacity = (t * 0.4).clamp(0.0, 0.4);

        return Stack(
          children: [
            if (scrimOpacity > 0)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: scrimOpacity),
                ),
              ),
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: RepaintBoundary(
                child: Material(
                  color: containerBg,
                  elevation: elevation,
                  borderRadius: BorderRadius.circular(radius),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      if (closedOpacity > 0)
                        Positioned(
                          left: 0,
                          top: 0,
                          width: width,
                          height: height,
                          child: FittedBox(
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: cardRect.width,
                              height: cardRect.height,
                              child: Opacity(
                                opacity: closedOpacity,
                                child: IgnorePointer(
                                  child: closedBuilder(context, () {}),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (openOpacity > 0)
                        Positioned(
                          left: 0,
                          top: 0,
                          width: width,
                          height: height,
                          child: FittedBox(
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: screenSize.width,
                              height: screenSize.height,
                              child: Opacity(
                                opacity: openOpacity,
                                child: IgnorePointer(
                                  ignoring: !animation.isCompleted,
                                  child: child,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
