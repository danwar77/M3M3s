import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import the generated localizations file
// This path is standard if using flutter_localizations with generate: true
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Assuming LoginScreen and MainScreen (with its child screens) are defined
// For brevity, including minimal placeholders here. User should have their actual screens.
class LoginScreenPlaceholder extends StatelessWidget {
  const LoginScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.loginScreenTitle)),
      body: Center(child: Text(loc.loginScreenTitle)) // Example usage
    );
  }
}
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(child: Text(loc.createTabLabel)); // Using createTabLabel as placeholder content
  }
}
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(child: Text(loc.historyTabLabel)); // Using historyTabLabel as placeholder content
  }
}
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[CreateScreen(), HistoryScreen()];

  Future<void> _performLogout() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!; // Ensure localizations is available

    scaffoldMessenger.removeCurrentSnackBar();

    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(localizations.logoutSuccessfulSnackbar),
              backgroundColor: Colors.green.shade700
            ),
          );
      }
    } on AuthException catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(localizations.logoutFailedSnackbar(e.message)),
              backgroundColor: theme.colorScheme.error
            ),
          );
        }
    } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              // Consider a generic error key for e.toString() part
              content: Text('An unexpected error occurred during logout: ${e.toString()}'),
              backgroundColor: theme.colorScheme.error
            ),
          );
        }
    }
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Future<void> _showLanguageSelectionDialog(BuildContext parentContext) async {
    final AppLocalizations? currentLocalizations = AppLocalizations.of(parentContext);
    if (currentLocalizations == null) {
      ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text("Localizations not ready.")));
      return;
    }

    final Locale? currentLocale = Localizations.localeOf(parentContext);

    await showDialog<void>(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(currentLocalizations.languageButtonTooltip),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AppLocalizations.supportedLocales.length,
              itemBuilder: (BuildContext context, int index) {
                final locale = AppLocalizations.supportedLocales[index];
                String languageName = locale.languageCode;
                if (locale.languageCode == 'en') languageName = 'English'; // Ideally, these names would also be localized
                if (locale.languageCode == 'es') languageName = 'Español';

                return RadioListTile<Locale>(
                  title: Text(languageName),
                  value: locale,
                  groupValue: currentLocale,
                  onChanged: (Locale? newLocale) {
                    if (newLocale != null) {
                      Navigator.of(dialogContext).pop(newLocale);
                    }
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(currentLocalizations.cancelButton),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    ).then((selectedLocale) {
        if (selectedLocale != null && selectedLocale is Locale) {
            final memeAppState = parentContext.findAncestorStateOfType<_MemeAppState>();
            if (memeAppState != null) {
                memeAppState.changeLocale(selectedLocale);
            } else {
                print("Error: Could not find _MemeAppState to change locale.");
                ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(content: Text("Error: Could not change language state."), backgroundColor: Colors.red)
                );
            }
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!; // Ensure this is fetched
    final List<String> appBarTitles = [
      localizations.createTabLabel,
      localizations.historyTabLabel,
    ];
    final List<String> tabLabels = [
      localizations.createTabLabel,
      localizations.historyTabLabel,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: localizations.languageButtonTooltip,
            onPressed: () {
              _showLanguageSelectionDialog(context);
            },
          ),
          IconButton(icon: const Icon(Icons.logout), tooltip: localizations.logoutButtonTooltip, onPressed: _performLogout),
        ],
      ),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: const Icon(Icons.add_circle_outline), label: tabLabels[0]),
          BottomNavigationBarItem(icon: const Icon(Icons.history_outlined), label: tabLabels[1]),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  Session? _session;
  bool _isLoading = true;
  late final StreamSubscription<AuthState> _authStateSubscription;

  Locale? _currentLocale;
  static const String _selectedLocaleKey = 'selected_locale_code';

  @override
  void initState() {
    super.initState();
    _loadCurrentLocale();

    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() {
        _session = data.session;
      });
    });
    _checkInitialAuthAndSetLoading();
  }

  Future<void> _checkInitialAuthAndSetLoading() async {
    _session = Supabase.instance.client.auth.currentSession;
    if (_session == null) {
        await Future.delayed(const Duration(milliseconds: 250));
        _session = Supabase.instance.client.auth.currentSession;
    }
    if (mounted) {
        setState(() {
            _isLoading = false;
        });
    }
  }

  Future<void> _loadCurrentLocale() async {
    // TODO: User needs to add shared_preferences: ^latest_version to pubspec.yaml and uncomment
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // String? languageCode = prefs.getString(_selectedLocaleKey);

    String? languageCode;
    // languageCode = 'es'; // Uncomment to test Spanish by default

    if (languageCode != null && languageCode.isNotEmpty) {
      final localeToSet = Locale(languageCode);
      if (AppLocalizations.supportedLocales.contains(localeToSet)) {
          if (mounted) {
              setState(() { _currentLocale = localeToSet; });
          }
      } else {
          print("Warning: Loaded unsupported locale code '$languageCode'. Falling back.");
          if (mounted) setState(() => _currentLocale = null);
      }
    } else {
      if (mounted) setState(() => _currentLocale = null);
    }
  }

  void changeLocale(Locale newLocale) {
    if (!mounted) return;
    if (AppLocalizations.supportedLocales.contains(newLocale)) {
      setState(() {
        _currentLocale = newLocale;
      });
      _persistLocale(newLocale);
    } else {
      print("Warning: Attempted to change to unsupported locale: ${newLocale.languageCode}");
    }
  }

  Future<void> _persistLocale(Locale locale) async {
    // TODO: User needs to add shared_preferences: ^latest_version to pubspec.yaml and uncomment
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.setString(_selectedLocaleKey, locale.languageCode);
    print("Locale changed to: ${locale.languageCode} (Persistence with shared_preferences is conceptual)");
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MaterialApp will build its own context with AppLocalizations.
    // So, we access AppLocalizations *inside* the MaterialApp builder or its children.

    if (_isLoading && Supabase.instance.client.auth.currentSession == null && _session == null) {
      // For the initial loading screen, we can't use AppLocalizations yet if it's the very first MaterialApp.
      // So, hardcoded or a very basic localization is fine here.
      return const MaterialApp(
        home: Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height:10), Text("Initializing App...")]))),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp(
      // onGenerateTitle: (BuildContext context) { // Use onGenerateTitle for localized app title
      //   return AppLocalizations.of(context)?.appTitle ?? 'MemeMarvel App';
      // },
      // title: 'MemeMarvel App', // This is a fallback if onGenerateTitle is not used or if AppLocalizations is null.
                               // For simplicity, we'll keep the hardcoded one here for now, as AppLocalizations
                               // is primarily for widget content. The OS-level title is often set natively.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            elevation: 4.0,
        ),
      ),
      locale: _currentLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder( // Use Builder to ensure context has AppLocalizations
        builder: (context) {
          // Now AppLocalizations.of(context) is available for the title
          // However, MaterialApp.title is a simple string, not built with context.
          // The title displayed in task switchers etc. is often from AndroidManifest/Info.plist.
          // For in-app titles, AppBar is the place.
          // We can set a default non-localized title here, or use onGenerateTitle for context-aware title.
          // For simplicity, keeping a non-localized one or relying on native config.
          // If MemeApp was a child of another MaterialApp, then AppLocalizations.of(context) for title would work.
          return _session == null ? const LoginScreenPlaceholder() : const MainScreen();
        }
      ),
      // This title is for OS level, typically set in native files (AndroidManifest.xml, Info.plist)
      // or via onGenerateTitle for dynamic localization.
      // For simplicity, hardcoding or leaving it as is.
      // It's not the title shown in AppBars within the app.
      title: "MemeMarvel App", // Fallback/OS title
      debugShowCheckedModeBanner: false,
    );
  }
}
```
