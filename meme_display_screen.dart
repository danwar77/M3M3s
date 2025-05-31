import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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

  // New state variables for Text Stroke/Outline
  bool _isTextStrokeEnabled = true; // Default to enabled
  Color _textStrokeColor = Colors.black; // Default stroke color
  double _textStrokeWidth = 2.0; // Default stroke width

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
    // ... (implementation as previously defined)
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
        'user_id': userId,
        'image_url': uploadedImageUrl,
        'text_input': {'top': _topTextController.text.trim(), 'bottom': _bottomTextController.text.trim()},
        'template_id': widget.initialMemeData.templateId,
        'is_custom_image': widget.initialMemeData.localImageFile != null || (widget.initialMemeData.imageUrl != null && widget.initialMemeData.templateId == null),
        'visibility': 'private',
      };

      // This if block was redundant as the initial assignment of 'is_custom_image' is already comprehensive.
      // if (memeDataToInsert['template_id'] == null && widget.initialMemeData.localImageFile == null) {
      //    memeDataToInsert['is_custom_image'] = widget.initialMemeData.localImageFile != null || (widget.initialMemeData.imageUrl != null && widget.initialMemeData.templateId == null);
      // }

      if (memeDataToInsert['template_id'] == null) {
        memeDataToInsert.remove('template_id');
      }

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
    // ... (implementation as previously defined)
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
      final shareResult = await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')], text: 'Check out this awesome meme I made with MemeMarvel!', subject: 'Meme from MemeMarvel App');
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
      if (mounted) {
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error sharing meme: ${e.toString()}'), backgroundColor: Colors.redAccent.shade700));
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Widget _buildMemePreview(BuildContext context) {
    // ... (implementation as previously defined)
    final theme = Theme.of(context);
    Widget imageWidget;

    // Image loading logic (remains the same)
    if (widget.initialMemeData.localImageFile != null) {
      imageWidget = Image.file(
        widget.initialMemeData.localImageFile!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading local file: $error");
          return const Center(child: Icon(Icons.broken_image_outlined, size: 50, color: Colors.redAccent));
        },
      );
    } else if (widget.initialMemeData.imageUrl != null) {
      imageWidget = Image.network(
        widget.initialMemeData.imageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2.0));
        },
        errorBuilder: (context, error, stackTrace) {
          print("Error loading network image: $error");
          return const Center(child: Icon(Icons.signal_wifi_off_outlined, size: 50, color: Colors.orangeAccent));
        },
      );
    } else {
      imageWidget = Container(
        color: Colors.grey[300],
        child: const Center(child: Text('Error: No image source provided!')),
      );
    }

    // Helper function to build a single text element (either top or bottom)
    Widget _buildTextElement(String text, {required bool isTopText}) {
      // Fill text style
      TextStyle fillTextStyle = TextStyle(
        fontFamily: _fontFamily,
        fontSize: _fontSize,
        color: _textColor, // User-selected fill color
        fontWeight: FontWeight.bold, // Common for meme text
      );

      if (!_isTextStrokeEnabled || _textStrokeWidth <= 0) {
        // If stroke is disabled or width is zero, just render the fill text
        // Optionally, add back the old shadow effect here if desired as a fallback
        if (!_isTextStrokeEnabled && _textStrokeWidth <=0) { // Only add shadows if stroke is explicitly off
            fillTextStyle = fillTextStyle.copyWith(
              shadows: const <Shadow>[ // Basic text outline for when stroke is off
                  Shadow(offset: Offset(-1.5, -1.5), color: Colors.black54),
                  Shadow(offset: Offset(1.5, -1.5), color: Colors.black54),
                  Shadow(offset: Offset(1.5, 1.5), color: Colors.black54),
                  Shadow(offset: Offset(-1.5, 1.5), color: Colors.black54),
              ]
            );
        }
        return Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: fillTextStyle,
          overflow: TextOverflow.visible, // Changed from ellipsis to allow larger stroke to be visible
        );
      }

      // Stroke text style
      TextStyle strokeTextStyle = TextStyle(
        fontFamily: _fontFamily,
        fontSize: _fontSize,
        fontWeight: FontWeight.bold, // Match fill's weight for consistent glyph shape
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _textStrokeWidth
          ..color = _textStrokeColor // User-selected stroke color
          ..strokeJoin = StrokeJoin.round // Common for better looking corners
          ..strokeCap = StrokeCap.round,
      );

      return Stack(
        children: [
          // Stroke Text (drawn behind)
          Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: strokeTextStyle,
            overflow: TextOverflow.visible, // Changed from ellipsis
          ),
          // Fill Text (drawn on top)
          Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: fillTextStyle,
            overflow: TextOverflow.visible, // Changed from ellipsis
          ),
        ],
      );
    }

    return RepaintBoundary(
      key: _memeBoundaryKey,
      child: AspectRatio(
        aspectRatio: 4 / 3, // Or derive from image, or fixed size
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor, width: 1),
            color: Colors.black, // Background if image doesn't fill
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Center(child: imageWidget), // Background image

              // Top Text Element
              Positioned(
                top: 10, left: 10, right: 10,
                child: _buildTextElement(_topTextController.text, isTopText: true),
              ),

              // Bottom Text Element
              Positioned(
                bottom: 10, left: 10, right: 10,
                child: _buildTextElement(_bottomTextController.text, isTopText: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildStrokeColorButton(Color color, BuildContext context) {
  final theme = Theme.of(context);
  return InkWell(
    onTap: (_isSaving || _isSharing) ? null : () => setState(() => _textStrokeColor = color),
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: _textStrokeColor == color ? theme.colorScheme.primary : Colors.grey,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(1,1),
          )
        ]
      ),
    ),
  );
}


