import '../../domain/canvas_domain.dart';
import '../../models/canvas_objects/sticky_note.dart';
import '../../models/canvas_objects/document_block.dart';
import '../../models/documents/document_content.dart';
import '../../utils/logger.dart';

class CanvasDocumentService {
  final InMemoryCanvasRepository _repository;
  final CommandHistory _commandHistory;

  // Callbacks
  void Function(DocumentBlock)? onOpenDocumentEditor;
  void Function()? onDocumentChanged;

  // Text editing state
  StickyNote? _editingStickyNote;

  CanvasDocumentService(
    this._repository,
    this._commandHistory,
  );

  // ===== PUBLIC API =====

  void updateDocumentBlockContent(String documentBlockId, DocumentContent newContent) {
    print('🔄 updateDocumentBlockContent called for ID: $documentBlockId');
    CanvasLogger.canvasService('Updating document block content for ID: $documentBlockId');
    final documentBlock = _repository.getById(documentBlockId);
    if (documentBlock is DocumentBlock) {
      print('✅ Found DocumentBlock, old content: ${documentBlock.content?.blocks.length ?? 0} blocks');
      CanvasLogger.canvasService('Found document block, updating content');
      CanvasLogger.canvasService('Old content blocks: ${documentBlock.content?.blocks.length ?? 0}');
      CanvasLogger.canvasService('New content blocks: ${newContent.blocks.length}');

      final oldState = documentBlock.clone();
      documentBlock.content = newContent;
      documentBlock.invalidateCache(); // Clear cached rendering
      print('📝 Set new content: ${documentBlock.content?.blocks.length ?? 0} blocks');
      CanvasLogger.canvasService('Invalidated cache');

      _commandHistory.execute(ModifyObjectCommand(_repository, documentBlock.id, oldState, documentBlock));
      print('💾 Executed modify command');
      CanvasLogger.canvasService('Executed modify command');

      onDocumentChanged?.call();
      print('🔔 Notified listeners - should trigger autosave');
      CanvasLogger.canvasService('Notified listeners - canvas should redraw');
    } else {
      print('❌ DocumentBlock not found with ID: $documentBlockId');
      CanvasLogger.canvasService('Document block not found with ID: $documentBlockId');
    }
  }

  void _openDocumentEditor(DocumentBlock documentBlock) {
    // Call the callback set by the canvas screen
    onOpenDocumentEditor?.call(documentBlock);
  }

  void _startEditingStickyNote(StickyNote stickyNote) {
    _editingStickyNote = stickyNote;
    stickyNote.isEditing = true;
    onDocumentChanged?.call();
  }

  void stopEditingStickyNote() {
    if (_editingStickyNote != null) {
      _editingStickyNote!.isEditing = false;
      _editingStickyNote = null;
      onDocumentChanged?.call();
    }
  }

  void updateStickyNoteText(String newText) {
    if (_editingStickyNote != null) {
      final oldState = _editingStickyNote!.clone();
      _editingStickyNote!.text = newText;
      _commandHistory.execute(ModifyObjectCommand(_repository, _editingStickyNote!.id, oldState, _editingStickyNote!));
      onDocumentChanged?.call();
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}
