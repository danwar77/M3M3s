import 'package:flutter/material.dart';
import 'dart:io'; // For File type
import 'dart:typed_data'; // For Uint8List
import 'dart:ui' as ui; // For ui.Image to work with RenderRepaintBoundary
import 'package:flutter/rendering.dart'; // For RenderRepaintBoundary
// import 'package:supabase_flutter/supabase_flutter.dart'; // TODO: Uncomment for actual Supabase calls
// import 'package:share_plus/share_plus.dart'; // TODO: Uncomment for actual sharing
// import 'package:path_provider/path_provider.dart'; // TODO: Uncomment for temporary file storage if needed for sharing

// (MemeData class remains the same as previously defined)
class MemeData {
  final String? topText;
  final String? bottomText;
  final String? imageUrl; // URL for network images (templates)
  final File? localImageFile; // File for local/uploaded images

  MemeData({
    this.topText,
    this.bottomText,
    this.imageUrl,
    this.localImageFile,
  }) : assert(imageUrl != null || localImageFile != null, 'Either imageUrl or localImageFile must be provided.');
}

class MemeDisplayScreen extends StatefulWidget {
  final MemeData initialMemeData;

  const MemeDisplayScreen({super.key, required this.initialMemeData});

  @override
  State<MemeDisplayScreen> createState() => _MemeDisplayScreenState();
}

class _MemeDisplayScreenState extends State<MemeDisplayScreen> {
  late TextEditingController _topTextController;
  late TextEditingController _bottomTextController;
  double _fontSize = 32.0;
  Color _textColor = Colors.white;
  String _fontFamily = 'Impact';

  // Key for the RepaintBoundary to capture the meme image
  final GlobalKey _memeBoundaryKey = GlobalKey();
  bool _isSaving = false; // To show loading indicator and disable buttons

  // TODO: (Advanced Editing) Explore adding a list of custom fonts.
  // TODO: (Advanced Editing) Implement a more comprehensive color picker.
  // TODO: (Advanced Editing) Add text stroke/outline options beyond simple shadows.
  // TODO: (Advanced Editing) Consider draggable text positioning and resizing.
  // TODO: (Advanced Editing) Implement state for text alignment.
  // TODO: (Advanced Editing) Add state for image filters/adjustments.
  // TODO: (Advanced Editing) Implement Undo/Redo stack.

  @override
  void initState() {
    super.initState();
    _topTextController = TextEditingController(text: widget.initialMemeData.topText ?? '');
    _bottomTextController = TextEditingController(text: widget.initialMemeData.bottomText ?? '');
    // Add listeners to update the preview when text changes
    _topTextController.addListener(() => setState(() {}));
    _bottomTextController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _topTextController.dispose();
    _bottomTextController.dispose();
    super.dispose();
  }

