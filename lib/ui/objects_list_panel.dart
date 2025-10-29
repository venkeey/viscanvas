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

  const _ObjectGroupCard({
    required this.typeName,
    required this.objects,
    required this.onObjectTap,
    required this.selectedIds,
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
          // Group header
          Container(
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

            return ListTile(
              dense: true,
              title: Text(
                '$typeName #${index + 1}',
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
            );
          }).toList(),
        ],
      ),
    );
  }
}

