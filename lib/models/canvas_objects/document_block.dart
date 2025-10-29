import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'canvas_object.dart';
import '../documents/document_content.dart';
import '../../utils/logger.dart';

// Simple UUID generator for now
String generateUuid() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

enum DocumentViewMode {
  collapsed,  // Icon + title only
  preview,    // Thumbnail or first few blocks
  expanded,   // Full document rendering
}

class DocumentBlockStyle {
  final Color backgroundColor;
  final TextStyle titleStyle;
  final double borderRadius;
  final double padding;

  const DocumentBlockStyle({
    this.backgroundColor = Colors.white,
    this.titleStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    this.borderRadius = 8.0,
    this.padding = 16.0,
  });
}

class DocumentBlock extends CanvasObject {
  final String id;
  Offset worldPosition;
  Color strokeColor;
  double strokeWidth;
  Color? fillColor;
  bool isSelected;

  final String documentId;
  DocumentContent? content;
  DocumentViewMode viewMode;
  final Size size;
  final List<CanvasReference> canvasReferences;

  // Canvas-specific properties
  bool isExpanded;
  bool isEditing;
  DocumentBlockStyle style;

  // Cached rendering
  ui.Image? _cachedThumbnail;
  Path? _cachedPath;

  DocumentBlock({
    required this.id,
    required this.worldPosition,
    required this.strokeColor,
    this.strokeWidth = 1.0,
    this.fillColor = Colors.white,
    this.isSelected = false,
    required this.documentId,
    this.content,
    this.viewMode = DocumentViewMode.preview,
    List<CanvasReference>? canvasReferences,
    this.size = const Size(400, 300),
    this.isExpanded = false,
    this.isEditing = false,
    this.style = const DocumentBlockStyle(),
  }) : canvasReferences = canvasReferences ?? [],
        super(
          id: id,
          worldPosition: worldPosition,
          strokeColor: strokeColor,
          strokeWidth: strokeWidth,
          fillColor: fillColor,
          isSelected: isSelected,
        );

  @override
  Rect calculateBoundingRect() {
    return Rect.fromLTWH(
      worldPosition.dx,
      worldPosition.dy,
      size.width,
      size.height,
    );
  }

  @override
  bool hitTest(Offset worldPoint) {
    final bounds = calculateBoundingRect();
    final inflatedBounds = bounds.inflate(16); // Added inflation for easier selection
    final hit = inflatedBounds.contains(worldPoint);
    if (hit) {
      CanvasLogger.documentBlock('Hit test passed for DocumentBlock ${id} at point $worldPoint');
    }
    return hit;
  }

  @override
  void draw(Canvas canvas, Matrix4 worldToScreen) {
    final rect = calculateBoundingRect();

    CanvasLogger.documentBlock('Drawing DocumentBlock ${id} in mode: $viewMode, content blocks: ${content?.blocks.length ?? 0}');

    switch (viewMode) {
      case DocumentViewMode.collapsed:
        _drawCollapsed(canvas, rect, worldToScreen);
        break;
      case DocumentViewMode.preview:
        _drawPreview(canvas, rect, worldToScreen);
        break;
      case DocumentViewMode.expanded:
        _drawExpanded(canvas, rect, worldToScreen);
        break;
    }

    if (isEditing) {
      _drawEditingIndicator(canvas, rect);
    }
  }

