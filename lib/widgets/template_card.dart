import 'package:flutter/material.dart';
import '../models/templates/document_template.dart';
import '../models/templates/template_category.dart';

class TemplateCard extends StatelessWidget {
  final DocumentTemplate template;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isDeletable;

  const TemplateCard({
    Key? key,
    required this.template,
    required this.onTap,
    this.onDelete,
    this.isDeletable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail/Icon
            _buildThumbnail(context),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with category icon
                    Row(
                      children: [
                        Text(
                          template.category.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            template.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDeletable && onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: onDelete,
                            tooltip: 'Delete template',
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Description
                    Expanded(
                      child: Text(
                        template.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Metadata row
                    _buildMetadataRow(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.3;
    
    if (template.preview.thumbnailPath != null || template.preview.thumbnailUrl != null) {
      // Show thumbnail image
      return Container(
        height: size * 0.6,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          child: Image.network(
            template.preview.thumbnailUrl ?? '',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultThumbnail(context);
            },
          ),
        ),
      );
    }
    
    // Default thumbnail with category icon
    return _buildDefaultThumbnail(context);
  }

  Widget _buildDefaultThumbnail(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.3;
    return Container(
      height: size * 0.6,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(template.category),
            _getCategoryColor(template.category).withOpacity(0.7),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Center(
        child: Text(
          template.category.icon,
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        // Variable count
        if (template.variables.isNotEmpty)
          Row(
            children: [
              Icon(Icons.label_outline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${template.variables.length} variables',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        
        // Rating
        if (template.rating > 0)
          Row(
            children: [
              Icon(Icons.star, size: 14, color: Colors.amber,),
              const SizedBox(width: 4),
              Text(
                template.rating.toStringAsFixed(1),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        
        const Spacer(),
        
        // Author
        Text(
          template.authorName,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(TemplateCategory category) {
    switch (category) {
      case TemplateCategory.meetingNotes:
        return Colors.blue;
      case TemplateCategory.projectPlanning:
        return Colors.green;
      case TemplateCategory.taskManagement:
        return Colors.orange;
      case TemplateCategory.documentation:
        return Colors.purple;
      case TemplateCategory.brainstorming:
        return Colors.yellow;
      case TemplateCategory.personal:
        return Colors.pink;
      case TemplateCategory.business:
        return Colors.indigo;
      case TemplateCategory.education:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

