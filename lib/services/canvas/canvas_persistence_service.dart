import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart' show File;
import '../../domain/canvas_domain.dart';
import '../../models/canvas_objects/canvas_object.dart';
import '../../models/canvas_objects/freehand_path.dart';
import '../../models/canvas_objects/canvas_rectangle.dart';
import '../../models/canvas_objects/canvas_circle.dart';
import '../../models/canvas_objects/canvas_triangle.dart';
import '../../models/canvas_objects/sticky_note.dart';
import '../../models/canvas_objects/document_block.dart';
import '../../models/canvas_objects/connector.dart';
import '../../models/canvas_objects/canvas_text.dart';
import '../../models/canvas_objects/canvas_comment.dart';
import '../../models/documents/document_content.dart';

// Canvas data structure for serialization
class _CanvasData {
  final List<CanvasObject> objects;
  final Transform2D transform;

  _CanvasData({required this.objects, required this.transform});
}

class CanvasPersistenceService {
  final InMemoryCanvasRepository _repository;
  final CommandHistory _commandHistory;

  // In-memory web storage simulation
  static final Map<String, String> _webStorage = {};

  CanvasPersistenceService(this._repository, this._commandHistory);

  // ===== PUBLIC API =====

  Future<void> saveCanvasToFile(List<CanvasObject> objects, Transform2D transform, String fileName) async {
    try {
      if (kIsWeb) {
        await _saveToWebStorage(objects, transform, fileName);
        print('✅ Canvas saved to web storage as: $fileName');
      } else {
        await _saveToFile(objects, transform, fileName);
        print('✅ Canvas saved as: $fileName');
      }
    } catch (e) {
      print('❌ Save failed: $e');
      rethrow;
    }
  }

  Future<_CanvasData?> loadCanvasFromFile(String fileName) async {
    try {
      if (kIsWeb) {
        return await _loadFromWebStorage(fileName);
      } else {
        return await _loadFromFile(fileName);
      }
    } catch (e) {
      print('❌ Load failed: $e');
      rethrow;
    }
  }

  Future<List<FileSystemEntity>> getSavedCanvases() async {
    try {
      if (kIsWeb) {
        return await _listWebStorageFiles();
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final files = directory
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.canvas.json'))
            .toList();

        files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        return files;
      }
    } catch (e) {
      print('❌ List files error: $e');
      return [];
    }
  }

  Future<bool> deleteCanvas(String fileName) async {
    try {
      if (kIsWeb) {
        return await _deleteFromWebStorage(fileName);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName.canvas.json';
        final file = File(filePath);

        if (await file.exists()) {
          await file.delete();
          print('✅ Deleted: $fileName');
          return true;
        }
        return false;
      }
    } catch (e) {
      print('❌ Delete error: $e');
      return false;
    }
  }

  Future<void> autoSave(List<CanvasObject> objects, Transform2D transform) async {
    if (objects.isEmpty) return;

    // Debug: Log what we're saving
    final documentBlocks = objects.whereType<DocumentBlock>().toList();
    print('💾 Auto-saving ${objects.length} objects, ${documentBlocks.length} DocumentBlocks');
    for (final docBlock in documentBlocks) {
      print('   📄 DocumentBlock ${docBlock.id}: content=${docBlock.content?.blocks.length ?? 0} blocks');
    }

    try {
      if (kIsWeb) {
        await _saveToWebStorage(objects, transform, 'autosave_canvas');
      } else {
        await _saveToFile(objects, transform, 'autosave_canvas');
      }
      print('✅ Auto-save completed');
    } catch (e) {
      print('❌ Auto-save failed: $e');
    }
  }

  Future<_CanvasData?> loadAutoSave() async {
    try {
      if (kIsWeb) {
        return await _loadFromWebStorage('autosave_canvas');
      } else {
        return await _loadFromFile('autosave_canvas');
      }
    } catch (e) {
      print('⚠️ Could not load autosave: $e');
      return null;
    }
  }

  // ===== PRIVATE METHODS =====

