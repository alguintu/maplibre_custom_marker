import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_custom_marker/maplibre_custom_marker.dart';

enum MarkerShape { circle, pin, bubble }

class CircleMarkerOptions {
  final double? diameter;

  const CircleMarkerOptions({this.diameter});
}

class PinMarkerOptions {
  final Color pinDotColor;
  final double? diameter;

  const PinMarkerOptions({this.pinDotColor = Colors.white, this.diameter});
}

class BubbleMarkerOptions {
  final bool enableAnchorTriangle;
  final double anchorTriangleWidth;
  final double anchorTriangleHeight;
  final double cornerRadius;

  const BubbleMarkerOptions({
    this.enableAnchorTriangle = true,
    this.anchorTriangleWidth = 16,
    this.anchorTriangleHeight = 16,
    this.cornerRadius = 64,
  });
}

class PresetImageResult {
  final Uint8List bytes;

  /// MapLibre string: 'center' or 'bottom'
  final String iconAnchor;

  /// Pixel offset. Positive y pushes down.
  final Offset? iconOffset;

  const PresetImageResult({
    required this.bytes,
    required this.iconAnchor,
    this.iconOffset,
  });
}

class MapLibreCustomMarkerColor {
  static const Color markerRed = Color(0xFFCF2B2B);
  static const Color markerBlue = Color(0xFF61CFBE);
  static const Color markerPink = Color(0xFFCF27CF);
  static const Color markerGreen = Color(0xFF2BCF5A);
  static const Color markerBrown = Color(0xFF7A4242);
  static const Color markerYellow = Color(0xFFD1B634);
  static const Color markerGrey = Color(0xFF566F7A);
  static const Color markerShadow = Color(0x77000000);

  static const List<Color> markerColors = [
    markerGrey,
    markerBlue,
    markerPink,
    markerGreen,
    markerBrown,
    markerYellow,
    markerRed,
  ];
}

TextStyle _normalizeTextStyle({
  required double textSize,
  required Color textColor,
  TextStyle? textStyle,
}) {
  final base = textStyle ?? const TextStyle(fontWeight: FontWeight.bold);
  return base.copyWith(fontSize: textSize, color: textColor);
}

class _PresetPainter extends CustomPainter {
  _PresetPainter({
    required this.shape,
    required this.title,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.textStyle,
    required this.enableShadow,
    required this.shadowColor,
    required this.shadowBlur,
    required this.padding,
    required this.circle,
    required this.pin,
    required this.bubble,
    required this.textPainter,
    required this.bitmapSize,
  });

  final MarkerShape shape;
  final String? title;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color shadowColor;
  final TextStyle textStyle;
  final bool enableShadow;
  final double shadowBlur;
  final double padding;
  final CircleMarkerOptions circle;
  final PinMarkerOptions pin;
  final BubbleMarkerOptions bubble;
  final TextPainter textPainter;
  final Size bitmapSize;

  @override
  void paint(Canvas canvas, Size size) {
    final shadowSpace = enableShadow ? shadowBlur : 0.0;

    switch (shape) {
      case MarkerShape.circle:
        final diameter = circle.diameter ?? textPainter.width + padding;
        final radius = diameter / 2;
        final center = Offset(size.width / 2, size.height / 2);

        if (enableShadow) {
          final shadowPaint = Paint()
            ..color = shadowColor
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur / 2);
          canvas.drawCircle(center, radius, shadowPaint);
        }
        canvas.drawCircle(center, radius, Paint()..color = backgroundColor);

        textPainter.paint(
          canvas,
          Offset(
            (size.width - textPainter.width) / 2,
            (size.height - textPainter.height) / 2,
          ),
        );

      case MarkerShape.pin:
        final diameter = pin.diameter ?? textPainter.width + padding;
        final radius = diameter / 2;
        final pinHeight = radius;

        Path path() {
          final w = size.width;
          final arcCenter = Offset(w / 2, shadowSpace + diameter / 2);
          final p = Path()
            ..moveTo(shadowSpace, shadowSpace + diameter / 2)
            ..arcTo(
              Rect.fromCircle(center: arcCenter, radius: radius),
              -math.pi,
              math.pi,
              false,
            )
            ..quadraticBezierTo(
              w - shadowSpace,
              shadowSpace + diameter * 4 / 5,
              w / 2,
              shadowSpace + diameter + pinHeight,
            )
            ..quadraticBezierTo(
              shadowSpace,
              shadowSpace + diameter * 4 / 5,
              shadowSpace,
              shadowSpace + diameter / 2,
            )
            ..close();
          return p;
        }

        if (enableShadow) {
          final shadowPaint = Paint()
            ..color = shadowColor
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur / 2);
          canvas.drawPath(path(), shadowPaint);
        }
        canvas.drawPath(path(), Paint()..color = backgroundColor);

        if (title == null) {
          final dotR = radius * 0.4;
          canvas.drawCircle(
            Offset(size.width / 2, shadowSpace + radius),
            dotR,
            Paint()..color = pin.pinDotColor,
          );
        }

        textPainter.paint(
          canvas,
          Offset(
            (size.width - textPainter.width) / 2,
            shadowSpace + (diameter - textPainter.height) / 2,
          ),
        );

