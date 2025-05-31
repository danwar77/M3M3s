import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

// Basic model for a Meme item.
class MemeHistoryItem {
  final String id;
  final String imageUrl;
  final String? topText;
  final String? bottomText;
  final DateTime createdAt;

  MemeHistoryItem({
    required this.id,
    required this.imageUrl,
    this.topText,
    this.bottomText,
    required this.createdAt,
  });

  factory MemeHistoryItem.fromMap(Map<String, dynamic> map) {
    String? tText;
    String? bText;
    if (map['text_input'] != null && map['text_input'] is Map) {
        final textInputData = map['text_input'] as Map<String, dynamic>;
        tText = textInputData['top'] as String?;
        bText = textInputData['bottom'] as String?;
    }
    return MemeHistoryItem(
      id: map['id'] as String,
      imageUrl: map['image_url'] as String,
      topText: tText,
      bottomText: bText,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<MemeHistoryItem>> _memesFuture;
  // bool _isFetchingData = false; // _isFetchingData is not strictly necessary with FutureBuilder's ConnectionState

  @override
  void initState() {
    super.initState();
    _memesFuture = _fetchMemeHistory();
  }

  Future<List<MemeHistoryItem>> _fetchMemeHistory() async {
    // if (mounted) { // Not needed here as FutureBuilder handles its own state
    //   setState(() { _isFetchingData = true; });
    // }

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      // if (mounted) { setState(() => _isFetchingData = false); }
      return Future.error('User not authenticated. Please log in to view history.');
    }

    try {
      final response = await supabase
          .from('memes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      final List<MemeHistoryItem> memes = response
          .map((item) => MemeHistoryItem.fromMap(item as Map<String, dynamic>))
          .toList();

      // if (mounted) { setState(() => _isFetchingData = false); }
      return memes;

    } on PostgrestException catch (error) {
      print('Supabase fetch error: ${error.message}');
      // if (mounted) { setState(() => _isFetchingData = false); }
      return Future.error('Server error: ${error.message}');
    } catch (e) {
      print('Generic fetch error: $e');
      // if (mounted) { setState(() => _isFetchingData = false); }
      return Future.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<void> _refreshHistory() async {
    if (mounted) {
      setState(() {
        _memesFuture = _fetchMemeHistory();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: FutureBuilder<List<MemeHistoryItem>>(
        future: _memesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            String errorMessage = snapshot.error.toString();
            bool isAuthError = false;
            if (errorMessage.contains('User not authenticated')) {
                errorMessage = 'Please log in to see your meme history.';
                isAuthError = true;
            } else if (snapshot.error is PostgrestException) {
                errorMessage = 'Could not load memes: ${(snapshot.error as PostgrestException).message}';
            } else {
                errorMessage = 'An error occurred. Tap to retry.';
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 60),
                    const SizedBox(height: 16),
                    Text('Oops!', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.error)),
                    const SizedBox(height: 8),
                    Text(errorMessage, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: Icon(isAuthError ? Icons.login : Icons.refresh_rounded),
                      label: Text(isAuthError ? 'Login' : 'Retry'),
                      onPressed: () {
                        if (isAuthError) {
                          // TODO: Navigate to LoginScreen. This requires a router setup.
                          // For now, show a SnackBar or print.
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: const Text('Login navigation placeholder.'), backgroundColor: theme.colorScheme.secondary)
                          );
                        } else {
                          _refreshHistory();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAuthError ? theme.colorScheme.secondary : theme.colorScheme.primary,
                        foregroundColor: isAuthError ? theme.colorScheme.onSecondary : theme.colorScheme.onPrimary
                      ),
                    )
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_search_outlined, size: 80, color: Colors.grey[500]),
                    const SizedBox(height: 20),
                    Text('No Memes Yet!', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey[700])),
                    const SizedBox(height: 10),
                    Text("Your meme gallery is empty.\nTime to create some masterpieces!", textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline), // Changed icon
                      label: const Text('Create First Meme!'), // Changed label
                      onPressed: () {
                        // TODO: Navigate to Create Tab (index 0). This requires MainScreen's _onItemTapped
                        // or a shared state/callback mechanism to change the tab.
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: const Text('Navigate to Create tab placeholder.'), backgroundColor: theme.colorScheme.primary)
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                      ),
                    )
                  ],
                ),
              ),
            );
          }

          final List<MemeHistoryItem> memes = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshHistory,
            child: GridView.builder(
              padding: const EdgeInsets.all(12.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.85,
              ),
              itemCount: memes.length,
              itemBuilder: (context, index) {
                final meme = memes[index];
                return Card(
                  elevation: 3.0,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  child: InkWell(
                    onTap: () {
                      // TODO: Navigate to a meme detail screen or an edit screen
                      // Example:
                      // Navigator.push(context, MaterialPageRoute(builder: (context) =>
                      //   MemeDisplayScreen(initialMemeData: MemeData(imageUrl: meme.imageUrl, topText: meme.topText, bottomText: meme.bottomText, templateId: meme.template_id_if_any)) // Ensure MemeData can take templateId if needed
                      // ));
                      ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Clear previous snackbars
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tapped on meme: ${meme.topText ?? meme.id}'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: theme.colorScheme.secondary,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Image.network(
                            meme.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2.0,
                                ),
                              );
                            },
                            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Center(child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey[400])),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            (meme.topText?.isNotEmpty ?? false)
                                ? meme.topText!
                                : (meme.bottomText?.isNotEmpty ?? false)
                                    ? meme.bottomText!
                                    : 'Meme',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                          child: Text(
                            '${meme.createdAt.day}/${meme.createdAt.month}/${meme.createdAt.year}',
                            style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
```
