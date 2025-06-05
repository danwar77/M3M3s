import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'overlay_item_model.dart'; // Assuming overlay_item_model.dart is in the same directory or lib/models/
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

  // New state variables for Sticker/Image Overlays
  List<OverlayItem> _overlayItems = []; // List to hold all active overlay items
  String? _selectedOverlayId;      // ID of the currently selected overlay item for manipulation

  // New state variables for gesture handling of selected overlay item
  double _gestureInitialStickerScale = 1.0;
  double _gestureInitialStickerRotation = 0.0;
  // Offset _gestureInitialFocalPoint = Offset.zero; // For more precise combined drag/scale/rotate - keep commented for now
  // Offset _gestureInitialStickerOffset = Offset.zero; // For more precise combined drag/scale/rotate - keep commented for now

  // Define the list of available sticker assets (as conceptualized in Plan Step 1)
  // User needs to ensure these assets are in their pubspec.yaml and project structure.
  final List<String> _availableStickerAssets = [
    'assets/stickers/sticker_cool_sunglasses.png',
    'assets/stickers/sticker_party_hat.png',
    'assets/stickers/sticker_thumbs_up.png',
    'assets/stickers/sticker_speech_bubble_wow.png',
    'assets/stickers/sticker_heart_eyes.png',
  ];

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

void _addStickerToCanvas(String assetPath) {
  if (!mounted) return;
  setState(() {
    final newSticker = OverlayItem(
      assetPath: assetPath,
      offset: const Offset(50, 50), 
      scale: 0.5, 
    );
    _overlayItems.add(newSticker);
    _selectedOverlayId = newSticker.id; 
    _overlayItems = _overlayItems.map((item) {
      return item.copyWith(isSelected: item.id == _selectedOverlayId);
    }).toList();
  });
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Sticker added! Drag to position.'), duration: Duration(seconds: 2), backgroundColor: Colors.green),
  );
}

