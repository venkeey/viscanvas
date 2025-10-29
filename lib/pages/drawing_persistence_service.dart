import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/canvas_objects/canvas_object.dart';
import '../models/canvas_objects/freehand_path.dart';
import '../models/canvas_objects/canvas_rectangle.dart';
import '../models/canvas_objects/canvas_circle.dart';
import '../models/canvas_objects/sticky_note.dart';
import '../domain/canvas_domain.dart';
import '../services/canvas_service.dart';
import 'drawingCanvas.dart';

// ===== SERIALIZATION EXTENSIONS =====

/// Factory for deserializing canvas objects from JSON
class CanvasObjectFactory {
  static CanvasObject fromJson(Map<String, dynamic> json) {
    try {
      switch (json['type']) {
        case 'FreehandPath':
          return _deserializeFreehandPath(json);
        case 'CanvasRectangle':
          return _deserializeRectangle(json);
        case 'CanvasCircle':
          return _deserializeCircle(json);
        case 'StickyNote':
          return _deserializeStickyNote(json);
        default:
          throw FormatException('Unknown object type: ${json['type']}');
      }
    } catch (e) {
      throw FormatException('Failed to deserialize object: $e');
    }
  }

  static FreehandPath _deserializeFreehandPath(Map<String, dynamic> json) {
    return FreehandPath(
      id: json['id'],
      worldPosition: Offset(
        json['worldPosition']['dx'].toDouble(),
        json['worldPosition']['dy'].toDouble(),
      ),
      strokeColor: Color(json['strokeColor']),
      strokeWidth: json['strokeWidth'].toDouble(),
      isSelected: json['isSelected'] ?? false,
      points: (json['points'] as List)
          .map((p) => Offset(p['dx'].toDouble(), p['dy'].toDouble()))
          .toList(),
    );
  }

  static CanvasRectangle _deserializeRectangle(Map<String, dynamic> json) {
    return CanvasRectangle(
      id: json['id'],
      worldPosition: Offset(
        json['worldPosition']['dx'].toDouble(),
        json['worldPosition']['dy'].toDouble(),
      ),
      strokeColor: Color(json['strokeColor']),
      fillColor: json['fillColor'] != null ? Color(json['fillColor']) : null,
      strokeWidth: json['strokeWidth'].toDouble(),
      isSelected: json['isSelected'] ?? false,
      size: Size(
        json['size']['width'].toDouble(),
        json['size']['height'].toDouble(),
      ),
    );
  }

  static CanvasCircle _deserializeCircle(Map<String, dynamic> json) {
    return CanvasCircle(
      id: json['id'],
      worldPosition: Offset(
        json['worldPosition']['dx'].toDouble(),
        json['worldPosition']['dy'].toDouble(),
      ),
      strokeColor: Color(json['strokeColor']),
      fillColor: json['fillColor'] != null ? Color(json['fillColor']) : null,
      strokeWidth: json['strokeWidth'].toDouble(),
      isSelected: json['isSelected'] ?? false,
      radius: json['radius'].toDouble(),
    );
  }

  static StickyNote _deserializeStickyNote(Map<String, dynamic> json) {
    return StickyNote(
      id: json['id'],
      worldPosition: Offset(
        json['worldPosition']['dx'].toDouble(),
        json['worldPosition']['dy'].toDouble(),
      ),
      strokeColor: Color(json['strokeColor']),
      strokeWidth: json['strokeWidth'].toDouble(),
      isSelected: json['isSelected'] ?? false,
      text: json['text'] ?? 'Double tap to edit',
      size: Size(
        json['size']['width'].toDouble(),
        json['size']['height'].toDouble(),
      ),
      backgroundColor: json['backgroundColor'] != null ? Color(json['backgroundColor']) : Colors.yellow,
      fontSize: json['fontSize']?.toDouble() ?? 14.0,
      isEditing: json['isEditing'] ?? false,
    );
  }
}

