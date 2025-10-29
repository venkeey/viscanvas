import 'package:flutter/material.dart';
import '../models/documents/notion_blocks.dart';
import '../models/documents/rich_text.dart';
import '../models/documents/block_types.dart';
import 'notion_document_editor.dart';

/// Demo page showing Notion-style blocks
class NotionDemo extends StatefulWidget {
  const NotionDemo({Key? key}) : super(key: key);

  @override
  State<NotionDemo> createState() => _NotionDemoState();
}

class _NotionDemoState extends State<NotionDemo> {
  late List<NotionBlock> _blocks;

  @override
  void initState() {
    super.initState();
    _blocks = _createSampleBlocks();
  }

  List<NotionBlock> _createSampleBlocks() {
    return [
      NotionBlock.fromJson({
        'id': 'block_1',
        'type': BlockType.heading1.toString(),
        'richText': RichTextContent.plain('Welcome to Notion-Style Blocks').toJson(),
        'properties': {},
      }),
      NotionBlock.fromJson({
        'id': 'block_2',
        'type': BlockType.paragraph.toString(),
        'richText': RichTextContent.plain('This is a paragraph with some text. You can type "/" to see the block creation menu.').toJson(),
        'properties': {},
      }),
      NotionBlock.fromJson({
        'id': 'block_3',
        'type': BlockType.heading2.toString(),
        'richText': RichTextContent.plain('Features').toJson(),
        'properties': {},
      }),
      NotionBlock.fromJson({
        'id': 'block_4',
        'type': BlockType.bulletedListItem.toString(),
        'richText': RichTextContent.plain('Rich text editing with formatting').toJson(),
        'properties': {},
      }),
      NotionBlock.fromJson({
        'id': 'block_5',
        'type': BlockType.bulletedListItem.toString(),
        'richText': RichTextContent.plain('Slash commands for quick block creation').toJson(),
        'properties': {},
      }),
      NotionBlock.fromJson({
        'id': 'block_6',
        'type': BlockType.bulletedListItem.toString(),
        'richText': RichTextContent.plain('Multiple block types (headings, lists, code, etc.)').toJson(),
        'properties': {},
      }),
      NotionBlock.fromJson({
        'id': 'block_7',
        'type': BlockType.toDo.toString(),
        'richText': RichTextContent.plain('Interactive checkboxes').toJson(),
        'properties': {'checked': false},
      }),
      NotionBlock.fromJson({
        'id': 'block_8',
        'type': BlockType.toDo.toString(),
        'richText': RichTextContent.plain('Completed task example').toJson(),
        'properties': {'checked': true},
      }),
      NotionBlock.fromJson({
        'id': 'block_9',
        'type': BlockType.quote.toString(),
        'richText': RichTextContent.plain('This is a quote block with italic text and a left border.').toJson(),
        'properties': {},
      }),
      NotionBlock.fromJson({
        'id': 'block_10',
        'type': BlockType.code.toString(),
        'richText': RichTextContent.plain('// This is a code block\nconst message = "Hello, Notion-style blocks!";\nconsole.log(message);').toJson(),
        'properties': {'language': 'javascript'},
      }),
      NotionBlock.fromJson({
        'id': 'block_11',
        'type': BlockType.callout.toString(),
        'richText': RichTextContent.plain('This is a callout block with an icon and colored background.').toJson(),
        'properties': {'icon': '💡', 'color': 'blue'},
      }),
      NotionBlock.fromJson({
        'id': 'block_12',
        'type': BlockType.divider.toString(),
        'richText': RichTextContent.empty().toJson(),
        'properties': {},
      }),
      NotionBlock.fromJson({
        'id': 'block_13',
        'type': BlockType.paragraph.toString(),
        'richText': RichTextContent.plain('Try creating new blocks by typing "/" and selecting from the menu!').toJson(),
        'properties': {},
      }),
    ];
  }

  void _onBlocksChanged(List<NotionBlock> blocks) {
    setState(() {
      _blocks = blocks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notion-Style Blocks Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: NotionDocumentEditor(
        blocks: _blocks,
        title: 'Notion-Style Blocks Demo',
        onBlocksChanged: _onBlocksChanged,
      ),
    );
  }
}