void _showStickerBrowser() {
  if (_isSaving || _isSharing) return; 

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext bc) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Column(
              children: [
                Padding( 
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10))),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10.0),
                  child: Text("Add a Sticker", style: Theme.of(context).textTheme.titleLarge),
                ),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(12.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, 
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 1.0, 
                    ),
                    itemCount: _availableStickerAssets.length,
                    itemBuilder: (context, index) {
                      final assetPath = _availableStickerAssets[index];
                      return InkWell(
                        onTap: () {
                          _addStickerToCanvas(assetPath);
                          Navigator.pop(context); 
                        },
                        child: Card(
                          elevation: 1.0,
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset( 
                              assetPath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print("Error loading asset: $assetPath, $error");
                                return Center(child: Icon(Icons.error_outline, color: Colors.red[300], size: 30));
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  Future<Uint8List?> _captureMemeAsImage() async {
    if (!mounted) return null;
    if (_selectedOverlayId != null) {
      setState(() {
        _selectedOverlayId = null;
        _overlayItems = _overlayItems.map((item) => item.copyWith(isSelected: false)).toList();
      });
      await Future.delayed(const Duration(milliseconds: 50)); 
    }
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
          SnackBar(content: Text('Error capturing meme image: ${e.toString()}'), backgroundColor: Colors.redAccent ?? Colors.redAccent),
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
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Error: User not logged in.'), backgroundColor: Colors.redAccent ?? Colors.redAccent));
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
      
      if (memeDataToInsert['template_id'] == null) {
        memeDataToInsert.remove('template_id');
      }
      
      await supabase.from('memes').insert(memeDataToInsert);

      if (mounted) {
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Meme saved successfully! 🎉'), backgroundColor: Colors.green));
      }
    } on StorageException catch (error) {
        if (mounted) {
          scaffoldMessenger.removeCurrentSnackBar();
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('Storage Error: ${error.message}'), backgroundColor: Colors.redAccent ));
        }
    } on PostgrestException catch (error) {
        if (mounted) {
          scaffoldMessenger.removeCurrentSnackBar();
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('Database Error: ${error.message}'), backgroundColor: Colors.redAccent ));
        }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('An unexpected error occurred: ${e.toString()}'), backgroundColor: Colors.redAccent ));
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
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Could not prepare meme for sharing.'), backgroundColor:Colors.redAccent ));
        setState(() => _isSharing = false);
      }
      return;
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'meme_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      final shareResult = await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')], text: 'Check out this awesome meme I made with M3M3s!', subject: 'Meme from M3M3s App');
      if (mounted) {
        scaffoldMessenger.removeCurrentSnackBar();
        if (shareResult.status == ShareResultStatus.success) {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Meme shared!'), backgroundColor: Colors.green));        } else if (shareResult.status == ShareResultStatus.dismissed) {
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Sharing dismissed.'), backgroundColor: Colors.orangeAccent));
        } else {
           scaffoldMessenger.showSnackBar(SnackBar(content: Text('Sharing unavailable or failed: ${shareResult.status}'), backgroundColor: Colors.grey[700] ?? Colors.grey));
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error sharing meme: ${e.toString()}'), backgroundColor: Colors.redAccent ?? Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Widget _buildMemePreview(BuildContext context) {
    final theme = Theme.of(context);
    Widget imageWidget;
    
    if (widget.initialMemeData.localImageFile != null) {
      imageWidget = Image.file(
        widget.initialMemeData.localImageFile!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) { 
          print("Error loading local file: $error");
          return const Center(child: Icon(Icons.broken_image_outlined, size: 50, color: Colors.redAccent));
        }
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
        }
      );
    } else {
      imageWidget = Container(
        color: Colors.grey[300],
        child: const Center(child: Text('Error: No image source provided!')),
      );
    }

    Widget _buildTextElement(String text, {required bool isTopText}) {
        TextStyle fillTextStyle = TextStyle(
          fontFamily: _fontFamily,
          fontSize: _fontSize,
          color: _textColor, 
          fontWeight: FontWeight.bold, 
        );

        if (!_isTextStrokeEnabled || _textStrokeWidth <= 0) {
          if (!_isTextStrokeEnabled && _textStrokeWidth <=0) { 
              fillTextStyle = fillTextStyle.copyWith(
                shadows: const <Shadow>[ 
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
            overflow: TextOverflow.visible, 
          );
        }

        TextStyle strokeTextStyle = TextStyle(
          fontFamily: _fontFamily,
          fontSize: _fontSize,
          fontWeight: FontWeight.bold, 
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = _textStrokeWidth
            ..color = _textStrokeColor 
            ..strokeJoin = StrokeJoin.round 
            ..strokeCap = StrokeCap.round, 
        );

        return Stack(
          children: [
            Text(
              text.toUpperCase(),
              textAlign: TextAlign.center,
              style: strokeTextStyle,
              overflow: TextOverflow.visible, 
            ),
            Text(
              text.toUpperCase(),
              textAlign: TextAlign.center,
              style: fillTextStyle,
              overflow: TextOverflow.visible, 
            ),
          ],
        );
      }

    return RepaintBoundary(
      key: _memeBoundaryKey,
      child: AspectRatio(
        aspectRatio: 4 / 3, 
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor, width: 1),
            color: Colors.black,
          ),
          child: Stack( 
            alignment: Alignment.center, 
            children: <Widget>[
              Center(child: imageWidget),
              Positioned(
                top: 10, left: 10, right: 10,
                child: _buildTextElement(_topTextController.text, isTopText: true),
              ),
              Positioned(
                bottom: 10, left: 10, right: 10,
                child: _buildTextElement(_bottomTextController.text, isTopText: false),
              ),
              ..._overlayItems.map((overlayItem) {
                const double stickerBaseRenderSize = 60.0;
                bool isSelected = overlayItem.id == _selectedOverlayId;

                Widget stickerVisual = Image.asset(
                  overlayItem.assetPath,
                  width: stickerBaseRenderSize, 
                  height: stickerBaseRenderSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print("Error loading sticker asset: ${overlayItem.assetPath}, $error");
                    return Container(
                      width: stickerBaseRenderSize, height: stickerBaseRenderSize,
                      color: Colors.red.withOpacity(0.3),
                      child: const Icon(Icons.broken_image_outlined, size: 20, color: Colors.white),
                    );
                  }
                );

                Widget interactiveSticker = Transform.rotate(
                  angle: overlayItem.rotation,
                  child: Transform.scale(
                    scale: overlayItem.scale,
                    child: stickerVisual,
                  ),
                );
                
                final double actualScaledWidth = stickerBaseRenderSize * overlayItem.scale;
                final double actualScaledHeight = stickerBaseRenderSize * overlayItem.scale;

                List<Widget> stackChildren = [
                  interactiveSticker, 
                ];

                if (isSelected) {
                  stackChildren.add(
                    Positioned.fill( 
                      child: Container(
                        width: actualScaledWidth,
                        height: actualScaledHeight,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.9),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  );
                  
                  final double handleSize = 24.0;
                  final double handleOffset = -handleSize / 2;

                  stackChildren.add(
                    Positioned(
                      top: handleOffset,
                      right: handleOffset,
                      child: GestureDetector(
                        onTap: () {
                          if(!mounted || _isSaving || _isSharing) return;
                          final String? currentSelectedId = overlayItem.id; 
                          setState(() {
                              _overlayItems.removeWhere((item) => item.id == currentSelectedId);
                              if (_selectedOverlayId == currentSelectedId) {
                                _selectedOverlayId = null; 
                              }
                          });
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sticker removed.'), backgroundColor: Colors.orangeAccent)
                          );
                        },
                        child: Container(
                          width: handleSize, height: handleSize,
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 16.0),
                        ),
                      ),
                    ),
                  );

                  stackChildren.add(
                    Positioned(
                      bottom: handleOffset,
                      right: handleOffset,
                      child: GestureDetector(
                        child: Container(
                          width: handleSize, height: handleSize,
                          decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.9), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.0)),
                          child: const Icon(Icons.transform_rounded, color: Colors.white, size: 14.0),
                        ),
                      ),
                    ),
                  );
                }
                
                return Positioned(
                  left: overlayItem.offset.dx,
                  top: overlayItem.offset.dy,
                  child: GestureDetector(
                    onPanStart: (DragStartDetails details) {
                      if (!mounted || _isSaving || _isSharing) return;
                      setState(() {
                        final index = _overlayItems.indexWhere((item) => item.id == overlayItem.id);
                        if (index != -1) {
                          final item = _overlayItems.removeAt(index);
                          _overlayItems.add(item); 
                          _selectedOverlayId = item.id; 
                          _gestureInitialStickerScale = item.scale;
                          _gestureInitialStickerRotation = item.rotation;
                        }
                        _overlayItems = _overlayItems.map((item) {
                          return item.copyWith(isSelected: item.id == _selectedOverlayId);
                        }).toList();
                      });
                    },
                    onPanUpdate: (DragUpdateDetails details) {
                      if (!mounted || _isSaving || _isSharing || _selectedOverlayId != overlayItem.id) return;
                       setState(() {
                        final index = _overlayItems.indexWhere((item) => item.id == _selectedOverlayId);
                        if (index != -1) {
                          _overlayItems[index].offset = Offset(
                            _overlayItems[index].offset.dx + details.delta.dx,
                            _overlayItems[index].offset.dy + details.delta.dy,
                          );
                        }
                      });
                    },
                    onScaleStart: (ScaleStartDetails details) {
                      if (!mounted || _isSaving || _isSharing) return;
                      final int index = _overlayItems.indexWhere((item) => item.id == overlayItem.id);
                      if (index == -1) return; 
                      final OverlayItem currentItem = _overlayItems[index];
                      if (_selectedOverlayId != overlayItem.id || index != _overlayItems.length - 1) {
                        setState(() {
                          final item = _overlayItems.removeAt(index);
                          _overlayItems.add(item); 
                          _selectedOverlayId = item.id;
                          _overlayItems = _overlayItems.map((i) => i.copyWith(isSelected: i.id == _selectedOverlayId)).toList();
                          _gestureInitialStickerScale = _overlayItems.last.scale;
                          _gestureInitialStickerRotation = _overlayItems.last.rotation;
                        });
                      } else {
                        _gestureInitialStickerScale = currentItem.scale;
                        _gestureInitialStickerRotation = currentItem.rotation;
                      }
                    },
                    onScaleUpdate: (ScaleUpdateDetails details) {
                      if (!mounted || _isSaving || _isSharing || _selectedOverlayId != overlayItem.id) return;
                      setState(() {
                        final index = _overlayItems.indexWhere((item) => item.id == _selectedOverlayId);
                        if (index != -1) {
                          double newScale = _gestureInitialStickerScale * details.scale;
                          _overlayItems[index].scale = newScale.clamp(0.2, 5.0); 
                          // Rotation logic will be added here in next step
                          // _overlayItems[index].rotation = _gestureInitialStickerRotation + details.rotation;
                        }
                      });
                    },
                    onScaleEnd: (ScaleEndDetails details) {
                      if (!mounted || _isSaving || _isSharing || _selectedOverlayId != overlayItem.id) return;
                      // _gestureInitialStickerScale = 1.0; 
                      // _gestureInitialStickerRotation = 0.0;
                    },
                    child: Stack( 
                      clipBehavior: Clip.none, 
                      alignment: Alignment.center, 
                      children: stackChildren,
                    ),
                  ),
                );
              }).toList(),
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

