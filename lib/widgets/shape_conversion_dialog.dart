import 'dart:math';
import 'package:flutter/material.dart';
import '../models/canvas_objects/freehand_path.dart';
import '../services/shape_recognition_service.dart';

/// Dialog widget for shape conversion with preview
class ShapeConversionDialog extends StatelessWidget {
  final ShapeRecognitionResult recognitionResult;
  final FreehandPath originalPath;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const ShapeConversionDialog({
    Key? key,
    required this.recognitionResult,
    required this.originalPath,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shapeName = _getShapeName(recognitionResult.type);
    final confidencePercent = (recognitionResult.confidence * 100).toInt();

    return AlertDialog(
      title: const Text('Shape Detected!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Convert to $shapeName?'),
          const SizedBox(height: 16),
          
          // Preview comparison
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Original freehand path
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Original', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CustomPaint(
                      painter: PathPainter(
                        originalPath,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Arrow icon
              const Icon(Icons.arrow_forward, size: 24, color: Colors.blue),
              
              // Recognized shape preview
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(shapeName, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CustomPaint(
                      painter: ShapePreviewPainter(recognitionResult),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Confidence indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Confidence: $confidencePercent%'),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: recognitionResult.confidence,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  confidencePercent >= 70 
                    ? Colors.green 
                    : confidencePercent >= 50 
                      ? Colors.orange 
                      : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onReject,
          child: const Text('Keep Original'),
        ),
        ElevatedButton(
          onPressed: onAccept,
          child: Text('Convert to $shapeName'),
        ),
      ],
    );
  }

  String _getShapeName(RecognizedShape type) {
    switch (type) {
      case RecognizedShape.circle:
        return 'Circle';
      case RecognizedShape.rectangle:
        return 'Rectangle';
      case RecognizedShape.triangle:
        return 'Triangle';
      case RecognizedShape.unknown:
        return 'Unknown';
    }
  }
}

/// Custom painter for freehand path preview
class PathPainter extends CustomPainter {
  final FreehandPath path;

  PathPainter(this.path);

  @override
  void paint(Canvas canvas, Size size) {
    if (path.points.isEmpty) return;

    // Calculate scale to fit path in preview area
    final bounds = path.calculateBoundingRect();
    if (bounds.width == 0 || bounds.height == 0) return;

    final scale = 0.8 * min(
      size.width / bounds.width,
      size.height / bounds.height,
    );

    // Center the path in the preview area
    final offset = Offset(
      (size.width - bounds.width * scale) / 2 - bounds.left * scale,
      (size.height - bounds.height * scale) / 2 - bounds.top * scale,
    );

    final paint = Paint()
      ..color = path.strokeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = path.strokeWidth * scale;

    // Draw the path
    final previewPath = Path();
    if (path.points.isNotEmpty) {
      final firstPoint = path.points.first;
      previewPath.moveTo(
        (path.worldPosition.dx + firstPoint.dx) * scale + offset.dx,
        (path.worldPosition.dy + firstPoint.dy) * scale + offset.dy,
      );
      
      for (int i = 1; i < path.points.length; i++) {
        previewPath.lineTo(
          (path.worldPosition.dx + path.points[i].dx) * scale + offset.dx,
          (path.worldPosition.dy + path.points[i].dy) * scale + offset.dy,
        );
      }
    }

    canvas.drawPath(previewPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for recognized shape preview
class ShapePreviewPainter extends CustomPainter {
  final ShapeRecognitionResult result;

  ShapePreviewPainter(this.result);

  @override
  void paint(Canvas canvas, Size size) {
    // Use a default color if not provided
    final color = Colors.blue;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    switch (result.type) {
      case RecognizedShape.circle:
        if (result.center != null && result.radius != null) {
          final scale = _calculateScale(
            Rect.fromCircle(center: result.center!, radius: result.radius!),
            size,
          );
          final center = Offset(size.width / 2, size.height / 2);
          final radius = result.radius! * scale;
          
          canvas.drawCircle(center, radius, paint);
        }
        break;

      case RecognizedShape.rectangle:
        if (result.bounds != null) {
          final scale = _calculateScale(result.bounds!, size);
          final scaledBounds = Rect.fromLTWH(
            (size.width - result.bounds!.width * scale) / 2,
            (size.height - result.bounds!.height * scale) / 2,
            result.bounds!.width * scale,
            result.bounds!.height * scale,
          );
          
          canvas.drawRect(scaledBounds, paint);
        }
        break;

      case RecognizedShape.triangle:
        if (result.vertices != null && result.vertices!.length == 3) {
          final bounds = _calculateBounds(result.vertices!);
          final scale = _calculateScale(bounds, size);
          
          final path = Path();
          final first = result.vertices![0];
          final centerX = size.width / 2;
          final centerY = size.height / 2;
          final offsetX = centerX - bounds.center.dx * scale;
          final offsetY = centerY - bounds.center.dy * scale;
          
          path.moveTo(
            first.dx * scale + offsetX,
            first.dy * scale + offsetY,
          );
          for (int i = 1; i < result.vertices!.length; i++) {
            path.lineTo(
              result.vertices![i].dx * scale + offsetX,
              result.vertices![i].dy * scale + offsetY,
            );
          }
          path.close();
          
          canvas.drawPath(path, paint);
        }
        break;

      case RecognizedShape.unknown:
        break;
    }
  }

  double _calculateScale(Rect bounds, Size size) {
    if (bounds.width == 0 || bounds.height == 0) return 1.0;
    return 0.8 * min(
      size.width / bounds.width,
      size.height / bounds.height,
    );
  }

  Rect _calculateBounds(List<Offset> vertices) {
    if (vertices.isEmpty) return Rect.zero;
    
    double minX = vertices.first.dx;
    double minY = vertices.first.dy;
    double maxX = vertices.first.dx;
    double maxY = vertices.first.dy;

    for (final vertex in vertices) {
      minX = min(minX, vertex.dx);
      minY = min(minY, vertex.dy);
      maxX = max(maxX, vertex.dx);
      maxY = max(maxY, vertex.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

