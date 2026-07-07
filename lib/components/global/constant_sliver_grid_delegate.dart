import 'package:flutter/rendering.dart';

class ConstantSliverGridDelegate extends SliverGridDelegate {
  final double itemWidth;
  final double itemHeight;

  const ConstantSliverGridDelegate({
    required this.itemWidth,
    required this.itemHeight,
  });

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final double usableWidth = constraints.crossAxisExtent;
    final int crossAxisCount = (usableWidth / itemWidth).floor().clamp(1, 999);
    final double cellWidth = usableWidth / crossAxisCount;
    
    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: itemHeight,
      crossAxisStride: cellWidth,
      childMainAxisExtent: itemHeight,
      childCrossAxisExtent: cellWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(ConstantSliverGridDelegate oldDelegate) {
    return oldDelegate.itemWidth != itemWidth ||
        oldDelegate.itemHeight != itemHeight;
  }
}