/// Extension to add serialization to canvas objects
extension CanvasObjectSerialization on CanvasObject {
  Map<String, dynamic> toJson() {
    final base = {
      'id': id,
      'worldPosition': {'dx': worldPosition.dx, 'dy': worldPosition.dy},
      'strokeColor': strokeColor.value,
      'fillColor': fillColor?.value,
      'strokeWidth': strokeWidth,
      'isSelected': isSelected,
    };

    if (this is FreehandPath) {
      final path = this as FreehandPath;
      return {
        'type': 'FreehandPath',
        ...base,
        'points': path.points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      };
    } else if (this is CanvasRectangle) {
      final rect = this as CanvasRectangle;
      return {
        'type': 'CanvasRectangle',
        ...base,
        'size': {'width': rect.size.width, 'height': rect.size.height},
      };
    } else if (this is CanvasCircle) {
      final circle = this as CanvasCircle;
      return {
        'type': 'CanvasCircle',
        ...base,
        'radius': circle.radius,
      };
    } else if (this is StickyNote) {
      final stickyNote = this as StickyNote;
      return {
        'type': 'StickyNote',
        ...base,
        'text': stickyNote.text,
        'size': {'width': stickyNote.size.width, 'height': stickyNote.size.height},
        'backgroundColor': stickyNote.backgroundColor.value,
        'fontSize': stickyNote.fontSize,
        'isEditing': stickyNote.isEditing,
      };
    } else {
      throw UnsupportedError('Cannot serialize ${runtimeType}');
    }
  }
}

// ===== PERSISTENCE SERVICE =====

class CanvasData {
  final List<CanvasObject> objects;
  final Transform2D transform;
  final String version;
  final DateTime timestamp;

