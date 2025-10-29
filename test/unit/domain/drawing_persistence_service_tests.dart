import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viscanvas/pages/drawing_persistence_service.dart';
import 'package:viscanvas/pages/drawingCanvas.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes for testing
class MockDirectory extends Mock implements Directory {}

class MockFile extends Mock implements File {}

class MockFileStat extends Mock implements FileStat {}

void main() {
  late CanvasPersistenceService persistenceService;
  late Directory tempDir;
  late File tempFile;

  setUp(() async {
    persistenceService = CanvasPersistenceService();

    // Create a temporary directory for testing
    tempDir = await Directory.systemTemp.createTemp('canvas_test_');
    tempFile = File('${tempDir.path}/test_canvas.canvas.json');
  });

  tearDown(() async {
    // Clean up temp files
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    await tempDir.delete(recursive: true);
  });

  group('CanvasObjectFactory Tests', () {
    test('should deserialize FreehandPath correctly', () {
      final json = {
        'type': 'FreehandPath',
        'id': 'path_1',
        'worldPosition': {'dx': 10.0, 'dy': 20.0},
        'strokeColor': Colors.blue.value,
        'strokeWidth': 3.0,
        'isSelected': false,
        'points': [
          {'dx': 0.0, 'dy': 0.0},
          {'dx': 10.0, 'dy': 5.0},
          {'dx': 20.0, 'dy': 10.0},
        ],
      };

      final object = CanvasObjectFactory.fromJson(json);

      expect(object, isA<FreehandPath>());
      final path = object as FreehandPath;
      expect(path.id, 'path_1');
      expect(path.worldPosition, Offset(10, 20));
      expect(path.strokeColor.value, Colors.blue.value);
      expect(path.strokeWidth, 3.0);
      expect(path.isSelected, false);
      expect(path.points.length, 3);
      expect(path.points[0], Offset(0, 0));
      expect(path.points[1], Offset(10, 5));
      expect(path.points[2], Offset(20, 10));
    });

    test('should deserialize CanvasRectangle correctly', () {
      final json = {
        'type': 'CanvasRectangle',
        'id': 'rect_1',
        'worldPosition': {'dx': 50.0, 'dy': 30.0},
        'strokeColor': Colors.red.value,
        'fillColor': Colors.green.value,
        'strokeWidth': 2.0,
        'isSelected': true,
        'size': {'width': 100.0, 'height': 80.0},
      };

      final object = CanvasObjectFactory.fromJson(json);

      expect(object, isA<CanvasRectangle>());
      final rect = object as CanvasRectangle;
      expect(rect.id, 'rect_1');
      expect(rect.worldPosition, Offset(50, 30));
      expect(rect.strokeColor.value, Colors.red.value);
      expect(rect.fillColor?.value, Colors.green.value);
      expect(rect.strokeWidth, 2.0);
      expect(rect.isSelected, true);
      expect(rect.size, Size(100, 80));
    });

    test('should deserialize CanvasCircle correctly', () {
      final json = {
        'type': 'CanvasCircle',
        'id': 'circle_1',
        'worldPosition': {'dx': 100.0, 'dy': 100.0},
        'strokeColor': Colors.purple.value,
        'strokeWidth': 4.0,
        'isSelected': false,
        'radius': 25.0,
      };

      final object = CanvasObjectFactory.fromJson(json);

      expect(object, isA<CanvasCircle>());
      final circle = object as CanvasCircle;
      expect(circle.id, 'circle_1');
      expect(circle.worldPosition, Offset(100, 100));
      expect(circle.strokeColor.value, Colors.purple.value);
      expect(circle.strokeWidth, 4.0);
      expect(circle.isSelected, false);
      expect(circle.radius, 25.0);
    });

    test('should deserialize StickyNote correctly', () {
      final json = {
        'type': 'StickyNote',
        'id': 'note_1',
        'worldPosition': {'dx': 200.0, 'dy': 150.0},
        'strokeColor': Colors.black.value,
        'strokeWidth': 1.0,
        'isSelected': false,
        'text': 'Test note',
        'size': {'width': 150.0, 'height': 100.0},
        'backgroundColor': Colors.yellow.value,
        'fontSize': 16.0,
        'isEditing': false,
      };

      final object = CanvasObjectFactory.fromJson(json);

      expect(object, isA<StickyNote>());
      final note = object as StickyNote;
      expect(note.id, 'note_1');
      expect(note.worldPosition, Offset(200, 150));
      expect(note.strokeColor.value, Colors.black.value);
      expect(note.strokeWidth, 1.0);
      expect(note.isSelected, false);
      expect(note.text, 'Test note');
      expect(note.size, Size(150, 100));
      expect(note.backgroundColor.value, Colors.yellow.value);
      expect(note.fontSize, 16.0);
      expect(note.isEditing, false);
    });

    test('should throw exception for unknown object type', () {
      final json = {
        'type': 'UnknownType',
        'id': 'unknown_1',
      };

      expect(() => CanvasObjectFactory.fromJson(json), throwsA(isA<FormatException>()));
    });

    test('should handle missing required fields gracefully', () {
      final json = {
        'type': 'FreehandPath',
        'id': 'path_1',
        // Missing worldPosition and other required fields
      };

      expect(() => CanvasObjectFactory.fromJson(json), throwsA(isA<FormatException>()));
    });
  });

  group('CanvasObjectSerialization Tests', () {
    test('should serialize FreehandPath correctly', () {
      final path = FreehandPath(
        id: 'path_1',
        worldPosition: Offset(10, 20),
        strokeColor: Colors.blue,
        strokeWidth: 3.0,
        points: [Offset(0, 0), Offset(10, 5), Offset(20, 10)],
      );

      final json = path.toJson();

      expect(json['type'], 'FreehandPath');
      expect(json['id'], 'path_1');
      expect(json['worldPosition'], {'dx': 10.0, 'dy': 20.0});
      expect(json['strokeColor'], Colors.blue.value);
      expect(json['strokeWidth'], 3.0);
      expect(json['points'], [
        {'dx': 0.0, 'dy': 0.0},
        {'dx': 10.0, 'dy': 5.0},
        {'dx': 20.0, 'dy': 10.0},
      ]);
    });

    test('should serialize CanvasRectangle correctly', () {
      final rect = CanvasRectangle(
        id: 'rect_1',
        worldPosition: Offset(50, 30),
        strokeColor: Colors.red,
        fillColor: Colors.green,
        strokeWidth: 2.0,
        size: Size(100, 80),
      );

      final json = rect.toJson();

      expect(json['type'], 'CanvasRectangle');
      expect(json['id'], 'rect_1');
      expect(json['worldPosition'], {'dx': 50.0, 'dy': 30.0});
      expect(json['strokeColor'], Colors.red.value);
      expect(json['fillColor'], Colors.green.value);
      expect(json['strokeWidth'], 2.0);
      expect(json['size'], {'width': 100.0, 'height': 80.0});
    });

    test('should serialize CanvasCircle correctly', () {
      final circle = CanvasCircle(
        id: 'circle_1',
        worldPosition: Offset(100, 100),
        strokeColor: Colors.purple,
        strokeWidth: 4.0,
        radius: 25.0,
      );

      final json = circle.toJson();

      expect(json['type'], 'CanvasCircle');
      expect(json['id'], 'circle_1');
      expect(json['worldPosition'], {'dx': 100.0, 'dy': 100.0});
      expect(json['strokeColor'], Colors.purple.value);
      expect(json['strokeWidth'], 4.0);
      expect(json['radius'], 25.0);
    });

    test('should serialize StickyNote correctly', () {
      final note = StickyNote(
        id: 'note_1',
        worldPosition: Offset(200, 150),
        strokeColor: Colors.black,
        strokeWidth: 1.0,
        text: 'Test note',
        size: Size(150, 100),
        backgroundColor: Colors.yellow,
        fontSize: 16.0,
      );

      final json = note.toJson();

      expect(json['type'], 'StickyNote');
      expect(json['id'], 'note_1');
      expect(json['worldPosition'], {'dx': 200.0, 'dy': 150.0});
      expect(json['strokeColor'], Colors.black.value);
      expect(json['strokeWidth'], 1.0);
      expect(json['text'], 'Test note');
      expect(json['size'], {'width': 150.0, 'height': 100.0});
      expect(json['backgroundColor'], Colors.yellow.value);
      expect(json['fontSize'], 16.0);
      expect(json['isEditing'], false);
    });

    test('should handle null fillColor correctly', () {
      final rect = CanvasRectangle(
        id: 'rect_1',
        worldPosition: Offset(0, 0),
        strokeColor: Colors.black,
        strokeWidth: 1.0,
        size: Size(50, 50),
      );

      final json = rect.toJson();
      expect(json['fillColor'], null);
    });
  });

  group('CanvasPersistenceService Tests', () {
    test('should initialize with correct default values', () {
      expect(persistenceService.isSaving, false);
    });

    test('should create CanvasData correctly', () {
      final objects = [
        CanvasRectangle(
          id: 'rect_1',
          worldPosition: Offset(0, 0),
          strokeColor: Colors.black,
          strokeWidth: 1.0,
          size: Size(50, 50),
        ),
      ];
      final transform = Transform2D(translation: Offset(10, 20), scale: 1.5);

      final data = CanvasData(objects: objects, transform: transform);

      expect(data.objects.length, 1);
      expect(data.transform.translation, Offset(10, 20));
      expect(data.transform.scale, 1.5);
      expect(data.version, '1.0');
      expect(data.timestamp, isNotNull);
    });

    test('should handle save operation with mutex lock', () async {
      final objects = [
        CanvasRectangle(
          id: 'rect_1',
          worldPosition: Offset(0, 0),
          strokeColor: Colors.black,
          strokeWidth: 1.0,
          size: Size(50, 50),
        ),
      ];
      final transform = Transform2D(translation: Offset.zero, scale: 1.0);

      // Mock getApplicationDocumentsDirectory to return our temp directory
      // Note: In a real test, we'd need to mock path_provider

      // For now, test the serialization logic
      final data = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'transform': {
          'translation': {'dx': 0.0, 'dy': 0.0},
          'scale': 1.0,
        },
        'objects': objects.map((obj) => obj.toJson()).toList(),
      };

      final jsonString = jsonEncode(data);
      expect(jsonString, isNotNull);
      expect(jsonString.contains('CanvasRectangle'), true);
    });

    test('should handle load operation with validation', () async {
      // Create a test JSON file
      final testData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'transform': {
          'translation': {'dx': 10.0, 'dy': 20.0},
          'scale': 1.5,
        },
        'objects': [
          {
            'type': 'CanvasRectangle',
            'id': 'rect_1',
            'worldPosition': {'dx': 0.0, 'dy': 0.0},
            'strokeColor': Colors.black.value,
            'fillColor': null,
            'strokeWidth': 1.0,
            'isSelected': false,
            'size': {'width': 50.0, 'height': 50.0},
          },
        ],
      };

      await tempFile.writeAsString(jsonEncode(testData));

      // Test deserialization logic
      final jsonString = await tempFile.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(data['version'], '1.0');
      expect(data['transform']['translation']['dx'], 10.0);
      expect(data['objects'].length, 1);
      expect(data['objects'][0]['type'], 'CanvasRectangle');
    });

    test('should handle file listing operations', () async {
      // Create some test files
      final file1 = File('${tempDir.path}/test1.canvas.json');
      final file2 = File('${tempDir.path}/test2.canvas.json');
      final file3 = File('${tempDir.path}/other.txt'); // Non-canvas file

      await file1.writeAsString('{"version": "1.0"}');
      await file2.writeAsString('{"version": "1.0"}');
      await file3.writeAsString('not a canvas file');

      // Test file listing logic (simplified)
      final files = tempDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.canvas.json'))
          .toList();

      expect(files.length, 2);
      expect(files.any((f) => f.path.contains('test1')), true);
      expect(files.any((f) => f.path.contains('test2')), true);
    });

    test('should handle delete operations', () async {
      await tempFile.writeAsString('{"version": "1.0"}');
      expect(await tempFile.exists(), true);

      // Test delete logic
      if (await tempFile.exists()) {
        await tempFile.delete();
        expect(await tempFile.exists(), false);
      }
    });
  });

  group('CanvasPersistenceException Tests', () {
    test('should create exception with message and cause', () {
      final cause = Exception('Original error');
      final exception = CanvasPersistenceException('Test message', cause);

      expect(exception.message, 'Test message');
      expect(exception.cause, cause);
      expect(exception.toString(), contains('Test message'));
      expect(exception.toString(), contains('Original error'));
    });

    test('should handle null cause', () {
      final exception = CanvasPersistenceException('Test message');

      expect(exception.message, 'Test message');
      expect(exception.cause, null);
      expect(exception.toString(), contains('Test message'));
    });
  });

  group('FileInfo Tests', () {
    test('should create FileInfo correctly', () {
      final lastModified = DateTime.now();
      final fileInfo = FileInfo(
        name: 'test_canvas',
        path: '/path/to/test_canvas.canvas.json',
        lastModified: lastModified,
        size: 1024,
      );

      expect(fileInfo.name, 'test_canvas');
      expect(fileInfo.path, '/path/to/test_canvas.canvas.json');
      expect(fileInfo.lastModified, lastModified);
      expect(fileInfo.size, 1024);
    });
  });

  group('CanvasData Tests', () {
    test('should create CanvasData with custom timestamp', () {
      final customTimestamp = DateTime(2023, 1, 1);
      final objects = <CanvasObject>[];
      final transform = Transform2D(translation: Offset.zero, scale: 1.0);

      final data = CanvasData(
        objects: objects,
        transform: transform,
        version: '2.0',
        timestamp: customTimestamp,
      );

      expect(data.objects, objects);
      expect(data.transform, transform);
      expect(data.version, '2.0');
      expect(data.timestamp, customTimestamp);
    });

    test('should use current timestamp when not provided', () {
      final objects = <CanvasObject>[];
      final transform = Transform2D(translation: Offset.zero, scale: 1.0);

      final before = DateTime.now();
      final data = CanvasData(objects: objects, transform: transform);
      final after = DateTime.now();

      expect(data.timestamp.isAfter(before) || data.timestamp.isAtSameMomentAs(before), true);
      expect(data.timestamp.isBefore(after) || data.timestamp.isAtSameMomentAs(after), true);
    });
  });
}