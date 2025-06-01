import 'package:flutter/material.dart'; // For Offset and UniqueKey

class OverlayItem {
  final String id; // Unique identifier for the item
  final String assetPath; // Path to the image asset (e.g., 'assets/stickers/cool.png')
  Offset offset; // Current position (dx, dy) on the canvas
  double scale;    // Current scale factor
  double rotation; // Current rotation angle in radians
  bool isSelected; // Whether the item is currently selected for manipulation

  OverlayItem({
    String? id, // Allow providing an ID, or generate one
    required this.assetPath,
    Offset? offset,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.isSelected = false,
  }) : id = id ?? UniqueKey().toString(), // Generate a unique ID if not provided
       offset = offset ?? Offset.zero;   // Default offset to (0,0) or center of canvas later

  // Optional: copyWith method for easier state updates (especially with immutable patterns)
  OverlayItem copyWith({
    String? assetPath,
    Offset? offset,
    double? scale,
    double? rotation,
    bool? isSelected,
  }) {
    return OverlayItem(
      id: id, // ID is immutable for a given instance
      assetPath: assetPath ?? this.assetPath,
      offset: offset ?? this.offset,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  // Optional: For debugging or logging
  @override
  String toString() {
    return 'OverlayItem(id: $id, assetPath: $assetPath, offset: $offset, scale: $scale, rotation: $rotation, isSelected: $isSelected)';
  }
}
