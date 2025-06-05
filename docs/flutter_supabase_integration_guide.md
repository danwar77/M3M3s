# Flutter & Supabase Integration Guide

This guide provides a comprehensive overview for Flutter developers on how to use the `supabase_flutter` package to interact with various Supabase backend services, including Authentication, Database (PostgREST), Storage, and Edge Functions.

## 1. Project Setup & Initialization

### 1.1. Installation
Add the `supabase_flutter` package to your `pubspec.yaml`:

yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0 # Always check for the latest version

Then, run `flutter pub get` in your terminal.

### 1.2. Initialization
Initialize Supabase in your `main.dart` file before running your app. This typically happens in the `main()` function.

dart
// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',       // Replace with your Supabase project URL
    anonKey: 'YOUR_SUPABASE_ANON_KEY', // Replace with your Supabase anon key
    // Optional: custom schema, auth storage, etc.
    // authFlowType: AuthFlowType.pkce,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Supabase App',
      home: AuthWrapper(), // Your app's entry point
    );
  }
}


**Best Practices for Storing URL and Anon Key:**
Do **not** hardcode your Supabase URL and Anon Key directly in your source code if it's public.
*   **Using `--dart-define` (Recommended for build time):**
    Pass variables during `flutter run` or `flutter build`:
    bash
    flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_KEY
    
    Access them in your Dart code:
    dart
    const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'DEFAULT_URL_IF_NOT_SET');
    const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'DEFAULT_KEY_IF_NOT_SET');
    
