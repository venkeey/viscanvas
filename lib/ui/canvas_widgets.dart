import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/canvas/canvas_service.dart';
import '../domain/canvas_domain.dart';
import '../pages/drawing_persistence_service.dart';
import '../models/canvas_objects/sticky_note.dart';

class PropertiesPanel extends StatelessWidget {
  final CanvasService service;

  PropertiesPanel({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Properties', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            Row(
              children: [
                const Text('Stroke: '),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final color = await _showColorPicker(context, service.strokeColor);
                    if (color != null) service.setStrokeColor(color);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: service.strokeColor,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Text('Fill:     '),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final color = await _showColorPicker(context, service.fillColor);
                    if (color != null) service.setFillColor(color);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: service.fillColor,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Sticky Note Background Color (only show if sticky note is selected)
            if (_hasSelectedStickyNote(service))
              Row(
                children: [
                  const Text('Note:     '),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final selectedStickyNote = _getSelectedStickyNote(service);
                      if (selectedStickyNote != null) {
                        final color = await _showColorPicker(context, selectedStickyNote.backgroundColor);
                        if (color != null) service.setStickyNoteBackgroundColor(color);
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getSelectedStickyNote(service)?.backgroundColor ?? Colors.yellow,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Text('Width: '),
                SizedBox(
                  width: 100,
                  child: Slider(
                    value: service.strokeWidth,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: service.strokeWidth.toStringAsFixed(0),
                    onChanged: (value) => service.setStrokeWidth(value),
                  ),
                ),
              ],
            ),

            const Divider(),

            Text('Zoom: ${(service.transform.scale * 100).toStringAsFixed(0)}%'),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => service.updateTransform(
                    service.transform.translation,
                    service.transform.scale * 0.8,
                  ),
                  tooltip: 'Zoom Out',
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => service.updateTransform(
                    service.transform.translation,
                    service.transform.scale * 1.25,
                  ),
                  tooltip: 'Zoom In',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => service.updateTransform(Offset.zero, 1.0),
                  tooltip: 'Reset View',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _hasSelectedStickyNote(CanvasService service) {
    return service.objects.any((obj) => obj.isSelected && obj is StickyNote);
  }

  StickyNote? _getSelectedStickyNote(CanvasService service) {
    try {
      return service.objects.firstWhere((obj) => obj.isSelected && obj is StickyNote) as StickyNote;
    } catch (_) {
      return null;
    }
  }

  Future<Color?> _showColorPicker(BuildContext context, Color currentColor) async {
    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Colors.black, Colors.white, Colors.red, Colors.green,
              Colors.blue, Colors.yellow, Colors.orange, Colors.purple,
              Colors.pink, Colors.brown, Colors.grey, Colors.transparent,
            ].map((color) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context, color);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: color == currentColor ? Colors.blue : Colors.grey,
                      width: color == currentColor ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }).toList(),
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
  }
}

class BottomControls extends StatelessWidget {
  final CanvasService service;

  const BottomControls({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: service.canUndo ? service.undo : null,
              tooltip: 'Undo (Ctrl+Z)',
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: service.canRedo ? service.redo : null,
              tooltip: 'Redo (Ctrl+Y)',
            ),
            const VerticalDivider(),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: service.deleteSelected,
              tooltip: 'Delete (Del)',
            ),
          ],
        ),
      ),
    );
  }
}

class PerformanceMetrics extends StatelessWidget {
  final CanvasService service;

  const PerformanceMetrics({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Text(
          'Objects: ${service.objects.length} | QuadTree Optimized',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

class AutoSaveControls extends StatelessWidget {
  final CanvasService service;

  const AutoSaveControls({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Auto-save toggle
            Row(
              children: [
                const Text('Auto-save: '),
                Switch(
                  value: service.isAutoSaveEnabled,
                  onChanged: (value) => service.setAutoSaveEnabled(value),
                ),
              ],
            ),
            const Divider(),

            // Save button
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _showSaveDialog(context),
              tooltip: 'Save Canvas',
            ),

            // Load button
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: () => _showLoadDialog(context),
              tooltip: 'Load Canvas',
            ),
          ],
        ),
      ),
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
        await service.saveCanvasToFile(fileName: result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved as: $result')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Save failed: $e')),
          );
        }
      }
    }
  }

  Future<void> _showLoadDialog(BuildContext context) async {
    final files = await _listSavedFiles();

    if (!context.mounted) return;

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
                  'Modified: ${file.lastModified.toString().split('.')[0]}',
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
      try {
        await service.loadCanvasFromFile(fileName: selected);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Loaded: $selected')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Load failed: $e')),
          );
        }
      }
    }
  }

  Future<List<FileInfo>> _listSavedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.canvas.json'))
          .toList();

      final fileInfos = <FileInfo>[];
      for (var file in files) {
        final stat = await file.stat();
        final name = file.path.split('/').last.replaceAll('.canvas.json', '');
        fileInfos.add(FileInfo(
          name: name,
          path: file.path,
          lastModified: stat.modified,
          size: stat.size,
        ));
      }

      fileInfos.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      return fileInfos;
    } catch (e) {
      print('❌ List files error: $e');
      return [];
    }
  }
}

// Connector Confirmation Dialog Widget
class ConnectorConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConnectorConfirmationDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Connection?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text('Convert freehand line to connection'),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: onConfirm,
                  child: const Text('Yes'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onCancel,
                  child: const Text('No'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Back Button Widget
class CanvasBackButton extends StatelessWidget {
  final VoidCallback onBack;

  const CanvasBackButton({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onBack,
            child: const Center(
              child: Icon(
                Icons.arrow_back,
                color: Colors.black87,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}