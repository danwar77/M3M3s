import 'package:flutter/material.dart';

// Data Model for Template Information
// In a real project, this would be in a shared models file (e.g., models/template_info.dart)
// or imported from where it's defined (e.g., text_input_screen.dart if it's only used there).
// For the purpose of this subtask, it's defined here for self-containment.
class TemplateInfo {
  final String id;
  final String name;
  final String imageUrl; // Main image URL
  final String? thumbnailUrl; // Optional: smaller image for list/grid view
  final List<String>? tags;

  TemplateInfo({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.thumbnailUrl,
    this.tags,
  });

  // Example factory constructor if this model needs to parse from Supabase data directly
  // factory TemplateInfo.fromMap(Map<String, dynamic> map) {
  //   return TemplateInfo(
  //     id: map['id'] as String,
  //     name: map['name'] as String,
  //     imageUrl: map['image_url'] as String,
  //     thumbnailUrl: map['thumbnail_url'] as String?,
  //     tags: (map['tags'] as List<dynamic>?)?.map((tag) => tag.toString()).toList(),
  //   );
  // }
}


/// A widget to display a single template item in a grid or list.
///
/// It shows a thumbnail of the template and its name, and is tappable.
class TemplateListItem extends StatelessWidget {
  final TemplateInfo template;
  final VoidCallback onTap;

  const TemplateListItem({
    super.key,
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Use thumbnail if available and not empty, otherwise fallback to main image URL.
    final String displayImageUrl =
        (template.thumbnailUrl != null && template.thumbnailUrl!.isNotEmpty)
            ? template.thumbnailUrl!
            : template.imageUrl;

    return Card(
      elevation: 3.0, // Slightly more pronounced shadow
      clipBehavior: Clip.antiAlias, // Ensures the image respects the card's rounded corners
      margin: const EdgeInsets.all(4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Consistent rounded corners
      child: InkWell(
        onTap: onTap,
        splashColor: theme.colorScheme.primary.withOpacity(0.3),
        child: GridTile(
          footer: Material( // Use Material for elevation and theming consistency if needed
            color: Colors.transparent, // Make Material transparent
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0), // Adjusted padding
              // Semi-transparent gradient for a smoother look than solid color
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.9], // Control gradient spread
                ),
              ),
              child: Text(
                template.name,
                style: theme.textTheme.bodySmall?.copyWith( // Using bodySmall for footer, can be adjusted
                  color: Colors.white,
                  fontWeight: FontWeight.w600, // Slightly bolder
                  shadows: [ // Simple shadow for text pop on varied backgrounds
                    Shadow(
                      blurRadius: 2.0,
                      color: Colors.black.withOpacity(0.7),
                      offset: const Offset(1.0, 1.0),
                    ),
                  ]
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // Allow for slightly longer names
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          child: AspectRatio( // Ensure a consistent aspect ratio for the image container
            aspectRatio: 1.0, // Square, adjust as needed for your template shapes
            child: Image.network(
              displayImageUrl,
              fit: BoxFit.cover, // Cover ensures the image fills the space, cropping if necessary
              // Consider adding a specific height/width if not relying on GridView's aspect ratio
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                return Container(
                  color: Colors.grey[100], // Lighter background for error
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 36, // Slightly smaller icon
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No Preview',
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
```
