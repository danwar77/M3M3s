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
  // Remove or adapt old state variables for FutureBuilder approach
  // late Future<List<MemeHistoryItem>> _memesFuture; // REMOVE
  // bool _isFetching = false; // REMOVE or rename/repurpose if a general fetch flag was used differently

  static const double _scrollOffsetThreshold = 200.0; // Threshold to trigger loading more items

  // New state variables for meme history pagination
  List<MemeHistoryItem> _allHistoryMemes = [];
  int _historyCurrentPage = 0; // 0-indexed for offset calculation
  final int _historyPageSize = 12; // Number of items per page (e.g., for a 2 or 3 column grid)
  bool _isLoadingInitialHistory = false; // For the very first fetch
  bool _isLoadingMoreHistory = false;  // For fetching subsequent pages
  bool _hasMoreHistory = true;         // True if more history items might be available
  Object? _fetchHistoryError;        // To store any error during history fetching
  final ScrollController _historyScrollController = ScrollController(); // For infinite scroll

  @override
  void initState() {
    super.initState();

    // Initial fetch if user is logged in.
    // The actual listener for auth changes driving this might be in a higher widget,
    // or we can check here. For simplicity, assume if screen is shown, we attempt fetch.
    // The _fetchMemeHistory method will guard against no user.
    // _fetchMemeHistory(isInitialFetch: true); // We'll trigger this from build or _selectTemplate like logic

    // Add listener to scroll controller for infinite scrolling
    _historyScrollController.addListener(() {
      if (_historyScrollController.position.pixels >= _historyScrollController.position.maxScrollExtent - _scrollOffsetThreshold && // Trigger before exact bottom
          _hasMoreHistory &&
          !_isLoadingMoreHistory &&
          !_isLoadingInitialHistory &&
          _fetchHistoryError == null) { // Don't load more if there was an error on previous pages
        _fetchMemeHistory(); // isInitialFetch defaults to false
      }
    });

    // If Supabase auth state changes while this screen is active, we might need to re-fetch.
    // This can be handled by listening to Supabase.instance.client.auth.onAuthStateChange here
    // or by making sure this widget rebuilds (e.g. if it's a child of MemeApp which handles auth state).
    // For now, initial fetch will be triggered if list is empty when build method is called.

    // Attempt initial fetch. _fetchMemeHistory will handle null user.
    // Ensure it only runs if no data and not already loading to prevent multiple calls on hot reload.
    if (_allHistoryMemes.isEmpty && !_isLoadingInitialHistory && _fetchHistoryError == null) {
       _fetchMemeHistory(isInitialFetch: true);
    }
  }

  @override
  void dispose() {
    _historyScrollController.dispose(); // Dispose the scroll controller
    // Cancel any active listeners if added (e.g., for auth state changes locally)
    super.dispose();
  }

Future<void> _fetchMemeHistory({bool isInitialFetch = false}) async {
  // Prevent concurrent fetches or fetching if no more data or error occurred previously (unless initial fetch)
  if ((isInitialFetch && _isLoadingInitialHistory) ||
      (!isInitialFetch && _isLoadingMoreHistory) ||
      (!isInitialFetch && !_hasMoreHistory)) {
    // If trying to load more but an error occurred on a previous "load more", allow if user explicitly retries.
    // The current check _hasMoreHistory would prevent this.
    // For now, this strict check is okay. Retry from error state will use isInitialFetch=true.
    return;
  }

  final scaffoldMessenger = ScaffoldMessenger.of(context); // Cache for async gaps

  if (mounted) {
    setState(() {
      if (isInitialFetch) {
        _isLoadingInitialHistory = true;
        _fetchHistoryError = null; // Clear previous errors on a new initial fetch
      } else {
        _isLoadingMoreHistory = true;
        // Don't clear _fetchHistoryError for "load more" as main screen might still show prior error if list empty
      }
    });
  }

  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    if (mounted) {
      setState(() {
        _fetchHistoryError = 'User not authenticated. Please log in.';
        _isLoadingInitialHistory = false;
        _isLoadingMoreHistory = false;
        _hasMoreHistory = false; // No point in trying to fetch more
        _allHistoryMemes.clear(); // Clear any stale data
      });
    }
    return;
  }

  try {
    if (isInitialFetch) {
      _historyCurrentPage = 0; // Reset page for initial fetch
      _allHistoryMemes.clear(); // Clear existing history items
      _hasMoreHistory = true;   // Assume there's more until proven otherwise
    }

    final offset = _historyCurrentPage * _historyPageSize;

    final response = await supabase
        .from('memes')
        .select() // Fetches all columns, ensure MemeHistoryItem.fromMap handles them
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + _historyPageSize - 1);
        // Supabase Dart v2.x.x returns List<Map<String,dynamic>> or throws PostgrestException

    final List<dynamic> fetchedData = response as List<dynamic>;
    final List<MemeHistoryItem> newHistoryItems = fetchedData
        .map((item) => MemeHistoryItem.fromMap(item as Map<String, dynamic>))
        .toList();

    if (mounted) {
      setState(() {
        _allHistoryMemes.addAll(newHistoryItems);
        _historyCurrentPage++; // Increment page for next fetch
        if (newHistoryItems.length < _historyPageSize) {
          _hasMoreHistory = false; // No more history if fetched less than page size
        }
        _fetchHistoryError = null; // Clear error on ANY successful fetch (initial or load more)
      });
    }
  } on PostgrestException catch (error) {
    print('Supabase fetch meme history error: ${error.message}');
    if (mounted) {
      setState(() {
        _fetchHistoryError = error;
        // _hasMoreHistory = false; // Potentially stop further attempts if a page fails
      });
      if (!isInitialFetch && _allHistoryMemes.isNotEmpty) {
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to load more: ${error.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () {
                _fetchMemeHistory(); // Attempt to load more again
              },
            ),
          ),
        );
      }
    }
  } catch (e) {
    print('Generic fetch meme history error: $e');
    if (mounted) {
      setState(() {
        _fetchHistoryError = e;
        // _hasMoreHistory = false;
      });
      if (!isInitialFetch && _allHistoryMemes.isNotEmpty) {
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Failed to load more: An unexpected error occurred.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () {
                _fetchMemeHistory(); // Attempt to load more again
              },
            ),
          ),
        );
      }
    }
  } finally {
    if (mounted) {
      setState(() {
        if (isInitialFetch) {
          _isLoadingInitialHistory = false;
        } else {
          _isLoadingMoreHistory = false;
        }
      });
    }
  }
}

