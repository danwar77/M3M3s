import 'package:flutter/material.dart';

// It's good practice to initialize Supabase (or other services)
// in main() if they are needed globally before the app runs.
// For this basic structure, we'll keep it simple.
// import 'package:supabase_flutter/supabase_flutter.dart'; // Example

// --- Placeholder Screens ---
// These would typically be in their own files (e.g., screens/create_screen.dart)

/// Placeholder for the screen where users can create or start generating memes.
/// This might also serve as a "home" or "welcome" screen.
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.add_photo_alternate_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Create / Welcome Screen Area',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Users will start their meme creation journey here, '
              'select templates, or input text for AI generation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for the screen where users can view their saved meme history.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.history_edu_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Meme History Screen Area',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
           Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'This screen will display a list of memes previously generated and saved by the user.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Main Application Widget ---

/// The root widget of the Meme Generator application.
/// It sets up the [MaterialApp], defines the theme, and specifies the home screen.
class MemeApp extends StatelessWidget {
  const MemeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meme Generator App',
      debugShowCheckedModeBanner: false, // Optional: remove debug banner
      theme: ThemeData(
        primarySwatch: Colors.deepPurple, // Changed to deepPurple for a bit of fun
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light, // Or Brightness.dark for a dark theme
        ),
        useMaterial3: true,
        // Further theme customizations can go here:
        // appBarTheme: AppBarTheme(
        //   backgroundColor: Colors.deepPurpleAccent,
        //   foregroundColor: Colors.white,
        // ),
        // bottomNavigationBarTheme: BottomNavigationBarThemeData(
        //   selectedItemColor: Colors.deepPurpleAccent,
        //   unselectedItemColor: Colors.grey[600],
        // ),
      ),
      home: const MainScreen(), // The main screen with BottomNavigationBar
    );
  }
}

// --- Screen with Bottom Navigation Bar ---

/// A stateful widget that manages the main application screen,
/// including a [BottomNavigationBar] to switch between different sections
/// like "Create" and "History".
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Index for the currently selected tab

  // List of widgets to display in the body based on the selected tab index.
  // These are the main sections of our app.
  static const List<Widget> _widgetOptions = <Widget>[
    CreateScreen(), // Corresponds to index 0
    HistoryScreen(),  // Corresponds to index 1
  ];

  // List of titles for the AppBar corresponding to each screen.
  static const List<String> _appBarTitles = <String>[
    'Create Meme',
    'My Meme History',
  ];

  /// Handles tap events on the BottomNavigationBar items.
  /// Updates the `_selectedIndex` to switch the displayed screen.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]), // Dynamically set AppBar title
        // actions: [ // Example: Add an action button to AppBar
        //   if (_selectedIndex == 0) // Only show for Create screen
        //     IconButton(
        //       icon: Icon(Icons.info_outline),
        //       onPressed: () {
        //         // Show some info
        //       },
        //     ),
        // ],
      ),
      body: Center(
        // Display the widget from _widgetOptions based on the current index
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle), // Optional: different icon when active
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history), // Optional: different icon when active
            label: 'History',
          ),
        ],
        currentIndex: _selectedIndex, // Highlights the current tab
        selectedItemColor: Theme.of(context).colorScheme.primary, // Use theme color
        unselectedItemColor: Colors.grey, // Optional: for inactive tabs
        onTap: _onItemTapped, // Callback for when a tab is tapped
        // type: BottomNavigationBarType.shifting, // Optional: for different animation/style
        // showUnselectedLabels: false, // Optional: to hide labels of unselected items
      ),
    );
  }
}

// --- Main Function ---

/// The entry point of the Flutter application.
void main() async {
  // It's crucial to ensure Flutter bindings are initialized before any async operations
  // like Supabase initialization if they are done here.
  WidgetsFlutterBinding.ensureInitialized();

  // Example: Initialize Supabase (or other services) here if needed globally
  // try {
  //   await Supabase.initialize(
  //     url: 'YOUR_SUPABASE_URL',       // From --dart-define or config
  //     anonKey: 'YOUR_SUPABASE_ANON_KEY', // From --dart-define or config
  //   );
  // } catch (e) {
  //   print("Error initializing Supabase: $e");
  //   // Handle initialization error, maybe show an error screen
  // }

  runApp(const MemeApp());
}
```
