import 'package:flutter/material.dart';
import '../models/templates/document_template.dart';
import '../models/templates/template_category.dart';
import '../services/templates/template_service.dart';
import '../widgets/template_card.dart';
import '../widgets/template_variable_dialog.dart';
import '../models/documents/document_content.dart';

class TemplateLibraryScreen extends StatefulWidget {
  final TemplateService templateService;
  final Function(DocumentContent)? onTemplateSelected;

  const TemplateLibraryScreen({
    Key? key,
    required this.templateService,
    this.onTemplateSelected,
  }) : super(key: key);

  @override
  State<TemplateLibraryScreen> createState() => _TemplateLibraryScreenState();
}

class _TemplateLibraryScreenState extends State<TemplateLibraryScreen> {
  List<DocumentTemplate> _templates = [];
  List<DocumentTemplate> _filteredTemplates = [];
  bool _isLoading = true;
  String? _error;
  
  TemplateCategory? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final templates = await widget.templateService.getAllTemplates(
        category: _selectedCategory,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
      
      setState(() {
        _templates = templates;
        _filteredTemplates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load templates: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredTemplates = _templates.where((template) {
        // Category filter
        if (_selectedCategory != null && template.category != _selectedCategory) {
          return false;
        }
        
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matches = 
            template.name.toLowerCase().contains(query) ||
            template.description.toLowerCase().contains(query) ||
            template.metadata.tags.any((tag) => tag.toLowerCase().contains(query));
          if (!matches) return false;
        }
        
        return true;
      }).toList();
    });
  }

  void _onCategorySelected(TemplateCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyFilters();
  }

  Future<void> _onTemplateTapped(DocumentTemplate template) async {
    // Check if template has variables
    if (template.variables.isEmpty) {
      // Instantiate directly without variable dialog
      try {
        final content = await widget.templateService.instantiateTemplate(
          template.id,
          {},
        );
        widget.onTemplateSelected?.call(content);
        Navigator.of(context).pop();
      } catch (e) {
        _showError('Failed to instantiate template: $e');
      }
    } else {
      // Show variable dialog
      final values = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => TemplateVariableDialog(
          template: template,
        ),
      );

      if (values != null) {
        try {
          final content = await widget.templateService.instantiateTemplate(
            template.id,
            values,
          );
          widget.onTemplateSelected?.call(content);
          Navigator.of(context).pop();
        } catch (e) {
          _showError('Failed to instantiate template: $e');
        }
      }
    }
  }

  Future<void> _onTemplateDelete(DocumentTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.templateService.deleteTemplate(template.id);
        _loadTemplates();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template "${template.name}" deleted')),
        );
      } catch (e) {
        _showError('Failed to delete template: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTemplates,
            tooltip: 'Refresh templates',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(),
          
          // Content
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                ? _buildErrorView()
                : _filteredTemplates.isEmpty
                  ? _buildEmptyView()
                  : _buildTemplatesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search templates...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(null, 'All'),
                const SizedBox(width: 8),
                ...TemplateCategory.values.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(category, category.displayName),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(TemplateCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _onCategorySelected(selected ? category : null);
      },
      avatar: category != null 
        ? Text(category.icon)
        : const Icon(Icons.apps, size: 18),
    );
  }

  Widget _buildTemplatesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = _filteredTemplates[index];
        final isDeletable = !template.id.startsWith('prebuilt_');
        
        return TemplateCard(
          template: template,
          onTap: () => _onTemplateTapped(template),
          onDelete: isDeletable
            ? () => _onTemplateDelete(template)
            : null,
          isDeletable: isDeletable,
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No templates found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != null
              ? 'Try adjusting your filters'
              : 'Templates will appear here once created',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading templates',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTemplates,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