  CanvasData({
    required this.objects,
    required this.transform,
    this.version = '1.0',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class FileInfo {
  final String name;
  final String path;
  final DateTime lastModified;
  final int size;

  FileInfo({
    required this.name,
    required this.path,
    required this.lastModified,
    required this.size,
  });
}

class CanvasPersistenceException implements Exception {
  final String message;
  final dynamic cause;

  CanvasPersistenceException(this.message, [this.cause]);

  @override
  String toString() => 'CanvasPersistenceException: $message${cause != null ? ' ($cause)' : ''}';
}

class CanvasPersistenceService {
  static const String _fileExtension = '.canvas.json';
  static const String _defaultFileName = 'my_canvas';
  static const String _autosaveFileName = 'autosave_canvas';
  static const String _currentVersion = '1.0';

  bool _isSaving = false;
  final _saveLock = Completer<void>()..complete();

  // ===== SAVE OPERATIONS =====

  /// Save canvas to file with mutex lock to prevent concurrent writes
  Future<File> saveCanvas({
    required List<CanvasObject> objects,
    required Transform2D transform,
    String? fileName,
  }) async {
    // Wait for any pending save to complete
    await _saveLock.future;

    final newLock = Completer<void>();

    try {
      _isSaving = true;

      final directory = await getApplicationDocumentsDirectory();
      final name = fileName ?? _defaultFileName;
      final file = File('${directory.path}${Platform.pathSeparator}$name$_fileExtension');

      final data = {
        'version': _currentVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'transform': {
          'translation': {
            'dx': transform.translation.dx,
            'dy': transform.translation.dy,
          },
          'scale': transform.scale,
        },
        'objects': objects.map((obj) => obj.toJson()).toList(),
      };

      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);

      debugPrint('✅ Canvas saved: ${file.path} (${objects.length} objects)');
      return file;
    } on FileSystemException catch (e) {
      throw CanvasPersistenceException('File system error during save', e);
    } on JsonUnsupportedObjectError catch (e) {
      throw CanvasPersistenceException('Serialization error', e);
    } catch (e) {
      throw CanvasPersistenceException('Unknown error during save', e);
    } finally {
      _isSaving = false;
      newLock.complete();
    }
  }

  /// Auto-save canvas (called periodically)
  Future<void> autoSave({
    required List<CanvasObject> objects,
    required Transform2D transform,
  }) async {
    try {
      await saveCanvas(
        objects: objects,
        transform: transform,
        fileName: _autosaveFileName,
      );
    } catch (e) {
      debugPrint('⚠️ Auto-save failed: $e');
      // Don't rethrow - auto-save failures should not crash the app
    }
  }

  // ===== LOAD OPERATIONS =====

  /// Load canvas from file with validation
  Future<CanvasData?> loadCanvas({String? fileName}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final name = fileName ?? _defaultFileName;
      final file = File('${directory.path}${Platform.pathSeparator}$name$_fileExtension');

      if (!await file.exists()) {
        debugPrint('⚠️ File not found: ${file.path}');
        return null;
      }

      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate version
      final version = data['version'] as String?;
      if (version == null) {
        throw CanvasPersistenceException('Missing version field in saved file');
      }
      if (version != _currentVersion) {
        debugPrint('⚠️ Version mismatch: expected $_currentVersion, got $version');
        // Could implement migration logic here
      }

      // Validate required fields
      if (!data.containsKey('transform') || !data.containsKey('objects')) {
        throw CanvasPersistenceException('Invalid file format: missing required fields');
      }

      // Deserialize transform
      final transformData = data['transform'] as Map<String, dynamic>;
      final transform = Transform2D(
        translation: Offset(
          (transformData['translation']['dx'] as num).toDouble(),
          (transformData['translation']['dy'] as num).toDouble(),
        ),
        scale: (transformData['scale'] as num).toDouble(),
      );

      // Deserialize objects
      final objectsData = data['objects'] as List;
      final objects = <CanvasObject>[];

      for (var i = 0; i < objectsData.length; i++) {
        try {
          final obj = CanvasObjectFactory.fromJson(objectsData[i] as Map<String, dynamic>);
          objects.add(obj);
        } catch (e) {
          debugPrint('⚠️ Skipping object $i: $e');
          // Continue loading other objects even if one fails
        }
      }

      final timestamp = data['timestamp'] != null
          ? DateTime.parse(data['timestamp'] as String)
          : null;

      debugPrint('✅ Canvas loaded: ${objects.length} objects');
      return CanvasData(
        objects: objects,
        transform: transform,
        version: version,
        timestamp: timestamp,
      );
    } on FileSystemException catch (e) {
      throw CanvasPersistenceException('File system error during load', e);
    } on FormatException catch (e) {
      throw CanvasPersistenceException('Invalid JSON format', e);
    } catch (e) {
      throw CanvasPersistenceException('Unknown error during load', e);
    }
  }

  // ===== FILE MANAGEMENT =====

  /// List all saved canvas files
  Future<List<FileInfo>> listSavedCanvases() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith(_fileExtension))
          .toList();

      final fileInfos = <FileInfo>[];
      for (var file in files) {
        try {
          final stat = await file.stat();
          final name = path.basenameWithoutExtension(file.path).replaceAll('.canvas', '');
          fileInfos.add(FileInfo(
            name: name,
            path: file.path,
            lastModified: stat.modified,
            size: stat.size,
          ));
        } catch (e) {
          debugPrint('⚠️ Error reading file info for ${file.path}: $e');
        }
      }

      fileInfos.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      return fileInfos;
    } on FileSystemException catch (e) {
      throw CanvasPersistenceException('Error listing files', e);
    } catch (e) {
      throw CanvasPersistenceException('Unknown error listing files', e);
    }
  }

  /// Delete a canvas file
  Future<bool> deleteCanvas(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}${Platform.pathSeparator}$fileName$_fileExtension');

      if (await file.exists()) {
        await file.delete();
        debugPrint('✅ Deleted: $fileName');
        return true;
      }
      debugPrint('⚠️ File not found for deletion: $fileName');
      return false;
    } on FileSystemException catch (e) {
      throw CanvasPersistenceException('Error deleting file', e);
    } catch (e) {
      throw CanvasPersistenceException('Unknown error deleting file', e);
    }
  }

  /// Check if a save operation is currently in progress
  bool get isSaving => _isSaving;
}