Future<void> _showAdvancedColorPicker({required bool forStroke}) async {
  Color currentColor = forStroke ? _textStrokeColor : _textColor;
  Color pickerColor = currentColor; 

  if (_isSaving || _isSharing) return;

  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(forStroke ? 'Pick an Outline Color' : 'Pick a Fill Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor, 
            onColorChanged: (Color color) {
              pickerColor = color; 
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); 
            },
          ),
          ElevatedButton(
            child: const Text('Select Color'),
            onPressed: () {
              if (mounted) { 
                setState(() {
                  if (forStroke) {
                    _textStrokeColor = pickerColor;
                  } else {
                    _textColor = pickerColor;
                  }
                });
              }
              Navigator.of(context).pop(); 
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
        TextField(controller: _topTextController, decoration: InputDecoration(labelText: 'Top Text', hintText: 'Enter top text here', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true), maxLines: 2, enabled: !_isSaving && !_isSharing),
        const SizedBox(height: 12),
        TextField(controller: _bottomTextController, decoration: InputDecoration(labelText: 'Bottom Text', hintText: 'Enter bottom text here', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true), maxLines: 2, enabled: !_isSaving && !_isSharing),
        const SizedBox(height: 16),
        Row(children: [
          const Text('Font Size:'),
          Expanded(child: Slider(value: _fontSize, min: 10.0, max: 60.0, divisions: 50, label: _fontSize.round().toString(), onChanged: (_isSaving || _isSharing) ? null : (double value) => setState(() => _fontSize = value))),
           Text(_fontSize.round().toString()), 
        ]),
        Text("Fill Color", style: theme.textTheme.titleSmall),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildColorButton(Colors.white, "White"),
            _buildColorButton(Colors.black, "Black"),
            _buildColorButton(Colors.yellowAccent, "Yellow"),
            _buildColorButton(Colors.redAccent, "Red"),
            IconButton( 
              icon: Icon(Icons.colorize_outlined, color: _textColor), 
              tooltip: 'More Fill Colors',
              onPressed: (_isSaving || _isSharing) ? null : () => _showAdvancedColorPicker(forStroke: false),
            )
          ],
        ),
        const SizedBox(height: 10), 
        Row(children: [
          const Text('Font:'), const SizedBox(width: 10),
          Expanded( 
            child: DropdownButton<String>(
              value: _fontFamily,
              isExpanded: true, 
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
        SwitchListTile(
          title: const Text('Enable Text Outline'),
          value: _isTextStrokeEnabled,
          onChanged: (_isSaving || _isSharing) ? null : (bool value) => setState(() => _isTextStrokeEnabled = value),
          secondary: Icon(_isTextStrokeEnabled ? Icons.check_box_outlined : Icons.check_box_outline_blank_outlined),
          activeColor: theme.colorScheme.primary,
        ),
        if (_isTextStrokeEnabled) ...[
          const SizedBox(height: 8),
          Row(children: [ 
            const Text('Outline Width:'),
            Expanded(child: Slider(value: _textStrokeWidth, min: 0.5, max: 8.0, divisions: 15, label: _textStrokeWidth.toStringAsFixed(1), onChanged: (_isSaving || _isSharing) ? null : (double value) => setState(() => _textStrokeWidth = value))),
            Text(_textStrokeWidth.toStringAsFixed(1)),
          ]),
          const SizedBox(height: 8),
          Text("Outline Color", style: theme.textTheme.titleSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStrokeColorButton(Colors.black, context),
              _buildStrokeColorButton(Colors.white, context),
              _buildStrokeColorButton(Colors.redAccent[400] ?? Colors.redAccent, context),
              _buildStrokeColorButton(Colors.blueAccent[400] ?? Colors.blueAccent, context),
              IconButton( 
                icon: Icon(Icons.colorize_outlined, color: _textStrokeColor), 
                tooltip: 'More Outline Colors',
                onPressed: (_isSaving || _isSharing) ? null : () => _showAdvancedColorPicker(forStroke: true),
              )
            ],
          ),
        ],
        
        const Divider(height: 24, thickness: 1), 
        Text("Stickers & Overlays", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.sticky_note_2_outlined),
          label: const Text('Add Sticker'),
          style: ElevatedButton.styleFrom(
            // backgroundColor: theme.colorScheme.secondary, 
            // foregroundColor: theme.colorScheme.onSecondary,
          ),
          onPressed: (_isSaving || _isSharing) ? null : _showStickerBrowser,
        ),
        // TODO: Add controls for selected sticker manipulation later (delete, layer order, etc.)

      ],
    ),
  );
}

  Widget _buildColorButton(Color color, String tooltip) { // This is for FILL color
    bool isSelected = _textColor == color;
    return Tooltip(message: tooltip, child: InkWell(onTap: (_isSaving || _isSharing) ? null : () => setState(() => _textColor = color), borderRadius: BorderRadius.circular(15), child: Container(width: 30, height: 30, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[400] ?? Colors.grey, width: isSelected ? 3 : 1.5), boxShadow: isSelected ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), blurRadius: 3, spreadRadius: 1)] : []))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Preview & Edit Meme'), elevation: 1.0, actions: [_isSharing ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))) : IconButton(icon: const Icon(Icons.share_outlined), tooltip: 'Share Meme', onPressed: _isSaving ? null : _shareMeme), _isSaving ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))) : IconButton(icon: const Icon(Icons.save_alt_outlined), tooltip: 'Save Meme', onPressed: _isSharing ? null : _saveMeme)]), body: SingleChildScrollView(child: Column(children: <Widget>[const SizedBox(height: 10), _buildMemePreview(context), const Divider(height: 20, thickness: 1, indent: 16, endIndent: 16), _buildEditingControls(context), const SizedBox(height: 20)])));
  }
}


