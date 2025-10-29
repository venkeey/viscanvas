import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/hybrid_canvas_document_bridge.dart';
import '../models/documents/document_content.dart';

/// Implementation of CrossReferenceManager for managing references between canvas and documents
class CrossReferenceManagerImpl implements CrossReferenceManager {
  final List<CanvasReference> _references = [];
  final StreamController<ReferenceEvent> _eventController = StreamController<ReferenceEvent>.broadcast();

  @override
  List<CanvasReference> get references => List.unmodifiable(_references);

  @override
  Stream<ReferenceEvent> get events => _eventController.stream;

  @override
  CanvasReference create(String canvasObjectId, String documentBlockId) {
    // Determine reference type based on context
    final type = ReferenceType.mention; // Default to mention

    final reference = CanvasReference(
      id: 'ref_${DateTime.now().millisecondsSinceEpoch}',
      canvasObjectId: canvasObjectId,
      documentBlockId: documentBlockId,
      type: type,
    );

    _references.add(reference);
    _eventController.add(ReferenceEvent(reference.id, ReferenceEventType.referenceCreated));

    return reference;
  }

  @override
  void remove(String referenceId) {
    final index = _references.indexWhere((ref) => ref.id == referenceId);
    if (index != -1) {
      _references.removeAt(index);
      _eventController.add(ReferenceEvent(referenceId, ReferenceEventType.referenceRemoved));
    }
  }

  @override
  List<CanvasReference> findByCanvasObject(String canvasObjectId) {
    return _references.where((ref) => ref.canvasObjectId == canvasObjectId).toList();
  }

  @override
  List<CanvasReference> findByDocument(String documentId) {
    return _references.where((ref) => ref.documentBlockId.startsWith(documentId)).toList();
  }

  @override
  bool validateReference(CanvasReference ref) {
    // For now, assume all references are valid
    // In a real implementation, this would check if the referenced objects exist
    return ref.isValid;
  }

  // Additional utility methods
  void removeReferencesForCanvasObject(String canvasObjectId) {
    final refsToRemove = findByCanvasObject(canvasObjectId);
    for (final ref in refsToRemove) {
      remove(ref.id);
    }
  }

  void removeReferencesForDocument(String documentId) {
    final refsToRemove = findByDocument(documentId);
    for (final ref in refsToRemove) {
      remove(ref.id);
    }
  }

  void validateAllReferences() {
    for (final ref in _references) {
      if (!validateReference(ref)) {
        ref.markInvalid();
        _eventController.add(ReferenceEvent(ref.id, ReferenceEventType.referenceInvalidated));
      }
    }
  }

  void dispose() {
    _eventController.close();
  }
}