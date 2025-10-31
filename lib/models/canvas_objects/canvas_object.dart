import 'package:flutter/material.dart';

enum ResizeHandle { 
  none, 
  topLeft, topCenter, topRight, 
  centerLeft, centerRight, 
  bottomLeft, bottomCenter, bottomRight, 
  top, bottom, left, right,
  // Connector handles - split into 4 equal parts
  connectorStart, connectorEnd, connectorFirstQuarter, connectorThirdQuarter
}

abstract class CanvasObject {
  String id;
  Offset worldPosition;
  Color strokeColor;
  Color? fillColor;
  double strokeWidth;
  bool isSelected;
  // Optional human-friendly label shown in UI lists
  String? label;
  Rect? _cachedBoundingRect;

  CanvasObject({
    required this.id,
    required this.worldPosition,
    required this.strokeColor,
    this.fillColor,
    this.strokeWidth = 2.0,
    this.isSelected = false,
    this.label,
  });

  void invalidateCache() => _cachedBoundingRect = null;

  Rect getBoundingRect() {
    _cachedBoundingRect ??= calculateBoundingRect();
    return _cachedBoundingRect!;
  }

  Rect calculateBoundingRect();
  bool hitTest(Offset worldPoint);
  void draw(Canvas canvas, Matrix4 worldToScreen);
  void move(Offset delta);
  void resize(ResizeHandle handle, Offset delta, Offset initialWorldPosition, Rect initialBounds);
  CanvasObject clone();

  void drawBoundingBox(Canvas canvas, Matrix4 worldToScreen) {
    final rect = getBoundingRect();
    if (rect == Rect.zero) return;

    final path = Path()..addRect(rect);
    final transformedPath = path.transform(worldToScreen.storage);
    final transformedRect = transformedPath.getBounds();

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(transformedRect, borderPaint);

    const handleSize = 8.0;
    final handlePaint = Paint()..color = Colors.blue..style = PaintingStyle.fill;

    final handles = {
      ResizeHandle.topLeft: transformedRect.topLeft,
      ResizeHandle.topCenter: transformedRect.topCenter,
      ResizeHandle.topRight: transformedRect.topRight,
      ResizeHandle.centerLeft: transformedRect.centerLeft,
      ResizeHandle.centerRight: transformedRect.centerRight,
      ResizeHandle.bottomLeft: transformedRect.bottomLeft,
      ResizeHandle.bottomCenter: transformedRect.bottomCenter,
      ResizeHandle.bottomRight: transformedRect.bottomRight,
    };

    for (final point in handles.values) {
      canvas.drawRect(
        Rect.fromCenter(center: point, width: handleSize, height: handleSize),
        handlePaint,
      );
    }
  }

  // Helper method to get display name for object type
  String getDisplayTypeName() {
    final typeName = runtimeType.toString();
    if (typeName == 'CanvasRectangle') return 'Rectangle';
    if (typeName == 'CanvasCircle') return 'Circle';
    if (typeName == 'StickyNote') return 'Sticky Note';
    if (typeName == 'Connector') return 'Connector';
    if (typeName == 'DocumentBlock') return 'Document';
    if (typeName == 'FreehandPath') return 'Drawing';
    return typeName;
  }
}