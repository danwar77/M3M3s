import 'dart:async'; // For StreamSubscription
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Placeholder Screens (Simplified for this file's context) ---
// In a real app, these would be imported from their respective files.
// For this subtask, LoginScreen and SignUpScreen are defined in their own files
// and would be imported into main_app_structure.dart if it were the true main.dart.
// However, to make this file self-contained for the tool, we use these simple placeholders.

class LoginScreenPlaceholder extends StatelessWidget { // Renamed to avoid conflict if importing real LoginScreen
  const LoginScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login Screen', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // TODO: Navigate to a conceptual SignUpScreen if it were defined here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigate to Sign Up (Placeholder)')),
                );
              },
              child: const Text('Go to Sign Up (Placeholder)'),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Create Screen (Home)'));
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('History Screen'));
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[CreateScreen(), HistoryScreen()];
  static const List<String> _appBarTitles = <String>['Create Meme', 'My History'];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Future<void> _performLogout() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context); // For SnackBar theming

    scaffoldMessenger.removeCurrentSnackBar(); // Clear previous SnackBars

    try {
      await Supabase.instance.client.auth.signOut();
      // The onAuthStateChange listener in MemeApp will handle navigation to LoginScreen.
      // No need for explicit navigation here if listener is set up correctly.
      if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('Successfully logged out.'),
              backgroundColor: Colors.green.shade700 // Consistent success color
            ),
          );
      }
    } on AuthException catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Logout failed: ${e.message}'),
              backgroundColor: theme.colorScheme.error
            ),
          );
        }
    } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('An unexpected error occurred during logout: ${e.toString()}'),
              backgroundColor: theme.colorScheme.error
            ),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _performLogout, // Call the implemented logout method
          )
        ],
      ),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'History'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// --- Main Application Logic ---

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Replace with your actual Supabase URL and Anon Key.
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  runApp(const MemeApp());
}

class MemeApp extends StatefulWidget {
  const MemeApp({super.key});

  @override
  State<MemeApp> createState() => _MemeAppState();
}

class _MemeAppState extends State<MemeApp> {
  Session? _initialSession = Supabase.instance.client.auth.currentSession;
  StreamSubscription<AuthState>? _authStateSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAuthStateListener();
  }

  void _initializeAuthStateListener() {
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _initialSession = data.session;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      if (mounted) {
         print("Auth listener error: $error");
         setState(() {
           _isLoading = false;
         });
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () { // Reduced delay slightly
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Initializing App..."),
              ],
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp(
      title: 'MemeMarvel App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        snackBarTheme: SnackBarThemeData( // Consistent SnackBar behavior
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          elevation: 4.0,
        )
      ),
      home: _initialSession == null ? const LoginScreenPlaceholder() : const MainScreen(), // Using placeholder LoginScreen
      debugShowCheckedModeBanner: false,
      // TODO: Define actual routes when LoginScreen and SignUpScreen are in separate files and imported.
      // routes: {
      //   '/login': (context) => const LoginScreen(),
      //   '/main': (context) => const MainScreen(),
      //   '/signup': (context) => const SignUpScreen(),
      // },
    );
  }
}
```
