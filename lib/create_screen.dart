import 'package:flutter/material.dart';

/// CreateScreen serves as the initial welcome/dashboard view within the "Create" tab.
/// It provides a user-friendly interface with clear calls to action.
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context); // Access the current theme for consistent styling
    final ColorScheme colorScheme = theme.colorScheme; // Access color scheme

    return Scaffold(
      // Note: The AppBar is typically handled by the parent widget (e.g., MainScreen)
      // when CreateScreen is used as one of the BottomNavigationBar's _widgetOptions.
      // If this screen were pushed as a new route, it might define its own AppBar here.
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView( // Added for smaller screens or more content
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // App Logo (Placeholder - can be replaced with an Image widget)
                Icon(
                  Icons.auto_awesome_mosaic, // Example icon, consider a more relevant one
                  size: 80.0,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24), // Adjusted spacing

                // App Title
                Text(
                  'M3M3s', // Replace with your actual app name if different
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12), // Adjusted spacing

                // App Tagline
                Text(
                  'Craft hilarious memes in seconds!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant, // Good for secondary text
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48), // Increased spacing before buttons

                // Call to Action Button: Create New Meme
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Create New Meme'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder( // Added rounded corners
                        borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () {
                    // TODO: Implement navigation to the meme creation flow.
                    // This could involve:
                    // 1. Navigator.push(context, MaterialPageRoute(builder: (context) => ActualMemeEditorScreen()));
                    // 2. Using a named route: Navigator.pushNamed(context, '/createMeme');
                    // 3. If part of a more complex flow within the "Create" tab, update local state.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Action: Navigate to Create New Meme flow!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Call to Action Button: View My History
                OutlinedButton.icon(
                  icon: const Icon(Icons.history_edu_outlined),
                  label: const Text('View My History'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.secondary, // Use secondary color for outline button
                    side: BorderSide(color: colorScheme.secondary, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder( // Added rounded corners
                        borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () {
                    // TODO: Implement navigation/switching to the History Tab.
                    // This depends on how MainScreen's state is managed or if a global
                    // navigation state (like Riverpod, Provider, BLoC) is used.
                    // Simplest for this structure might be to call a callback passed from MainScreen,
                    // or use a global key if MainScreen's state needs to be accessed directly (less ideal).
                    // For now, a SnackBar message:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Action: Switch to History Tab (index 1)!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    // Example if using DefaultTabController or similar context:
                    // TabController? tabController = DefaultTabController.of(context);
                    // if (tabController != null && tabController.index != 1) {
                    //   tabController.animateTo(1);
                    // }
                    // Or, if MainScreen's _onItemTapped is exposed via a state management solution.
                  },
                ),
                const SizedBox(height: 40), // Some padding at the bottom

                // Optional: A small inspirational or funny quote related to memes
                Text(
                  '"Memes are the DNA of the soul." - Richard Dawkins (paraphrased for fun)',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