  void _drawCollapsed(Canvas canvas, Rect rect, Matrix4 transform) {
    // Draw icon + title only
    final paint = Paint()
      ..color = style.backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(style.borderRadius)),
      paint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(style.borderRadius)),
      borderPaint,
    );

    // Draw title
    final title = content?.getTitle() ?? 'Untitled';
    final textPainter = TextPainter(
      text: TextSpan(text: title, style: style.titleStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: rect.width - 32);
    textPainter.paint(canvas, rect.topLeft + Offset(16, 16));
  }

  void _drawPreview(Canvas canvas, Rect rect, Matrix4 transform) {
    // Draw thumbnail if available, otherwise render first few blocks
    if (_cachedThumbnail != null) {
      paintImage(
        canvas: canvas,
        rect: rect,
        image: _cachedThumbnail!,
        fit: BoxFit.cover,
      );
    } else {
      _drawExpanded(canvas, rect, transform, maxBlocks: 3);
    }
  }

  void _drawExpanded(Canvas canvas, Rect rect, Matrix4 transform, {int? maxBlocks}) {
    CanvasLogger.documentBlock('Drawing expanded content for DocumentBlock ${id}');

    // Draw background
    final paint = Paint()
      ..color = style.backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(style.borderRadius)),
      paint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = isSelected ? Colors.red : strokeColor // Make selected blocks red for debugging
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(style.borderRadius)),
      borderPaint,
    );

    CanvasLogger.documentBlock('Drew border for DocumentBlock ${id}, selected: $isSelected');

    // Debug: Draw a small colored square in the top-right corner to confirm drawing
    final debugPaint = Paint()..color = Colors.purple;
    canvas.drawRect(Rect.fromLTWH(rect.right - 10, rect.top, 10, 10), debugPaint);

    // Render actual document blocks (simplified for now)
    if (content != null) {
      final blocksToRender = maxBlocks != null
          ? content!.blocks.take(maxBlocks).toList()
          : content!.blocks;

      CanvasLogger.documentBlock('Rendering ${blocksToRender.length} blocks');

      double offsetY = rect.top + style.padding;

      for (final block in blocksToRender) {
        final text = block.getPlainText();
        CanvasLogger.documentBlock('Block ${block.id}: "$text"');

        // Simplified block rendering - just draw text for now
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: const TextStyle(fontSize: 14, color: Colors.black)),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: rect.width - 32);

        final paintOffset = Offset(rect.left + 16, offsetY);
        CanvasLogger.documentBlock('Painting text at offset: $paintOffset, size: ${textPainter.size}');

        textPainter.paint(canvas, paintOffset);
        offsetY += textPainter.height + 8;

        if (offsetY > rect.bottom - style.padding) break;
      }
    } else {
      CanvasLogger.documentBlock('No content to render for DocumentBlock ${id}');
    }
  }

  void _drawEditingIndicator(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(style.borderRadius)),
      paint,
    );
  }

  @override
  void move(Offset delta) {
    worldPosition += delta;
    invalidateCache();
  }

  void resize(ResizeHandle handle, Offset delta, Offset initialWorldPosition, Rect initialBounds) {
    // Resize document block
    double newWidth = initialBounds.width;
    double newHeight = initialBounds.height;

    switch (handle) {
      case ResizeHandle.bottomRight:
        newWidth += delta.dx;
        newHeight += delta.dy;
        break;
      case ResizeHandle.bottomLeft:
        newWidth -= delta.dx;
        newHeight += delta.dy;
        break;
      case ResizeHandle.topRight:
        newWidth += delta.dx;
        newHeight -= delta.dy;
        break;
      case ResizeHandle.topLeft:
        newWidth -= delta.dx;
        newHeight -= delta.dy;
        break;
      case ResizeHandle.top:
        newHeight -= delta.dy;
        break;
      case ResizeHandle.bottom:
        newHeight += delta.dy;
        break;
      case ResizeHandle.left:
        newWidth -= delta.dx;
        break;
      case ResizeHandle.right:
        newWidth += delta.dx;
        break;
      default:
        // No resize for other handles
        break;
    }

    // Update size with constraints
    final newSize = Size(
      math.max(200.0, newWidth),
      math.max(150.0, newHeight),
    );

    // For now, we can't actually change the size since it's final
    // This would need to be updated when integrating with actual canvas
    invalidateCache();
  }

  DocumentBlock clone() {
    return DocumentBlock(
      id: '${id}_copy',
      worldPosition: worldPosition,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      fillColor: fillColor,
      documentId: documentId,
      content: content, // Shallow copy
      viewMode: viewMode,
      canvasReferences: List.from(canvasReferences),
      size: size,
      isExpanded: isExpanded,
      isEditing: isEditing,
      style: style,
    );
  }

  // Document-specific methods
  void enterEditMode() {
    isEditing = true;
    viewMode = DocumentViewMode.expanded;
  }

  void exitEditMode() {
    isEditing = false;
    viewMode = DocumentViewMode.preview;
  }

  void toggleExpanded() {
    isExpanded = !isExpanded;
    viewMode = isExpanded
        ? DocumentViewMode.expanded
        : DocumentViewMode.preview;
  }

  void addCanvasReference(dynamic object) {
    final ref = CanvasReference(
      id: generateUuid(),
      canvasObjectId: object.id,
      documentBlockId: documentId,
      type: ReferenceType.mention,
    );
    canvasReferences.add(ref);
  }

  void invalidateThumbnail() {
    _cachedThumbnail = null;
  }

  void invalidateCache() {
    _cachedThumbnail = null;
    _cachedPath = null;
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worldPosition': {'dx': worldPosition.dx, 'dy': worldPosition.dy},
      'strokeColor': strokeColor.value,
      'strokeWidth': strokeWidth,
      'fillColor': fillColor?.value,
      'isSelected': isSelected,
      'documentId': documentId,
      'viewMode': viewMode.toString(),
      'size': {'width': size.width, 'height': size.height},
      'canvasReferences': canvasReferences.map((ref) => ref.toJson()).toList(),
      'isExpanded': isExpanded,
      'isEditing': isEditing,
      'style': {
        'backgroundColor': style.backgroundColor.value,
        'titleStyle': {
          'fontSize': style.titleStyle.fontSize,
          'fontWeight': style.titleStyle.fontWeight?.index,
        },
        'borderRadius': style.borderRadius,
        'padding': style.padding,
      },
    };
  }

  factory DocumentBlock.fromJson(Map<String, dynamic> json) {
    final styleJson = json['style'] ?? {};
    final titleStyleJson = styleJson['titleStyle'] ?? {};

    return DocumentBlock(
      id: json['id'],
      worldPosition: Offset(json['worldPosition']['dx'], json['worldPosition']['dy']),
      strokeColor: Color(json['strokeColor']),
      strokeWidth: json['strokeWidth']?.toDouble() ?? 1.0,
      fillColor: json['fillColor'] != null ? Color(json['fillColor']) : Colors.white,
      documentId: json['documentId'],
      viewMode: DocumentViewMode.values.firstWhere(
        (mode) => mode.toString() == json['viewMode'],
        orElse: () => DocumentViewMode.preview,
      ),
      size: json['size'] != null
          ? Size(json['size']['width'].toDouble(), json['size']['height'].toDouble())
          : const Size(400, 300),
      canvasReferences: (json['canvasReferences'] as List?)
          ?.map((ref) => CanvasReference.fromJson(ref))
          .toList() ?? [],
      isExpanded: json['isExpanded'] ?? false,
      isEditing: json['isEditing'] ?? false,
      style: DocumentBlockStyle(
        backgroundColor: styleJson['backgroundColor'] != null
            ? Color(styleJson['backgroundColor'])
            : Colors.white,
        titleStyle: TextStyle(
          fontSize: titleStyleJson['fontSize']?.toDouble() ?? 18.0,
          fontWeight: titleStyleJson['fontWeight'] != null
              ? FontWeight.values[titleStyleJson['fontWeight']]
              : FontWeight.w600,
        ),
        borderRadius: styleJson['borderRadius']?.toDouble() ?? 8.0,
        padding: styleJson['padding']?.toDouble() ?? 16.0,
      ),
    );
  }
}