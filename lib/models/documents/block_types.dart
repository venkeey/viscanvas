import 'dart:convert';
import 'package:flutter/material.dart';

enum BlockType {
  paragraph,
  heading1,
  heading2,
  heading3,
  bulletedListItem,
  numberedListItem,
  toDo,
  toggle,
  code,
  quote,
  callout,
  divider,
  image,
  video,
  file,
  embed,
  bookmark,
  table,
  tableRow,
  columnList,
  column,
  tableOfContents,
  breadcrumb,
  linkToPage,
  childPage,
  childDatabase,
  syncedBlock,
}

abstract class Block {
  final String id;
  final BlockType type;
  final Map<String, dynamic> content;
  final Map<String, dynamic> properties;

  Block({
    required this.id,
    required this.type,
    required this.content,
    this.properties = const {},
  });

  // Abstract methods
  String getPlainText();
  Widget render();
  Block clone();

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'content': content,
      'properties': properties,
    };
  }

  factory Block.fromJson(Map<String, dynamic> json) {
    final type = BlockType.values.firstWhere(
      (t) => t.toString() == json['type'],
    );

    // This would need to be implemented for each block type
    // For now, return a basic implementation
    return BasicBlock.fromJson(json);
  }
}

// Basic implementation for testing
class BasicBlock extends Block {
  BasicBlock({
    required super.id,
    required super.type,
    required super.content,
    super.properties,
  });

  factory BasicBlock.fromJson(Map<String, dynamic> json) {
    return BasicBlock(
      id: json['id'],
      type: BlockType.values.firstWhere((t) => t.toString() == json['type']),
      content: json['content'] ?? {},
      properties: json['properties'] ?? {},
    );
  }

  @override
  String getPlainText() {
    return content['text']?.toString() ?? '';
  }

  @override
  Widget render() {
    return Text(getPlainText());
  }

  @override
  Block clone() {
    return BasicBlock(
      id: '${id}_copy',
      type: type,
      content: Map.from(content),
      properties: Map.from(properties),
    );
  }
}