// Update _refreshHistory to use the new paginated fetch
Future<void> _refreshHistory() async {
  // Ensure user is still logged in before refreshing
  if (Supabase.instance.client.auth.currentUser != null) {
    // No need to manage _isLoadingInitialHistory directly here,
    // _fetchMemeHistory will handle its own loading flags.
    // Just ensure it's treated as an initial fetch.
    await _fetchMemeHistory(isInitialFetch: true);
  } else {
    if (mounted) {
      setState(() {
        _allHistoryMemes.clear(); // Clear data if user logged out
        _fetchHistoryError = 'User not authenticated. Please log in.';
        _hasMoreHistory = false;
        _isLoadingInitialHistory = false; // Ensure loading stops
        _isLoadingMoreHistory = false;
      });
    }
  }
}

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  // Initial fetch is now triggered from initState.
  // The build method will reflect the state set by that initial fetch or subsequent updates.

  Widget content;

  if (_isLoadingInitialHistory && _allHistoryMemes.isEmpty) {
    content = Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Loading your meme history..."),
          ],
        ),
      ),
    );
  } else if (_fetchHistoryError != null && _allHistoryMemes.isEmpty) {
    String displayError = 'Oops! Could not load your history.';
    if (_fetchHistoryError is String && (_fetchHistoryError as String).contains('User not authenticated')) {
        displayError = 'Please log in to see your meme history.';
    } else if (_fetchHistoryError is PostgrestException) {
        displayError += '\nError: ${(_fetchHistoryError as PostgrestException).message}';
    } else if (_fetchHistoryError is String) {
        displayError += '\nError: $_fetchHistoryError';
    }

    content = Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 50),
            const SizedBox(height: 16),
            Text(displayError, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.errorContainer, foregroundColor: theme.colorScheme.onErrorContainer),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _fetchHistoryError = null;
                    _hasMoreHistory = true; // Reset to allow fetching
                  });
                  _fetchMemeHistory(isInitialFetch: true);
                }
              },
            )
          ],
        ),
      ),
    );
  } else if (_allHistoryMemes.isEmpty && !_hasMoreHistory) { // After a successful fetch with no data
    content = Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_outlined, size: 60, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text('No memes found in your history yet.', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Text('Go create some awesome memes!', style: theme.textTheme.bodySmall),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh), // Or an Add icon to go to create screen
              label: const Text('Refresh History'),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _fetchHistoryError = null; // Clear any latent error
                    _hasMoreHistory = true;     // Allow re-fetch attempt
                  });
                  _fetchMemeHistory(isInitialFetch: true);
                }
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Create a Meme'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              onPressed: () {
                // TODO: Implement navigation to the Create screen/tab
                // This might involve calling a callback from a parent widget (e.g., MainScreen)
                // or using a more sophisticated navigation solution if available.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigate to Create Meme screen (placeholder).')),
                );
              },
            ),
          ],
        ),
      ),
    );
  } else { // Data available or loading more
    content = RefreshIndicator(
      onRefresh: _refreshHistory, // _refreshHistory calls _fetchMemeHistory(isInitialFetch: true)
      child: GridView.builder(
        controller: _historyScrollController,
        padding: const EdgeInsets.all(8.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 1.0, // Square items
        ),
        itemCount: _allHistoryMemes.length + (_hasMoreHistory && _allHistoryMemes.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _allHistoryMemes.length && _hasMoreHistory) {
            // Last item is the loading indicator if there are more pages and list is not empty
            return _isLoadingMoreHistory
                ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: SizedBox(height: 24, width: 24, child:CircularProgressIndicator(strokeWidth: 2.5))))
                : const SizedBox.shrink(); // Should not normally be visible if listener works correctly
          }

          if (index >= _allHistoryMemes.length) {
            // Should not happen if itemCount is correct, but as a safeguard
            return const SizedBox.shrink();
          }

          final meme = _allHistoryMemes[index];
          return Card(
            elevation: 2.0,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                // TODO: Navigate to meme detail or edit screen
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tapped on meme: ${meme.id}')),
                );
              },
              child: GridTile(
                footer: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  color: Colors.black.withOpacity(0.5),
                  child: Text(
                    meme.topText ?? 'Created: ${meme.createdAt.day}/${meme.createdAt.month}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                child: Image.network(
                  meme.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null));
                  },
                  errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                    return Container(color: Colors.grey[200], child: Center(child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey[400])));
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  return Scaffold(
    // AppBar is handled by MainScreen as this is a tab.
    body: content,
  );
}
}
```
