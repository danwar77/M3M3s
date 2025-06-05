import 'package:flutter/material.dart';

/// A widget to display a single suggested template item.
///
/// This item typically includes a thumbnail, the template name, an optional relevance score,
/// and is tappable to select the suggestion.
class SuggestedTemplateItem extends StatelessWidget {
  /// Data for a suggested template, expected to be a map usually parsed from JSON.
  /// Example structure:
  /// json
  /// {
  ///   "id": "uuid-string-for-template",
  ///   "name": "Template Name",
  ///   "thumbnailUrl": "url_to_template_thumbnail.png", // Optional
  ///   "imageUrl": "url_to_full_template_image.png", // Main image, used if thumbnail is missing
  ///   "score": 0.85 // Optional relevance score (0.0 to 1.0)
  /// }
  /// 
  final Map<String, dynamic> suggestionData;
  final VoidCallback onTap;

  const SuggestedTemplateItem({
    super.key,
    required this.suggestionData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // Extract data with null safety and fallbacks
    final String name = suggestionData['name'] as String? ?? 'Unnamed Template';
    final String? thumbnailUrl = suggestionData['thumbnailUrl'] as String?;
    final String? imageUrl = suggestionData['imageUrl'] as String?; // Fallback if thumbnail is missing
    final double? score = suggestionData['score'] as double?;

    // Determine the URL to display for the image preview
    final String? displayImageUrl = (thumbnailUrl != null && thumbnailUrl.isNotEmpty) 
                                    ? thumbnailUrl 
                                    : (imageUrl != null && imageUrl.isNotEmpty ? imageUrl : null);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0), // Match Card's shape for ripple effect
      child: Card( // Wrap with a Card for better visual separation and elevation
        elevation: 1.0,
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0), // Adjusted margin for list context
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Padding(
          padding: const EdgeInsets.all(10.0), // Padding inside the card
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 64.0, // Slightly larger thumbnail
                height: 64.0,
                decoration: BoxDecoration(
                  color: Colors.grey[200], 
                  borderRadius: BorderRadius.circular(6.0), // Rounded corners for the image container
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5), width: 0.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: displayImageUrl != null
                    ? Image.network(
                        displayImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                          return Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 32);
                        },
                      )
                    : Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 32), // Placeholder if no URL
              ),
              const SizedBox(width: 16.0), // Increased spacing

              // Name and Score (Expanded to take available space)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, // Vertically center text
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600, // Slightly bolder for name
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (score != null) ...[
                      const SizedBox(height: 4.0), // Spacing between name and score
                      Text(
                        'Relevance: ${(score * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8.0), // Spacing before trailing icon

              // Trailing Icon to indicate actionability
              Icon(Icons.arrow_forward_ios_rounded, size: 18.0, color: colorScheme.outline.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