  /// Captures the widget identified by _memeBoundaryKey as an image (Uint8List).
  Future<Uint8List?> _captureMemeAsImage() async {
    if (!mounted) return null; // Ensure widget is still in the tree
    try {
      RenderRepaintBoundary boundary = _memeBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // Increase pixelRatio for higher quality images, default is 1.0
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print("Error capturing meme: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing meme image: ${e.toString()}')),
        );
      }
      return null;
    }
  }

  /// Handles saving the meme: captures image, uploads to Storage, saves metadata to DB.
  Future<void> _saveMeme() async {
    if (_isSaving) return; // Prevent multiple save attempts
    setState(() => _isSaving = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context); // Cache for async gap
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Saving meme...'), duration: Duration(milliseconds: 2500)),
    );

    final imageBytes = await _captureMemeAsImage();
    if (imageBytes == null) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    // --- TODO: Implement actual Supabase saving logic ---
    // Ensure supabase_flutter is initialized and user is logged in.
    // final supabase = Supabase.instance.client;
    // final userId = supabase.auth.currentUser?.id;

    // if (userId == null) {
    //   if (mounted) {
    //     scaffoldMessenger.showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text('Error: User not logged in.')));
    //     setState(() => _isSaving = false);
    //   }
    //   return;
    // }

    // final imageFileName = '${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, 6)}.png';
    // final imagePath = '$userId/memes/$imageFileName'; // Store in a user-specific folder

    try {
      // 1. Upload image to Supabase Storage (Conceptual)
      // print('Uploading image to Supabase Storage at path: $imagePath');
      // await supabase.storage.from('user_memes').uploadBinary(
      //   imagePath,
      //   imageBytes,
      //   fileOptions: const FileOptions(cacheControl: '3600', upsert: false, contentType: 'image/png'),
      // );
      // final String uploadedImageUrl = supabase.storage.from('user_memes').getPublicUrl(imagePath);
      // print('Image uploaded, URL: $uploadedImageUrl');

      // Simulate upload delay and get a placeholder URL
      await Future.delayed(const Duration(seconds: 3));
      const String uploadedImageUrl = "https://mockstorage.com/path/to/uploaded_meme.png"; // Placeholder
      print('Simulated image upload complete. URL: $uploadedImageUrl');

      // 2. Save metadata to Supabase Database (Conceptual)
      // print('Saving meme metadata to database...');
      // final response = await supabase.from('memes').insert({
      //   'user_id': userId,
      //   'image_url': uploadedImageUrl, // Store the public URL or path from storage
      //   'text_input': {'top': _topTextController.text, 'bottom': _bottomTextController.text},
      //   // 'template_id': widget.initialMemeData.templateId, // Pass templateId if available and relevant
      //   'is_custom_image': widget.initialMemeData.localImageFile != null || widget.initialMemeData.imageUrl == null, // Heuristic
      //   'visibility': 'private', // Default visibility
      //   'tags': [], // Add tags if you have a tagging system
      //   // 'analysis_results': {}, // Add analysis results if available
      // }).select(); // Use .select() if you want the inserted row back

      // if (response.error != null) {
      //   print('Database insert error: ${response.error!.message}');
      //   throw response.error!;
      // }
      // print('Meme metadata saved successfully: ${response.data}');
      await Future.delayed(const Duration(seconds: 1)); // Simulate DB save
      print('Simulated metadata save complete.');


      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Meme saved successfully! 🎉'), backgroundColor: Colors.green),
        );
        // Optionally, navigate away or provide further actions
        // Navigator.of(context).pop(); // Example: Go back after saving
      }
    } catch (e) {
      print("Error saving meme: $e");
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error saving meme: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Handles sharing the meme: captures image and uses share_plus.
  Future<void> _shareMeme() async {
    if (_isSaving) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Preparing meme for sharing...')),
    );

    final imageBytes = await _captureMemeAsImage();
    if (imageBytes == null) return;

    // --- TODO: Implement actual sharing using share_plus ---
    // Ensure share_plus and path_provider packages are added to pubspec.yaml
    try {
      // final tempDir = await getTemporaryDirectory();
      // final filePath = '${tempDir.path}/meme_to_share.png';
      // final file = await File(filePath).create();
      // await file.writeAsBytes(imageBytes);
      // print('Meme saved to temporary file: $filePath');

      // await Share.shareXFiles(
      //   [XFile(filePath)],
      //   text: 'Check out this awesome meme I made with MemeMarvel!'
      // );
      // print('Share dialog invoked.');

      // Simulate sharing action
      await Future.delayed(const Duration(seconds: 1));
      print("Simulated sharing of image bytes (${imageBytes.length} bytes)");
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Meme shared (simulated)! 🚀'), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      print("Error sharing meme: $e");
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error sharing meme: ${e.toString()}')),
        );
      }
    }
  }

  /// Builds the core meme preview widget, wrapped in RepaintBoundary for capturing.
  Widget _buildMemePreview(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    Widget imageWidget;

    if (widget.initialMemeData.imageUrl != null) {
      imageWidget = Image.network(
        widget.initialMemeData.imageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
          ));
        },
        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
          return Container(color: Colors.grey[200], child: Center(child: Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey[400])));
        },
      );
    } else if (widget.initialMemeData.localImageFile != null) {
      imageWidget = Image.file(widget.initialMemeData.localImageFile!, fit: BoxFit.contain);
    } else {
      imageWidget = Container(color: Colors.grey[300], child: const Center(child: Text('Image source not available')));
    }

    final TextStyle memeTextStyle = TextStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize,
      color: _textColor,
      fontWeight: FontWeight.w900,
      // TODO: (Advanced Editing) Make shadows/stroke configurable.
      shadows: const <Shadow>[
        Shadow(offset: Offset(-2.0, -2.0), color: Colors.black), Shadow(offset: Offset(2.0, -2.0), color: Colors.black),
        Shadow(offset: Offset(2.0, 2.0), color: Colors.black), Shadow(offset: Offset(-2.0, 2.0), color: Colors.black),
        Shadow(offset: Offset(-1.0, -1.0), color: Colors.black), Shadow(offset: Offset(1.0, -1.0), color: Colors.black),
        Shadow(offset: Offset(1.0, 1.0), color: Colors.black), Shadow(offset: Offset(-1.0, 1.0), color: Colors.black),
      ],
    );

    // Key part: Wrap the visual representation of the meme with RepaintBoundary
    return RepaintBoundary(
      key: _memeBoundaryKey,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor, width: 0.5),
            color: Colors.grey[800],
            // TODO: (Advanced Editing) Consider allowing background color change if image is transparent or smaller.
          ),
          // TODO: (Advanced Editing) For draggable text, convert Stack children to a list of
          //       editable items, each with its own position, style, and gesture detectors.
          //       This would likely involve a custom painter or more complex widget stack.
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Center(child: imageWidget), // TODO: (Advanced Editing) Add controls for image filters, crop, rotation here.
              Positioned(
                top: 15, left: 15, right: 15,
                // TODO: (Advanced Editing) Wrap Text with GestureDetector for dragging.
                child: Text(_topTextController.text.toUpperCase(), textAlign: TextAlign.center, style: memeTextStyle, maxLines: 3, overflow: TextOverflow.ellipsis),
              ),
              Positioned(
                bottom: 15, left: 15, right: 15,
                // TODO: (Advanced Editing) Wrap Text with GestureDetector for dragging.
                child: Text(_bottomTextController.text.toUpperCase(), textAlign: TextAlign.center, style: memeTextStyle, maxLines: 3, overflow: TextOverflow.ellipsis),
              ),
              // TODO: (Advanced Editing) Add UI for adding more text layers or stickers.
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditingControls(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Edit Meme Text & Style", style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: _topTextController, decoration: InputDecoration(labelText: 'Top Text', hintText: 'Enter top text here', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true), maxLines: 2),
          const SizedBox(height: 12),
          TextField(controller: _bottomTextController, decoration: InputDecoration(labelText: 'Bottom Text', hintText: 'Enter bottom text here', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true), maxLines: 2),
          const SizedBox(height: 20),
          Text('Font Size: ${_fontSize.round()}', style: theme.textTheme.titleMedium),
          Slider(value: _fontSize, min: 12.0, max: 72.0, divisions: 60, label: _fontSize.round().toString(), onChanged: (double value) => setState(() => _fontSize = value)),
          const SizedBox(height: 10),
          Text('Text Color:', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8.0, runSpacing: 8.0, alignment: WrapAlignment.center, children: [
            _buildColorButton(Colors.white, "White"), _buildColorButton(Colors.black, "Black"),
            _buildColorButton(Colors.yellowAccent, "Yellow"), _buildColorButton(Colors.redAccent, "Red"),
            _buildColorButton(Colors.lightBlueAccent, "Blue"),
            // TODO: (Advanced Editing) Add button to open a full color picker.
          ]),
          const SizedBox(height: 20),
          Text('Font Family:', style: theme.textTheme.titleMedium),
          DropdownButtonFormField<String>(
            value: _fontFamily,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0)),
            items: <String>['Impact', 'Arial', 'Comic Sans MS', 'Roboto', 'Times New Roman'] // TODO: (Advanced Editing) Populate with more fonts, possibly custom/Google Fonts.
                .map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(value: value, child: Text(value, style: TextStyle(fontFamily: value, fontSize: 16))))
                .toList(),
            onChanged: (String? newValue) { if (newValue != null) setState(() => _fontFamily = newValue); },
          ),
          const SizedBox(height: 20),
          // --- Placeholder for Advanced Editing Controls ---
          // Text("--- Advanced Editing Placeholder ---", textAlign: TextAlign.center, style: theme.textTheme.caption),
          // TODO: (Advanced Editing) Add UI controls for features like image filters, text stroke, text alignment, layer management etc. here.
          // Example:
          // ElevatedButton(onPressed: () {/* Open image filter options */}, child: Text("Apply Image Filter")),
          // ElevatedButton(onPressed: () {/* Add new text layer */}, child: Text("Add Text Layer")),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color, String tooltip) {
    bool isSelected = _textColor == color;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _textColor = color),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
            border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400, width: isSelected ? 3 : 1.5),
            boxShadow: isSelected ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), blurRadius: 3, spreadRadius: 1)] : [],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview & Edit Meme'),
        elevation: 1.0,
        actions: [
          // TODO: (Advanced Editing) Add Undo/Redo buttons here.
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Meme',
            onPressed: _isSaving ? null : _shareMeme, // Disable while saving
          ),
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)))
              : IconButton(
                  icon: const Icon(Icons.save_alt_outlined),
                  tooltip: 'Save Meme',
                  onPressed: _saveMeme,
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            _buildMemePreview(context),
            const Divider(height: 20, thickness: 1, indent: 16, endIndent: 16),
            _buildEditingControls(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

```
