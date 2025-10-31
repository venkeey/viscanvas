import 'package:flutter/material.dart';
import '../services/canvas/canvas_service.dart';
import '../models/canvas_objects/canvas_object.dart';

class ObjectsListPanel extends StatelessWidget {
  final CanvasService service;

  const ObjectsListPanel({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final objects = service.objects;
        if (objects.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No objects on canvas',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final grouped = _groupObjectsByType(objects);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final entry = grouped.entries.toList()[index];
            final typeName = entry.key;
            final typeObjects = entry.value;

            return _ObjectGroupCard(
              typeName: typeName,
              objects: typeObjects,
              onObjectTap: (objectId) {
                service.selectObjectById(objectId);
              },
              selectedIds: objects.where((o) => o.isSelected).map((o) => o.id).toSet(),
              service: service,
            );
          },
        );
      },
    );
  }

  Map<String, List<CanvasObject>> _groupObjectsByType(List<CanvasObject> objects) {
    final groups = <String, List<CanvasObject>>{};

    for (var obj in objects) {
      final typeName = obj.getDisplayTypeName();
      groups.putIfAbsent(typeName, () => []).add(obj);
    }

    // Sort group keys for consistent display order
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) {
        // Custom ordering: Shapes first, then others
        const order = ['Rectangle', 'Circle', 'Sticky Note', 'Document', 'Connector', 'Drawing'];
        final aIndex = order.indexOf(a);
        final bIndex = order.indexOf(b);
        if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
        if (aIndex != -1) return -1;
        if (bIndex != -1) return 1;
        return a.compareTo(b);
      });

    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, groups[key]!)),
    );
  }
}

class _ObjectGroupCard extends StatelessWidget {
  final String typeName;
  final List<CanvasObject> objects;
  final Function(String) onObjectTap;
  final Set<String> selectedIds;
  final CanvasService service;

  const _ObjectGroupCard({
    required this.typeName,
    required this.objects,
    required this.onObjectTap,
    required this.selectedIds,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Group header with deterministic key for tests
          Container(
            key: Key('objectsGroup_${typeName.replaceAll(' ', '')}'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              '$typeName (${objects.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // Object list
          ...objects.asMap().entries.map((entry) {
            final index = entry.key;
            final obj = entry.value;
            final isSelected = selectedIds.contains(obj.id);

            return GestureDetector(
              onSecondaryTap: () {
                // Right-click: open properties popup
                onObjectTap(obj.id);
                _openObjectProperties(context, obj, service, defaultName: obj.label ?? '$typeName #${index + 1}');
              },
              onLongPress: () {
                // Mobile fallback
                onObjectTap(obj.id);
                _openObjectProperties(context, obj, service, defaultName: obj.label ?? '$typeName #${index + 1}');
              },
              child: ListTile(
                dense: true,
                title: Text(
                  obj.label == null || obj.label!.isEmpty
                      ? '$typeName #${index + 1}'
                      : obj.label!,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.blue, size: 20)
                    : null,
                selected: isSelected,
                selectedTileColor: Colors.blue.withOpacity(0.1),
                onTap: () => onObjectTap(obj.id),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

void _openObjectProperties(BuildContext context, CanvasObject obj, CanvasService service, {String? defaultName}) {
  showDialog(
    context: context,
    builder: (context) {
      final nameController = TextEditingController(text: obj.label ?? (defaultName ?? ''));
      double tempStrokeWidth = obj.strokeWidth;
      Color tempStroke = obj.strokeColor;
      Color? tempFill = obj.fillColor;
      TextEditingController? noteController;
      Color? noteBg;

      final isSticky = obj.runtimeType.toString() == 'StickyNote';
      if (isSticky) {
        // ignore: cast_from_null_always_fails
        final sticky = obj as dynamic;
        noteController = TextEditingController(text: sticky.text as String? ?? '');
        noteBg = sticky.backgroundColor as Color?;
      }

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Properties'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Name'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a display name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => service.setObjectLabel(obj.id, v),
                  ),
                  const SizedBox(height: 12),
                  const Text('Stroke Color'),
                  const SizedBox(height: 6),
                  _ColorRow(
                    current: tempStroke,
                    onPick: (c) {
                      setState(() => tempStroke = c);
                      service.setStrokeColor(c);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Fill Color'),
                  const SizedBox(height: 6),
                  _ColorRow(
                    current: tempFill ?? Colors.transparent,
                    onPick: (c) {
                      setState(() => tempFill = c);
                      service.setFillColor(c);
                    },
                    includeTransparent: true,
                  ),
                  const SizedBox(height: 12),
                  const Text('Stroke Width'),
                  Slider(
                    value: tempStrokeWidth,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: tempStrokeWidth.toStringAsFixed(0),
                    onChanged: (v) {
                      setState(() => tempStrokeWidth = v);
                      service.setStrokeWidth(v);
                    },
                  ),
                  if (isSticky) ...[
                    const SizedBox(height: 12),
                    const Text('Sticky Note Text'),
                    TextField(
                      controller: noteController,
                      maxLines: null,
                      onChanged: (v) => service.updateStickyNoteText(v),
                    ),
                    const SizedBox(height: 12),
                    const Text('Sticky Note Color'),
                    _ColorRow(
                      current: noteBg ?? Colors.yellow,
                      onPick: (c) {
                        setState(() => noteBg = c);
                        service.setStickyNoteBackgroundColor(c);
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // confirm delete
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete object?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    service.selectObjectById(obj.id);
                    service.deleteSelected();
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ColorRow extends StatelessWidget {
  final Color current;
  final bool includeTransparent;
  final ValueChanged<Color> onPick;

  const _ColorRow({
    required this.current,
    required this.onPick,
    this.includeTransparent = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      Colors.black, Colors.white, Colors.red, Colors.green,
      Colors.blue, Colors.yellow, Colors.orange, Colors.purple,
      Colors.pink, Colors.brown, Colors.grey,
      if (includeTransparent) Colors.transparent,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((c) {
        final selected = c.value == current.value;
        return GestureDetector(
          onTap: () => onPick(c),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: selected ? Colors.blue : Colors.grey, width: selected ? 2 : 1),
            ),
          ),
        );
      }).toList(),
    );
  }
}

