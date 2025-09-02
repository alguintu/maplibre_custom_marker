import 'package:flutter/widgets.dart';
import 'package:maplibre_custom_marker/src/widget_to_bytes.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class MapLibreCustomMarkerController {
  final MapLibreMapController _controller;

  MapLibreCustomMarkerController(this._controller);

  Future<void> upsertImageFromWidget({
    required String imageId,
    required Widget widget,
    Size logicalSize = const Size(120, 120),
    double devicePixelRatio = 3.0,
  }) async {
    final bytes = await widgetToBytes(
      widget: widget,
      logicalSize: logicalSize,
      devicePixelRatio: devicePixelRatio,
    );
    await _controller.addImage(imageId, bytes);
  }

  Future<Symbol> addMarker({
    required String imageId,
    required LatLng position,
    double? iconSize,
    String? text,
    Offset? textOffset,
    String? iconAnchor,
    bool draggable = false,
  }) {
    return _controller.addSymbol(SymbolOptions(
      geometry: position,
      iconImage: imageId,
      iconSize: iconSize,
      textField: text,
      textOffset: textOffset,
      iconAnchor: iconAnchor,
      draggable: draggable,
    ));
  }

  Future<void> remove(Symbol symbol) => _controller.removeSymbol(symbol);
}
