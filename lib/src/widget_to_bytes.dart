import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

Future<Uint8List> widgetToBytes({
  required Widget widget,
  Size logicalSize = const Size(120, 120),
  double devicePixelRatio = 3.0,
}) async {
  final repaintBoundary = RenderRepaintBoundary();
  final renderView = RenderView(
    view: PlatformDispatcher.instance.implicitView!,
    child: RenderPositionedBox(
      child: repaintBoundary,
    ),
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(logicalSize),
      devicePixelRatio: devicePixelRatio,
    ),
  );

  final pipelineOwner = PipelineOwner();
  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();

  final buildOwner = BuildOwner(focusManager: WidgetsBinding.instance.focusManager);
  final renderWidget = RenderObjectToWidgetAdapter<RenderBox>(
    container: repaintBoundary,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: SizedBox.fromSize(size: logicalSize, child: widget),
      ),
    ),
  ).attachToRenderTree(buildOwner);

  buildOwner.buildScope(renderWidget);
  buildOwner.finalizeTree();

  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();

  final image = await repaintBoundary.toImage(pixelRatio: devicePixelRatio);
  final byteData = await image.toByteData(format: ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
