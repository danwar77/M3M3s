import 'package:flutter/material.dart';

// Placeholder for navigation or data passing if needed later
// import 'meme_display_screen.dart'; // Example: a screen to show the generated meme

class TextInputScreen extends StatefulWidget {
  const TextInputScreen({super.key});

  @override
  State<TextInputScreen> createState() => _TextInputScreenState();
}

class _TextInputScreenState extends State<TextInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topTextController = TextEditingController();
  final _bottomTextController = TextEditingController();

  // Placeholder state for selected template or image
  // In a real app, this might be a more complex object or managed by a state provider
  String? _selectedTemplateId;
  String? _selectedTemplateName; // To display a more user-friendly name
  // String? _customImagePath; // Path for a custom uploaded image from device

  @override
  void dispose() {
    _topTextController.dispose();
    _bottomTextController.dispose();
    super.dispose();
  }

  void _generateMeme() {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final topText = _topTextController.text.trim();
      final bottomText = _bottomTextController.text.trim();

      // --- TODO: Implement actual meme generation logic ---
      // 1. Determine the image source:
      //    - If _selectedTemplateId is not null, use that template's image URL.
      //    - If _customImagePath is not null, use that local image file (needs upload first).
      //    - If neither, prompt user to choose or use a default/error state.
      if (_selectedTemplateId == null /* && _customImagePath == null */) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a template or upload an image first!'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // 2. Prepare data for generation:
      //    This might involve calling a Supabase Edge Function like `get-meme-suggestions`
      //    if NLP or server-side template matching is part of the flow before final rendering.
      //    Or, if rendering is purely client-side with a selected template, you might
      //    proceed directly to a display/edit screen.

      //    Example structure for data to pass:
      //    final memeData = {
      //      'topText': topText,
      //      'bottomText': bottomText,
      //      'templateId': _selectedTemplateId,
      //      'customImagePath': _customImagePath,
      //    };

      // 3. Navigate to a MemeDisplayScreen or an editor screen:
      //    Navigator.push(
      //      context,
      //      MaterialPageRoute(
      //        builder: (context) => MemeDisplayScreen(
      //          topText: topText,
      //          bottomText: bottomText,
      //          templateId: _selectedTemplateId, // Or image path
      //          // Pass other necessary data
      //        ),
      //      ),
      //    );

      // For now, show a SnackBar with the captured info
      String message = 'Generating Meme:\nTop: "$topText"\nBottom: "$bottomText"';
      if (_selectedTemplateId != null) {
        message += '\nTemplate: "$_selectedTemplateName" (ID: $_selectedTemplateId)';
      }
      // if (_customImagePath != null) {
      //   message += '\nCustom Image: $_customImagePath';
      // }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
      print('--- Meme Generation Triggered ---');
      print('Top Text: $topText');
      print('Bottom Text: $bottomText');
      if (_selectedTemplateId != null) {
        print('Selected Template ID: $_selectedTemplateId, Name: $_selectedTemplateName');
      }
      // if (_customImagePath != null) {
      //   print('Custom Image Path: $_customImagePath');
      // }
      print('--------------------------------');
    }
  }

  void _selectTemplate() {
    // TODO: Implement template selection UI.
    // This could involve:
    // - Navigating to a new screen that lists templates (fetched from Supabase DB).
    // - Showing a dialog/modal bottom sheet with template choices.
    // Upon selection, update _selectedTemplateId and _selectedTemplateName.
    setState(() {
      _selectedTemplateId = 'template_classic_001'; // Example ID
      _selectedTemplateName = 'Classic Drake'; // Example Name
      // _customImagePath = null; // Clear custom image if a template is selected
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Template selected: $_selectedTemplateName')),
    );
  }

  void _uploadImage() {
    // TODO: Implement image uploading logic using a package like `image_picker`.
    // After picking an image, you might store its path in `_customImagePath`.
    // The actual upload to Supabase Storage would happen either here or before generation.
    // setState(() {
    //   _customImagePath = '/local/path/to/custom/image.png'; // Example path
    //   _selectedTemplateId = null; // Clear template if a custom image is uploaded
    //   _selectedTemplateName = null;
    // });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload image placeholder: Logic to be implemented.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Meme Details'),
        elevation: 1.0, // Subtle shadow
        // actions: [ // Optional: Add a help or info button
        //   IconButton(
        //     icon: Icon(Icons.help_outline),
        //     onPressed: () { /* Show help dialog */ },
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0), // Adjusted top padding
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Section for Template/Image Selection and Preview
              Text('1. Choose Your Base', style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      if (_selectedTemplateId != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Chip(
                            avatar: Icon(Icons.check_circle, color: colorScheme.primary),
                            label: Text('Template: $_selectedTemplateName', style: theme.textTheme.bodyMedium),
                            backgroundColor: colorScheme.primaryContainer.withOpacity(0.7),
                          ),
                        ),
                      // TODO: Add similar preview/chip for _customImagePath if implementing
                      // if (_customImagePath != null) ...

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround, // Use spaceAround for better spacing
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.photo_library_outlined, size: 20),
                            label: const Text('From Templates'),
                            onPressed: _selectTemplate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.secondary,
                              foregroundColor: colorScheme.onSecondary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file_outlined, size: 20),
                            label: const Text('Upload Custom'),
                            onPressed: _uploadImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.secondary,
                              foregroundColor: colorScheme.onSecondary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 20),

              // Section for Text Input
              Text('2. Add Your Text', style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _topTextController,
                decoration: InputDecoration(
                  labelText: 'Top Text',
                  hintText: 'Enter text for the top (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.align_vertical_top_rounded),
                  filled: true,
                ),
                maxLength: 120, // Increased max length slightly
                minLines: 1,
                maxLines: 3, // Allow multi-line input
                // No validator, as it's optional if bottom text is present
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _bottomTextController,
                decoration: InputDecoration(
                  labelText: 'Bottom Text',
                  hintText: 'Enter text for the bottom (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.align_vertical_bottom_rounded),
                  filled: true,
                ),
                maxLength: 120,
                minLines: 1,
                maxLines: 3,
                validator: (value) {
                  // Validate that at least one text field has input
                  if ((value == null || value.trim().isEmpty) && (_topTextController.text.trim().isEmpty)) {
                    return 'Please enter some text for the meme.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32), // Increased spacing

              // Generate Meme Button
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_fix_high, size: 28), // Slightly larger icon
                label: Padding( // Added padding to label for better touch target
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Generate Meme', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4.0, // Added elevation
                ),
                onPressed: _generateMeme,
              ),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
```
