import 'package:flutter/material.dart';
import 'block_types.dart';

enum ReferenceType {
  mention,  // @canvas-object in document
  embed,    // Embed canvas object visual in document
  link,     // Hyperlink to canvas object
}

class CanvasReference {
  final String id;
  final String canvasObjectId;
  final String documentBlockId;
  final ReferenceType type;
  final Offset? position;
  final String? label;
  final DateTime createdAt;

  bool _isValid;

  CanvasReference({
    required this.id,
    required this.canvasObjectId,
    required this.documentBlockId,
    required this.type,
    this.position,
    this.label,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       _isValid = true;

  bool get isValid => _isValid;

  void markInvalid() {
    _isValid = false;
  }

  // Navigation methods (to be implemented by services)
  void navigateToCanvas(dynamic canvasService) {
    // Implementation would depend on canvas service
    canvasService.panToObject(canvasObjectId);
    canvasService.highlightObject(canvasObjectId, duration: Duration(seconds: 2));
  }

  void navigateToDocument(dynamic documentService) {
    // Implementation would depend on document service
    documentService.scrollToBlock(documentBlockId);
    documentService.highlightBlock(documentBlockId, duration: Duration(seconds: 2));
  }

  // Validation
  bool validate(dynamic canvasRepo, dynamic docRepo) {
    final canvasObject = canvasRepo.getById(canvasObjectId);
    final docBlock = docRepo.getBlock(documentBlockId);

    _isValid = canvasObject != null && docBlock != null;
    return _isValid;
  }

  // Visual representation
  Widget buildCanvasIndicator() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _getTypeColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        _getTypeIcon(),
        size: 16,
        color: _getTypeColor(),
      ),
    );
  }

  Widget buildDocumentLink() {
    return InkWell(
      onTap: () {
        // Navigate to canvas object
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getTypeColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _getTypeColor()),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getTypeIcon(), size: 16, color: _getTypeColor()),
            SizedBox(width: 4),
            Text(
              label ?? 'Canvas Object',
              style: TextStyle(color: _getTypeColor()),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (type) {
      case ReferenceType.mention:
        return Colors.blue;
      case ReferenceType.embed:
        return Colors.purple;
      case ReferenceType.link:
        return Colors.green;
    }
  }

  IconData _getTypeIcon() {
    switch (type) {
      case ReferenceType.mention:
        return Icons.alternate_email;
      case ReferenceType.embed:
        return Icons.insert_photo;
      case ReferenceType.link:
        return Icons.link;
    }
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'canvasObjectId': canvasObjectId,
      'documentBlockId': documentBlockId,
      'type': type.toString(),
      'position': position != null
          ? {'dx': position!.dx, 'dy': position!.dy}
          : null,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CanvasReference.fromJson(Map<String, dynamic> json) {
    return CanvasReference(
      id: json['id'],
      canvasObjectId: json['canvasObjectId'],
      documentBlockId: json['documentBlockId'],
      type: ReferenceType.values.firstWhere(
        (t) => t.toString() == json['type'],
      ),
      position: json['position'] != null
          ? Offset(json['position']['dx'], json['position']['dy'])
          : null,
      label: json['label'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class BlockHierarchy {
  final Map<String, List<String>> _parentToChildren;
  final Map<String, String?> _childToParent;

  BlockHierarchy()
      : _parentToChildren = {},
        _childToParent = {};

  void addBlock(Block block, {String? parentId}) {
    final effectiveParentId = parentId ?? '';
    _parentToChildren.putIfAbsent(effectiveParentId, () => []).add(block.id);
    _childToParent[block.id] = effectiveParentId.isEmpty ? null : effectiveParentId;
  }

  void removeBlock(String blockId) {
    final parentId = _childToParent[blockId];
    final effectiveParentId = parentId ?? '';
    _parentToChildren[effectiveParentId]?.remove(blockId);
    _childToParent.remove(blockId);

    // Remove children recursively
    final children = _parentToChildren[blockId];
    if (children != null) {
      for (final childId in List.from(children)) {
        removeBlock(childId);
      }
    }
    _parentToChildren.remove(blockId);
  }

  void moveBlock(String blockId, String newParentId, int newIndex) {
    final oldParentId = _childToParent[blockId];
    if (oldParentId != null) {
      _parentToChildren[oldParentId]?.remove(blockId);
    }

    _childToParent[blockId] = newParentId;
    final siblings = _parentToChildren.putIfAbsent(newParentId, () => []);
    siblings.insert(newIndex, blockId);
  }

  List<String> getChildren(String parentId) {
    return _parentToChildren[parentId] ?? [];
  }

  String? getParent(String blockId) {
    return _childToParent[blockId];
  }

  Map<String, dynamic> toJson() {
    return {
      'parentToChildren': _parentToChildren,
      'childToParent': _childToParent.map((k, v) => MapEntry(k, v ?? '')),
    };
  }

  factory BlockHierarchy.fromJson(Map<String, dynamic> json) {
    final hierarchy = BlockHierarchy();
    hierarchy._parentToChildren.addAll(
      Map<String, List<String>>.from(
        (json['parentToChildren'] as Map).map(
          (k, v) => MapEntry(k.toString(), List<String>.from(v)),
        ),
      ),
    );
    hierarchy._childToParent.addAll(
      Map<String, String?>.from(
        (json['childToParent'] as Map).map(
          (k, v) => MapEntry(k.toString(), v == '' ? null : v.toString()),
        ),
      ),
    );
    return hierarchy;
  }
}

class DocumentContent {
  final String id;
  final List<Block> blocks;
  final Map<String, Block> _blockMap;
  final BlockHierarchy hierarchy;

  bool isDirty;
  DateTime lastModified;
  int version;

  DocumentContent({
    required this.id,
    required this.blocks,
    required this.hierarchy,
    this.isDirty = false,
    DateTime? lastModified,
    this.version = 1,
  }) : _blockMap = {for (var block in blocks) block.id: block},
       lastModified = lastModified ?? DateTime.now();

  // Block operations
  void addBlock(Block block, {String? parentId, int? index}) {
    final insertIndex = index ?? blocks.length;
    blocks.insert(insertIndex, block);
    _blockMap[block.id] = block;
    hierarchy.addBlock(block, parentId: parentId);
    markDirty();
  }

  void removeBlock(String blockId) {
    final block = _blockMap[blockId];
    if (block != null) {
      blocks.remove(block);
      _blockMap.remove(blockId);
      hierarchy.removeBlock(blockId);
      markDirty();
    }
  }

  void updateBlock(String blockId, Map<String, dynamic> changes) {
    if (_blockMap.containsKey(blockId)) {
      // This would need to be implemented based on block type
      // For now, just mark as dirty
      markDirty();
    }
  }

  void moveBlock(String blockId, String newParentId, int newIndex) {
    final block = _blockMap[blockId];
    if (block != null) {
      blocks.remove(block);
      blocks.insert(newIndex, block);
      hierarchy.moveBlock(blockId, newParentId, newIndex);
      markDirty();
    }
  }

  // Query methods
  Block? getBlock(String blockId) => _blockMap[blockId];

  String? getTitle() {
    try {
      final titleBlock = blocks.firstWhere(
        (b) => b.type == BlockType.heading1,
      );
      return titleBlock.getPlainText();
    } catch (e) {
      return null;
    }
  }

  List<CanvasReference> extractReferences() {
    final refs = <CanvasReference>[];
    for (final block in blocks) {
      // This would need to be implemented in Block subclasses
      // For now, return empty list
    }
    return refs;
  }

  // State management
  void markDirty() {
    isDirty = true;
    lastModified = DateTime.now();
    version++;
  }

  void markClean() {
    isDirty = false;
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'lastModified': lastModified.toIso8601String(),
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'hierarchy': hierarchy.toJson(),
    };
  }

  factory DocumentContent.fromJson(Map<String, dynamic> json) {
    final blocks = (json['blocks'] as List)
        .map((b) => Block.fromJson(Map<String, dynamic>.from(b)))
        .toList();

    return DocumentContent(
      id: json['id'],
      blocks: blocks,
      hierarchy: BlockHierarchy.fromJson(Map<String, dynamic>.from(json['hierarchy'])),
      version: json['version'] ?? 1,
      lastModified: DateTime.parse(json['lastModified']),
    );
  }
}