*   **Using a configuration file (e.g., `.env` loaded at runtime - ensure it's in `.gitignore`):**
    Use packages like `flutter_dotenv` to load environment variables from a `.env` file.

### 1.3. Accessing the Client
Once initialized, you can access the Supabase client instance globally:

dart
final supabase = Supabase.instance.client;
// For brevity, you can also use:
// final client = Supabase.client;


## 2. Authentication

Supabase Auth provides robust user authentication. The `supabase_flutter` package simplifies its integration.

*   **Core Operations:** Sign-up, sign-in (with email/password, phone, social OAuth), sign-out.
*   **Auth State:** Listen to `supabase.auth.onAuthStateChange` to reactively update your UI based on the user's authentication status (e.g., navigating to a home screen on login or a login screen on logout).
*   **User Management:** Access current user details via `supabase.auth.currentUser`.
*   **Session Persistence:** `supabase_flutter` automatically handles session persistence and token refreshing.

**For detailed examples and setup, please refer to the `supabase_auth_guide.md` document.**

## 3. Database (CRUD Operations with PostgREST)

Interact with your Supabase PostgreSQL database using the PostgREST client.

dart
final client = Supabase.instance.client;


### 3.1. Fetching Data (`select`)

*   **Select all columns from a table:**
    dart
    final response = await client.from('your_table').select();
    if (response.isEmpty) {
      print('No data found');
    } else {
      print('Data: $response'); // List of maps
    }
    

*   **Select specific columns:**
    dart
    final data = await client.from('your_table').select('column1, column2');
    

*   **Fetch related data (foreign tables using `!inner` for non-nullable or default for nullable):**
    Assuming `profiles` table has a foreign key to `your_table`'s `id`.
    dart
    // Fetch 'your_table' data and related 'profiles' data
    final data = await client.from('your_table').select('*, profiles(*)');
    // To specify columns from related table:
    // final data = await client.from('your_table').select('id, name, profiles(username, avatar_url)');
    

*   **Filtering Data:**
    *   `.eq('column_name', value)`: Equal to
    *   `.neq('column_name', value)`: Not equal to
    *   `.gt('column_name', value)`: Greater than
    *   `.lt('column_name', value)`: Less than
    *   `.gte('column_name', value)`: Greater than or equal to
    *   `.lte('column_name', value)`: Less than or equal to
    *   `.like('column_name', '%pattern%')`: LIKE operator (case-sensitive)
    *   `.ilike('column_name', '%pattern%')`: ILIKE operator (case-insensitive)
    *   `.is_('column_name', null)`: Is null (or `true`, `false`)
    *   `.in_('column_name', ['value1', 'value2'])`: In a list of values
    *   `.cs('array_column_name', ['value1', 'value2'])`: Array column contains elements
    *   `.cd('array_column_name', ['value1', 'value2'])`: Array column is contained by elements
    *   `.not('column_name', 'eq', value)`: Negate a filter
    *   `.or('filter1,filter2')`: OR condition, e.g., `.or('id.eq.1,name.eq.John')`
    *   `.filter('column_name', 'operator', 'value')`: Generic filter

    dart
    final data = await client
        .from('products')
        .select()
        .eq('category', 'Electronics')
        .gt('price', 100)
        .limit(10);
    

*   **Ordering Results:**
    dart
    final data = await client
        .from('your_table')
        .select()
        .order('created_at', ascending: false); // Default is false (descending)
    // Order by multiple columns:
    // .order('category', ascending: true).order('name', ascending: true)
    

*   **Limiting and Pagination:**
    *   `.limit(count)`: Limit the number of rows returned.
    *   `.range(from, to)`: Fetch rows within a specific range (inclusive, 0-indexed).
    dart
    final dataPage1 = await client.from('your_table').select().range(0, 9); // First 10 rows
    final dataPage2 = await client.from('your_table').select().range(10, 19); // Next 10 rows
    

*   **Single Row Fetch:**
    *   `.single()`: Fetches a single row. Throws an error if not exactly one row is found.
    *   `.maybeSingle()`: Fetches a single row. Returns `null` if no row is found. Throws an error if multiple rows are found.
    dart
    try {
      final data = await client.from('your_table').select().eq('id', someId).single();
      // Use data
    } catch (e) {
      // Handle error (e.g., PostgrestException if row not found or multiple found)
    }

    final dataOrNull = await client.from('your_table').select().eq('id', someId).maybeSingle();
    if (dataOrNull != null) {
      // Use dataOrNull
    }
    

### 3.2. Inserting Data (`insert`)

dart
try {
  final List<Map<String, dynamic>> response = await client
      .from('your_table')
      .insert({'column1': 'value1', 'column2': 123})
      .select(); // Optionally .select() to get the inserted row(s) back
  print('Inserted data: $response');
} on PostgrestException catch (error) {
  print('Database error: ${error.message}');
}

*   **Bulk Inserts:**
    dart
    await client.from('your_table').insert([
      {'column1': 'valueA', 'column2': 1},
      {'column1': 'valueB', 'column2': 2},
    ]);
    

### 3.3. Updating Data (`update`)

dart
try {
  final List<Map<String, dynamic>> response = await client
      .from('your_table')
      .update({'status': 'updated', 'column2': 'new_value'})
      .eq('id', someId) // Filter condition is crucial
      .select(); // Optionally .select() to get the updated row(s) back
  print('Updated data: $response');
} on PostgrestException catch (error) {
  print('Database error: ${error.message}');
}


### 3.4. Deleting Data (`delete`)

dart
try {
  // The delete operation by default does not return the deleted rows.
  // If you need the deleted data, select it first or use a function.
  await client
      .from('your_table')
      .delete()
      .eq('id', someId); // Filter condition is crucial
  print('Data deleted successfully.');
} on PostgrestException catch (error) {
  print('Database error: ${error.message}');
}


### 3.5. Upserting Data (`upsert`)
Inserts rows if they don't exist (based on primary key or conflict target), or updates them if they do.

dart
try {
  final List<Map<String, dynamic>> response = await client
      .from('your_table')
      .upsert({
        'id': existingOrNewId, // Must include the primary key for matching
        'column1': 'new_or_updated_value'
      })
      .select();
  print('Upserted data: $response');
} on PostgrestException catch (error) {
  print('Database error: ${error.message}');
}

You can specify `onConflict` for more control if not using the primary key.

### 3.6. Calling PostgreSQL Functions (RPC)
Call custom database functions defined in your Supabase SQL editor.

dart
try {
  // Assuming a function `increment_views(meme_id_param UUID)` exists
  final result = await client.rpc(
    'increment_views',
    params: {'meme_id_param': 'your-meme-id-uuid'},
  );
  print('RPC result: $result');
} on PostgrestException catch (error) {
  print('RPC error: ${error.message}');
}


## 4. Storage Operations

Supabase Storage allows you to manage files like images and videos.

*   **Core Operations:** Uploading files (from `File` or `Uint8List`), generating public URLs for public files, creating signed URLs for private files, and deleting files.
*   **File Organization:** Structure files in buckets, often using user IDs in paths for easier RLS policy management (e.g., `user_id/image.png`).

**For detailed examples and setup, please refer to the `supabase_storage_guide.md` document.**

## 5. Invoking Edge Functions

Execute server-side TypeScript (Deno) functions for custom logic.

dart
final functions = Supabase.instance.client.functions;

try {
  final response = await functions.invoke(
    'your-edge-function-name', // Name of the Edge Function
    body: {'param1': 'value1', 'customData': {'key': 'value'}},
    // headers: {'X-Custom-Header': 'custom-value'}, // Optional custom headers
  );

  if (response.status == 200) { // Or other success codes
    print('Edge function data: ${response.data}');
    // Process response.data
  } else {
    print('Edge function error: ${response.status} - ${response.data}');
  }
} on FunctionException catch (error) {
  // More specific error from Supabase client for functions
  print('FunctionException: ${error.message}');
  print('FunctionException Details: ${error.details}'); // Might contain more info like status code
} catch (e) {
  print('Generic error invoking Edge Function: $e');
}

*   The `body` can be any serializable JSON object.
*   `response.data` contains the data returned by the Edge Function.
*   `response.status` gives the HTTP status code from the function's response.

## 6. Realtime Subscriptions (Brief Overview)

Supabase Realtime allows you to listen to database changes (inserts, updates, deletes), presence events, and broadcast messages.

dart
final client = Supabase.instance.client;
final myChannel = client.channel('my_table_updates'); // Unique channel name

// Subscribe to all changes on 'your_table' in the 'public' schema
myChannel.on(
  RealtimeListenTypes.postgresChanges,
  ChannelFilter(
    event: '*', // Listen to 'INSERT', 'UPDATE', 'DELETE', or '*' for all
    schema: 'public',
    table: 'your_table',
    // filter: 'id=eq.some_value', // Optional: filter specific rows
  ),
  (payload, [ref]) {
    print('Change received on your_table:');
    print('Event type: ${payload['eventType']}');
    print('New data: ${payload['new']}'); // For INSERT and UPDATE
    print('Old data: ${payload['old']}'); // For UPDATE and DELETE
    // Handle the payload
  },
).subscribe((status, [_]) {
  if (status == 'SUBSCRIBED') {
    print('Subscribed to my_table_updates channel!');
  } else if (status == 'CLOSED') {
    print('Subscription to my_table_updates closed.');
  } else if (status == 'CHANNEL_ERROR') {
    print('Error on my_table_updates channel.');
  }
});

// To unsubscribe when done (e.g., in dispose method of a StatefulWidget):
// client.removeChannel(myChannel);
// or
// myChannel.unsubscribe();


**Use Cases:**
*   Live updates in UI when database data changes.
*   Realtime chat features.
*   Notifications.

**Note:** Implementing specific realtime features often requires careful state management and consideration of data flow. This is a basic introduction to the subscription mechanism.

## 7. State Management Integration

Integrating Supabase operations with a state management solution (like Provider, Riverpod, BLoC/Cubit) is highly recommended for managing UI state, loading indicators, error display, and data flow.

**General Advice:**

1.  **Service/Repository Layer:** Create service classes or repositories that encapsulate your Supabase API calls. These classes will interact directly with `Supabase.instance.client`.
    dart
    // Example: profile_service.dart
    class ProfileService {
      final SupabaseClient _client = Supabase.instance.client;

      Future<Map<String, dynamic>?> getProfile(String userId) async {
        try {
          return await _client.from('profiles').select().eq('id', userId).single();
        } catch (e) {
          // Handle error
          return null;
        }
      }
      // Add other profile related methods...
    }
    

2.  **State Notifiers/Controllers:** Use your chosen state management tool's controllers (e.g., `ChangeNotifier`, `StateNotifier`, `Bloc`) to:
    *   Call methods from your service/repository classes.
    *   Manage loading states (e.g., `isLoading = true` before the call, `false` after).
    *   Store fetched data or error messages.
    *   Notify the UI to rebuild when state changes.

**Conceptual Example (using Riverpod):**

dart
// 1. Define a provider for your service
final profileServiceProvider = Provider((ref) => ProfileService());

// 2. Define a FutureProvider to fetch data
final userProfileProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, userId) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getProfile(userId);
});