      case MarkerShape.bubble:
        final padH = padding;
        final padV = padding / 2;
        final bubbleWidth = textPainter.width + padH;
        final bubbleHeight = textPainter.height + padV;

        final rRect = RRect.fromLTRBAndCorners(
          shadowBlur,
          shadowBlur,
          shadowBlur + bubbleWidth,
          shadowBlur + bubbleHeight,
          bottomLeft: Radius.circular(bubble.cornerRadius),
          bottomRight: Radius.circular(bubble.cornerRadius),
          topLeft: Radius.circular(bubble.cornerRadius),
          topRight: Radius.circular(bubble.cornerRadius),
        );

        if (enableShadow) {
          final shadowPaint = Paint()
            ..color = shadowColor
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur / 2);
          canvas.drawRRect(rRect, shadowPaint);
        }
        canvas.drawRRect(rRect, Paint()..color = backgroundColor);

        if (bubble.enableAnchorTriangle) {
          final path = Path()
            ..moveTo(
              shadowBlur + bubbleWidth / 2 - bubble.anchorTriangleWidth / 2,
              shadowBlur + bubbleHeight,
            )
            ..lineTo(
              shadowBlur + bubbleWidth / 2,
              shadowBlur + bubbleHeight + bubble.anchorTriangleHeight,
            )
            ..lineTo(
              shadowBlur + bubbleWidth / 2 + bubble.anchorTriangleWidth / 2,
              shadowBlur + bubbleHeight,
            )
            ..close();
          canvas.drawPath(path, Paint()..color = backgroundColor);
        }

        textPainter.paint(
          canvas,
          Offset(shadowBlur + padH / 2, shadowBlur + padV / 2),
        );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<PresetImageResult> buildPresetMarkerBytes({
  required MarkerShape shape,
  String? title,
  Color backgroundColor = MapLibreCustomMarkerColor.markerRed,
  Color foregroundColor = Colors.white,
  double textSize = 20,
  bool enableShadow = true,
  Color shadowColor = MapLibreCustomMarkerColor.markerShadow,
  double shadowBlur = 8,
  double padding = 32,
  TextStyle? textStyle,
  double? imagePixelRatio, // DPR for rasterization
  CircleMarkerOptions? circleOptions,
  PinMarkerOptions? pinOptions,
  BubbleMarkerOptions? bubbleOptions,
}) async {
  final style = _normalizeTextStyle(
    textSize: textSize,
    textColor: foregroundColor,
    textStyle: textStyle,
  );

  final tp = TextPainter(
    text: TextSpan(style: style, text: title),
    textAlign: TextAlign.center,
    textDirection: ui.TextDirection.ltr,
  )..layout();

  final shadows = enableShadow ? shadowBlur : 0.0;
  circleOptions ??= const CircleMarkerOptions();
  pinOptions ??= const PinMarkerOptions();
  bubbleOptions ??= const BubbleMarkerOptions();

  late Size logicalSize;
  late String iconAnchor;
  Offset? iconOffset; // pixel offset

  switch (shape) {
    case MarkerShape.circle:
      {
        final diameter = circleOptions.diameter ?? tp.width + padding;
        final w = diameter + shadows * 2;
        final h = diameter + shadows * 2;
        logicalSize = Size(w, h);
        iconAnchor = 'center'; // (0.5, 0.5)
        break;
      }
    case MarkerShape.pin:
      {
        final diameter = pinOptions.diameter ?? tp.width + padding;
        final radius = diameter / 2;
        final pinHeight = radius;
        final w = diameter + shadows * 2;
        final h = diameter + shadows * 2 + pinHeight;
        logicalSize = Size(w, h);
        iconAnchor = 'bottom'; // match visual tip
        // tiny upward nudge so tip aligns exactly; optional:
        iconOffset = Offset.zero;
        break;
      }
    case MarkerShape.bubble:
      {
        final padH = padding;
        final padV = padding / 2;
        final bw = tp.width + padH;
        final bh = tp.height + padV;
        final extra = enableShadow ? shadows : 8.0;
        final triH = bubbleOptions.enableAnchorTriangle ? bubbleOptions.anchorTriangleHeight : 0.0;
        final w = bw + extra * 2;
        final h = bh + extra * 2 + triH;
        logicalSize = Size(w, h);
        iconAnchor = bubbleOptions.enableAnchorTriangle ? 'bottom' : 'center';
        iconOffset = Offset.zero;
        break;
      }
  }

  final painter = _PresetPainter(
    shape: shape,
    title: title,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    textStyle: style,
    enableShadow: enableShadow,
    shadowColor: shadowColor,
    shadowBlur: shadowBlur,
    padding: padding,
    circle: circleOptions,
    pin: pinOptions,
    bubble: bubbleOptions,
    textPainter: tp,
    bitmapSize: logicalSize,
  );

  final bytes = await widgetToBytes(
    widget: CustomPaint(size: logicalSize, painter: painter),
    logicalSize: logicalSize,
    devicePixelRatio: imagePixelRatio ?? 1.0,
  );

  return PresetImageResult(
    bytes: bytes,
    iconAnchor: iconAnchor,
    iconOffset: iconOffset,
  );
}
