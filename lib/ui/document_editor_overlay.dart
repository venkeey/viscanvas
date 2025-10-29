import 'package:flutter/material.dart';
import '../models/documents/document_content.dart';
import '../models/documents/block_types.dart';
import '../models/documents/notion_blocks.dart';
import '../models/documents/rich_text.dart';
import '../utils/logger.dart';
import 'block_renderer.dart';
import 'notion_document_editor.dart';

/// Overlay document editor for hybrid mode
class DocumentEditorOverlay extends StatefulWidget {
  final DocumentContent document;
  final VoidCallback? onClose;
  final Function(DocumentContent)? onDocumentChanged;

  const DocumentEditorOverlay({
    Key? key,
    required this.document,
    this.onClose,
    this.onDocumentChanged,
  }) : super(key: key);

  @override
  State<DocumentEditorOverlay> createState() => _DocumentEditorOverlayState();
}

class _DocumentEditorOverlayState extends State<DocumentEditorOverlay> {
  late DocumentContent _currentDocument;

  @override
  void initState() {
    super.initState();
    _currentDocument = widget.document;
  }

  @override
  Widget build(BuildContext context) {
    // Convert DocumentContent blocks to NotionBlocks
    final notionBlocks = _currentDocument.blocks.map((block) {
      return NotionBlock.fromJson({
        'id': block.id,
        'type': block.type.toString(),
        'richText': RichTextContent.plain(block.getPlainText()).toJson(),
        'properties': block.properties,
      });
    }).toList();

    return NotionDocumentOverlay(
      initialBlocks: notionBlocks,
      initialTitle: _currentDocument.getTitle(),
      onSave: (blocks, title) {
        // Convert NotionBlocks back to DocumentContent blocks
        final updatedBlocks = blocks.map((notionBlock) {
          return BasicBlock(
            id: notionBlock.id,
            type: notionBlock.type,
            content: {'text': notionBlock.richText.plainText},
            properties: notionBlock.properties,
          );
        }).toList();

        setState(() {
          _currentDocument.blocks.clear();
          _currentDocument.blocks.addAll(updatedBlocks);
        });

        _notifyDocumentChanged();
        widget.onClose?.call();
      },
      onClose: widget.onClose,
    );
  }



  void _notifyDocumentChanged() {
    CanvasLogger.documentEditor('Notifying document changed with ${_currentDocument.blocks.length} blocks');
    for (var block in _currentDocument.blocks) {
      CanvasLogger.documentEditor('Block ${block.id}: ${block.getPlainText()}');
    }
    widget.onDocumentChanged?.call(_currentDocument);
  }
}

/// Simple document creation dialog
class DocumentCreationDialog extends StatefulWidget {
  final Function(String title)? onCreate;

  const DocumentCreationDialog({
    Key? key,
    this.onCreate,
  }) : super(key: key);

  @override
  State<DocumentCreationDialog> createState() => _DocumentCreationDialogState();
}

class _DocumentCreationDialogState extends State<DocumentCreationDialog> {
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Document'),
      content: TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Document Title',
          hintText: 'Enter document title...',
        ),
        autofocus: true,
        onSubmitted: (value) {
          _createDocument();
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createDocument,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _createDocument() {
    final title = _titleController.text.trim();
    if (title.isNotEmpty) {
      widget.onCreate?.call(title);
      Navigator.of(context).pop();
    }
  }
}