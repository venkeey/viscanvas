import 'package:flutter/material.dart';
import '../../domain/canvas_domain.dart';
import '../../utils/logger.dart';

class CanvasTransformService {
  Transform2D _transform = Transform2D(translation: Offset.zero, scale: 1.0);

  // ===== PUBLIC API =====

  Transform2D get transform => _transform;

  void updateTransform(Transform2D newTransform) {
    _transform = newTransform;
    CanvasLogger.canvasService('updateTransform translation=${_transform.translation} scale=${_transform.scale}');
  }

  void updateTransformWithPanAndScale(Offset pan, double newScale) {
    _transform = Transform2D(
      translation: pan,
      scale: newScale.clamp(0.1, 10.0),
    );
    CanvasLogger.canvasService('updateTransformWithPanAndScale pan=$pan scale=${_transform.scale}');
  }

  void panBy(Offset delta) {
    _transform = _transform.copyWith(translation: _transform.translation + delta);
    CanvasLogger.canvasService('panBy delta=$delta -> translation=${_transform.translation}');
  }

  void scaleBy(double scaleFactor, Offset focalPoint) {
    final newScale = (_transform.scale * scaleFactor).clamp(0.1, 10.0);
    _transform = _transform.copyWith(scale: newScale);
    CanvasLogger.canvasService('scaleBy factor=$scaleFactor focal=$focalPoint -> scale=${_transform.scale}');
  }

  void reset() {
    _transform = Transform2D(translation: Offset.zero, scale: 1.0);
    CanvasLogger.canvasService('reset transform to identity');
  }

  void dispose() {
    // Cleanup if needed
  }
}
