import 'package:flutter/material.dart';
import 'dart:io'; // For File type
import 'dart:typed_data'; // For Uint8List
import 'dart:ui' as ui; // For ui.Image
import 'package:flutter/rendering.dart'; // For RenderRepaintBoundary
import 'package:supabase_flutter/supabase_flutter.dart'; // For save functionality
import 'package:share_plus/share_plus.dart'; // Import for actual sharing
import 'package:path_provider/path_provider.dart'; // For temporary file storage

class MemeData {
  final String? topText;
  final String? bottomText;
  final String? imageUrl;
  final File? localImageFile;
  final String? templateId;

  MemeData({
    this.topText,
    this.bottomText,
    this.imageUrl,
    this.localImageFile,
    this.templateId,
  }) : assert(imageUrl != null || localImageFile != null, 'Either imageUrl or localImageFile must be provided for display.');
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
  final GlobalKey _memeBoundaryKey = GlobalKey();
  bool _isSaving = false;
  bool _isSharing = false;

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
    _topTextController.addListener(() => setState(() {}));
    _bottomTextController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _topTextController.dispose();
    _bottomTextController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _captureMemeAsImage() async {
    if (!mounted) return null;
    try {
      RenderRepaintBoundary boundary = _memeBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print("Error capturing meme: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing meme image: ${e.toString()}'), backgroundColor: Colors.redAccent.shade700),
        );
      }
      return null;
    }
  }

  Future<void> _saveMeme() async {
    if (_isSaving || _isSharing) return;
    if (!mounted) return;
    setState(() => _isSaving = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.removeCurrentSnackBar();
    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Saving meme...'), duration: Duration(milliseconds: 1500)));

    final imageBytes = await _captureMemeAsImage();
    if (imageBytes == null) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      if (mounted) {
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Error: User not logged in.'), backgroundColor: Colors.redAccent.shade700));
        setState(() => _isSaving = false);
      }
      return;
    }

    final imageFileName = 'meme_${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0,8)}.png';
    final imagePath = '$userId/$imageFileName';

    try {
      await supabase.storage.from('user_memes').uploadBinary(
        imagePath,
        imageBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false, contentType: 'image/png'),
      );
      final String uploadedImageUrl = supabase.storage.from('user_memes').getPublicUrl(imagePath);
      final Map<String, dynamic> memeDataToInsert = {
        'user_id': userId, 'image_url': uploadedImageUrl,
        'text_input': {'top': _topTextController.text.trim(), 'bottom': _bottomTextController.text.trim()},
        'template_id': widget.initialMemeData.templateId,
        'is_custom_image': widget.initialMemeData.localImageFile != null || (widget.initialMemeData.imageUrl != null && widget.initialMemeData.templateId == null),
        'visibility': 'private',
      };
      if (memeDataToInsert['template_id'] == null) memeDataToInsert.remove('template_id');
      await supabase.from('memes').insert(memeDataToInsert);

      if (mounted) {
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Meme saved successfully! 🎉'), backgroundColor: Colors.green.shade700));
      }
    } on StorageException catch (error) {
        if (mounted) {
          scaffoldMessenger.removeCurrentSnackBar();
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('Storage Error: ${error.message}'), backgroundColor: Colors.redAccent.shade700));
        }
    } on PostgrestException catch (error) {
        if (mounted) {
          scaffoldMessenger.removeCurrentSnackBar();
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('Database Error: ${error.message}'), backgroundColor: Colors.redAccent.shade700));
        }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('An unexpected error occurred: ${e.toString()}'), backgroundColor: Colors.redAccent.shade700));
      }
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareMeme() async {
    if (_isSaving || _isSharing) return;
    if (!mounted) return;

    setState(() => _isSharing = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.removeCurrentSnackBar();
    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Preparing meme for sharing...')));

    final imageBytes = await _captureMemeAsImage();
    if (imageBytes == null) {
      if (mounted) {
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Could not prepare meme for sharing.'), backgroundColor: Colors.redAccent.shade700));
        setState(() => _isSharing = false);
      }
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'meme_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      print('Meme saved to temporary file for sharing: ${file.path}');

      final shareResult = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'Check out this awesome meme I made with MemeMarvel!',
        subject: 'Meme from MemeMarvel App'
      );

      if (mounted) {
        scaffoldMessenger.removeCurrentSnackBar();
        if (shareResult.status == ShareResultStatus.success) {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Meme shared!'), backgroundColor: Colors.green.shade700));
        } else if (shareResult.status == ShareResultStatus.dismissed) {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Sharing dismissed.'), backgroundColor: Colors.orangeAccent.shade700));
        } else {
           scaffoldMessenger.showSnackBar(SnackBar(content: Text('Sharing unavailable or failed: ${shareResult.status}'), backgroundColor: Colors.grey.shade700));
        }
      }
    } catch (e) {
      print("Error sharing meme: $e");
      if (mounted) {
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error sharing meme: ${e.toString()}'), backgroundColor: Colors.redAccent.shade700));
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

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
          _isSharing
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))))
            : IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share Meme', // Semantics label
                onPressed: _isSaving ? null : _shareMeme,
              ),
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))))
              : IconButton(
                  icon: const Icon(Icons.save_alt_outlined),
                  tooltip: 'Save Meme', // Semantics label
                  onPressed: _isSharing ? null : _saveMeme,
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