// New method to show the advanced color picker dialog
Future<void> _showAdvancedColorPicker({required bool forStroke}) async {
  Color currentColor = forStroke ? _textStrokeColor : _textColor;
  Color pickerColor = currentColor; // Temporary color for the picker dialog

  // Disable if saving or sharing
  if (_isSaving || _isSharing) return;

  // final scaffoldMessenger = ScaffoldMessenger.of(context); // Cache for async gap // Not strictly needed here

  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(forStroke ? 'Pick an Outline Color' : 'Pick a Fill Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor, // Current color for the picker
            onColorChanged: (Color color) {
              pickerColor = color; // Update temporary color as user interacts
            },
            // Optional: customize the picker
            // enableAlpha: false, // Set to true if you want opacity control
            // displayThumbColor: true,
            // pickerAreaHeightPercent: 0.8,
            // colorPickerWidth: 300,
            // labelTypes: const [ColorLabelType.rgb, ColorLabelType.hsv, ColorLabelType.hex],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss dialog without applying color
            },
          ),
          ElevatedButton(
            child: const Text('Select Color'),
            onPressed: () {
              if (mounted) { // Ensure widget is still in the tree
                setState(() {
                  if (forStroke) {
                    _textStrokeColor = pickerColor;
                  } else {
                    _textColor = pickerColor;
                  }
                });
              }
              Navigator.of(context).pop(); // Dismiss dialog
            },
          ),
        ],
      );
    },
  );
}