  Future<void> _saveToFile(List<CanvasObject> objects, Transform2D transform, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.canvas.json';
      final file = File(filePath);

      final data = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'transform': {
          'translation': {
            'dx': transform.translation.dx,
            'dy': transform.translation.dy,
          },
          'scale': transform.scale,
        },
        'objects': objects.map((obj) => _serializeObject(obj)).toList(),
      };

      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);
    } catch (e) {
      print('❌ File save error: $e');
      rethrow;
    }
  }

  Future<_CanvasData?> _loadFromFile(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.canvas.json';
      final file = File(filePath);

      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Deserialize transform
      final transformData = data['transform'];
      final transform = Transform2D(
        translation: Offset(
          transformData['translation']['dx'],
          transformData['translation']['dy'],
        ),
        scale: transformData['scale'],
      );

      // Two-pass deserialization for objects with references
      final objectsData = data['objects'] as List;
      final objects = <CanvasObject>[];
      final objectMap = <String, CanvasObject>{};

      // First pass: deserialize non-Connector objects
      for (var objJson in objectsData) {
        final type = objJson['type'];
        if (type != 'Connector') {
          final obj = _deserializeObject(objJson as Map<String, dynamic>);
          objects.add(obj);
          objectMap[obj.id] = obj;
        }
      }

      // Second pass: deserialize Connectors with object references
      for (var objJson in objectsData) {
        final type = objJson['type'];
        if (type == 'Connector') {
          try {
            final connector = _deserializeObject(objJson as Map<String, dynamic>, objectMap);
            objects.add(connector);
          } catch (e) {
            // Skip connectors with missing object references
            print('⚠️ Skipping connector with missing references: ${objJson['id']}');
          }
        }
      }

      return _CanvasData(objects: objects, transform: transform);
    } catch (e) {
      print('❌ File load error: $e');
      return null;
    }
  }

  Map<String, dynamic> _serializeObject(CanvasObject obj) {
    return {
      'id': obj.id,
      'worldPosition': {'dx': obj.worldPosition.dx, 'dy': obj.worldPosition.dy},
      'strokeColor': obj.strokeColor.value,
      'fillColor': obj.fillColor?.value,
      'strokeWidth': obj.strokeWidth,
      'isSelected': obj.isSelected,
      'type': obj.runtimeType.toString(),
      // Add specific properties based on object type
      if (obj is FreehandPath) 'points': obj.points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      if (obj is CanvasRectangle) 'size': {'width': obj.size.width, 'height': obj.size.height},
      if (obj is CanvasCircle) 'radius': obj.radius,
      if (obj is CanvasTriangle) 'vertices': obj.vertices.map((v) => {'dx': v.dx, 'dy': v.dy}).toList(),
      if (obj is StickyNote) ...{
        'text': obj.text,
        'size': {'width': obj.size.width, 'height': obj.size.height},
        'backgroundColor': obj.backgroundColor.value,
        'fontSize': obj.fontSize,
        'isEditing': obj.isEditing,
      },
      if (obj is Connector) ...{
        'sourceObjectId': obj.sourceObject.id,
        'targetObjectId': obj.targetObject.id,
        'sourcePoint': {'dx': obj.sourcePoint.dx, 'dy': obj.sourcePoint.dy},
        'targetPoint': {'dx': obj.targetPoint.dx, 'dy': obj.targetPoint.dy},
        'showArrow': obj.showArrow,
      },
      if (obj is DocumentBlock) ...{
        'documentId': obj.documentId,
        'viewMode': obj.viewMode.toString(),
        'size': {'width': obj.size.width, 'height': obj.size.height},
        'content': obj.content?.toJson(), // Serialize the document content
        'canvasReferences': obj.canvasReferences.map((ref) => ref.toJson()).toList(),
        'isExpanded': obj.isExpanded,
        'isEditing': obj.isEditing,
        'style': {
          'backgroundColor': obj.style.backgroundColor.value,
          'titleStyle': {
            'fontSize': obj.style.titleStyle.fontSize,
            'fontWeight': obj.style.titleStyle.fontWeight?.index,
          },
          'borderRadius': obj.style.borderRadius,
          'padding': obj.style.padding,
        },
      } ..addAll({'debug_content_blocks': (obj.content?.blocks.length ?? 0)}), // Debug: add content block count
      if (obj is CanvasText) ...{
        'text': obj.text,
        'size': {'width': obj.size.width, 'height': obj.size.height},
        'fontSize': obj.fontSize,
        'textAlign': obj.textAlign.toString().split('.').last,
        'fontWeight': obj.fontWeight.index,
        'textColor': obj.textColor.value,
        'isEditing': obj.isEditing,
        'maxWidth': obj.maxWidth,
      },
      if (obj is CanvasComment) ...{
        'text': obj.text,
        'author': obj.author,
        'createdAt': obj.createdAt.toIso8601String(),
        'parentCommentId': obj.parentCommentId,
        'size': {'width': obj.size.width, 'height': obj.size.height},
        'backgroundColor': obj.backgroundColor.value,
        'fontSize': obj.fontSize,
        'isResolved': obj.isResolved,
        'isEditing': obj.isEditing,
        'anchorPoint': obj.anchorPoint != null
            ? {'dx': obj.anchorPoint!.dx, 'dy': obj.anchorPoint!.dy}
            : null,
        'replies': obj.replies.map((reply) => _serializeObject(reply)).toList(),
      },
    };
  }

  CanvasObject _deserializeObject(Map<String, dynamic> json, [Map<String, CanvasObject>? objectMap]) {
    final type = json['type'];

    switch (type) {
      case 'FreehandPath':
        return FreehandPath(
          id: json['id'],
          worldPosition: Offset(json['worldPosition']['dx'], json['worldPosition']['dy']),
          strokeColor: Color(json['strokeColor']),
          strokeWidth: json['strokeWidth'],
          isSelected: json['isSelected'] ?? false,
          points: (json['points'] as List).map((p) => Offset(p['dx'], p['dy'])).toList(),
        );
      case 'CanvasRectangle':
        return CanvasRectangle(
          id: json['id'],
          worldPosition: Offset(json['worldPosition']['dx'], json['worldPosition']['dy']),
          strokeColor: Color(json['strokeColor']),
          fillColor: json['fillColor'] != null ? Color(json['fillColor']) : Colors.transparent,
          strokeWidth: json['strokeWidth'],
          isSelected: json['isSelected'] ?? false,
          size: Size(json['size']['width'], json['size']['height']),
        );
      case 'CanvasCircle':
        return CanvasCircle(
          id: json['id'],
          worldPosition: Offset(json['worldPosition']['dx'], json['worldPosition']['dy']),
          strokeColor: Color(json['strokeColor']),
          fillColor: json['fillColor'] != null ? Color(json['fillColor']) : Colors.transparent,
          strokeWidth: json['strokeWidth'],
          isSelected: json['isSelected'] ?? false,
          radius: json['radius'],
        );
      case 'CanvasTriangle':
        // Handle null vertices (for backward compatibility)
        List<Offset> vertices;
        if (json['vertices'] != null && json['vertices'] is List) {
          vertices = (json['vertices'] as List).map((v) => Offset(v['dx'], v['dy'])).toList();
        } else {
          // Default triangle if vertices are missing
          vertices = [
            const Offset(0, 0), // Top
            const Offset(-25, 50), // Bottom left
            const Offset(25, 50), // Bottom right
          ];
        }
        return CanvasTriangle(
          id: json['id'],
          worldPosition: Offset(json['worldPosition']['dx'], json['worldPosition']['dy']),
          strokeColor: Color(json['strokeColor']),
          fillColor: json['fillColor'] != null ? Color(json['fillColor']) : Colors.transparent,
          strokeWidth: json['strokeWidth'],
          isSelected: json['isSelected'] ?? false,
          vertices: vertices,
        );
      case 'StickyNote':
        return StickyNote(
          id: json['id'],
          worldPosition: Offset(json['worldPosition']['dx'], json['worldPosition']['dy']),
          strokeColor: Color(json['strokeColor']),
          strokeWidth: json['strokeWidth'],
          isSelected: json['isSelected'] ?? false,
          text: json['text'] ?? 'Double tap to edit',
          size: Size(json['size']['width'], json['size']['height']),
          backgroundColor: json['backgroundColor'] != null ? Color(json['backgroundColor']) : Colors.yellow,
          fontSize: json['fontSize'] ?? 14.0,
          isEditing: json['isEditing'] ?? false,
        );
      case 'Connector':
        if (objectMap == null) {
          throw Exception('Connector deserialization requires objectMap');
        }
        final sourceObj = objectMap[json['sourceObjectId']];
        final targetObj = objectMap[json['targetObjectId']];
        if (sourceObj == null || targetObj == null) {
          throw Exception('Connector references missing objects');
        }
        return Connector(
          id: json['id'],
          sourceObject: sourceObj,
          targetObject: targetObj,
          sourcePoint: Offset(json['sourcePoint']['dx'], json['sourcePoint']['dy']),
          targetPoint: Offset(json['targetPoint']['dx'], json['targetPoint']['dy']),
          strokeColor: Color(json['strokeColor']),
          strokeWidth: json['strokeWidth'],
          isSelected: json['isSelected'] ?? false,
          showArrow: json['showArrow'] ?? true,
        );
      case 'DocumentBlock':
        return DocumentBlock(
          id: json['id'],
          worldPosition: Offset(json['worldPosition']['dx'], json['worldPosition']['dy']),
          strokeColor: Color(json['strokeColor']),
          strokeWidth: json['strokeWidth']?.toDouble() ?? 1.0,
          fillColor: json['fillColor'] != null ? Color(json['fillColor']) : Colors.white,
          isSelected: json['isSelected'] ?? false,
          documentId: json['documentId'] ?? 'doc_legacy_${json['id']}', // Provide default for legacy saves
          content: json['content'] != null ? DocumentContent.fromJson(json['content']) : null, // Restore content
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
            backgroundColor: json['style']?['backgroundColor'] != null
                ? Color(json['style']['backgroundColor'])
                : Colors.white,
            titleStyle: TextStyle(
              fontSize: json['style']?['titleStyle']?['fontSize']?.toDouble() ?? 18.0,
              fontWeight: json['style']?['titleStyle']?['fontWeight'] != null
                  ? FontWeight.values[json['style']['titleStyle']['fontWeight']]
                  : FontWeight.w600,
            ),
            borderRadius: json['style']?['borderRadius']?.toDouble() ?? 8.0,
            padding: json['style']?['padding']?.toDouble() ?? 16.0,
          ),
        );
      case 'CanvasText':
        final sizeData = json['size'];
        return CanvasText(
          id: json['id'],
          worldPosition: Offset(json['worldPosition']['dx'], json['worldPosition']['dy']),
          strokeColor: Color(json['strokeColor']),
          strokeWidth: json['strokeWidth']?.toDouble() ?? 2.0,
          isSelected: json['isSelected'] ?? false,
          text: json['text'] ?? '',
          size: sizeData != null
              ? Size(sizeData['width']?.toDouble() ?? 200.0, sizeData['height']?.toDouble() ?? 30.0)
              : const Size(200, 30),
          fontSize: json['fontSize']?.toDouble() ?? 16.0,
          textAlign: json['textAlign'] != null
              ? TextAlign.values.firstWhere(
                  (align) => align.toString().split('.').last == json['textAlign'],
                  orElse: () => TextAlign.left,
                )
              : TextAlign.left,
          fontWeight: json['fontWeight'] != null
              ? FontWeight.values[json['fontWeight']]
              : FontWeight.normal,
          textColor: json['textColor'] != null ? Color(json['textColor']) : Colors.black,
          isEditing: json['isEditing'] ?? false,
          maxWidth: json['maxWidth']?.toDouble(),
        );
      case 'CanvasComment':
        final sizeData = json['size'];
        final comment = CanvasComment(
          id: json['id'],
          worldPosition: Offset(json['worldPosition']['dx'], json['worldPosition']['dy']),
          strokeColor: Color(json['strokeColor']),
          strokeWidth: json['strokeWidth']?.toDouble() ?? 2.0,
          isSelected: json['isSelected'] ?? false,
          text: json['text'] ?? '',
          author: json['author'],
          createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
          parentCommentId: json['parentCommentId'],
          size: sizeData != null
              ? Size(sizeData['width']?.toDouble() ?? 250.0, sizeData['height']?.toDouble() ?? 80.0)
              : const Size(250, 80),
          backgroundColor: json['backgroundColor'] != null
              ? Color(json['backgroundColor'])
              : const Color(0xFFE3F2FD),
          fontSize: json['fontSize']?.toDouble() ?? 14.0,
          isResolved: json['isResolved'] ?? false,
          isEditing: json['isEditing'] ?? false,
          anchorPoint: json['anchorPoint'] != null
              ? Offset(json['anchorPoint']['dx'], json['anchorPoint']['dy'])
              : null,
          replies: [],
        );
        // Deserialize replies recursively
        if (json['replies'] != null && json['replies'] is List) {
          for (var replyJson in json['replies']) {
            final reply = _deserializeObject(replyJson as Map<String, dynamic>) as CanvasComment;
            comment.addReply(reply);
          }
        }
        return comment;
      default:
        throw Exception('Unknown object type: $type');
    }
  }

  // Web storage implementation using localStorage
  Future<void> _saveToWebStorage(List<CanvasObject> objects, Transform2D transform, String fileName) async {
    try {
      final data = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'transform': {
          'translation': {
            'dx': transform.translation.dx,
            'dy': transform.translation.dy,
          },
          'scale': transform.scale,
        },
        'objects': objects.map((obj) => _serializeObject(obj)).toList(),
      };

      final jsonString = jsonEncode(data);
      // Use html window.localStorage (requires dart:html)
      // For now, we'll use a simple in-memory storage simulation
      _webStorage[fileName] = jsonString;
    } catch (e) {
      print('❌ Web storage save error: $e');
      rethrow;
    }
  }

  Future<_CanvasData?> _loadFromWebStorage(String fileName) async {
    try {
      final jsonString = _webStorage[fileName];
      if (jsonString == null) {
        return null;
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Deserialize transform
      final transformData = data['transform'];
      final transform = Transform2D(
        translation: Offset(
          transformData['translation']['dx'],
          transformData['translation']['dy'],
        ),
        scale: transformData['scale'],
      );

      // Two-pass deserialization for objects with references
      final objectsData = data['objects'] as List;
      final objects = <CanvasObject>[];
      final objectMap = <String, CanvasObject>{};

      // First pass: deserialize non-Connector objects
      for (var objJson in objectsData) {
        final type = objJson['type'];
        if (type != 'Connector') {
          final obj = _deserializeObject(objJson as Map<String, dynamic>);
          objects.add(obj);
          objectMap[obj.id] = obj;
        }
      }

      // Second pass: deserialize Connectors with object references
      for (var objJson in objectsData) {
        final type = objJson['type'];
        if (type == 'Connector') {
          final connector = _deserializeObject(objJson as Map<String, dynamic>, objectMap);
          objects.add(connector);
        }
      }

      return _CanvasData(objects: objects, transform: transform);
    } catch (e) {
      print('❌ Web storage load error: $e');
      return null;
    }
  }

  Future<List<FileSystemEntity>> _listWebStorageFiles() async {
    try {
      // For web storage, return empty list since we can't create FileSystemEntity
      return [];
    } catch (e) {
      print('❌ Web storage list error: $e');
      return [];
    }
  }

  Future<bool> _deleteFromWebStorage(String fileName) async {
    try {
      _webStorage.remove(fileName);
      print('✅ Deleted from web storage: $fileName');
      return true;
    } catch (e) {
      print('❌ Web storage delete error: $e');
      return false;
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}
