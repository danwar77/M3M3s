import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'template_list_item.dart'; // Import TemplateListItem and TemplateInfo

// Data class for passing data to MemeDisplayScreen.
class MemeData {
  final String? topText;
  final String? bottomText;
  final String? imageUrl;
  final String? templateId;

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

  bool _isProcessing = false;
  Map<String, dynamic>? _suggestionResults;

  late Future<List<TemplateInfo>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _templatesFuture = _fetchTemplates();
  }

  @override
  void dispose() {
    _topTextController.dispose();
    _bottomTextController.dispose();
    super.dispose();
  }

  Future<List<TemplateInfo>> _fetchTemplates() async {
    if (!mounted) return [];
    print("Fetching templates from Supabase...");
    // Simulate network delay for testing loading indicator
    // await Future.delayed(const Duration(seconds: 2));
    try {
      final response = await Supabase.instance.client
          .from('templates')
          .select('id, name, image_url, thumbnail_url, tags')
          .order('name', ascending: true)
          .limit(50);

      final List<dynamic> data = response;

      print("Templates fetched: ${data.length}");
      return data.map((item) => TemplateInfo.fromMap(item as Map<String, dynamic>)).toList();

    } on PostgrestException catch (error) {
      print('Supabase fetch templates error: ${error.message}');
      // SnackBar is shown by the FutureBuilder's error state, but good to log.
      // if (mounted) {
      //   ScaffoldMessenger.of(context).removeCurrentSnackBar();
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Failed to fetch templates: ${error.message}'), backgroundColor: Colors.redAccent.shade700),
      //   );
      // }
      throw 'Failed to fetch templates: ${error.message}';
    } catch (e) {
      print('Generic fetch templates error: $e');
      //  if (mounted) {
      //   ScaffoldMessenger.of(context).removeCurrentSnackBar();
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('An unexpected error occurred: $e'), backgroundColor: Colors.redAccent.shade700),
      //   );
      // }
      throw 'An unexpected error occurred while fetching templates: $e';
    }
  }

  void _retryFetchTemplates() {
    if (mounted) {
      setState(() {
        _templatesFuture = _fetchTemplates();
      });
    }
  }

  Future<void> _processMeme() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTemplateId == null || _selectedTemplateImageUrl == null) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a template first!'),
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

      print("Conceptual Navigation: To MemeDisplayScreen with template: $_selectedTemplateName, Image URL: $_selectedTemplateImageUrl, Top: $topText, Bottom: $bottomText, Template ID: $_selectedTemplateId");

      // TODO: Step 5 - Uncomment and implement actual navigation to MemeDisplayScreen.
      // Ensure MemeDisplayScreen is imported.
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => MemeDisplayScreen(
      //       initialMemeData: MemeData(
      //         topText: topText,
      //         bottomText: bottomText,
      //         imageUrl: _selectedTemplateImageUrl,
      //         templateId: _selectedTemplateId,
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

  void _selectTemplate() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<TemplateInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
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
                    child: Text("Select a Template", style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: FutureBuilder<List<TemplateInfo>>(
                      future: _templatesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text("Loading templates..."),
                              ],
                            )
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error, size: 40),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Oops! Couldn't load templates.\nPlease check your connection and try again.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Theme.of(context).colorScheme.error)
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Retry'),
                                    onPressed: _retryFetchTemplates,
                                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.errorContainer, foregroundColor: Theme.of(context).colorScheme.onErrorContainer),
                                  )
                                ],
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.collections_bookmark_outlined, color: Colors.grey[600], size: 40),
                                  const SizedBox(height: 10),
                                  const Text('No templates found.\nTry refreshing or check back later!'),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Refresh'),
                                    onPressed: _retryFetchTemplates,
                                  )
                                ],
                              ),
                            )
                          );
                        }

                        final List<TemplateInfo> templates = snapshot.data!;
                        final crossAxisCount = MediaQuery.of(context).size.width > 600 ? 4 : 3;

                        return GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(8.0),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: templates.length,
                          itemBuilder: (BuildContext context, int index) {
                            final tpl = templates[index];
                            return TemplateListItem(
                              template: tpl,
                              onTap: () {
                                Navigator.pop(context, tpl);
                              },
                            );
                          },
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
    ).then((selectedTemplate) {
      if (selectedTemplate != null && mounted) {
        setState(() {
          _selectedTemplateId = selectedTemplate.id;
          _selectedTemplateName = selectedTemplate.name;
          _selectedTemplateImageUrl = selectedTemplate.imageUrl;
          _suggestionResults = null;
        });
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('"${selectedTemplate.name}" selected.'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.shade700, // Success color
            behavior: SnackBarBehavior.floating, // Consistent with theme if defined globally
          ),
        );
      }
    });
  }

  void _uploadImage() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Upload image: Feature to be implemented.'), backgroundColor: Colors.blueGrey.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    const double previewAreaHeight = 180.0;

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
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _selectTemplate,
                  child: Container(
                    height: previewAreaHeight,
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_selectedTemplateImageUrl != null) ...[
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                _selectedTemplateImageUrl!,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return SizedBox(
                                    height: 100,
                                    width: 100,
                                    child: Center(child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    )),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return SizedBox(
                                    height: 100,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 40),
                                          const SizedBox(height: 4),
                                          Text("Preview Error", style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Selected: ${_selectedTemplateName ?? _selectedTemplateId!}',
                              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "(Tap card to change)", // Refined hint
                            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                            textAlign: TextAlign.center,
                          )
                        ] else ...[
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'No template selected.\nTap card to choose one.', // Refined instructive text
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
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

              _isProcessing
                  ? const Center(child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator()))
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome_outlined, size: 28),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text('Get Suggestions & Prepare', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4.0),
                      onPressed: _processMeme,
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
                              .map((keyword) => Chip(label: Text(keyword), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0)))
                              .toList(),
                        ),
                        if ((_suggestionResults!['suggestedTemplates'] as List<dynamic>?)?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 12),
                          Text('Top Suggested Template:', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text('${_suggestionResults!['suggestedTemplates'][0]['name']} (ID: ${_suggestionResults!['suggestedTemplates'][0]['templateId']})', style: theme.textTheme.bodyLarge),
                        ]
                      ],
                    ),
                  ),
                ),
                 const SizedBox(height: 16),
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
