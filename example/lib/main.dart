import 'package:flutter/material.dart';
import 'package:maplibre_custom_marker/maplibre_custom_marker.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DemoMapPage(),
    );
  }
}

class DemoMapPage extends StatefulWidget {
  const DemoMapPage({super.key});

  @override
  State<DemoMapPage> createState() => _DemoMapPageState();
}

class _DemoMapPageState extends State<DemoMapPage> {
  static const _center = LatLng(10.2071192, 118.8386443);

  MapLibreMapController? mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapLibreMap(
        initialCameraPosition: const CameraPosition(
          target: _center,
          zoom: 4.5,
        ),
        onMapCreated: (controller) => mapController = controller,
        onStyleLoadedCallback: _renderDemo,
      ),
    );
  }

  Future<void> _renderDemo() async {
    if (mapController == null) return;

    Future<void> addPreset({
      required String id,
      required MarkerShape shape,
      required LatLng at,
      String? title,
      Color background = MapLibreCustomMarkerColor.markerRed,
      Color foreground = Colors.white,
      double textSize = 20,
      bool enableShadow = true,
      Color shadowColor = MapLibreCustomMarkerColor.markerShadow,
      double shadowBlur = 8,
      double padding = 32,
      double? imagePixelRatio,
      CircleMarkerOptions? circle,
      PinMarkerOptions? pin,
      BubbleMarkerOptions? bubble,
      double iconSize = 1.0,
      Offset? textOffset,
    }) async {
      final preset = await buildPresetMarkerBytes(
        shape: shape,
        title: title,
        backgroundColor: background,
        foregroundColor: foreground,
        textSize: textSize,
        enableShadow: enableShadow,
        shadowColor: shadowColor,
        shadowBlur: shadowBlur,
        padding: padding,
        imagePixelRatio: imagePixelRatio ?? 2.0,
        circleOptions: circle,
        pinOptions: pin,
        bubbleOptions: bubble,
      );

      await mapController!.addImage(id, preset.bytes);
      await mapController!.addSymbol(SymbolOptions(
        geometry: at,
        iconImage: id,
        iconAnchor: preset.iconAnchor,
        iconOffset: preset.iconOffset,
        iconSize: iconSize,
        textOffset: textOffset,
      ));
    }

    LatLng spread(LatLng base, {required double dx, double dy = 0}) => LatLng(base.latitude + dy, base.longitude + dx);

    const rowGap = 2.0; // longitude step
    const dy = 4.0; // latitude step between rows

    // Pin with circle dots, varying sizes
    const pinRowBase = _center;
    for (var i = 0; i < 5; i++) {
      await addPreset(
        id: 'pin_$i',
        shape: MarkerShape.pin,
        at: spread(pinRowBase, dx: (i - 2) * rowGap, dy: -dy * 1.0),
        pin: PinMarkerOptions(diameter: 32 + i * 8),
      );
    }

    // Circles with numbers 1..6 and palette colors ---
    const colors = MapLibreCustomMarkerColor.markerColors;
    final circleRowBase = spread(_center, dx: 0, dy: -dy * 2);
    for (var i = 0; i < 6; i++) {
      await addPreset(
        id: 'circle_${i + 1}',
        shape: MarkerShape.circle,
        at: spread(circleRowBase, dx: (i - 2.5) * rowGap),
        title: '${i + 1}',
        background: colors[(i + 1) % colors.length],
        circle: const CircleMarkerOptions(),
        textSize: 24,
        padding: 40,
      );
    }

    // Pin with titles 1..3 (colored)
    final pinLabeledRowBase = spread(_center, dx: 0, dy: dy * 0.9);
    for (var i = 0; i < 3; i++) {
      await addPreset(
        id: 'pin_lbl_$i',
        shape: MarkerShape.pin,
        at: spread(pinLabeledRowBase, dx: (i - 1) * rowGap),
        title: '${i + 1}',
        background: colors[(i + 3) % colors.length],
        textSize: 22,
        padding: 40,
        pin: const PinMarkerOptions(diameter: 72),
      );
    }

    // Bubble WITHOUT anchor triangle
    await addPreset(
      id: 'bubble_no_triangle',
      shape: MarkerShape.bubble,
      at: spread(_center, dx: 0, dy: dy * 2.0),
      title: 'Bubble without Anchor Triangle',
      background: MapLibreCustomMarkerColor.markerGrey,
      textSize: 22,
      padding: 48,
      bubble: const BubbleMarkerOptions(
        enableAnchorTriangle: false,
        cornerRadius: 24,
      ),
    );

    // "Hello World!" bubble centered
    await addPreset(
      id: 'bubble_hello',
      shape: MarkerShape.bubble,
      at: spread(_center, dx: 0),
      title: 'Hello World!',
      textSize: 22,
      padding: 48,
      bubble: const BubbleMarkerOptions(
        anchorTriangleWidth: 20,
        cornerRadius: 24,
      ),
    );

    // Big "Customize Me!" bubble
    await addPreset(
      id: 'bubble_customize',
      shape: MarkerShape.bubble,
      at: spread(_center, dx: 0, dy: dy * 2.2),
      title: 'Customize Me!',
      background: const Color(0xFFF2CC55),
      foreground: Colors.black87,
      textSize: 36,
      padding: 96,
      bubble: const BubbleMarkerOptions(
        anchorTriangleWidth: 36,
        anchorTriangleHeight: 28,
        cornerRadius: 40,
      ),
      iconSize: 0.9,
    );
  }
}