// 3. In your widget:
// Consumer(
//   builder: (context, ref, child) {
//     final asyncProfile = ref.watch(userProfileProvider('user-id'));
//     return asyncProfile.when(
//       data: (profile) => profile != null ? Text(profile['username']) : Text('Profile not found'),
//       loading: () => CircularProgressIndicator(),
//       error: (err, stack) => Text('Error: $err'),
//     );
//   },
// )

Refer to the documentation of your chosen state management package for specific integration patterns with asynchronous operations.

## 8. Error Handling in Flutter

Robust error handling is crucial for a good user experience.

*   **Common Supabase Exceptions:**
    *   `AuthException`: For authentication errors (e.g., invalid credentials, email not confirmed).
    *   `PostgrestException`: For database errors (e.g., RLS violations, network issues, invalid query). Contains `message`, `code`, `details`, `hint`.
    *   `StorageException`: For file storage errors (e.g., file not found, access denied).
    *   `FunctionException`: For errors when invoking Edge Functions. Contains `message`, `details` (which might include `status` code from the function).
*   **Try-Catch Blocks:** Always wrap Supabase calls in `try-catch` blocks.
    dart
    try {
      // Supabase operation
    } on AuthException catch (e) {
      // Handle auth error
      print('Auth Error: ${e.message}');
    } on PostgrestException catch (e) {
      // Handle database error
      print('DB Error: ${e.code} - ${e.message}');
    } on StorageException catch (e) {
      // Handle storage error
      print('Storage Error: ${e.message}');
    } on FunctionException catch (e) {
      // Handle function error
      print('Function Error: ${e.message} (${e.details})');
    } catch (e) {
      // Handle any other generic errors
      print('Generic Error: $e');
    }
    
*   **User-Friendly Messages:** Convert caught exceptions into user-friendly messages to display in the UI (e.g., via SnackBars, Dialogs, or inline error texts). Avoid showing raw error messages directly to users unless it's for debugging.
*   **Logging:** Log detailed errors to your preferred logging service for debugging and monitoring.

This guide provides a starting point for integrating Supabase into your Flutter application. Always refer to the official [Supabase Flutter documentation](https://supabase.io/docs/guides/getting-started/tutorials/with-flutter) for the most current and detailed information.

