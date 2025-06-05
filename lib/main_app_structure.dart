import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'login_screen.dart'; // Import the actual LoginScreen
// import 'package:shared_preferences/shared_preferences.dart'; // User TODO

class LoginScreenPlaceholder extends StatelessWidget { 
  const LoginScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!; 
    return Scaffold(
      appBar: AppBar(title: Text(loc.loginScreenTitle)), 
      body: Center(child: Text(loc.loginScreenTitle)) 
    );
  }
}
class CreateScreenPlaceholder extends StatelessWidget { 
  const CreateScreenPlaceholder({super.key}); 
  @override Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(child: Text(loc.createTabLabel));
  }
}
class HistoryScreenPlaceholder extends StatelessWidget { 
  const HistoryScreenPlaceholder({super.key}); 
  @override Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(child: Text(loc.historyTabLabel));
  }
}
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[CreateScreenPlaceholder(), HistoryScreenPlaceholder()]; 
  
  Future<void> _performLogout() async { 
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!; 
    final theme = Theme.of(context);

    final bool? confirmLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
            final dialogLoc = AppLocalizations.of(context)!;
            return AlertDialog(
                title: Text(dialogLoc.logoutButtonTooltip), 
                content: Text(dialogLoc.appTitle + " - Confirm Logout?"), // Placeholder: Needs specific key e.g. confirmLogoutDialogMessage
                actions: <Widget>[
                    TextButton(
                        child: Text(dialogLoc.cancelButton),
                        onPressed: () => Navigator.of(context).pop(false),
                    ),
                    TextButton(
                        child: Text(dialogLoc.logoutButtonTooltip), 
                        onPressed: () => Navigator.of(context).pop(true),
                    ),
                ],
            );
        },
    );

    if (confirmLogout != true) return;

    scaffoldMessenger.removeCurrentSnackBar();
    scaffoldMessenger.showSnackBar(SnackBar(content: Text(loc.appTitle + " - Logging out..."))); // Placeholder: Needs specific key e.g. loggingOutSnackbar

    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
          scaffoldMessenger.removeCurrentSnackBar(); 
          scaffoldMessenger.showSnackBar(SnackBar(
            content: Text(loc.logoutSuccessfulSnackbar),
            backgroundColor: Colors.green.shade700,
          ));
      }
    } on AuthException catch (e) {
      if (mounted) {
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(loc.logoutFailedSnackbar(e.message)), 
          backgroundColor: theme.colorScheme.error
        ));
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.removeCurrentSnackBar();
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(loc.logoutFailedSnackbar(e.toString())), 
          backgroundColor: theme.colorScheme.error
        ));
      }
    }
  }
  
  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _showLanguageSelectionDialog(BuildContext parentContext) async {
      final loc = AppLocalizations.of(parentContext)!;
      
      final Locale? currentLocale = Localizations.localeOf(parentContext);
      final Locale? selectedLocale = await showDialog<Locale>(
        context: parentContext,
        builder: (BuildContext dialogContext) {
          final dialogLoc = AppLocalizations.of(dialogContext)!; // Use dialogContext for localizations
          return AlertDialog(
            title: Text(dialogLoc.languageButtonTooltip), 
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: AppLocalizations.supportedLocales.length,
                itemBuilder: (BuildContext context, int index) {
                  final locale = AppLocalizations.supportedLocales[index];
                  String languageName = locale.languageCode;
                  // These should be localized via ARB if more languages are added e.g. languageNameEn, languageNameEs
                  if (locale.languageCode == 'en') languageName = 'English';
                  if (locale.languageCode == 'es') languageName = 'Español';
                  return RadioListTile<Locale>(
                    title: Text(languageName),
                    value: locale,
                    groupValue: currentLocale,
                    onChanged: (Locale? newLocale) => Navigator.of(dialogContext).pop(newLocale),
                  );
                },
              ),
            ),
            actions: <Widget>[TextButton(child: Text(dialogLoc.cancelButton), onPressed: () => Navigator.of(dialogContext).pop())],
          );
        },
      );
      if (selectedLocale != null && mounted) {
        final memeAppState = parentContext.findAncestorStateOfType<_MemeAppState>();
        memeAppState?.changeLocale(selectedLocale);
      }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!; 
    final List<String> appBarTitles = [loc.createTabLabel, loc.historyTabLabel];
    final List<String> tabLabels = [loc.createTabLabel, loc.historyTabLabel];

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: loc.languageButtonTooltip,
            onPressed: () => _showLanguageSelectionDialog(context),
          ),
          IconButton(icon: const Icon(Icons.logout), tooltip: loc.logoutButtonTooltip, onPressed: _performLogout),
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
    // TODO: User: Add shared_preferences dependency and uncomment below
    /* 
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? languageCode = prefs.getString(_selectedLocaleKey);

      if (languageCode != null && languageCode.isNotEmpty) {
        final localeToSet = Locale(languageCode);
        if (AppLocalizations.supportedLocales.contains(localeToSet)) {
          if (mounted) {
            setState(() {
              _currentLocale = localeToSet;
            });
          }
        } else {
          print("Warning: Loaded unsupported locale code '$languageCode'. Falling back.");
          if (mounted) setState(() => _currentLocale = null); 
        }
      } else {
        if (mounted) setState(() => _currentLocale = null); 
      }
    } catch (e) {
      print("Error loading locale preference: $e");
      if (mounted) setState(() => _currentLocale = null); 
    }
    */
    if (mounted) {
      setState(() => _currentLocale = null); 
      print("Locale persistence (shared_preferences) not yet implemented. Defaulting locale.");
    }
  }

  void changeLocale(Locale newLocale) {
    if (!mounted) return;
    if (AppLocalizations.supportedLocales.contains(newLocale)) {
      setState(() {
        _currentLocale = newLocale;
      });
      _persistLocale(newLocale);
      print("App locale changed to: ${newLocale.languageCode}");
    } else {
      print("Warning: Attempted to change to an unsupported locale: ${newLocale.languageCode}");
    }
  }

  Future<void> _persistLocale(Locale locale) async {
    // TODO: User: Add shared_preferences dependency and uncomment below
    /*
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedLocaleKey, locale.languageCode);
      print("Locale preference '${locale.languageCode}' persisted.");
    } catch (e) {
      print("Error persisting locale preference: $e");
    }
    */
    print("Conceptual: Persisted locale '${locale.languageCode}' (shared_preferences TODO).");
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && Supabase.instance.client.auth.currentSession == null && _session == null) { 
      return const MaterialApp( // This initial MaterialApp won't have AppLocalizations yet.
        home: Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height:10), Text("Initializing App...")]))),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp(
      onGenerateTitle: (BuildContext context) {
        // Ensure AppLocalizations is available from this context
        return AppLocalizations.of(context)?.appTitle ?? 'M3M3s App';
      },
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
      home: _session == null ? const LoginScreen() : const MainScreen(), // Use the actual LoginScreen
      debugShowCheckedModeBanner: false,
    );
  }
}

