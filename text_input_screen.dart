import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Data class for passing data to MemeDisplayScreen.
// Ensure this is defined or import it if it's in another file (e.g., meme_display_screen.dart)
class MemeData {
  final String? topText;
  final String? bottomText;
  final String? imageUrl;
  final String? templateId; // Added to pass along the template ID

  MemeData({
    this.topText,
    this.bottomText,
    this.imageUrl,
    this.templateId,
  });
}

class TextInputScreen extends StatefulWidget {
  const TextInputScreen({super.key});

  @override
  State<TextInputScreen> createState() => _TextInputScreenState();
}

class _TextInputScreenState extends State<TextInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topTextController = TextEditingController();
  final _bottomTextController = TextEditingController();

  String? _selectedTemplateId;
  String? _selectedTemplateName;
  String? _selectedTemplateImageUrl;

  bool _isProcessing = false; // Renamed from _isGenerating for clarity

  Map<String, dynamic>? _suggestionResults;

  @override
  void dispose() {
    _topTextController.dispose();
    _bottomTextController.dispose();
    super.dispose();
  }

  Future<void> _processMeme() async { // Renamed for clarity
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTemplateId == null || _selectedTemplateImageUrl == null) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a template first.'),
          backgroundColor: Colors.orangeAccent.shade700,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    _suggestionResults = null;

    final topText = _topTextController.text.trim();
    final bottomText = _bottomTextController.text.trim();
    final primaryTextForSuggestions = (topText.isNotEmpty ? topText : bottomText);

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      print('Calling get-meme-suggestions with text: "$primaryTextForSuggestions"');
      final response = await Supabase.instance.client.functions.invoke(
        'get-meme-suggestions',
        body: {
          'text': primaryTextForSuggestions,
          'userId': Supabase.instance.client.auth.currentUser?.id ?? 'anonymous'
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw Exception("No data received from Edge Function or data is not a map.");
      }

      if (mounted) {
        setState(() {
          _suggestionResults = data;
        });
      }

      final analysis = data['analyzedText'] as Map<String, dynamic>?;
      final tone = analysis?['tone'] ?? 'N/A';
      final firstSuggestedTemplateList = data['suggestedTemplates'] as List<dynamic>?;
      final firstSuggestedTemplate = firstSuggestedTemplateList?.firstOrNull as Map<String, dynamic>?;

      scaffoldMessenger.removeCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Suggestions received! Tone: $tone. Top Suggestion: ${firstSuggestedTemplate?['name'] ?? 'None'}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.blueAccent,
        ),
      );

      // Decide which template to use for navigation: user's explicit selection takes precedence.
      final String finalTemplateIdForDisplay = _selectedTemplateId!;
      final String finalTemplateImageUrlForDisplay = _selectedTemplateImageUrl!;
      final String finalTemplateName = _selectedTemplateName!; // For clarity if needed

      // If suggestions are meant to allow user to CHANGE template, add UI for that here.
      // For now, we proceed with the user's chosen template and display suggestions as info.

      print("Proceeding to display/edit with: Top: \"$topText\", Bottom: \"$bottomText\", Image URL: $finalTemplateImageUrlForDisplay, Template ID: $finalTemplateIdForDisplay");

      // TODO: Navigate to MemeDisplayScreen. Ensure MemeDisplayScreen is imported.
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => MemeDisplayScreen(
      //       initialMemeData: MemeData(
      //         topText: topText,
      //         bottomText: bottomText,
      //         imageUrl: finalTemplateImageUrlForDisplay,
      //         templateId: finalTemplateIdForDisplay, // Pass the template ID
      //       ),
      //     ),
      //   ),
      // );

    } on FunctionsException catch (error) {
      print('Edge Function Exception: ${error.message}, Details: ${error.details}');
      if (mounted) {
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent.shade700, content: Text('Error from suggestions: ${error.message}')),
        );
      }
    } catch (e) {
      print('Generic Error during meme processing: $e');
      if (mounted) {
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent.shade700, content: Text('An unexpected error occurred: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _selectTemplate() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    // TODO: Replace with actual call to fetch templates from Supabase DB.
    // Example:
    // final response = await Supabase.instance.client.from('templates').select('id, name, image_url').limit(20);
    // final List<Map<String, dynamic>> templatesFromDb = (response as List<dynamic>).cast<Map<String, dynamic>>();

    final mockTemplates = [
      {'id': 'tpl_drake_001', 'name': 'Drake Hotline Bling', 'image_url': 'https://i.imgflip.com/ drake.jpg'}, // Example with a broken URL for testing errorBuilder
      {'id': 'tpl_distracted_002', 'name': 'Distracted Boyfriend', 'image_url': 'https://i.imgflip.com/2/1ur9b0.jpg'},
      {'id': 'tpl_boromir_003', 'name': 'One Does Not Simply', 'image_url': 'https://i.imgflip.com/1bij.jpg'},
      {'id': 'tpl_success_kid_004', 'name': 'Success Kid', 'image_url': 'https://i.imgflip.com/q2j.jpg'},
    ];

    if (!mounted) return;

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true, // Allow sheet to take more height
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext bc) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6, // Start at 60% of screen height
          maxChildSize: 0.9,   // Max 90%
          minChildSize: 0.3,   // Min 30%
          builder: (BuildContext context, ScrollController scrollController) {
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom:8.0),
                  child: Text('Select a Template', style: Theme.of(context).textTheme.titleLarge),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController, // Use the controller from DraggableScrollableSheet
                    itemCount: mockTemplates.length,
                    itemBuilder: (BuildContext context, int index) {
                      final tpl = mockTemplates[index];
                      return ListTile(
                        leading: Image.network(
                          tpl['image_url']!,
                          width: 60, height: 60, fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(width:60, height:60, color: Colors.grey[200], child: const Icon(Icons.broken_image_outlined, size: 30, color: Colors.grey)),
                          loadingBuilder: (c, child, progress) => progress == null ? child : Container(width:60, height:60, child: const Center(child: SizedBox(width:20, height:20, child:CircularProgressIndicator(strokeWidth: 2.0)))),
                        ),
                        title: Text(tpl['name']!),
                        onTap: () => Navigator.pop(context, tpl),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedTemplateId = selected['id'];
        _selectedTemplateName = selected['name'];
        _selectedTemplateImageUrl = selected['image_url'];
        _suggestionResults = null;
      });
      scaffoldMessenger.removeCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Template selected: ${_selectedTemplateName!}')),
      );
    }
  }

  void _uploadImage() {
    // TODO: Implement image uploading logic (e.g., using image_picker).
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Upload image: Feature to be implemented.'), backgroundColor: Colors.blueGrey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Meme Details'),
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('1. Choose Your Base Image', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary)),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_selectedTemplateImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            _selectedTemplateImageUrl!,
                            height: 150, // Increased preview size
                            fit: BoxFit.contain,
                            errorBuilder: (c,e,s) => Container(height:150, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[Icon(Icons.error_outline, color: Colors.red.shade300, size: 30), SizedBox(height:4), Text("Preview Error", style: TextStyle(color: Colors.red.shade300))]))),
                            loadingBuilder: (c, child, progress) => progress == null ? child : Container(height:150, child: const Center(child: CircularProgressIndicator())),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          _selectedTemplateId != null
                              ? 'Selected: ${_selectedTemplateName ?? _selectedTemplateId}'
                              : 'No template selected yet.',
                          style: theme.textTheme.titleSmall?.copyWith(color: _selectedTemplateId != null ? colorScheme.onSurfaceVariant : Colors.grey[700], fontStyle: _selectedTemplateId == null ? FontStyle.italic: FontStyle.normal),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon( // Changed to TextButton for less emphasis than primary action
                            icon: const Icon(Icons.photo_library_outlined, size: 20),
                            label: const Text('Choose Template'),
                            onPressed: _selectTemplate,
                            style: TextButton.styleFrom(foregroundColor: colorScheme.secondary),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.upload_file_outlined, size: 20),
                            label: const Text('Upload Custom'),
                            onPressed: _uploadImage,
                            style: TextButton.styleFrom(foregroundColor: colorScheme.secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 20),

              Text('2. Add Your Text', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _topTextController,
                decoration: InputDecoration(labelText: 'Top Text', hintText: 'Enter text for the top (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.align_vertical_top_rounded), filled: false),
                maxLength: 120, minLines: 1, maxLines: 3,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _bottomTextController,
                decoration: InputDecoration(labelText: 'Bottom Text', hintText: 'Enter text for the bottom (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.align_vertical_bottom_rounded), filled: false),
                maxLength: 120, minLines: 1, maxLines: 3,
                validator: (value) {
                  if ((value == null || value.trim().isEmpty) && (_topTextController.text.trim().isEmpty)) {
                    return 'Please enter some text for the meme.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              _isProcessing // Renamed from _isGenerating
                  ? const Center(child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator()))
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome_outlined, size: 28),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        // Clarified button text
                        child: Text('Get Suggestions & Prepare', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4.0),
                      onPressed: _processMeme, // Renamed method
                    ),

              if (_suggestionResults != null && !_isProcessing) ...[
                const SizedBox(height: 24),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: Text('Analysis & Suggestions:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Card(
                  elevation: 1,
                  color: colorScheme.surfaceVariant.withOpacity(0.7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detected Tone: ${_suggestionResults!['analyzedText']?['tone'] ?? 'N/A'}', style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        Text('Keywords:', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 6.0,
                          runSpacing: 0.0,
                          children: ((_suggestionResults!['analyzedText']?['keywords'] as List<dynamic>?)?.cast<String>() ?? [])
                              .map((keyword) => Chip(label: Text(keyword), padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0)))
                              .toList(),
                        ),
                        if ((_suggestionResults!['suggestedTemplates'] as List<dynamic>?)?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 12),
                          Text('Top Suggested Template:', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text('${_suggestionResults!['suggestedTemplates'][0]['name']} (ID: ${_suggestionResults!['suggestedTemplates'][0]['templateId']})', style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 8),
                          // TODO: Add a button like "Use this suggested template" which would call _selectTemplate with its data.
                          // TextButton(onPressed: () { /* use suggestion */ }, child: Text("Use this suggestion?"))
                        ]
                      ],
                    ),
                  ),
                ),
                 const SizedBox(height: 16),
                 // TODO: Add a clearer "Next Step" button here like "Proceed to Edit/Display Screen"
                 // This button would use the _selectedTemplateImageUrl and input texts to navigate.
                 // For now, the user has to tap "Get Suggestions & Prepare" again if they change text
                 // after selecting a template and getting suggestions.
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

```
