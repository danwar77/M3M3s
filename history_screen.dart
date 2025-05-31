import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Uncomment for actual Supabase calls

// Basic model for a Meme item.
// This should be adapted to your actual data model from Supabase,
// especially the fields retrieved and how they map (e.g., text_input JSON).
class MemeHistoryItem {
  final String id;
  final String imageUrl; // URL or path in Supabase Storage
  final String? topText;    // Optional, might be part of a JSON object in DB
  final String? bottomText; // Optional
  final DateTime createdAt;

  MemeHistoryItem({
    required this.id,
    required this.imageUrl,
    this.topText,
    this.bottomText,
    required this.createdAt,
  });

  // Example factory constructor if fetching from a Map (like Supabase response)
  // factory MemeHistoryItem.fromMap(Map<String, dynamic> map) {
  //   final textInput = map['text_input'] as Map<String, dynamic>?;
  //   return MemeHistoryItem(
  //     id: map['id'] as String,
  //     imageUrl: map['image_url'] as String,
  //     topText: textInput?['top'] as String?,
  //     bottomText: textInput?['bottom'] as String?,
  //     createdAt: DateTime.parse(map['created_at'] as String),
  //   );
  // }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<MemeHistoryItem>> _memesFuture;
  bool _isFetching = false; // To prevent multiple simultaneous fetches

  @override
  void initState() {
    super.initState();
    _memesFuture = _fetchMemeHistory();
  }

  // Mock data fetching function
  // TODO: Replace this with actual Supabase calls.
  Future<List<MemeHistoryItem>> _fetchMemeHistory() async {
    if (_isFetching) return _memesFuture; // Return current future if already fetching
    _isFetching = true;

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // --- TODO: Replace with actual Supabase call ---
    // final supabase = Supabase.instance.client;
    // final userId = supabase.auth.currentUser?.id;

    // if (userId == null) {
    //   _isFetching = false;
    //   // It's better to handle "not logged in" state via AuthState listener
    //   // and not even show HistoryScreen, or show a specific "Please log in" message.
    //   return Future.error('User not logged in. Please log in to see your history.');
    // }

    // try {
    //   final response = await supabase
    //       .from('memes') // Your Supabase table name for memes
    //       .select() // Select all columns or specify: 'id, image_url, text_input, created_at'
    //       .eq('user_id', userId)
    //       .order('created_at', ascending: false)
    //       .limit(50); // Add pagination later if needed

    //   // The actual type of response.data depends on how PostgREST client is configured,
    //   // usually List<Map<String, dynamic>>
    //   final List<dynamic> data = response as List<dynamic>;

    //   _isFetching = false;
    //   if (data.isEmpty) {
    //     return []; // Return empty list if no data
    //   }

    //   return data.map((item) {
    //     final Map<String, dynamic> memeData = item as Map<String, dynamic>;
    //     final textInput = memeData['text_input'] as Map<String, dynamic>?;
    //     return MemeHistoryItem(
    //       id: memeData['id'] as String,
    //       imageUrl: memeData['image_url'] as String, // This should be a publicly accessible URL or requires signing
    //       topText: textInput?['top'] as String?,
    //       bottomText: textInput?['bottom'] as String?,
    //       createdAt: DateTime.parse(memeData['created_at'] as String),
    //     );
    //   }).toList();
    // } on PostgrestException catch (e) {
    //   _isFetching = false;
    //   print('Supabase fetch error: ${e.message}');
    //   return Future.error('Failed to load memes: ${e.message}');
    // } catch (e) {
    //   _isFetching = false;
    //   print('Generic fetch error: $e');
    //   return Future.error('An unexpected error occurred while fetching memes.');
    // }
    // --- End Supabase Call Placeholder ---


    // --- Mock Data Implementation ---
    _isFetching = false; // Reset fetch flag

    // Simulate an error state:
    // return Future.error('Failed to load memes. Please try again later.');

    // Simulate an empty state:
    // return [];

    // Simulate successful data fetch:
    return List.generate(10, (index) {
      return MemeHistoryItem(
        id: 'meme_mock_id_$index',
        imageUrl: 'https://picsum.photos/seed/memeMock$index/250/250', // Using picsum for placeholders
        topText: 'Mock Top Text ${index + 1}',
        bottomText: 'Mock Bottom Text ${index + 1}',
        createdAt: DateTime.now().subtract(Duration(days: index * 2, hours: index * 3)),
      );
    });
    // --- End Mock Data ---
  }

  Future<void> _refreshHistory() async {
    // Only trigger a new fetch if not already fetching.
    // The FutureBuilder will then react to the new future instance.
    if (!_isFetching) {
      setState(() {
        _memesFuture = _fetchMemeHistory();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The AppBar is typically handled by MainScreen when HistoryScreen is a tab.
    return Scaffold(
      body: FutureBuilder<List<MemeHistoryItem>>(
        future: _memesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong.',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}', // Display the actual error message
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      onPressed: _refreshHistory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
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
                    Text(
                      'No Memes Yet!',
                      style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Looks like your meme gallery is empty.\nGo create some masterpieces!",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Check Again'),
                      onPressed: _refreshHistory,
                    )
                  ],
                ),
              ),
            );
          }

          // Data has been successfully fetched and is not empty
          final List<MemeHistoryItem> memes = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshHistory,
            child: GridView.builder(
              padding: const EdgeInsets.all(12.0), // Increased padding
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2, // Responsive columns
                crossAxisSpacing: 12.0, // Increased spacing
                mainAxisSpacing: 12.0,  // Increased spacing
                childAspectRatio: 0.85, // Adjust for a slightly taller item if text is below
              ),
              itemCount: memes.length,
              itemBuilder: (context, index) {
                final meme = memes[index];
                return Card(
                  elevation: 3.0,
                  clipBehavior: Clip.antiAlias, // Ensures image respects card rounded corners
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), // Rounded corners for the card
                  child: InkWell(
                    onTap: () {
                      // TODO: Navigate to a meme detail screen or an edit screen
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => MemeDetailScreen(memeId: meme.id)));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tapped on meme: ${meme.id} - ${meme.topText ?? ''}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Column( // Using Column to place text below the image
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
                            // Display top text or a default name if no text
                            (meme.topText?.isNotEmpty ?? false) ? meme.topText! : 'Meme ${meme.id.substring(0,6)}',
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