// ===== CANVAS SERVICE INTEGRATION =====

/// Extension to add persistence functionality to CanvasService
extension CanvasServicePersistence on CanvasService {
  static final _persistenceServices = <CanvasService, _PersistenceState>{};

  _PersistenceState get _state {
    return _persistenceServices.putIfAbsent(this, () => _PersistenceState());
  }

  /// Start auto-save timer
  void startAutoSave({Duration interval = const Duration(seconds: 30)}) {
    _state.autoSaveTimer?.cancel();
    _state.autoSaveTimer = Timer.periodic(interval, (_) {
      if (!_state.service.isSaving) {
        _autoSave();
      }
    });
  }

  /// Stop auto-save timer
  void stopAutoSave() {
    _state.autoSaveTimer?.cancel();
    _state.autoSaveTimer = null;
  }

  Future<void> _autoSave() async {
    try {
      await _state.service.autoSave(
        objects: objects,
        transform: transform,
      );
    } catch (e) {
      debugPrint('Auto-save error: $e');
    }
  }

  /// Try to load auto-saved canvas
  Future<bool> loadAutoSave() async {
    try {
      final data = await _state.service.loadCanvas(fileName: 'autosave_canvas');
      if (data != null) {
        // This would need to be implemented in the actual CanvasService
        debugPrint('⚠️ Auto-save loaded but cannot restore state - implement restoration logic');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error loading auto-save: $e');
      return false;
    }
  }

  /// Save canvas with user-specified filename
  Future<File> saveCanvas({String? fileName}) async {
    return await _state.service.saveCanvas(
      objects: objects,
      transform: transform,
      fileName: fileName,
    );
  }

  /// Load canvas from file
  Future<CanvasData?> loadCanvas({String? fileName}) async {
    return await _state.service.loadCanvas(fileName: fileName);
  }

  /// Get list of saved canvases
  Future<List<FileInfo>> getSavedCanvases() async {
    return await _state.service.listSavedCanvases();
  }

  /// Delete a saved canvas
  Future<bool> deleteCanvas(String fileName) async {
    return await _state.service.deleteCanvas(fileName);
  }

  /// Clean up persistence resources
  void disposePersistence() {
    stopAutoSave();
    _persistenceServices.remove(this);
  }
}

class _PersistenceState {
  final CanvasPersistenceService service = CanvasPersistenceService();
  Timer? autoSaveTimer;
}

// ===== UI COMPONENTS =====

class SaveLoadUI extends StatelessWidget {
  final CanvasService canvasService;

  const SaveLoadUI({Key? key, required this.canvasService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showSaveDialog(context),
          icon: const Icon(Icons.save),
          label: const Text('Save Canvas'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _showLoadDialog(context),
          icon: const Icon(Icons.folder_open),
          label: const Text('Load Canvas'),
        ),
      ],
    );
  }

  Future<void> _showSaveDialog(BuildContext context) async {
    final controller = TextEditingController(text: 'my_canvas');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Canvas'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'File name',
            hintText: 'Enter file name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await canvasService.saveCanvas(fileName: result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved as: $result')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    controller.dispose();
  }

  Future<void> _showLoadDialog(BuildContext context) async {
    try {
      final files = await canvasService.getSavedCanvases();

      if (!context.mounted) return;

      if (files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved canvases found')),
        );
        return;
      }

      final selected = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Load Canvas'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(file.name),
                  subtitle: Text(
                    'Modified: ${file.lastModified.toString().split('.')[0]}\nSize: ${(file.size / 1024).toStringAsFixed(1)} KB',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Canvas'),
                          content: Text('Delete "${file.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await canvasService.deleteCanvas(file.name);
                        if (context.mounted) {
                          Navigator.pop(context);
                          _showLoadDialog(context);
                        }
                      }
                    },
                  ),
                  onTap: () => Navigator.pop(context, file.name),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selected != null) {
        final data = await canvasService.loadCanvas(fileName: selected);
        if (data != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Loaded: $selected (${data.objects.length} objects)')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