Widget _buildEditingControls(BuildContext context) {
  final theme = Theme.of(context);

  return Padding(
    padding: const EdgeInsets.all(12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Existing Controls for Fill Text ---
        TextField(
          controller: _topTextController,
          decoration: InputDecoration(labelText: 'Top Text', hintText: 'Enter top text here', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true), maxLines: 2,
          enabled: !_isSaving && !_isSharing, // Disable if saving/sharing
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bottomTextController,
          decoration: InputDecoration(labelText: 'Bottom Text', hintText: 'Enter bottom text here', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true), maxLines: 2,
          enabled: !_isSaving && !_isSharing, // Disable if saving/sharing
        ),
        const SizedBox(height: 16),
        // Font Size Control
        Row(children: [
          const Text('Font Size:'),
          Expanded(child: Slider(
            value: _fontSize, min: 10.0, max: 60.0, divisions: 50, label: _fontSize.round().toString(),
            onChanged: (_isSaving || _isSharing) ? null : (double value) => setState(() => _fontSize = value),
          )),
           Text(_fontSize.round().toString()), // Display current font size
        ]),
        // Text Fill Color Control
        Text("Fill Color", style: theme.textTheme.titleSmall),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildColorButton(Colors.white, "White"),
            _buildColorButton(Colors.black, "Black"),
            _buildColorButton(Colors.yellowAccent.shade700, "Yellow"),
            _buildColorButton(Colors.redAccent.shade400, "Red"),
            IconButton( // Button to launch advanced color picker for fill
              icon: Icon(Icons.colorize_outlined, color: _textColor), // Icon shows current fill color
              tooltip: 'More Fill Colors',
              onPressed: (_isSaving || _isSharing) ? null : () => _showAdvancedColorPicker(forStroke: false),
            )
          ],
        ),
        const SizedBox(height: 10), // Added space before font family
        // Font Family Control
        Row(children: [
          const Text('Font:'), const SizedBox(width: 10),
          Expanded( // Ensure dropdown doesn't overflow
            child: DropdownButton<String>(
              value: _fontFamily,
              isExpanded: true, // Allow dropdown to expand
              items: <String>['Impact', 'Arial', 'Comic Sans MS', 'Roboto', 'Times New Roman']
                  .map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(value: value, child: Text(value, style: TextStyle(fontFamily: value))))
                  .toList(),
              onChanged: (_isSaving || _isSharing) ? null : (String? newValue) => setState(() => _fontFamily = newValue ?? _fontFamily),
            ),
          ),
        ]),

        const Divider(height: 24, thickness: 1),
        Text("Text Outline Settings", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // --- New Controls for Text Stroke/Outline ---
        SwitchListTile(
          title: const Text('Enable Text Outline'),
          value: _isTextStrokeEnabled,
          onChanged: (_isSaving || _isSharing) ? null : (bool value) {
            setState(() {
              _isTextStrokeEnabled = value;
            });
          },
          secondary: Icon(_isTextStrokeEnabled ? Icons.check_box_outlined : Icons.check_box_outline_blank_outlined),
          activeColor: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),

        // Stroke Width Control (conditionally shown)
        if (_isTextStrokeEnabled) ...[
          Row(
            children: [
              const Text('Outline Width:'),
              Expanded(
                child: Slider(
                  value: _textStrokeWidth,
                  min: 0.5, // Min stroke width
                  max: 8.0,  // Max stroke width
                  divisions: 15, // (8.0 - 0.5) / 0.5 = 15 divisions for 0.5 steps
                  label: _textStrokeWidth.toStringAsFixed(1),
                  onChanged: (_isSaving || _isSharing) ? null : (double value) {
                    setState(() {
                      _textStrokeWidth = value;
                    });
                  },
                ),
              ),
              Text(_textStrokeWidth.toStringAsFixed(1)), // Display current width
            ],
          ),
          const SizedBox(height: 8),

          // Stroke Color Control (conditionally shown)
          // Stroke Color Control (conditionally shown)
          Text("Outline Color", style: theme.textTheme.titleSmall), // Added label for clarity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStrokeColorButton(Colors.black, context),
              _buildStrokeColorButton(Colors.white, context),
              _buildStrokeColorButton(Colors.redAccent.shade400, context),
              _buildStrokeColorButton(Colors.blueAccent.shade400, context),
              IconButton( // Button to launch advanced color picker for stroke
                icon: Icon(Icons.colorize_outlined, color: _textStrokeColor), // Icon shows current stroke color
                tooltip: 'More Outline Colors',
                onPressed: (_isSaving || _isSharing) ? null : () => _showAdvancedColorPicker(forStroke: true),
              )
            ],
          ),
        ],
      ],
    ),
  );
}

  Widget _buildColorButton(Color color, String tooltip) { // This is for FILL color
    bool isSelected = _textColor == color;
    // Access Theme.of(context) here if not already available as a member or passed in
    // For simplicity, assuming it's available or _buildEditingControls passes it if needed.
    // The original prompt's version seemed to imply Theme.of(context) would be available.
    return Tooltip(message: tooltip, child: InkWell(onTap: (_isSaving || _isSharing) ? null : () => setState(() => _textColor = color), borderRadius: BorderRadius.circular(15), child: Container(width: 30, height: 30, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400, width: isSelected ? 3 : 1.5), boxShadow: isSelected ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), blurRadius: 3, spreadRadius: 1)] : []))));
  }

  @override
  Widget build(BuildContext context) {
    // ... (implementation as previously defined)
    return Scaffold(appBar: AppBar(title: const Text('Preview & Edit Meme'), elevation: 1.0, actions: [_isSharing ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))) : IconButton(icon: const Icon(Icons.share_outlined), tooltip: 'Share Meme', onPressed: _isSaving ? null : _shareMeme), _isSaving ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))) : IconButton(icon: const Icon(Icons.save_alt_outlined), tooltip: 'Save Meme', onPressed: _isSharing ? null : _saveMeme)]), body: SingleChildScrollView(child: Column(children: <Widget>[const SizedBox(height: 10), _buildMemePreview(context), const Divider(height: 20, thickness: 1, indent: 16, endIndent: 16), _buildEditingControls(context), const SizedBox(height: 20)])));
  }
}

```
