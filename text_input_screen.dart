import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'template_list_item.dart'; // Import TemplateListItem and TemplateInfo
import 'meme_display_screen.dart'; // Import MemeDisplayScreen and MemeData
import 'suggested_template_item.dart'; // Import SuggestedTemplateItem
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  File? _customImageFile;

  bool _isProcessing = false;
  bool _isFetchingSuggestionDetails = false;
  Map<String, dynamic>? _suggestionResults;

  final ImagePicker _picker = ImagePicker();

  List<TemplateInfo> _allFetchedTemplates = [];
  int _templatesCurrentPage = 0;
  final int _templatesPageSize = 20;
  bool _isLoadingInitialTemplates = false;
  bool _isLoadingMoreTemplates = false;
  bool _hasMoreTemplates = true;
  Object? _fetchTemplatesError;
  final ScrollController _templateScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _templateScrollController.addListener(() {
      if (_templateScrollController.position.pixels >=
          _templateScrollController.position.maxScrollExtent - 200 &&
          _hasMoreTemplates &&
          !_isLoadingMoreTemplates &&
          !_isLoadingInitialTemplates &&
          _fetchTemplatesError == null) {
        print("Scroll listener: Reached near bottom, fetching more templates...");
        _fetchTemplates(isInitialFetch: false);
      }
    });
  }

  @override
  void dispose() {
    _topTextController.dispose();
    _bottomTextController.dispose();
    _templateScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchTemplates({bool isInitialFetch = false}) async {
    if (!mounted) return;
    if (isInitialFetch && _isLoadingInitialTemplates) return;
    if (!isInitialFetch && _isLoadingMoreTemplates) return;
    if (!isInitialFetch && !_hasMoreTemplates) {
      print("Fetch templates called but no more templates or already loading/no more.");
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context); // Cache for SnackBar

    setState(() {
      if (isInitialFetch) {
        _isLoadingInitialTemplates = true;
        _fetchTemplatesError = null;
        _templatesCurrentPage = 0;
        _allFetchedTemplates.clear();
        _hasMoreTemplates = true;
      } else {
        _isLoadingMoreTemplates = true;
      }
    });

    try {
      final offset = _templatesCurrentPage * _templatesPageSize;
      print("Fetching templates from Supabase... Page: $_templatesCurrentPage, Offset: $offset, Initial: $isInitialFetch");

      final response = await Supabase.instance.client
          .from('templates')
          .select('id, name, image_url, thumbnail_url, tags')
          .order('name', ascending: true)
          .range(offset, offset + _templatesPageSize - 1);

      final List<dynamic> fetchedData = response;
      final List<TemplateInfo> newTemplates = fetchedData
          .map((item) => TemplateInfo.fromMap(item as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _allFetchedTemplates.addAll(newTemplates);
          _templatesCurrentPage++;
          if (newTemplates.length < _templatesPageSize) {
            _hasMoreTemplates = false;
          }
          _fetchTemplatesError = null;
        });
      }
      print("Fetched ${newTemplates.length} templates. Total now: ${_allFetchedTemplates.length}. Has more: $_hasMoreTemplates");

    } on PostgrestException catch (error) {
      print('Supabase fetch templates error: ${error.message}');
      if (mounted) {
        setState(() {
          _fetchTemplatesError = error;
          _hasMoreTemplates = false;
        });
        // Show SnackBar only if it's a "load more" error and some items are already visible
        if (!isInitialFetch && _allFetchedTemplates.isNotEmpty) {
          scaffoldMessenger.removeCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to load more templates: ${error.message}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Generic fetch templates error: $e');
      if (mounted) {
        setState(() {
          _fetchTemplatesError = e;
          _hasMoreTemplates = false;
        });
        // Show SnackBar only if it's a "load more" error and some items are already visible
        if (!isInitialFetch && _allFetchedTemplates.isNotEmpty) {
          scaffoldMessenger.removeCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('Failed to load more templates: An unexpected error occurred.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isInitialFetch) _isLoadingInitialTemplates = false;
          else _isLoadingMoreTemplates = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    // ... (implementation remains the same)
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.removeCurrentSnackBar();
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 85, maxHeight: 1024, maxWidth: 1024);
      if (pickedFile != null) {
        if (mounted) {
          setState(() {
            _customImageFile = File(pickedFile.path);
            _selectedTemplateId = null; _selectedTemplateName = null; _selectedTemplateImageUrl = null;
            _suggestionResults = null;
          });
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('Custom image selected!'), backgroundColor: Colors.green.shade700));
        }
      } else {
        if (mounted) scaffoldMessenger.showSnackBar(SnackBar(content: const Text('No image selected.'), backgroundColor: Colors.orangeAccent.shade700));
      }
    } catch (e) {
      if (mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error picking image: ${e.toString()}'), backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  void _showImageSourceSelection() {
    // ... (implementation remains the same)
     showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (BuildContext bc) {
      return SafeArea(child: Wrap(children: <Widget>[
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Photo Library'), onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.gallery); }),
        ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Camera'), onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.camera); }),
      ]));
    });
  }

  Future<void> _processMeme() async {
    // ... (implementation remains the same)
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_customImageFile == null && (_selectedTemplateId == null || _selectedTemplateImageUrl == null)) {
      scaffoldMessenger.removeCurrentSnackBar();
      scaffoldMessenger.showSnackBar(SnackBar(content: const Text('Please select a template or upload a custom image first!'), backgroundColor: Colors.orangeAccent.shade700));
      return;
    }
    if(mounted) setState(() => _isProcessing = true);
    _suggestionResults = null;
    final topText = _topTextController.text.trim();
    final bottomText = _bottomTextController.text.trim();
    final primaryTextForSuggestions = (topText.isNotEmpty ? topText : (bottomText.isNotEmpty ? bottomText : "funny meme"));
    Map<String, dynamic>? edgeFunctionResults;
    try {
      final response = await Supabase.instance.client.functions.invoke('get-meme-suggestions', body: {'text': primaryTextForSuggestions, 'userId': Supabase.instance.client.auth.currentUser?.id ?? 'anonymous'});
      edgeFunctionResults = response.data as Map<String, dynamic>?;
      if (edgeFunctionResults == null) throw Exception("No data received from Edge Function.");
      if (mounted) {
        setState(() { _suggestionResults = edgeFunctionResults; });
        final analysis = edgeFunctionResults['analyzedText'] as Map<String, dynamic>?;
        final tone = analysis?['tone'] ?? 'N/A';
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Suggestions received! Tone: $tone.'), duration: const Duration(seconds: 2), backgroundColor: Colors.blueAccent));
      }
      if (mounted) { setState(() => _isProcessing = false); } else { return; }
      final memeDataForDisplay = MemeData(topText: topText, bottomText: bottomText, imageUrl: _customImageFile == null ? _selectedTemplateImageUrl! : null, localImageFile: _customImageFile, templateId: _customImageFile == null ? _selectedTemplateId! : null);
      if (mounted) navigator.push(MaterialPageRoute(builder: (context) => MemeDisplayScreen(initialMemeData: memeDataForDisplay)));
    } on FunctionsException catch (error) {
      if (mounted) { setState(() => _isProcessing = false); scaffoldMessenger.removeCurrentSnackBar(); scaffoldMessenger.showSnackBar(SnackBar(backgroundColor: Theme.of(context).colorScheme.error, content: Text('Suggestion Error: ${error.message}'))); }
    } catch (e) {
      if (mounted) { setState(() => _isProcessing = false); scaffoldMessenger.removeCurrentSnackBar(); scaffoldMessenger.showSnackBar(SnackBar(backgroundColor: Theme.of(context).colorScheme.error, content: Text('An unexpected error occurred: ${e.toString()}'))); }
    }
  }

  void _selectTemplate() {
    // ... (implementation remains the same)
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if ((_allFetchedTemplates.isEmpty && !_isLoadingInitialTemplates) || _fetchTemplatesError != null) {
        if (mounted) {
            setState(() { _fetchTemplatesError = null; _hasMoreTemplates = true; });
        }
        _fetchTemplates(isInitialFetch: true);
    }
    showModalBottomSheet<TemplateInfo>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (BuildContext bc) {
      return Builder(builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.9, expand: false,
          builder: (_, scrollControllerForSheet) {
            return Container(decoration: BoxDecoration(color: theme.canvasColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0))),
              child: Column(children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)))),
                Padding(padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 10.0), child: Text("Select a Template", style: theme.textTheme.titleLarge)),
                const Divider(height: 1, thickness: 0.5),
                Expanded(child: Builder(builder: (context) {
                  if (_isLoadingInitialTemplates && _allFetchedTemplates.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 20), Text("Loading templates...", style: theme.textTheme.bodyMedium)])));
                  if (_fetchTemplatesError != null && _allFetchedTemplates.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 48), const SizedBox(height: 16), Text("Oops! Couldn't load templates.", textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error)), const SizedBox(height: 8), Text(_fetchTemplatesError.toString(), textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error.withOpacity(0.8))), const SizedBox(height: 20), ElevatedButton.icon(icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'), onPressed: () => _fetchTemplates(isInitialFetch: true), style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.errorContainer, foregroundColor: theme.colorScheme.onErrorContainer))])));
                  if (_allFetchedTemplates.isEmpty && !_hasMoreTemplates && !_isLoadingInitialTemplates) return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.collections_bookmark_outlined, color: Colors.grey[500], size: 48), const SizedBox(height: 16), Text('No templates found.', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[700])), const SizedBox(height: 8), Text('Try refreshing or check back later!', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])), const SizedBox(height: 20), ElevatedButton.icon(icon: const Icon(Icons.refresh_rounded), label: const Text('Refresh'), onPressed: () => _fetchTemplates(isInitialFetch: true))])));
                  final crossAxisCount = MediaQuery.of(context).size.width > 600 ? 4 : 3;
                  return GridView.builder(controller: _templateScrollController, padding: const EdgeInsets.all(12.0), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0, childAspectRatio: 0.8), itemCount: _allFetchedTemplates.length + (_hasMoreTemplates && _allFetchedTemplates.isNotEmpty ? 1 : 0),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == _allFetchedTemplates.length) return _isLoadingMoreTemplates ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: SizedBox(height: 24, width: 24, child:CircularProgressIndicator(strokeWidth: 2.5)))) : const SizedBox.shrink();
                      final tpl = _allFetchedTemplates[index]; return TemplateListItem(template: tpl, onTap: () => Navigator.pop(context, tpl));
                    });
                }))])
            );
        });
      });
    }).then((selectedTemplate) {
      if (selectedTemplate != null && mounted) {
        setState(() {
          _selectedTemplateId = selectedTemplate.id; _selectedTemplateName = selectedTemplate.name; _selectedTemplateImageUrl = selectedTemplate.imageUrl;
          _customImageFile = null; _suggestionResults = null;
        });
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('"${selectedTemplate.name}" selected.'), duration: const Duration(seconds: 2), backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating));
      }
    });
  }

  Widget _buildPreviewCard(BuildContext context) {
    // ... (implementation remains the same)
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    const double previewAreaHeight = 200.0;
    Widget content;
    String titleText = "No image selected";
    String subtitleText = "Tap card or use buttons below.";

    if (_customImageFile != null) {
      titleText = "Custom Image";
      subtitleText = "Tap card to change or remove.";
      content = Stack(alignment: Alignment.center, children: [
        ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Image.file(_customImageFile!, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error_outline_rounded, color: Colors.red, size: 40)))),
        Positioned(top: 0, right: 0, child: Container(margin: const EdgeInsets.all(4.0), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20), tooltip: 'Remove custom image', padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () { if (mounted) { setState(() => _customImageFile = null); ScaffoldMessenger.of(context).removeCurrentSnackBar(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom image removed.'), backgroundColor: Colors.orangeAccent)); }}))),
      ]);
    } else if (_selectedTemplateImageUrl != null) {
      titleText = _selectedTemplateName ?? _selectedTemplateId!;
      subtitleText = "(Tap card to change template)";
      content = ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Image.network(_selectedTemplateImageUrl!, fit: BoxFit.contain, loadingBuilder: (context, child, loadingProgress) { if (loadingProgress == null) return child; return Center(child: CircularProgressIndicator(strokeWidth: 2.0, value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null)); }, errorBuilder: (context, error, stackTrace) { return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 40), const SizedBox(height: 4), Text("Preview Error", style: TextStyle(color: theme.colorScheme.error, fontSize: 12))])); }));
    } else {
      content = Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[400]), const SizedBox(height: 12), Text(titleText, style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[700])), const SizedBox(height: 4), Text(subtitleText, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center) ]);
    }
    return Card(elevation: _customImageFile != null || _selectedTemplateImageUrl != null ? 2.0 : 1.0, color: _customImageFile != null || _selectedTemplateImageUrl != null ? colorScheme.surface : Colors.grey[100], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: () { if (_customImageFile != null) { _showImageSourceSelection(); } else { _selectTemplate(); }},
        child: Container(height: previewAreaHeight, width: double.infinity, padding: const EdgeInsets.all(8.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Expanded(child: Center(child: content)),
            if (_customImageFile != null || _selectedTemplateImageUrl != null) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(titleText, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (_customImageFile != null || _selectedTemplateImageUrl != null) Text(subtitleText, style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline), textAlign: TextAlign.center),
          ]))));
  }

  Widget _buildSuggestionsCard(BuildContext context, Map<String, dynamic> suggestions) {
    // ... (implementation remains the same)
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final analyzedText = suggestions['analyzedText'] as Map<String, dynamic>?;
    final List<dynamic>? suggestedTemplatesDynamic = suggestions['suggestedTemplates'] as List<dynamic>?;
    final List<Map<String, dynamic>> suggestedTemplatesData = (suggestedTemplatesDynamic ?? []).map((item) => item as Map<String, dynamic>).toList();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    return Card(elevation: 2.0, margin: const EdgeInsets.symmetric(vertical: 16.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('AI Suggestions & Analysis', style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600)),
        const Divider(height: 20.0, thickness: 0.5),
        if (analyzedText != null) ...[
          Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(children: [Icon(Icons.psychology_outlined, color: colorScheme.secondary, size: 20), const SizedBox(width: 8), Text('Detected Tone: ', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)), Expanded(child: Text(analyzedText['tone']?.toString() ?? 'N/A', style: theme.textTheme.bodyMedium))])),
          if (analyzedText['language'] != null) Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(children: [Icon(Icons.translate_outlined, color: colorScheme.secondary, size: 20), const SizedBox(width: 8), Text('Language: ', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)), Expanded(child: Text(analyzedText['language']?.toString() ?? 'N/A', style: theme.textTheme.bodyMedium))])),
          Padding(padding: const EdgeInsets.only(top: 8.0, bottom: 4.0), child: Text('Keywords:', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
          if ((analyzedText['keywords'] as List?)?.isNotEmpty ?? false) Wrap(spacing: 8.0, runSpacing: 4.0, children: ((analyzedText['keywords'] as List).cast<String>()).map((keyword) => ActionChip(label: Text(keyword), backgroundColor: colorScheme.secondaryContainer.withOpacity(0.7), labelStyle: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: theme.textTheme.bodySmall?.fontSize), padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0.0), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, onPressed: () { scaffoldMessenger.removeCurrentSnackBar(); scaffoldMessenger.showSnackBar(SnackBar(content: Text('Keyword "$keyword" tapped. Future: Use for filtering or tagging.'), duration: const Duration(seconds: 2), backgroundColor: Colors.teal.shade700)); print('Keyword tapped: $keyword'); })).toList())
          else Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text('No keywords detected.', style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic))),
          const SizedBox(height: 12)],
        if (suggestedTemplatesData.isNotEmpty) ...[
          const Divider(height: 20.0, thickness: 0.5),
          Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Suggested Templates (Top ${suggestedTemplatesData.take(3).length}):', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
          Column(children: suggestedTemplatesData.take(3).map((suggestionMap) {
            final String? suggestedTemplateId = suggestionMap['templateId'] as String? ?? suggestionMap['id'] as String?; final String? suggestedTemplateName = suggestionMap['name'] as String?; final String? suggestedImageUrl = suggestionMap['imageUrl'] as String? ?? suggestionMap['thumbnailUrl'] as String?;
            if (suggestedTemplateId == null || suggestedTemplateName == null || suggestedImageUrl == null) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(bottom: 4.0), child: SuggestedTemplateItem(suggestionData: suggestionMap, onTap: () async {
              if (_isFetchingSuggestionDetails || !mounted) return;
              setState(() => _isFetchingSuggestionDetails = true); scaffoldMessenger.removeCurrentSnackBar(); scaffoldMessenger.showSnackBar(SnackBar(content: Text('Loading details for "$suggestedTemplateName"...'), duration: const Duration(seconds: 2), backgroundColor: Colors.blueGrey.shade700));
              try {
                final String mainImageUrl = suggestedImageUrl;
                if (mounted) {
                  setState(() { _selectedTemplateId = suggestedTemplateId; _selectedTemplateName = suggestedTemplateName; _selectedTemplateImageUrl = mainImageUrl; _customImageFile = null; _suggestionResults = null; });
                  scaffoldMessenger.removeCurrentSnackBar(); scaffoldMessenger.showSnackBar(SnackBar(content: Text('"$suggestedTemplateName" selected from suggestions!'), backgroundColor: Colors.green.shade700, duration: const Duration(seconds: 2)));
                }
              } catch (e) {
                if (mounted) { scaffoldMessenger.removeCurrentSnackBar(); scaffoldMessenger.showSnackBar(SnackBar(content: Text('Could not select "$suggestedTemplateName": ${e.toString()}'), backgroundColor: Theme.of(context).colorScheme.error)); }
              } finally { if (mounted) setState(() => _isFetchingSuggestionDetails = false); }
            }));
          }).toList())]
        else if (analyzedText != null) ...[ const Divider(height: 20.0, thickness: 0.5), Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('No specific template suggestions for this text.', style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)))]
      ]))));
  }

  @override
  Widget build(BuildContext context) {
    // ... (implementation remains the same)
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    bool canProcessMeme = !_isProcessing && !_isFetchingSuggestionDetails && (_selectedTemplateImageUrl != null || _customImageFile != null) ;

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Meme Details'), elevation: 1.0),
      body: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
          Text('1. Choose Your Base Image', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary)),
          const SizedBox(height: 12),
          _buildPreviewCard(context),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            TextButton.icon(icon: const Icon(Icons.photo_library_outlined, size: 20), label: const Text('Choose Template'), onPressed: (_isProcessing || _isFetchingSuggestionDetails) ? null : _selectTemplate, style: TextButton.styleFrom(foregroundColor: colorScheme.secondary)),
            TextButton.icon(icon: const Icon(Icons.upload_file_outlined, size: 20), label: const Text('Upload Custom'), onPressed: (_isProcessing || _isFetchingSuggestionDetails) ? null : _showImageSourceSelection, style: TextButton.styleFrom(foregroundColor: colorScheme.secondary))]),
          const SizedBox(height: 24), const Divider(height: 1, thickness: 0.5), const SizedBox(height: 20),
          Text('2. Add Your Text', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary)),
          const SizedBox(height: 16),
          TextFormField(controller: _topTextController, decoration: InputDecoration(labelText: 'Top Text', hintText: 'Enter text for the top (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.align_vertical_top_rounded), filled: false), maxLength: 120, minLines: 1, maxLines: 3, enabled: !_isProcessing && !_isFetchingSuggestionDetails),
          const SizedBox(height: 20),
          TextFormField(controller: _bottomTextController, decoration: InputDecoration(labelText: 'Bottom Text', hintText: 'Enter text for the bottom (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.align_vertical_bottom_rounded), filled: false), maxLength: 120, minLines: 1, maxLines: 3, enabled: !_isProcessing && !_isFetchingSuggestionDetails,
            validator: (value) { if ((value == null || value.trim().isEmpty) && (_topTextController.text.trim().isEmpty)) return 'Please enter some text for the meme.'; return null; }),
          const SizedBox(height: 32),
          if (_isProcessing || _isFetchingSuggestionDetails) const Center(child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator()))
          else ElevatedButton.icon(icon: const Icon(Icons.auto_awesome_outlined, size: 28), label: Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Text('Get Suggestions & Prepare', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))), style: ElevatedButton.styleFrom(backgroundColor: canProcessMeme ? colorScheme.primary : colorScheme.primary.withOpacity(0.5), foregroundColor: colorScheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4.0), onPressed: canProcessMeme ? _processMeme : null),
          if (!_isProcessing && !_isFetchingSuggestionDetails && _suggestionResults != null) _buildSuggestionsCard(context, _suggestionResults!),
          const SizedBox(height: 20)
        ]))));
  }
}

```
