import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/bar_chart/bar_chart_helper.dart';
import 'package:fl_chart/src/chart/bar_chart/bar_chart_painter.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_painter.dart';
import 'package:fl_chart/src/chart/base/base_chart/render_base_chart.dart';
import 'package:fl_chart/src/utils/canvas_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

// coverage:ignore-start

/// Low level BarChart Widget.
class BarChartLeaf extends MultiChildRenderObjectWidget {
  BarChartLeaf({
    super.key,
    required this.data,
    required this.targetData,
    required this.canBeScaled,
    required this.chartVirtualRect,
  }) : super(children: targetData.barGroups.toWidgets());

  final BarChartData data;
  final BarChartData targetData;
  final Rect? chartVirtualRect;
  final bool canBeScaled;

  @override
  RenderBarChart createRenderObject(BuildContext context) => RenderBarChart(
        context,
        data,
        targetData,
        MediaQuery.of(context).textScaler,
        chartVirtualRect,
        canBeScaled: canBeScaled,
      );

  @override
  void updateRenderObject(BuildContext context, RenderBarChart renderObject) {
    renderObject
      ..data = data
      ..targetData = targetData
      ..textScaler = MediaQuery.of(context).textScaler
      ..buildContext = context
      ..chartVirtualRect = chartVirtualRect
      ..canBeScaled = canBeScaled;
  }
}
// coverage:ignore-end

/// Renders our BarChart, also handles hitTest.
class RenderBarChart extends RenderBaseChart<BarTouchResponse>
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  RenderBarChart(
    BuildContext context,
    BarChartData data,
    BarChartData targetData,
    TextScaler textScaler,
    Rect? chartVirtualRect, {
    required bool canBeScaled,
  })  : _data = data,
        _targetData = targetData,
        _textScaler = textScaler,
        _chartVirtualRect = chartVirtualRect,
        super(targetData.barTouchData, context, canBeScaled: canBeScaled);

  BarChartData get data => _data;
  BarChartData _data;

  set data(BarChartData value) {
    if (_data == value) return;
    _data = value;
    markNeedsPaint();
  }

  BarChartData get targetData => _targetData;
  BarChartData _targetData;

  set targetData(BarChartData value) {
    if (_targetData == value) return;
    _targetData = value;
    super.updateBaseTouchData(_targetData.barTouchData);
    markNeedsPaint();
  }

  TextScaler get textScaler => _textScaler;
  TextScaler _textScaler;

  set textScaler(TextScaler value) {
    if (_textScaler == value) return;
    _textScaler = value;
    markNeedsPaint();
  }

  Rect? get chartVirtualRect => _chartVirtualRect;
  Rect? _chartVirtualRect;

  set chartVirtualRect(Rect? value) {
    if (_chartVirtualRect == value) return;
    _chartVirtualRect = value;
    markNeedsPaint();
  }

  // We couldn't mock [size] property of this class, that's why we have this
  @visibleForTesting
  Size? mockTestSize;

  @visibleForTesting
  BarChartPainter painter = BarChartPainter();

  PaintHolder<BarChartData> get paintHolder =>
      PaintHolder(data, targetData, textScaler, chartVirtualRect);

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    painter.paint(
      buildContext,
      CanvasWrapper(canvas, mockTestSize ?? size),
      paintHolder,
    );
    canvas.restore();
    badgeWidgetPaint(context, offset);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  void performLayout() {
    var child = firstChild;
    size = computeDryLayout(constraints);

    final childConstraints = constraints.loosen();

    var counter = 0;
    final badgeOffsets = painter.getBadgeOffsets(
      mockTestSize ?? size,
      paintHolder,
    );
    while (child != null) {
      if (counter >= badgeOffsets.length) {
        break;
      }
      child.layout(
        childConstraints.copyWith(maxHeight: 1000),
        parentUsesSize: true,
      );
      final childParentData = child.parentData! as MultiChildLayoutParentData;
      final sizeOffset = Offset(
        child.size.width / 2,
        child.size.height,
      );
      final newOffset = (badgeOffsets[counter]!) - sizeOffset;
      childParentData.offset = Offset(
        newOffset.dx.clamp(-24, (size.width - child.size.width) + 24),
        newOffset.dy,
      );
      child = childParentData.nextSibling;
      counter++;
    }
  }

  void badgeWidgetPaint(PaintingContext context, Offset offset) {
    RenderObject? child = firstChild;
    var counter = 0;
    while (child != null) {
      final childParentData = child.parentData! as MultiChildLayoutParentData;
      if (data.barGroups.length > counter &&
          (data.barGroups[counter].barRods.firstOrNull?.toY ?? 0) > 0) {
        context.paintChild(child, childParentData.offset + offset);
      }
      child = childParentData.nextSibling;
      counter++;
    }
  }

  @override
  BarTouchResponse getResponseAtLocation(Offset localPosition) {
    final chartSize = mockTestSize ?? size;
    return BarTouchResponse(
      touchLocation: localPosition,
      touchChartCoordinate: painter.getChartCoordinateFromPixel(
        localPosition,
        chartSize,
        paintHolder,
      ),
      spot: painter.handleTouch(
        localPosition,
        chartSize,
        paintHolder,
      ),
    );
  }
}
